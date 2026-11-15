//===- ToPlan.cpp - Compile lowered patterns into match plans -------------===//
//
// mpir-to-plan compiles each lowered mpir.pattern into an mpir_plan.matcher
// that matches it as SubtreeMatcher and InstructionMatcher do: from each
// root, over every instruction of the function; an instruction matcher
// checks its opcode, binds itself, then its block, its type-only operands,
// its flags, its keyed operands, its capture, its operand count and its
// operands in order; a matcher bound already matches only its binding.
// Constraints are checked at the end of the path that has bound what they
// read (see mpir_plan.check).
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/ToPlan.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Transforms/Lowering.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetOperations.h"

namespace llvm {
namespace metaphir {
namespace toplan {

using mlir::Attribute;
using mlir::Location;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;
namespace plan = mpir_plan;

static Sort sortOf(Value V) { return cast<SortType>(V.getType()).getSort(); }

/// Whether V is a meta variable: an mpir.var or a branch parameter.
static bool isVariable(Value V) {
  return isa<mlir::BlockArgument>(V) || V.getDefiningOp<VarOp>();
}

namespace {

/// The slots of a plan.
struct Slots {
  SmallVector<Attribute, 16> Names;
  SmallVector<int32_t, 16> Kinds;
  SmallVector<int32_t, 16> Sorts;
  SmallVector<Attribute, 16> Locs;
  DenseMap<Value, unsigned> Of;

  unsigned add(Value V, StringRef Name, plan::SlotKind Kind, Sort S,
               Location Loc, mlir::MLIRContext *Context) {
    unsigned Slot = Names.size();
    Names.push_back(mlir::StringAttr::get(Context, Name));
    Kinds.push_back(int32_t(Kind));
    Sorts.push_back(int32_t(S));
    Locs.push_back(Loc);
    Of[V] = Slot;
    return Slot;
  }
};

/// The slots known bound on a path.
struct BoundState {
  DenseSet<unsigned> Certain;
  /// Bound on some paths that join here.
  DenseSet<unsigned> Maybe;
};

class Compiler {
public:
  Compiler(PatternOp Pattern, OpBuilder &Builder)
      : Pattern(Pattern), Builder(Builder), Context(Builder.getContext()) {}

  plan::MatcherOp compile();

private:
  PatternOp Pattern;
  OpBuilder &Builder;
  mlir::MLIRContext *Context;
  Slots S;
  BoundState Bound;

  plan::RegType reg() { return plan::RegType::get(Context); }
  mlir::IntegerAttr i32(int64_t V) { return Builder.getI32IntegerAttr(V); }

  void assignSlots();
  unsigned slotOf(Value V) const { return S.Of.lookup(V); }

  /// Matches V against what Reg holds.
  void matchValue(Value V, Value Reg, bool TreatIntAsVec);
  void matchInstruction(InstOp Inst, Value Reg);
  void matchAlternatives(AltOp Alt, Value Reg);
  /// Matches the matcher V, an instruction or alternative, against Reg: by
  /// its binding if bound, or else in full (and at run time when only some
  /// paths bind it).
  void matchMatcher(Value V, Value Reg, function_ref<void()> Full);
  /// Matches the matchers of Block that the path has not bound, each against
  /// every instruction, and then checks Block's constraints.
  void finishBlock(mlir::Block &Block, ArrayRef<Operation *> Roots);
  void bindVariable(Value Reg, Value Var, bool AsSort);

  mlir::ArrayAttr typePattern(Value T);

