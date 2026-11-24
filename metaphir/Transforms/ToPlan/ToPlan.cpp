//===- ToPlan.cpp - Compile lowered patterns into match plans -------------===//
//
// mpir-to-plan compiles each lowered mpir.pattern into an mpir_plan.matcher
// that matches it: from each root, over every instruction of the function;
// an instruction matcher
// checks its opcode, binds itself, then its block, its type-only operands,
// its flags, its keyed operands, its capture, its operand count and its
// operands in order; a matcher bound already matches only its binding.
// Constraints are checked at the end of the path that has bound what they
// read (see mpir_plan.check).
//
//===----------------------------------------------------------------------===//

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/Bindings.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/IR/PatternSettings.h"
#include "metaphir/Transforms/ToPlan/Passes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetOperations.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallString.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_TOPLANPASS
#include "metaphir/Transforms/ToPlan/Passes.h.inc"
namespace toplan {

using mlir::Attribute;
using mlir::Location;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;
namespace plan = mpir_plan;

/// Whether V is a meta variable. Lowering leaves no branch parameter: each
/// is what its use passes.
static bool isVariable(Value V) { return V.getDefiningOp<VarOp>(); }

namespace {

/// The slots of a plan, and what the plan records of each.
struct Slots {
  SlotAssignment Assigned;
  SmallVector<Attribute, 16> Names;
  SmallVector<plan::SlotKind, 16> Kinds;
  SmallVector<Sort, 16> Sorts;
  SmallVector<Attribute, 16> Locs;
  /// The name a constraint reads each slot by: a variable's name, or an
  /// instruction's ('r' for '%r'), unlike Names, which are as printed.
  SmallVector<std::string, 16> ReadNames;

  void describe(StringRef Name, StringRef ReadName, plan::SlotKind Kind, Sort S,
                Location Loc, mlir::MLIRContext *Context) {
    Names.push_back(mlir::StringAttr::get(Context, Name));
    ReadNames.push_back(ReadName.str());
    Kinds.push_back(Kind);
    Sorts.push_back(S);
    Locs.push_back(Loc);
  }
};

/// The slots known bound on a path.
struct BoundState {
  DenseSet<unsigned> Certain;
  /// Bound on some paths that join here.
  DenseSet<unsigned> Maybe;

  void bind(unsigned Slot) {
    Certain.insert(Slot);
    Maybe.erase(Slot);
  }

  /// What is known bound where paths A and B join: certainly what both bound
  /// certainly, maybe whatever else either bound.
  static BoundState join(const BoundState &A, const BoundState &B) {
    BoundState Joined;
    for (unsigned Slot : A.Certain)
      (B.Certain.contains(Slot) ? Joined.Certain : Joined.Maybe).insert(Slot);
    for (unsigned Slot : B.Certain)
      if (!A.Certain.contains(Slot))
        Joined.Maybe.insert(Slot);
    set_union(Joined.Maybe, A.Maybe);
    set_union(Joined.Maybe, B.Maybe);
    for (unsigned Slot : Joined.Certain)
      Joined.Maybe.erase(Slot);
    return Joined;
  }
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
  unsigned slotOf(Value V) const {
    auto It = S.Assigned.Of.find(V);
    assert(It != S.Assigned.Of.end() && "a value a match binds has a slot");
    return It->second;
  }

  mlir::ArrayAttr typePattern(Value T);
  /// Binds the slot of V, a meta variable or matcher, to what Reg holds:
  /// BySort, read as V's sort reads IR values (failing the path if it
  /// cannot be), else as it is.
  void bind(Value Reg, Value V, bool BySort);
  /// Matches the matcher V, an instruction or alternative, against Reg: by
  /// its binding if bound, or else in full (and at run time when only some
  /// paths bind it).
  void matchMatcher(Value V, Value Reg, function_ref<void()> Full);
  /// Checks that Type, the type of what is matched, is of the type pattern
  /// Pattern.
  void checkType(Location Loc, Value Type, Value Pattern, bool TreatIntAsVec);
  /// What matchInstruction checks and binds of Reg, the instruction Inst
  /// matches: its flags, its keyed operands, and its operand count and
  /// operands.
  void matchFlags(InstOp Inst, Value Reg);
  void matchKeyedOperands(ArrayRef<MatcherOperandView> Operands, Value Reg,
                          Location Loc);
  void matchOperands(ArrayRef<MatcherOperandView> Operands, Value Reg,
                     Location Loc, bool TreatIntAsVec);
  void matchInstruction(InstOp Inst, Value Reg);
  void matchAlternatives(AltOp Alt, Value Reg);
  /// Matches V against what Reg holds.
  void matchValue(Value V, Value Reg, bool TreatIntAsVec);

