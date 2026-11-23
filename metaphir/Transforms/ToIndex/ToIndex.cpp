//===- ToIndex.cpp - Compile lowered patterns into index queries ----------===//
//
// mpir-to-index compiles each lowered mpir.pattern into an mpir_index.query
// after it: one mpir_index.variant per choice of an alternative of each
// mpir.alt the pattern reaches, whatever the alt stands for (a matcher's
// branches, operand orders, a matcher or its operand). The query is the union
// of its variants, so each needs only what its own choices match. Past
// MaxVariants an alt is not chosen for: it requires what all its alternatives
// need.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/IR/PatternSettings.h"
#include "metaphir/Matching/FeatureRequirement.h"
#include "metaphir/Transforms/ToIndex/Passes.h"
#include "metaphir/Transforms/ToIndex/Requirement.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_TOINDEXPASS
#include "metaphir/Transforms/ToIndex/Passes.h.inc"
namespace toindex {

using mlir::Attribute;
using mlir::Location;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;
namespace index = mpir_index;

namespace {

class Compiler {
public:
  Compiler(PatternOp Pattern, OpBuilder &Builder)
      : Pattern(Pattern), Builder(Builder) {}

  void compile();

private:
  PatternOp Pattern;
  OpBuilder &Builder;
  /// What the variant needs under its choices.
  RequirementBuilder Requirements;

  /// Emits a variant for each choice of the alternatives left to choose.
  void enumerate();
  /// Emits the variants of each alternative of Alt.
  void enumerateAlternatives(AltOp Alt);
};

} // namespace

/// Whether C refers to nothing a match binds, nor to definitions.
static bool isClosed(Value C) {
  Operation *Def = C.getDefiningOp();
  if (!Def || isa<mpir_expr::ReadOp, mpir_expr::ApplyOp>(Def))
    return false;
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def))
    return all_of(Call.getArgs(), isClosed);
  return all_of(Def->getOperands(), isClosed);
}

/// The values in Values, sorted, each once.
template <typename T>
static SmallVector<T, 4> sortedUnique(ArrayRef<T> Values) {
  SmallVector<T, 4> Result(Values.begin(), Values.end());
  llvm::sort(Result);
  Result.erase(std::unique(Result.begin(), Result.end()), Result.end());
  return Result;
}

namespace {

/// Emits the mpir_index.variant of a requirement: its features, the typings
/// of the instruction matchers it matches, and its constraints, reading the
/// pattern's values as the sites they occupy.
class VariantEmitter {
public:
  VariantEmitter(PatternOp Pattern, OpBuilder &Builder,
                 const BuildResult &Built, const AltChoices &Choices)
      : Pattern(Pattern), Builder(Builder), Context(Builder.getContext()),
        Loc(Pattern.getLoc()), R(Built.Needs), Constraints(Built.Constraints),
        Choices(Choices) {}

  void emit();

private:
  PatternOp Pattern;
  OpBuilder &Builder;
  mlir::MLIRContext *Context;
  Location Loc;
  const Requirement &R;
  ArrayRef<RequireOp> Constraints;
  /// The alternative each mpir.alt takes in the variant.
  const AltChoices &Choices;

  /// The instruction matchers the variant matches, each once, in pattern
  /// order, which numbers them. Node numbers are only compared for equality,
  /// so R.Matched's order (the walk's) would do as well; pattern order keeps
  /// them readable, and unchanged by how the walk goes.
  SmallVector<InstOp, 8> OrderedMatched;
  /// The node number of each: its position in OrderedMatched.
  DenseMap<Operation *, int64_t> Nodes;
  /// Type variables, numbered for the typings and constraints.
  MapVector<Value, unsigned> TypeVars;
  /// The sites each pattern value occupies.
  MapVector<Value, SmallVector<Attribute, 2>> SitesOf;
  /// The constraint expressions emitted for the pattern's.
  DenseMap<Value, Value> Readings;

  OpcodeAttr opcode(instruction::InstructionID ID) {
    return OpcodeAttr::get(Context, ID);
  }
  int64_t nodeOf(Operation *Op) const;
  Attribute site(Operation *Node, uint8_t Slots);

  void numberMatched();
  void emitPostedFeatures();
  void emitSiblings();
  void emitDetailFeatures();
  mlir::ArrayAttr typePattern(Value T);
  void emitTypings();
  void collectSites();
  void emitConstraints();

