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
#include "metaphir/Dialect/Pattern/Bindings.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
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
#include "llvm/ADT/SetVector.h"

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
      : Pattern(Pattern), Builder(Builder), Slots(assignSlots(Pattern)) {}

  void compile();

private:
  PatternOp Pattern;
  OpBuilder &Builder;
  /// The slots the pattern's plan binds, which number its type variables.
  SlotAssignment Slots;
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
                 const BuildResult &Built, const AltChoices &Choices,
                 const SlotAssignment &Slots)
      : Pattern(Pattern), Builder(Builder), Context(Builder.getContext()),
        Loc(Pattern.getLoc()), R(Built.Needs), Constraints(Built.Constraints),
        Choices(Choices), Slots(Slots) {}

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
  /// The plan's slots, which number the type variables.
  const SlotAssignment &Slots;

  /// The instruction matchers the variant matches, each once, in pattern
  /// order, which numbers them. Node numbers are only compared for equality,
  /// so R.Matched's order (the walk's) would do as well; pattern order keeps
  /// them readable, and unchanged by how the walk goes.
  SmallVector<InstOp, 8> OrderedMatched;
  /// The node number of each: its position in OrderedMatched.
  DenseMap<Operation *, int64_t> Nodes;
  /// The type variables the typings bind.
  DenseSet<Value> TypeVars;
  /// The sites each pattern value occupies.
  MapVector<Value, SmallSetVector<Attribute, 2>> SitesOf;
  /// The constraint expressions emitted for the pattern's.
  DenseMap<Value, Value> Readings;

  OpcodeAttr opcode(instruction::InstructionID ID) {
    return OpcodeAttr::get(Context, ID);
  }
  int64_t nodeOf(Operation *Op) const;
  Attribute site(Operation *Node, uint8_t Positions);

  void numberMatched();
  void emitPostedFeatures();
  void emitSiblings();
  void emitDetailFeatures();
  TypePatternAttr typePattern(Value T);
  void emitTypings();
  void collectSites();
  void emitConstraints();

  Value reading(Value E);
  Value readingOfValue(Value E);
  Value readingOfAnchor(Value Original, Location L);
  Value readingOfCall(mpir_expr::CallOp Call);
  Value readingOfApply(mpir_expr::ApplyOp Apply);
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
  for (auto [Node, Positions, A] : R.SiteFacts)
    if (Facts.insert({Node, Positions, A.getCode()}).second)
      index::HasFactOp::create(Builder, Loc, nodeOf(Node),
                               cast<InstOp>(Node).getOpcodeAttr(), Positions,
                               A.getCode());
}

TypePatternAttr VariantEmitter::typePattern(Value T) {
  SmallVector<Value, 2> Variables;
  TypePatternAttr Encoded = encodeTypePattern(T, Slots, &Variables);
  TypeVars.insert_range(Variables);
  return Encoded;
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
      bool Array = isArrayOperand(Op.Kind);
      Types.push_back(Op.Type && !Array ? Attribute(typePattern(Op.Type))
                                        : Builder.getUnitAttr());
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

Attribute VariantEmitter::site(Operation *Node, uint8_t Positions) {
  return index::encodeSite(
      Builder.getContext(),
      {nodeOf(Node), cast<InstOp>(Node).getOpcode().getValue(), Positions});
}

void VariantEmitter::collectSites() {
  // Where the pattern's values are operands and, for an instruction matched
  // as itself, its result.
  for (auto [V, Node, Positions] : R.OperandSites)
    SitesOf[V].insert(site(Node, Positions));
  for (InstOp Inst : OrderedMatched)
    SitesOf[canonical(Inst.getResult())].insert(
        site(Inst, uint8_t(1u << ResultPosition)));
  // A capture is at its instruction's sites, whether or not the variant
  // matches the instruction.
  Pattern.walk([&](InstOp Inst) {
    Value Capture = Inst.getCapture();
    if (!Capture)
      return;
    auto It = SitesOf.find(canonical(Inst.getResult()));
    if (It == SitesOf.end())
      return;
    // Copy before `SitesOf` is modified
    SmallSetVector<Attribute, 2> Of = It->second;
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
  } else if (auto Call = dyn_cast<mpir_expr::CallOp>(Def)) {
    Result = readingOfCall(Call);
  } else if (auto Apply = dyn_cast<mpir_expr::ApplyOp>(Def)) {
    Result = readingOfApply(Apply);
  } else {
    // An expression never reaches an mpir.int: ExpandMatchers folds each
    // read of one (a parameter a use binds to a constant) into a literal.
    assert(!isa<IntOp>(Def) &&
           "mpir_expr.read of an mpir.int not folded by ExpandMatchers");
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
    Reading =
        index::SitesOp::create(Builder, L, E.getType(),
                               Builder.getArrayAttr(It->second.getArrayRef()));
  else if (TypeVars.count(E))
    Reading =
        index::TypeVarOp::create(Builder, L, E.getType(), Slots.Of.lookup(E));
  else
    Reading = index::UnknownOp::create(Builder, L, E.getType());
  name(Reading, E);
  return Reading->getResult(0);
}

Value VariantEmitter::readingOfAnchor(Value Original, Location L) {
  // A value-tracking operator is anchored only at an instruction the variant
  // matches.
  if (Original)
    if (InstOp Inst = instructionOf(canonical(Original), Choices))
      if (Nodes.count(Inst))
        return index::NodeOp::create(Builder, L, Original.getType(),
                                     nodeOf(Inst));
  return Value();
}

Value VariantEmitter::readingOfCall(mpir_expr::CallOp Call) {
  SmallVector<Value, 4> Args;
  for (Value A : Call.getArgs())
    Args.push_back(reading(A));
  Value Anchor = readingOfAnchor(Call.getAnchor(), Call.getLoc());
  return mpir_expr::CallOp::create(Builder, Call.getLoc(), Call.getType(),
                                   Call.getOpAttr(), Call.getKindAttr(), Args,
                                   Anchor);
}

Value VariantEmitter::readingOfApply(mpir_expr::ApplyOp Apply) {
  SmallVector<Value, 4> Args;
  for (Value A : Apply.getArgs())
    Args.push_back(reading(A));
  Value Anchor = readingOfAnchor(Apply.getAnchor(), Apply.getLoc());
  return mpir_expr::ApplyOp::create(Builder, Apply.getLoc(), Apply.getType(),
                                    Apply.getCalleeAttr(), Args, Anchor);
}

void VariantEmitter::name(Operation *Reading, Value Original) {
  // Named as the instruction or alternative it is, else as its variable.
  // Only for readability.
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
  VariantEmitter(Pattern, Builder, Built, Requirements.Choices, Slots).emit();
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