  /// Clones the expression E into the plan, reading slots.
  Value cloneExpression(Value E, mlir::IRMapping &Mapping);
  void check(RequireOp Require);
};

} // namespace

void Compiler::assignSlots() {
  // Instruction matchers and alternatives, and the meta variables, in the
  // order they are written. A matcher an alternative yields is matched for
  // it, and shares its slot.
  Pattern.walk<mlir::WalkOrder::PreOrder>([&](Operation *Op) {
    Location Loc = Op->getLoc();
    if (auto Var = dyn_cast<VarOp>(Op)) {
      S.add(Var, Var.getVarName(), plan::SlotKind::Variable,
            resolveSort(sortOf(Var)), Loc, Context);
      return;
    }
    if (!isa<InstOp, AltOp>(Op))
      return;
    Value Result = Op->getResult(0);
    // The alternative this one is yielded by, outermost first.
    Value Outer = Result;
    while (true) {
      AltOp Yielding;
      // Only an alternative's own matcher: one ':o' yields in its place is
      // not the alternative's.
      for (Operation *User : Outer.getUsers())
        if (auto Yield = dyn_cast<YieldOp>(User))
          if (auto Alt = dyn_cast<AltOp>(Yield->getParentOp()))
            if (Outer.getDefiningOp() &&
                Outer.getDefiningOp()->getBlock() == Yield->getBlock())
              Yielding = Alt;
      if (!Yielding)
        break;
      Outer = Yielding.getResult();
    }
    if (Outer != Result) {
      // A yielded matcher of an alternative of an alternative: the
      // outermost's slot, assigned when it was walked.
      S.Of[Result] = S.Of.lookup(Outer);
      return;
    }
    StringRef Name;
    std::string OpcodeName;
    if (auto Inst = dyn_cast<InstOp>(Op)) {
      Name = Inst.getResultName().value_or("");
      OpcodeName =
          ("" + Instruction::getOpcodeName(Inst.getOpcode().getValue())).str();
    } else {
      if (auto N = Op->getAttrOfType<mlir::StringAttr>("result_name"))
        Name = N.getValue();
      // An unnamed alternative of one instruction matcher (its ':c' orders,
      // or its ':o') is named by its opcode, as the matcher is.
      Operation *Inner = Op;
      while (auto Alt = dyn_cast_or_null<AltOp>(Inner)) {
        if (Alt->getNumRegions() == 0 ||
            !(Alt->hasAttr("commuted") || Alt->hasAttr("or_self_region")))
          break;
        unsigned Region = 0;
        if (auto R = Alt->getAttrOfType<mlir::IntegerAttr>("or_self_region"))
          // The region of the matcher itself, not of its operand.
          Region = R.getInt() == 0 ? 1 : 0;
        if (Region >= Alt->getNumRegions())
          break;
        Inner = (*Alt->getRegion(Region).front().getOps<YieldOp>().begin())
                    .getValue()
                    .getDefiningOp();
      }
      if (auto Inst = dyn_cast_or_null<InstOp>(Inner))
        OpcodeName =
            ("" + Instruction::getOpcodeName(Inst.getOpcode().getValue()))
                .str();
    }
    std::string Printed = Name.empty() ? OpcodeName : ("%" + Name).str();
    S.add(Result, Printed, plan::SlotKind::Instruction, Sort::Instruction, Loc,
          Context);
  });
  // Branch parameters left in the lowered pattern (unbound ones) are
  // variables too.
}

mlir::ArrayAttr Compiler::typePattern(Value T) {
  SmallVector<Attribute, 8> Parts;
  auto Int = [&](int64_t V) { Parts.push_back(Builder.getI64IntegerAttr(V)); };
  Operation *Def = T.getDefiningOp();
  if (!Def || isa<VarOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Variable));
    Int(slotOf(T));
  } else if (auto Prim = dyn_cast<PrimTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Primitive));
    Int(Prim.getKind());
  } else if (auto IntTy = dyn_cast<IntTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Integer));
    Int(IntTy.getWidth());
    Int(IntTy.getByte());
  } else if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::MetaInteger));
    Int(slotOf(Meta.getWidth()));
    Int(Meta.getByte());
  } else if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Pointer));
    std::optional<uint32_t> Space = Ptr.getAddressSpace();
    Int(Space ? int64_t(*Space) : -1);
    Int(!Ptr.getElement());
  } else if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Sequence));
    Int(Seq.getKind());
    Int(Seq.getCount());
    Int(Seq.getCountVar() ? int64_t(slotOf(Seq.getCountVar())) : -1);
    Parts.push_back(typePattern(Seq.getElement()));
  } else if (auto Struct = dyn_cast<StructTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Struct));
    Int(Struct.getPacked());
    for (Value E : Struct.getElements())
      Parts.push_back(typePattern(E));
  } else if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
    Int(int64_t(plan::TypePatternKind::Function));
    Int(Func.getVarArg());
    Parts.push_back(typePattern(Func.getReturnType()));
    for (Value P : Func.getParams())
      Parts.push_back(typePattern(P));
  } else {
    llvm_unreachable("not a type pattern");
  }
  return Builder.getArrayAttr(Parts);
}