  /// Clones the expression E into the plan, reading slots.
  Value cloneExpression(Value E, mlir::IRMapping &Mapping);
  void check(RequireOp Require);
  void let(LetOp Let);

  /// Matches the matchers of Block that the path has not bound, each against
  /// every instruction, and then checks Block's constraints.
  void finishBlock(mlir::Block &Block, ArrayRef<Operation *> Roots);
};

} // namespace

/// The opcode every instruction matcher Op's alternatives yield has, if they
/// yield one and agree: an alternative yielding a value from outside it (an
/// operand in its place) has none to disagree with.
static std::optional<instruction::InstructionID> sharedOpcode(Operation *Op) {
  if (auto Inst = dyn_cast<InstOp>(Op))
    return Inst.getOpcode().getValue();
  auto Alt = dyn_cast<AltOp>(Op);
  if (!Alt)
    return std::nullopt;
  std::optional<instruction::InstructionID> Shared;
  for (mlir::Region &Region : Alt->getRegions()) {
    Operation *Yielded =
        (*Region.front().getOps<YieldOp>().begin()).getValue().getDefiningOp();
    if (!Yielded || Yielded->getBlock() != &Region.front())
      continue;
    std::optional<instruction::InstructionID> ID = sharedOpcode(Yielded);
    if (!ID || (Shared && *Shared != *ID))
      return std::nullopt;
    Shared = ID;
  }
  return Shared;
}

/// Numbers every value a match binds before anything is compiled (see
/// plan::assignSlots), and records each slot's name, kind, sort and location
/// to print the match and report errors.
void Compiler::assignSlots() {
  S.Assigned = mpir::assignSlots(Pattern);
  for (Value V : S.Assigned.Values) {
    Operation *Op = V.getDefiningOp();
    Location Loc = Op->getLoc();
    if (auto Var = dyn_cast<VarOp>(Op)) {
      S.describe(Var.getVarName(), Var.getVarName(), plan::SlotKind::Variable,
                 resolveSort(sortOf(Var)), Loc, Context);
      continue;
    }
    // Name the slot for printing by the pattern's '%name', or by its opcode
    // if the pattern leaves it unnamed.
    StringRef Name;
    StringRef OpcodeName;
    if (auto Inst = dyn_cast<InstOp>(Op)) {
      Name = Inst.getResultName().value_or("");
      OpcodeName = instruction::getOpcodeName(Inst.getOpcode().getValue());
    } else {
      if (auto N =
              Op->getAttrOfType<mlir::StringAttr>(mpir::ResultNameAttrName))
        Name = N.getValue();
      // An unnamed alt whose alternatives match instructions of one opcode
      // (the operand orders of one, or one or its operand) is named by it.
      if (std::optional<instruction::InstructionID> ID = sharedOpcode(Op))
        OpcodeName = instruction::getOpcodeName(*ID);
    }
    SmallString<32> Printed;
    if (Name.empty())
      Printed = OpcodeName;
    else
      ("%" + Name).toVector(Printed);
    S.describe(Printed, Name.empty() ? OpcodeName : Name,
               plan::SlotKind::Instruction, Sort::Instruction, Loc, Context);
  }
}

mlir::ArrayAttr Compiler::typePattern(Value T) {
  return mpir::encodeTypePattern(Builder, T, S.Assigned);
}

void Compiler::bind(Value Reg, Value V, bool BySort) {
  unsigned Slot = slotOf(V);
  auto Bind = plan::BindOp::create(Builder, V.getLoc(), Reg, i32(Slot),
                                   mlir::IntegerAttr());
  if (BySort)
    Bind.setSort(int32_t(resolveSort(sortOf(V))));
  Bound.bind(Slot);
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
    // Compared with what is there; after the roots, nothing is.
    if (Reg)
      plan::BindOp::create(Builder, Loc, Reg, i32(Slot), mlir::IntegerAttr());
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
  }
  BoundState First = Bound;
  First.bind(Slot);
  Bound = Before;
  {
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Either->getRegion(1).emplaceBlock());
    plan::CheckBoundOp::create(Builder, Loc, i32(Slot),
                               Builder.getBoolAttr(false));
    // Record that the check leaves it unbound here, so that a Full that
    // matches V again matches it in full instead of checking again.
    Bound.Maybe.erase(Slot);
    Full();
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
  }
  // Bound either way now; what else each path bound may differ.
  Bound = BoundState::join(First, Bound);
}

