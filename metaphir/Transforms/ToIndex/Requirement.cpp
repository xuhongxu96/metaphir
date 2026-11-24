//===- Requirement.cpp - What a variant of an index query needs -----------===//
//
// See Requirement.h.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/ToIndex/Requirement.h"

namespace llvm {
namespace metaphir {
namespace toindex {

using mlir::Operation;
using mlir::Value;
using namespace mpir;

static bool isVariable(Value V) {
  return isa<mlir::BlockArgument>(V) || V.getDefiningOp<VarOp>();
}

static Value yieldOf(mlir::Region &Region) {
  return (*Region.front().getOps<YieldOp>().begin()).getValue();
}

Value canonical(Value V) {
  // Climb to the alt V is the own matcher of: the region defining V yields
  // it. A value an alternative yields from outside it stays its own.
  while (Operation *Def = V.getDefiningOp()) {
    auto Users = V.getUsers();
    auto Yield = llvm::find_if(Users, [&](Operation *User) {
      return isa<YieldOp>(User) && User->getBlock() == Def->getBlock() &&
             isa<AltOp>(User->getParentOp());
    });
    if (Yield == Users.end())
      break;
    V = (*Yield)->getParentOp()->getResult(0);
  }
  return V;
}

InstOp instructionOf(Value V, const AltChoices &Choices) {
  Operation *Def = V.getDefiningOp();
  if (auto Inst = dyn_cast_or_null<InstOp>(Def))
    return Inst;
  auto Alt = dyn_cast_or_null<AltOp>(Def);
  if (!Alt || Alt->getNumRegions() == 0)
    return nullptr;
  auto It = Choices.find(Alt);
  if (It == Choices.end())
    return nullptr;
  return instructionOf(yieldOf(Alt->getRegion(It->second)), Choices);
}

/// The width a type pattern fixes for the integers of the value it matches.
static unsigned fixedWidth(Value Ty) {
  assert(Ty && "a typed operand has a type pattern");
  if (auto Int = Ty.getDefiningOp<IntTypeOp>())
    if (!Int.getByte())
      return Int.getWidth();
  return 0;
}

ShapeRequirement shapeOf(InstOp Node) {
  instruction::InstructionID ID = Node.getOpcode().getValue();
  ShapeRequirement Shape{ID};
  for (auto [Flag, Mode] : zip(Node.getFlags(), Node.getFlagModes())) {
    if (FlagMode(Mode) == FlagMode::Captured)
      continue;
    (FlagMode(Mode) == FlagMode::Negated ? Shape.Absent : Shape.Present) |=
        uint32_t(1) << Flag;
  }
  for (const MatcherOperandView &Op : getMatcherOperands(Node)) {
    // Only these have a type pattern.
    if (Op.Kind != OperandKind::TypedValue && Op.Kind != OperandKind::TypeOnly)
      continue;
    bool OfResult =
        isValueOperand(Op.Kind)
            ? instruction::getOperandSyntax(ID) ==
                  instruction::OperandSyntax::Binary
            : ID != instruction::I_alloca && ID != instruction::I_getelementptr;
    if (!OfResult)
      continue;
    if (unsigned Width = fixedWidth(Op.Type)) {
      Shape.Width = Width;
      break;
    }
  }
  return Shape;
}

BuildResult RequirementBuilder::build(mlir::Block &Block) {
  Undecided = nullptr;
  Constraints.clear();
  Met.clear();
  Walk All;
  visitBlock(Block, All);
  return {Undecided, std::move(All.R), Constraints.takeVector()};
}

void RequirementBuilder::visitInstruction(InstOp Node, Walk &Into) {
  if (!Into.Visited.insert(Node).second)
    return;
  Requirement &R = Into.R;
  instruction::InstructionID ID = Node.getOpcode().getValue();
  SmallVector<MatcherOperandView, 8> Values;
  for (const MatcherOperandView &Op : getMatcherOperands(Node))
    if (isValueOperand(Op.Kind))
      Values.push_back(Op);
  R.Instructions |= uint64_t(1) << ID;
  R.Matched.push_back(Node);
  ShapeRequirement Shape = shapeOf(Node);
  if (Shape.Present || Shape.Absent || Shape.Width)
    R.Shapes.push_back(Shape);
  // The matcher takes the operands of these from elsewhere than operands(),
  // which the index counts the uses of.
  bool UsesOperands = ID != instruction::I_phi &&
                      ID != instruction::I_extractvalue &&
                      ID != instruction::I_insertvalue;
  auto PositionBit = [](unsigned P) {
    return uint8_t(1) << std::min(P, NumOperandPositions - 1);
  };
  for (auto [Position, Op] : llvm::enumerate(Values)) {
    if (isArrayOperand(Op.Kind) || !Op.Val)
      continue;
    visit(Op.Val, Into);
    uint8_t Positions = PositionBit(Position);
    Operation *Def = Op.Val.getDefiningOp();
    bool IsMatcher = isa_and_nonnull<InstOp, AltOp>(Def);
    if (isVariable(Op.Val) || IsMatcher)
      R.OperandSites.push_back({canonical(Op.Val), Node, Positions});
    if (auto Int = dyn_cast_or_null<IntOp>(Def)) {
      mlir::IntegerAttr Value = Int.getValueAttr();
      APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
      if (std::optional<int64_t> V = Number.tryExtValue())
        if (std::optional<Atom> Literal = Atom::literal(*V))
          R.SiteFacts.push_back({Node, Positions, *Literal});
    }
    if (UsesOperands && (isVariable(Op.Val) || IsMatcher))
      R.Uses.push_back({canonical(Op.Val), ID});
    // An operand that is no instruction in the variant (an alternative may
    // yield a value matched otherwise) requires no edge.
    if (InstOp Child = instructionOf(Op.Val, Choices))
      R.Edges.push_back({ID, Child.getOpcode().getValue()});
  }
}

void RequirementBuilder::visit(Value V, Walk &Into) {
  Operation *Def = V.getDefiningOp();
  if (auto Inst = dyn_cast_or_null<InstOp>(Def))
    return visitInstruction(Inst, Into);
  if (auto Global = dyn_cast_or_null<GlobalOp>(Def)) {
    Into.R.Globals.push_back(Global.getName().str());
    return;
  }
  auto Alt = dyn_cast_or_null<AltOp>(Def);
  if (!Alt || Alt->getNumRegions() == 0 || !Into.Visited.insert(Alt).second)
    return;
  auto It = Choices.find(Alt);
  if (It != Choices.end())
    return visitRegion(Alt->getRegion(It->second), Into);
  if (Combinations * Alt->getNumRegions() > MaxVariants)
    return Into.R.unite(requirementOfAlternatives(Alt));
  if (!Undecided)
    Undecided = Alt;
}

const Requirement &RequirementBuilder::requirementOfAlternatives(AltOp Alt) {
  auto Known = Met.find(Alt);
  if (Known != Met.end())
    return Known->second;
  // What every alternative needs; the constraints of one alternative need
  // not hold when another matches.
  size_t NumConstraints = Constraints.size();
  Requirement R;
  for (auto [Index, Region] : llvm::enumerate(Alt->getRegions())) {
    Walk Each;
    visitRegion(Region, Each);
    if (Index == 0)
      R = std::move(Each.R);
    else
      R.intersect(Each.R);
  }
  while (Constraints.size() > NumConstraints)
    Constraints.pop_back();
  return Met.try_emplace(Alt, std::move(R)).first->second;
}

void RequirementBuilder::visitRegion(mlir::Region &Region, Walk &Into) {
  // The alternative's matchers and constraints, then the matcher it is:
  // what it yields, which is no root of its block.
  visitBlock(Region.front(), Into);
  visit(yieldOf(Region), Into);
}

void RequirementBuilder::visitBlock(mlir::Block &Block, Walk &Into) {
  for (Operation *Root : getPatternRoots(Block))
    visit(Root->getResult(0), Into);
  for (RequireOp Require : Block.getOps<RequireOp>())
    Constraints.insert(Require);
}

} // namespace toindex
} // namespace metaphir
} // namespace llvm