void Compiler::bindVariable(Value Reg, Value Var, bool AsSort) {
  unsigned Slot = slotOf(Var);
  auto Bind = plan::BindOp::create(Builder, Var.getLoc(), Reg, i32(Slot),
                                   mlir::IntegerAttr());
  if (AsSort)
    Bind.setSort(int32_t(resolveSort(sortOf(Var))));
  Bound.Certain.insert(Slot);
  Bound.Maybe.erase(Slot);
}

void Compiler::matchValue(Value V, Value Reg, bool TreatIntAsVec) {
  Operation *Def = V.getDefiningOp();
  Location Loc = V.getLoc();
  if (isVariable(V)) {
    bindVariable(Reg, V, /*AsSort=*/true);
    return;
  }
  if (auto Inst = dyn_cast<InstOp>(Def)) {
    matchMatcher(V, Reg, [&] { matchInstruction(Inst, Reg); });
    return;
  }
  if (auto Alt = dyn_cast<AltOp>(Def)) {
    matchMatcher(V, Reg, [&] { matchAlternatives(Alt, Reg); });
    return;
  }
  if (auto Int = dyn_cast<IntOp>(Def)) {
    auto Check =
        plan::CheckConstantOp::create(Builder, Loc, Reg, Int.getValueAttr());
    if (TreatIntAsVec)
      Check.setTreatIntAsVec(true);
    return;
  }
  if (auto Float = dyn_cast<FloatOp>(Def)) {
    plan::CheckConstantOp::create(Builder, Loc, Reg, Float.getValue());
    return;
  }
  if (auto Keyword = dyn_cast<KeywordOp>(Def)) {
    auto Check = plan::CheckConstantOp::create(Builder, Loc, Reg,
                                               Keyword.getKeywordAttr());
    Check.setKeyword(true);
    return;
  }
  if (auto Global = dyn_cast<GlobalOp>(Def)) {
    plan::CheckConstantOp::create(Builder, Loc, Reg, Global.getNameAttr());
    return;
  }
  if (auto Aggregate = dyn_cast<AggregateOp>(Def)) {
    mlir::OperandRange Elements = Aggregate.getElements();
    plan::CheckAggregateOp::create(Builder, Loc, Reg,
                                   i32(Aggregate.getDelimiter()),
                                   i32(Elements.size() / 2));
    for (unsigned I = 0; I + 1 < Elements.size(); I += 2) {
      Value Element =
          plan::GetElementOp::create(Builder, Loc, reg(), Reg, i32(I / 2));
      matchValue(Elements[I + 1], Element, /*TreatIntAsVec=*/false);
    }
    return;
  }
  llvm_unreachable("not a pattern value");
}