  Value reading(Value E);
  Value readingOfValue(Value E);
  Value readingOfLiteral(mpir_expr::ReadOp Read, IntOp Literal);
  Value readingOfCall(mpir_expr::CallOp Call);
  void name(Operation *Reading, Value Original);
};

} // namespace

void VariantEmitter::emit() {
  auto Variant = index::VariantOp::create(Builder, Loc);
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Variant.getBody().emplaceBlock());
  numberMatched();
  emitPostedFeatures();
  emitDetailFeatures();
  emitTypings();
  collectSites();
  emitConstraints();
}

void VariantEmitter::numberMatched() {
  DenseSet<Operation *> IsMatched(R.Matched.begin(), R.Matched.end());
  Pattern.walk([&](InstOp Inst) {
    if (IsMatched.contains(Inst))
      OrderedMatched.push_back(Inst);
  });
  for (auto [Number, Inst] : llvm::enumerate(OrderedMatched))
    Nodes[Inst] = Number;
}

int64_t VariantEmitter::nodeOf(Operation *Op) const {
  // A node of a fact or an operand site is matched: visitInstruction records
  // it with them.
  auto It = Nodes.find(Op);
  assert(It != Nodes.end() && "a fact or site of an unmatched instruction");
  return It->second;
}

void VariantEmitter::emitPostedFeatures() {
  for (uint64_t IDs = R.Instructions; IDs; IDs &= IDs - 1)
    index::HasInstructionOp::create(
        Builder, Loc,
        opcode(instruction::InstructionID(llvm::countr_zero(IDs))));
  for (auto [User, Operand] :
       sortedUnique<decltype(R.Edges)::value_type>(R.Edges))
    index::HasEdgeOp::create(Builder, Loc, opcode(User), opcode(Operand));
  emitSiblings();
  for (const std::string &Name : sortedUnique<std::string>(R.Globals))
    index::HasGlobalOp::create(Builder, Loc, Builder.getStringAttr(Name));
}

void VariantEmitter::emitSiblings() {
  // Instructions using the same value are siblings.
  SmallVector<std::pair<const void *, instruction::InstructionID>, 8> Uses;
  for (auto [V, ID] : R.Uses)
    Uses.push_back({V.getAsOpaquePointer(), ID});
  Uses = sortedUnique<decltype(Uses)::value_type>(Uses);
  SmallVector<std::pair<instruction::InstructionID, instruction::InstructionID>,
              4>
      Siblings;
  for (auto I = Uses.begin(); I != Uses.end(); ++I)
    for (auto J = std::next(I); J != Uses.end() && J->first == I->first; ++J)
      Siblings.push_back(
          {std::min(I->second, J->second), std::max(I->second, J->second)});
  for (auto [A, B] : sortedUnique<decltype(Siblings)::value_type>(Siblings))
    index::HasSiblingOp::create(Builder, Loc, opcode(A), opcode(B));
}

void VariantEmitter::emitDetailFeatures() {
  for (const ShapeRequirement &Shape : sortedUnique<ShapeRequirement>(R.Shapes))
    index::HasShapeOp::create(Builder, Loc, opcode(Shape.ID), Shape.Present,
                              Shape.Absent, Shape.Width);

  // Emit each fact once. R.SiteFacts can repeat one: an alt past MaxVariants
  // is walked on its own, so an instruction reached both inside and outside
  // it records its facts in both walks.
  DenseSet<std::tuple<Operation *, uint8_t, uint16_t>> Facts;
  for (auto [Node, Slots, A] : R.SiteFacts)
    if (Facts.insert({Node, Slots, A.getCode()}).second)
      index::HasFactOp::create(Builder, Loc, nodeOf(Node),
                               cast<InstOp>(Node).getOpcodeAttr(), Slots,
                               A.getCode());
}