void Compiler::checkType(Location Loc, Value Type, Value Pattern,
                         bool TreatIntAsVec) {
  auto Check =
      plan::CheckTypeOp::create(Builder, Loc, Type, typePattern(Pattern));
  if (TreatIntAsVec)
    Check.setTreatIntAsVec(true);
}

void Compiler::matchFlags(InstOp Inst, Value Reg) {
  // A flag the matcher does not write matches either way.
  Location Loc = Inst.getLoc();
  unsigned NextCapture = 0;
  for (auto [Flag, Mode] : zip(Inst.getFlags(), Inst.getFlagModes())) {
    switch (Mode) {
    case FlagMode::Required:
    case FlagMode::Negated:
      plan::CheckFlagOp::create(
          Builder, Loc, Reg, Flag,
          Builder.getBoolAttr(FlagMode(Mode) == FlagMode::Required));
      break;
    case FlagMode::Captured: {
      Value Present = plan::GetFlagOp::create(Builder, Loc, reg(), Reg, Flag);
      bind(Present, Inst.getFlagCaptures()[NextCapture++], /*BySort=*/false);
      break;
    }
    }
  }
}

void Compiler::matchKeyedOperands(ArrayRef<MatcherOperandView> Operands,
                                  Value Reg, Location Loc) {
  // In the order they are written; each is an integer, or a compare's
  // predicate, a keyword.
  for (const MatcherOperandView &Op : Operands) {
    if (!isKeyedOperand(Op.Kind))
      continue;
    Value Got = plan::GetKeyedOp::create(Builder, Loc, reg(), Reg, Op.Kind);
    if (isVariable(Op.Val)) {
      bind(Got, Op.Val, /*BySort=*/false);
    } else if (auto Keyword = Op.Val.getDefiningOp<KeywordOp>()) {
      auto Check = plan::CheckConstantOp::create(
          Builder, Loc, Got, Builder.getI32IntegerAttr(Keyword.getKeyword()));
      Check.setKeyword(true);
    } else {
      plan::CheckConstantOp::create(
          Builder, Loc, Got,
          cast<IntOp>(Op.Val.getDefiningOp()).getValueAttr());
    }
  }
}

void Compiler::matchOperands(ArrayRef<MatcherOperandView> Operands, Value Reg,
                             Location Loc, bool TreatIntAsVec) {
  SmallVector<const MatcherOperandView *, 8> Values;
  for (const MatcherOperandView &Op : Operands)
    if (isValueOperand(Op.Kind))
      Values.push_back(&Op);
  bool HasArray = !Values.empty() && isArrayOperand(Values.back()->Kind);
  auto Count = plan::CheckOperandCountOp::create(
      Builder, Loc, Reg, i32(HasArray ? Values.size() - 1 : Values.size()));
  if (HasArray)
    Count.setAtLeast(true);
  for (auto [Index, Op] : enumerate(Values)) {
    Location OpLoc = Op->Val ? Op->Val.getLoc() : Loc;
    if (isArrayOperand(Op->Kind)) {
      Value Array = plan::GetOperandsFromOp::create(Builder, OpLoc, reg(), Reg,
                                                    i32(Index));
      bind(Array, Op->Val, /*BySort=*/false);
      if (Op->Kind == OperandKind::TypedValueArray) {
        auto Types = plan::GetOperandsFromOp::create(Builder, OpLoc, reg(), Reg,
                                                     i32(Index));
        Types.setTypes(true);
        bind(Types, Op->Type, /*BySort=*/false);
      }
      continue;
    }
    Value Operand =
        plan::GetOperandOp::create(Builder, OpLoc, reg(), Reg, i32(Index));
    if (Op->Type)
      checkType(OpLoc, plan::GetTypeOp::create(Builder, OpLoc, reg(), Operand),
                Op->Type, TreatIntAsVec);
    matchValue(Op->Val, Operand, TreatIntAsVec);
  }
}