void Compiler::matchMatcher(Value V, Value Reg, function_ref<void()> Full) {
  unsigned Slot = slotOf(V);
  Location Loc = V.getLoc();
  if (Bound.Certain.contains(Slot)) {
    plan::BindOp::create(Builder, Loc, Reg, i32(Slot), mlir::IntegerAttr());
    return;
  }
  if (!Bound.Maybe.contains(Slot)) {
    Full();
    return;
  }
  // Bound on some paths only: by its binding where it is bound.
  auto Either =
      plan::EitherOp::create(Builder, Loc, mlir::TypeRange(), /*count=*/2);
  BoundState Before = Bound;
  {
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Either->getRegion(0).emplaceBlock());
    plan::CheckBoundOp::create(Builder, Loc, i32(Slot),
                               Builder.getBoolAttr(true));
    plan::BindOp::create(Builder, Loc, Reg, i32(Slot), mlir::IntegerAttr());
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
  }
  BoundState First = Bound;
  First.Certain.insert(Slot);
  Bound = Before;
  {
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Either->getRegion(1).emplaceBlock());
    plan::CheckBoundOp::create(Builder, Loc, i32(Slot),
                               Builder.getBoolAttr(false));
    Full();
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
  }
  // Bound either way now; what else each path bound may differ.
  BoundState Joined;
  for (unsigned Slot : First.Certain)
    (Bound.Certain.contains(Slot) ? Joined.Certain : Joined.Maybe).insert(Slot);
  for (unsigned Slot : Bound.Certain)
    if (!First.Certain.contains(Slot))
      Joined.Maybe.insert(Slot);
  set_union(Joined.Maybe, First.Maybe);
  set_union(Joined.Maybe, Bound.Maybe);
  for (unsigned Slot : Joined.Certain)
    Joined.Maybe.erase(Slot);
  Bound = std::move(Joined);
}