mlir::ArrayAttr VariantEmitter::typePattern(Value T) {
  SmallVector<Attribute, 8> Parts;
  auto Int = [&](int64_t V) { Parts.push_back(Builder.getI64IntegerAttr(V)); };
  auto Var = [&](Value V) {
    auto [It, Inserted] = TypeVars.try_emplace(V, TypeVars.size());
    return It->second;
  };
  Operation *Def = T.getDefiningOp();
  if (!Def || isa<VarOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Variable));
    Int(Var(T));
  } else if (auto Prim = dyn_cast<PrimTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Primitive));
    Int(Prim.getKind());
  } else if (auto IntTy = dyn_cast<IntTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Integer));
    Int(IntTy.getWidth());
    Int(IntTy.getByte());
  } else if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::MetaInteger));
    Int(Var(Meta.getWidth()));
    Int(Meta.getByte());
  } else if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Pointer));
    std::optional<uint32_t> Space = Ptr.getAddressSpace();
    Int(Space ? int64_t(*Space) : -1);
    Int(!Ptr.getElement());
  } else if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Sequence));
    Int(int64_t(Seq.getKind()));
    Int(Seq.getCount());
    Int(Seq.getCountVar() ? int64_t(Var(Seq.getCountVar())) : -1);
    Parts.push_back(typePattern(Seq.getElement()));
  } else if (auto Struct = dyn_cast<StructTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Struct));
    Int(Struct.getPacked());
    for (Value E : Struct.getElements())
      Parts.push_back(typePattern(E));
  } else if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
    Int(int64_t(mpir_plan::TypePatternKind::Function));
    Int(Func.getVarArg());
    Parts.push_back(typePattern(Func.getReturnType()));
    for (Value P : Func.getParams())
      Parts.push_back(typePattern(P));
  }
  return Builder.getArrayAttr(Parts);
}

void VariantEmitter::emitTypings() {
  // The typings of the matched instructions, numbered as they are.
  for (InstOp Inst : OrderedMatched) {
    ShapeRequirement Shape = shapeOf(Inst);
    SmallVector<Attribute, 4> Types;
    SmallVector<bool, 4> IsValue;
    for (const MatcherOperandView &Op : getMatcherOperands(Inst)) {
      if (isKeyedOperand(Op.Kind))
        continue;
      bool Array = Op.Kind == OperandKind::ValueArray ||
                   Op.Kind == OperandKind::TypedValueArray;
      Types.push_back(Op.Type && !Array ? Attribute(typePattern(Op.Type))
                                        : Builder.getArrayAttr({}));
      IsValue.push_back(isValueOperand(Op.Kind));
    }
    auto Typing = index::TypingOp::create(
        Builder, Inst.getLoc(), Inst.getOpcodeAttr(),
        Builder.getI32IntegerAttr(Shape.Present),
        Builder.getI32IntegerAttr(Shape.Absent), mlir::UnitAttr(),
        Builder.getArrayAttr(Types), Builder.getDenseBoolArrayAttr(IsValue));
    if (Inst.getTreatIntAsVec().value_or(
            pattern_setting::getDefault(pattern_setting::treatIntAsVec)))
      Typing.setTreatIntAsVec(true);
  }
}

Attribute VariantEmitter::site(Operation *Node, uint8_t Slots) {
  return Builder.getArrayAttr(
      {Builder.getI64IntegerAttr(nodeOf(Node)),
       Builder.getI64IntegerAttr(cast<InstOp>(Node).getOpcode().getValue()),
       Builder.getI64IntegerAttr(Slots)});
}

void VariantEmitter::collectSites() {
  // Where the pattern's values are operands and, for an instruction matched
  // as itself, its result.
  for (auto [V, Node, Slots] : R.OperandSites) {
    Attribute S = site(Node, Slots);
    if (!is_contained(SitesOf[V], S))
      SitesOf[V].push_back(S);
  }
  for (InstOp Inst : OrderedMatched)
    SitesOf[canonical(Inst.getResult())].push_back(
        site(Inst, uint8_t(1u << ResultSlot)));
  // A capture is at its instruction's sites, whether or not the variant
  // matches the instruction.
  Pattern.walk([&](InstOp Inst) {
    Value Capture = Inst.getCapture();
    if (!Capture)
      return;
    auto It = SitesOf.find(canonical(Inst.getResult()));
    if (It == SitesOf.end())
      return;
    SmallVector<Attribute, 2> Of = It->second;
    SitesOf[Capture] = std::move(Of);
  });
}

void VariantEmitter::emitConstraints() {
  // A closed constraint that is false (or cannot be evaluated) rejects every
  // match: the variant is impossible. The executor checks; here they are
  // marked.
  for (RequireOp Require : Constraints)
    index::AssumeOp::create(Builder, Require.getLoc(),
                            reading(Require.getCondition()),
                            isClosed(Require.getCondition()));
}

Value VariantEmitter::reading(Value E) {
  if (Value Done = Readings.lookup(E))
    return Done;
  Operation *Def = E.getDefiningOp();
  Value Result;
  if (!Def || isa<VarOp, InstOp, AltOp>(Def)) {
    Result = readingOfValue(E);
  } else if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def);
             Read && Read.getValue().getDefiningOp<IntOp>()) {
    Result = readingOfLiteral(Read, Read.getValue().getDefiningOp<IntOp>());
  } else if (auto Call = dyn_cast<mpir_expr::CallOp>(Def)) {
    Result = readingOfCall(Call);
  } else {
    mlir::IRMapping Mapping;
    for (Value Operand : Def->getOperands())
      Mapping.map(Operand, reading(Operand));
    Result = Builder.clone(*Def, Mapping)->getResult(0);
  }
  Readings[E] = Result;
  return Result;
}