void Compiler::matchInstruction(InstOp Inst, Value Reg) {
  Location Loc = Inst.getLoc();
  bool TreatIntAsVec = Inst.getTreatIntAsVec().value_or(
      pattern_setting::getDefault(pattern_setting::treatIntAsVec));
  plan::CheckOpcodeOp::create(Builder, Loc, Reg, Inst.getOpcodeAttr());
  bind(Reg, Inst.getResult(), /*BySort=*/false);
  if (Value Block = Inst.getParentBlock())
    bind(plan::GetParentBlockOp::create(Builder, Loc, reg(), Reg), Block,
         /*BySort=*/false);
  SmallVector<MatcherOperandView, 8> Operands = getMatcherOperands(Inst);
  // Type-only operands are matched against the result's type (or an
  // alloca's or getelementptr's).
  for (const MatcherOperandView &Op : Operands) {
    if (Op.Kind != OperandKind::TypeOnly)
      continue;
    auto Type = plan::GetTypeOp::create(Builder, Loc, reg(), Reg);
    Type.setOperandOf(true);
    checkType(Loc, Type, Op.Type, TreatIntAsVec);
  }
  matchFlags(Inst, Reg);
  matchKeyedOperands(Operands, Reg, Loc);
  if (Value Capture = Inst.getCapture())
    bind(Reg, Capture, /*BySort=*/false);
  matchOperands(Operands, Reg, Loc, TreatIntAsVec);
}

void Compiler::matchAlternatives(AltOp Alt, Value Reg) {
  Location Loc = Alt.getLoc();
  unsigned Slot = slotOf(Alt.getResult());
  if (Alt->getNumRegions() == 0) {
    // No branch fits: nothing matches.
    plan::FailOp::create(Builder, Loc);
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
    // A value matched in place of the alternative (an operand, which has no
    // slot or one of its own) is the alternative's binding too.
    auto YieldedSlot = S.Assigned.Of.find(Yielded);
    if (YieldedSlot == S.Assigned.Of.end() || YieldedSlot->second != Slot)
      bind(Reg, Alt.getResult(), /*BySort=*/false);
    for (BindOp Bind : Block.getOps<BindOp>()) {
      if (auto Int = Bind.getValue().getDefiningOp<IntOp>()) {
        plan::BindConstantOp::create(
            Builder, Bind.getLoc(), i32(slotOf(Bind.getVariable())),
            Builder.getBoolAttr(!Int.getValue().isZero()));
        Bound.bind(slotOf(Bind.getVariable()));
        continue;
      }
      bind(Reg, Bind.getVariable(), /*BySort=*/false);
    }
    SmallVector<Operation *, 4> Roots = getPatternRoots(Block);
    finishBlock(Block, Roots);
    plan::YieldOp::create(Builder, Loc, mlir::ValueRange());
    Joined = Joined ? BoundState::join(*Joined, Bound) : Bound;
  }
  Bound = std::move(*Joined);
}