void Compiler::matchInstruction(InstOp Inst, Value Reg) {
  Location Loc = Inst.getLoc();
  bool TreatIntAsVec = Inst.getTreatIntAsVec().value_or(false);
  Instruction::InstructionID ID = Inst.getOpcode().getValue();
  plan::CheckOpcodeOp::create(Builder, Loc, Reg, Inst.getOpcodeAttr());
  unsigned Slot = slotOf(Inst.getResult());
  plan::BindOp::create(Builder, Loc, Reg, i32(Slot), mlir::IntegerAttr());
  Bound.Certain.insert(Slot);
  Bound.Maybe.erase(Slot);

  if (Value Block = Inst.getParentBlock()) {
    Value Parent = plan::GetParentBlockOp::create(Builder, Loc, reg(), Reg);
    bindVariable(Parent, Block, /*AsSort=*/false);
  }
  SmallVector<MatcherOperandView, 8> Operands = getMatcherOperands(Inst);
  // Type-only operands are matched against the result's type (or an
  // alloca's or getelementptr's).
  for (const MatcherOperandView &Op : Operands) {
    if (Op.Kind != OperandKind::TypeOnly)
      continue;
    auto Type = plan::GetTypeOp::create(Builder, Loc, reg(), Reg);
    Type.setOperandOf(true);
    auto Check =
        plan::CheckTypeOp::create(Builder, Loc, Type, typePattern(Op.Type));
    if (TreatIntAsVec)
      Check.setTreatIntAsVec(true);
  }
  // A flag the matcher does not write matches either way.
  {
    unsigned NextCapture = 0;
    for (auto [Flag, Mode] : zip(Inst.getFlags(), Inst.getFlagModes())) {
      switch (FlagMode(Mode)) {
      case FlagMode::Required:
      case FlagMode::Negated:
        plan::CheckFlagOp::create(
            Builder, Loc, Reg, i32(Flag),
            Builder.getBoolAttr(FlagMode(Mode) == FlagMode::Required));
        break;
      case FlagMode::Captured: {
        Value Present =
            plan::GetFlagOp::create(Builder, Loc, reg(), Reg, i32(Flag));
        bindVariable(Present, Inst.getFlagCaptures()[NextCapture++],
                     /*AsSort=*/false);
        break;
      }
      }
    }
  }
  // Keyed integer operands, in the order of their kinds.
  for (OperandKind Kind :
       {OperandKind::Alignment, OperandKind::AddressSpace,
        OperandKind::InRangeLower, OperandKind::InRangeUpper}) {
    for (const MatcherOperandView &Op : Operands) {
      if (Op.Kind != Kind)
        continue;
      Value Keyed = plan::GetKeyedOp::create(Builder, Loc, reg(), Reg,
                                             i32(int32_t(Kind)));
      if (isVariable(Op.Val))
        bindVariable(Keyed, Op.Val, /*AsSort=*/false);
      else
        plan::CheckConstantOp::create(
            Builder, Loc, Keyed,
            cast<IntOp>(Op.Val.getDefiningOp()).getValueAttr());
    }
  }
  if (Value Capture = Inst.getCapture())
    bindVariable(Reg, Capture, /*AsSort=*/false);

  SmallVector<const MatcherOperandView *, 8> Values;
  for (const MatcherOperandView &Op : Operands)
    if (isValueOperand(Op.Kind))
      Values.push_back(&Op);
  bool HasArray =
      !Values.empty() && (Values.back()->Kind == OperandKind::ValueArray ||
                          Values.back()->Kind == OperandKind::TypedValueArray);
  auto Count = plan::CheckOperandCountOp::create(
      Builder, Loc, Reg, i32(HasArray ? Values.size() - 1 : Values.size()));
  if (HasArray)
    Count.setAtLeast(true);
  // A compare's predicate, of its operands in the order they are matched.
  for (const MatcherOperandView &Op : Operands) {
    if (Op.Kind != OperandKind::Predicate)
      continue;
    auto Predicate = plan::GetKeyedOp::create(
        Builder, Loc, reg(), Reg, i32(int32_t(OperandKind::Predicate)));
    if (Inst.getSwappedPredicate())
      Predicate.setSwapped(true);
    (void)ID;
    if (isVariable(Op.Val)) {
      bindVariable(Predicate, Op.Val, /*AsSort=*/false);
    } else {
      auto Keyword = cast<KeywordOp>(Op.Val.getDefiningOp());
      auto Check = plan::CheckConstantOp::create(Builder, Loc, Predicate,
                                                 Keyword.getKeywordAttr());
      Check.setKeyword(true);
    }
  }
  for (auto [Index, Op] : enumerate(Values)) {
    Location OpLoc = Op->Val ? Op->Val.getLoc() : Loc;
    if (Op->Kind == OperandKind::ValueArray ||
        Op->Kind == OperandKind::TypedValueArray) {
      Value Array = plan::GetOperandsFromOp::create(Builder, OpLoc, reg(), Reg,
                                                    i32(Index));
      bindVariable(Array, Op->Val, /*AsSort=*/false);
      if (Op->Kind == OperandKind::TypedValueArray) {
        auto Types = plan::GetOperandsFromOp::create(Builder, OpLoc, reg(), Reg,
                                                     i32(Index));
        Types.setTypes(true);
        bindVariable(Types, Op->Type, /*AsSort=*/false);
      }
      continue;
    }
    Value Operand =
        plan::GetOperandOp::create(Builder, OpLoc, reg(), Reg, i32(Index));
    if (Op->Type) {
      Value Type = plan::GetTypeOp::create(Builder, OpLoc, reg(), Operand);
      auto Check = plan::CheckTypeOp::create(Builder, OpLoc, Type,
                                             typePattern(Op->Type));
      if (TreatIntAsVec)
        Check.setTreatIntAsVec(true);
    }
    matchValue(Op->Val, Operand, TreatIntAsVec);
  }
}