Value VariantEmitter::readingOfValue(Value E) {
  // A pattern value is read as its sites, a type variable as its number, and
  // anything else as unknown.
  Location L = E.getLoc();
  Operation *Reading;
  auto It = SitesOf.find(canonical(E));
  if (It != SitesOf.end())
    Reading = index::SitesOp::create(Builder, L, E.getType(),
                                     Builder.getArrayAttr(It->second));
  else if (TypeVars.count(E))
    Reading =
        index::TypeVarOp::create(Builder, L, E.getType(), TypeVars.lookup(E));
  else
    Reading = index::UnknownOp::create(Builder, L, E.getType());
  name(Reading, E);
  return Reading->getResult(0);
}

Value VariantEmitter::readingOfLiteral(mpir_expr::ReadOp Read, IntOp Literal) {
  Location L = Read.getLoc();
  mlir::IntegerAttr Value = Literal.getValueAttr();
  APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
  if (sortOf(Read) == Sort::Boolean && Number.getBitWidth() == 1)
    return mpir_expr::BoolOp::create(Builder, L, !Number.isZero());
  bool Negative = Number.isSigned() && Number.isNegative();
  return mpir_expr::IntOp::create(
      Builder, L,
      Negative
          ? APSInt(
                Number.sextOrTrunc(std::max(64u, Number.getSignificantBits())),
                false)
          : APSInt(Number.zextOrTrunc(std::max(64u, Number.getActiveBits())),
                   true));
}

Value VariantEmitter::readingOfCall(mpir_expr::CallOp Call) {
  SmallVector<Value, 4> Args;
  for (Value A : Call.getArgs())
    Args.push_back(reading(A));
  // A value-tracking operator is anchored only at an instruction the variant
  // matches.
  Value Anchor;
  if (Value Original = Call.getAnchor())
    if (InstOp Inst = instructionOf(canonical(Original), Choices))
      if (Nodes.count(Inst))
        Anchor = index::NodeOp::create(Builder, Call.getLoc(),
                                       Original.getType(), nodeOf(Inst));
  return mpir_expr::CallOp::create(Builder, Call.getLoc(), Call.getType(),
                                   Call.getOpAttr(), Call.getKindAttr(), Args,
                                   Anchor);
}

void VariantEmitter::name(Operation *Reading, Value Original) {
  // Named as the instruction or alternative it is, else as its variable.
  if (Operation *D = canonical(Original).getDefiningOp()) {
    if (auto Name =
            D->getAttrOfType<mlir::StringAttr>(mpir::ResultNameAttrName)) {
      Reading->setAttr(mpir::ResultNameAttrName, Name);
      return;
    }
    if (auto Inst = dyn_cast<InstOp>(D)) {
      if (std::optional<StringRef> N = Inst.getResultName())
        Reading->setAttr(mpir::ResultNameAttrName, Builder.getStringAttr(*N));
      return;
    }
  }
  if (auto Var = Original.getDefiningOp<VarOp>())
    Reading->setAttr(mpir::VarNameAttrName, Var.getVarNameAttr());
}

void Compiler::enumerate() {
  BuildResult Built = Requirements.build(Pattern.getBody().front());
  if (Built.Undecided)
    return enumerateAlternatives(Built.Undecided);
  VariantEmitter(Pattern, Builder, Built, Requirements.Choices).emit();
}

void Compiler::enumerateAlternatives(AltOp Alt) {
  Requirements.Combinations *= Alt->getNumRegions();
  for (unsigned I = 0; I != Alt->getNumRegions(); ++I) {
    Requirements.Choices[Alt] = I;
    enumerate();
  }
  Requirements.Choices.erase(Alt);
  Requirements.Combinations /= Alt->getNumRegions();
}

void Compiler::compile() {
  auto Query = index::QueryOp::create(Builder, Pattern.getLoc());
  mlir::Block &Body = Query.getBody().emplaceBlock();
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Body);
  enumerate();
}

namespace {
struct ToIndexPass : impl::ToIndexPassBase<ToIndexPass> {
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

} // namespace toindex

} // namespace metaphir
} // namespace llvm