void Compiler::matchValue(Value V, Value Reg, bool TreatIntAsVec) {
  Operation *Def = V.getDefiningOp();
  Location Loc = V.getLoc();
  if (isVariable(V)) {
    bind(Reg, V, /*BySort=*/true);
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
    auto Check = plan::CheckConstantOp::create(
        Builder, Loc, Reg, Builder.getI32IntegerAttr(Keyword.getKeyword()));
    Check.setKeyword(true);
    return;
  }
  if (auto Global = dyn_cast<GlobalOp>(Def)) {
    plan::CheckConstantOp::create(Builder, Loc, Reg, Global.getNameAttr());
    return;
  }
  if (auto Aggregate = dyn_cast<AggregateOp>(Def)) {
    mlir::OperandRange Elements = Aggregate.getElements();
    plan::CheckAggregateOp::create(Builder, Loc, Reg, Aggregate.getDelimiter(),
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

Value Compiler::cloneExpression(Value E, mlir::IRMapping &Mapping) {
  if (Value Mapped = Mapping.lookupOrNull(E))
    return Mapped;
  Operation *Def = E.getDefiningOp();
  Location Loc = E.getLoc();
  Value Result;
  if (isa<VarOp, InstOp, AltOp>(Def)) {
    // A pattern value: its slot, named as the value, which the errors of
    // evaluating the constraint name it by.
    unsigned Slot = slotOf(E);
    auto SlotOp = plan::SlotOp::create(Builder, Loc, E.getType(), i32(Slot));
    SlotOp->setAttr(S.Kinds[Slot] == plan::SlotKind::Instruction
                        ? mpir::ResultNameAttrName
                        : mpir::VarNameAttrName,
                    Builder.getStringAttr(S.ReadNames[Slot]));
    Result = SlotOp;
  } else {
    // An expression never reaches an mpir.int: ExpandMatchers folds each
    // read of one (a parameter a use binds to a constant) into a literal.
    assert(!isa<IntOp>(Def) &&
           "mpir_expr.read of an mpir.int not folded by ExpandMatchers");
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
  if (Require.getFromMetaflag())
    Check.setFromMetaflag(true);
}

void Compiler::let(LetOp Let) {
  mlir::IRMapping Mapping;
  Value Variable = Let.getVariable();
  unsigned Slot = slotOf(Variable);
  Value Assigned = cloneExpression(Let.getValue(), Mapping);
  // What the variable has to be if it is bound already: the value.
  Value Current = cloneExpression(Variable, Mapping);
  mlir::Location Loc = Let.getLoc();
  Current = mpir_expr::ReadOp::create(
      Builder, Loc,
      SortType::get(Context, getRepresentation(resolveSort(sortOf(Variable)))),
      Current);
  Value Args[] = {Current, Assigned};
  Value Same = mpir_expr::CallOp::create(
      Builder, Loc, SortType::get(Context, Sort::Boolean),
      unsigned(constraint::O_Equal), unsigned(constraint::Binary), Args,
      Value());
  plan::LetOp::create(Builder, Loc, i32(Slot), Assigned, Same);
  Bound.bind(Slot);
}

void Compiler::finishBlock(mlir::Block &Block, ArrayRef<Operation *> Roots) {
  // Roots first, then any matcher the path left unbound: a block's
  // instructions all match.
  SmallSetVector<Operation *, 8> Order(Roots.begin(), Roots.end());
  for (Operation &Op : Block)
    if (isa<InstOp, AltOp>(Op))
      Order.insert(&Op);
  for (Operation *Op : Order) {
    Value V = Op->getResult(0);
    if (Bound.Certain.contains(slotOf(V)))
      continue;
    Location Loc = Op->getLoc();
    // Match it against every instruction, wherever the path has not bound
    // it.
    matchMatcher(V, Value(), [&] {
      Value Each = plan::ForeachInstructionOp::create(Builder, Loc, reg());
      matchValue(V, Each, /*TreatIntAsVec=*/false);
    });
  }
  for (Operation &Op : Block) {
    if (auto Require = dyn_cast<RequireOp>(Op))
      check(Require);
    else if (auto Let = dyn_cast<LetOp>(Op))
      let(Let);
  }
}

plan::MatcherOp Compiler::compile() {
  assignSlots();
  auto Matcher = plan::MatcherOp::create(
      Builder, Pattern.getLoc(), Builder.getArrayAttr({}),
      ArrayRef<plan::SlotKind>(), ArrayRef<Sort>(), Builder.getArrayAttr({}));
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
struct ToPlanPass : impl::ToPlanPassBase<ToPlanPass> {
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

} // namespace metaphir
} // namespace llvm