void Compiler::matchAlternatives(AltOp Alt, Value Reg) {
  Location Loc = Alt.getLoc();
  unsigned Slot = slotOf(Alt.getResult());
  if (Alt->getNumRegions() == 0) {
    // No branch fits: nothing matches.
    plan::CheckBoundOp::create(Builder, Loc, i32(Slot),
                               Builder.getBoolAttr(true));
    plan::CheckBoundOp::create(Builder, Loc, i32(Slot),
                               Builder.getBoolAttr(false));
    return;
  }
  auto Either = plan::EitherOp::create(Builder, Loc, mlir::TypeRange(),
                                       Alt->getNumRegions());
  BoundState Before = Bound;
  std::optional<BoundState> Joined;
  for (auto [Index, Region] : enumerate(Alt->getRegions())) {
    Bound = Before;
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Either->getRegion(Index).emplaceBlock());
    mlir::Block &Block = Region.front();
    auto Yield = *Block.getOps<YieldOp>().begin();
    Value Yielded = Yield.getValue();
    matchValue(Yielded, Reg, /*TreatIntAsVec=*/false);
    // A value matched in place of the alternative is the alternative's
    // binding too.
    if (slotOf(Yielded) != Slot || !S.Of.count(Yielded)) {
      plan::BindOp::create(Builder, Loc, Reg, i32(Slot), mlir::IntegerAttr());
      Bound.Certain.insert(Slot);
    }
    for (BindOp Bind : Block.getOps<BindOp>()) {
      if (auto Int = Bind.getValue().getDefiningOp<IntOp>()) {
        plan::BindConstantOp::create(
            Builder, Bind.getLoc(), i32(slotOf(Bind.getVariable())),
            Builder.getBoolAttr(!Int.getValue().isZero()));
        Bound.Certain.insert(slotOf(Bind.getVariable()));
        continue;
      }
      bindVariable(Reg, Bind.getVariable(), /*AsSort=*/false);
    }
    SmallVector<Operation *, 4> Roots = getPatternRoots(Block);
    finishBlock(Block, Roots);
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
    if (!Joined) {
      Joined = Bound;
      continue;
    }
    BoundState Next;
    for (unsigned S : Joined->Certain)
      (Bound.Certain.contains(S) ? Next.Certain : Next.Maybe).insert(S);
    for (unsigned S : Bound.Certain)
      if (!Joined->Certain.contains(S))
        Next.Maybe.insert(S);
    set_union(Next.Maybe, Joined->Maybe);
    set_union(Next.Maybe, Bound.Maybe);
    for (unsigned S : Next.Certain)
      Next.Maybe.erase(S);
    Joined = std::move(Next);
  }
  Bound = std::move(*Joined);
}

void Compiler::finishBlock(mlir::Block &Block, ArrayRef<Operation *> Roots) {
  // Roots first, then any matcher the path left unbound: a block's
  // instructions all match.
  SmallVector<Operation *, 8> Order(Roots.begin(), Roots.end());
  for (Operation &Op : Block)
    if (isa<InstOp, AltOp>(Op) && !is_contained(Order, &Op))
      Order.push_back(&Op);
  for (Operation *Op : Order) {
    Value V = Op->getResult(0);
    if (Bound.Certain.contains(slotOf(V)))
      continue;
    Location Loc = Op->getLoc();
    auto MatchAnywhere = [&] {
      Value Each = plan::ForeachInstructionOp::create(Builder, Loc, reg());
      matchValue(V, Each, /*TreatIntAsVec=*/false);
    };
    if (!Bound.Maybe.contains(slotOf(V))) {
      MatchAnywhere();
      continue;
    }
    matchMatcher(V, Value(), MatchAnywhere);
  }
  for (RequireOp Require : Block.getOps<RequireOp>())
    check(Require);
}

Value Compiler::cloneExpression(Value E, mlir::IRMapping &Mapping) {
  if (Value Mapped = Mapping.lookupOrNull(E))
    return Mapped;
  Operation *Def = E.getDefiningOp();
  Location Loc = E.getLoc();
  Value Result;
  if (!Def || isa<VarOp, InstOp, AltOp>(Def)) {
    // A pattern value: its slot.
    unsigned Slot = slotOf(E);
    auto SlotOp = plan::SlotOp::create(Builder, Loc, E.getType(), i32(Slot));
    StringRef Name = cast<mlir::StringAttr>(S.Names[Slot]).getValue();
    if (S.Kinds[Slot] == int32_t(plan::SlotKind::Instruction))
      SlotOp->setAttr("result_name",
                      Builder.getStringAttr(
                          Name.starts_with("%") ? Name.drop_front() : Name));
    else
      SlotOp->setAttr("var_name", Builder.getStringAttr(Name));
    Result = SlotOp;
  } else if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def);
             Read && Read.getValue().getDefiningOp<IntOp>()) {
    // A parameter a matcher's use binds to a constant reads as that
    // number, as a boolean if read as one.
    mlir::IntegerAttr Value =
        Read.getValue().getDefiningOp<IntOp>().getValueAttr();
    APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
    if (sortOf(Read) == Sort::Boolean && Number.getBitWidth() == 1)
      Result = mpir_expr::BoolOp::create(Builder, Loc, !Number.isZero());
    else {
      bool Negative = Number.isSigned() && Number.isNegative();
      APSInt Literal =
          Negative ? APSInt(Number.sextOrTrunc(
                                std::max(64u, Number.getSignificantBits())),
                            false)
                   : APSInt(Number.zextOrTrunc(
                                std::max(64u, Number.getActiveBits())),
                            true);
      Result = mpir_expr::IntOp::create(Builder, Loc, Literal);
    }
  } else {
    for (Value Operand : Def->getOperands())
      cloneExpression(Operand, Mapping);
    Result = Builder.clone(*Def, Mapping)->getResult(0);
  }
  Mapping.map(E, Result);
  return Result;
}

void Compiler::check(RequireOp Require) {
  mlir::IRMapping Mapping;
  Value Condition = cloneExpression(Require.getCondition(), Mapping);
  auto Check = plan::CheckOp::create(Builder, Require.getLoc(), Condition);
  if (Require->hasAttr("from_metaflag"))
    Check.setFromMetaflag(true);
}

plan::MatcherOp Compiler::compile() {
  assignSlots();
  auto Matcher = plan::MatcherOp::create(
      Builder, Pattern.getLoc(), Builder.getArrayAttr({}),
      Builder.getDenseI32ArrayAttr({}), Builder.getDenseI32ArrayAttr({}),
      Builder.getArrayAttr({}));
  mlir::Block &Body = Matcher.getBody().emplaceBlock();
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Body);
  mlir::Block &PatternBlock = Pattern.getBody().front();
  finishBlock(PatternBlock, getPatternRoots(PatternBlock));
  plan::EmitOp::create(Builder, Pattern.getLoc());
  Matcher.setSlotNamesAttr(Builder.getArrayAttr(S.Names));
  Matcher.setSlotKinds(S.Kinds);
  Matcher.setSlotSorts(S.Sorts);
  Matcher.setSlotLocsAttr(Builder.getArrayAttr(S.Locs));
  return Matcher;
}

namespace {
struct ToPlanPass
    : public mlir::PassWrapper<ToPlanPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(ToPlanPass)
  StringRef getArgument() const override { return "mpir-to-plan"; }
  StringRef getDescription() const override {
    return "Compile lowered patterns into match plans";
  }
  void getDependentDialects(mlir::DialectRegistry &Registry) const override {
    Registry.insert<plan::PlanDialect>();
  }
  void runOnOperation() override {
    OpBuilder Builder(&getContext());
    for (PatternOp Pattern :
         llvm::make_early_inc_range(getOperation().getOps<PatternOp>())) {
      Builder.setInsertionPointAfter(Pattern);
      Compiler(Pattern, Builder).compile();
    }
  }
};
} // namespace

} // namespace toplan

std::unique_ptr<mlir::Pass> createToPlanPass() {
  return std::make_unique<toplan::ToPlanPass>();
}

void registerToPlanPass() { mlir::PassRegistration<toplan::ToPlanPass>(); }

} // namespace metaphir
} // namespace llvm
