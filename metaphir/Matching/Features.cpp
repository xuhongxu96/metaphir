#include "metaphir/Matching/Features.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/OpcodePredicates.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/xxhash.h"
#include <algorithm>
#include <iterator>

namespace llvm {
namespace metaphir {

static constexpr unsigned NumInstructionIDs = 0
#define MIR_INSTRUCTION_MATCHER_ID(Name) +1
#include "metaphir/IR/InstructionMatchers.def"
    ;
static_assert(NumInstructionIDs <= 64,
              "instruction matchers must fit in a 64-bit mask");

static constexpr unsigned NumFlagIDs = InstructionFlag::NumFlagIDs;
static_assert(NumFlagIDs <= 18, "flags must fit in a shape key");

static uint64_t bit(Instruction::InstructionID ID) { return uint64_t(1) << ID; }
static uint32_t flagBit(unsigned Flag) { return uint32_t(1) << Flag; }

/// The width of the integers of Ty, if Ty is an integer type or a vector of
/// them; otherwise 0.
static unsigned scalarIntegerWidth(const llvm::Type &Ty) {
  if (const auto *Integer = dyn_cast<llvm::IntegerType>(Ty.getScalarType()))
    return Integer->getBitWidth();
  return 0;
}

/// The flags of I that instruction matcher ID supports.
static uint32_t supportedFlags(Instruction::InstructionID ID,
                               const llvm::Instruction &I) {
  uint32_t Flags = 0;
  Instruction::FlagMask Supported = Instruction::getSupportedFlags(ID);
  for (unsigned Flag = 0; Flag != NumFlagIDs; ++Flag)
    if (Supported >> Flag & 1 &&
        hasSemanticFlag(InstructionFlag::FlagID(Flag), I))
      Flags |= flagBit(Flag);
  return Flags;
}

/// The instruction matchers that accept I.
static uint64_t instructionMask(const llvm::Instruction &I) {
  uint64_t Mask = 0;
  for (unsigned ID = 0; ID != NumInstructionIDs; ++ID)
    if (matchesInstructionID(Instruction::InstructionID(ID), I))
      Mask |= uint64_t(1) << ID;
  return Mask;
}

template <typename T> static void sortUnique(SmallVectorImpl<T> &Values) {
  llvm::sort(Values);
  Values.erase(std::unique(Values.begin(), Values.end()), Values.end());
}

/// Adds the sorted, unique Other to the sorted, unique Values.
template <typename T>
static void unionSorted(SmallVectorImpl<T> &Values, ArrayRef<T> Other) {
  SmallVector<T, 16> Union;
  Union.reserve(Values.size() + Other.size());
  std::set_union(Values.begin(), Values.end(), Other.begin(), Other.end(),
                 std::back_inserter(Union));
  Values.assign(Union.begin(), Union.end());
}

uint64_t hashGlobalName(StringRef Name) { return xxh3_64bits(Name); }

uint64_t hashGlobal(const llvm::GlobalValue &Global) {
  // Mirrors SubtreeMatcher: a pattern's llvm.* name stands for an intrinsic's
  // base name, any other name for the global's own.
  if (const auto *F = dyn_cast<Function>(&Global); F && F->isIntrinsic())
    return hashGlobalName(Intrinsic::getBaseName(F->getIntrinsicID()));
  return hashGlobalName(Global.getName());
}

bool FunctionFeatures::mayHaveEdge(Instruction::InstructionID User,
                                   Instruction::InstructionID Operand) const {
  return std::binary_search(Edges.begin(), Edges.end(),
                            getEdgeKey(User, Operand));
}

bool FunctionFeatures::hasGlobal(uint64_t Hash) const {
  return std::binary_search(Globals.begin(), Globals.end(), Hash);
}

void FunctionFeatures::merge(const FunctionFeatures &Other) {
  Instructions |= Other.Instructions;
  unionSorted<uint32_t>(Shapes, Other.Shapes);
  unionSorted<uint16_t>(Edges, Other.Edges);
  unionSorted<uint16_t>(Siblings, Other.Siblings);
  unionSorted<uint64_t>(Globals, Other.Globals);
}

FunctionFeatures FunctionFeatures::compute(const Function &F) {
  FunctionFeatures Features;
  // Pattern instructions only match instructions (never constant
  // expressions), and a matched instruction's operands are among its
  // operands(), so these are all the edges a match can use.
  // The instruction matchers of the users of each value.
  DenseMap<const llvm::Value *, uint64_t> Users;
  for (const llvm::Instruction &I : instructions(F)) {
    uint64_t Mask = instructionMask(I);
    Features.Instructions |= Mask;
    unsigned Width = scalarIntegerWidth(*I.getType());
    for (uint64_t IDs = Mask; IDs; IDs &= IDs - 1) {
      auto ID = Instruction::InstructionID(llvm::countr_zero(IDs));
      Features.Shapes.push_back(getShapeKey(ID, supportedFlags(ID, I), Width));
    }
    for (const Use &Operand : I.operands()) {
      if (Mask)
        Users[Operand.get()] |= Mask;
      if (const auto *Global = dyn_cast<llvm::GlobalValue>(Operand.get())) {
        Features.Globals.push_back(hashGlobal(*Global));
        continue;
      }
      const auto *OperandInstruction =
          dyn_cast<llvm::Instruction>(Operand.get());
      if (!OperandInstruction)
        continue;
      uint64_t OperandMask = instructionMask(*OperandInstruction);
      for (uint64_t Users = Mask; Users; Users &= Users - 1)
        for (uint64_t Operands = OperandMask; Operands;
             Operands &= Operands - 1)
          Features.Edges.push_back(getEdgeKey(
              Instruction::InstructionID(llvm::countr_zero(Users)),
              Instruction::InstructionID(llvm::countr_zero(Operands))));
    }
  }
  for (const auto &[Value, Mask] : Users)
    for (uint64_t First = Mask; First; First &= First - 1)
      for (uint64_t Second = First; Second; Second &= Second - 1)
        Features.Siblings.push_back(
            getEdgeKey(Instruction::InstructionID(llvm::countr_zero(First)),
                       Instruction::InstructionID(llvm::countr_zero(Second))));
  sortUnique(Features.Shapes);
  sortUnique(Features.Edges);
  sortUnique(Features.Siblings);
  sortUnique(Features.Globals);
  return Features;
}

bool ShapeRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  auto Begin = llvm::lower_bound(Features.Shapes,
                                 FunctionFeatures::getShapeKey(ID, 0, 0));
  for (auto It = Begin;
       It != Features.Shapes.end() && FunctionFeatures::getShapeID(*It) == ID;
       ++It) {
    uint32_t Flags = FunctionFeatures::getShapeFlags(*It);
    if ((Flags & Present) == Present && (Flags & Absent) == 0 &&
        (!Width || FunctionFeatures::getShapeWidth(*It) ==
                       std::min(Width, FunctionFeatures::MaxWidth)))
      return true;
  }
  return false;
}

bool FeatureRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  if ((Instructions & ~Features.Instructions) != 0)
    return false;
  for (const ShapeRequirement &Shape : Shapes)
    if (!Shape.isSatisfiedBy(Features))
      return false;
  for (auto [User, Operand] : Edges)
    if (!Features.mayHaveEdge(User, Operand))
      return false;
  for (uint16_t Sibling : Siblings)
    if (!std::binary_search(Features.Siblings.begin(), Features.Siblings.end(),
                            Sibling))
      return false;
  return all_of(Globals,
                [&](uint64_t Hash) { return Features.hasGlobal(Hash); });
}

void FeatureRequirement::unite(const FeatureRequirement &Other) {
  Instructions |= Other.Instructions;
  Shapes.append(Other.Shapes.begin(), Other.Shapes.end());
  sortUnique(Shapes);
  Edges.append(Other.Edges.begin(), Other.Edges.end());
  sortUnique(Edges);
  Siblings.append(Other.Siblings.begin(), Other.Siblings.end());
  sortUnique(Siblings);
  Globals.append(Other.Globals.begin(), Other.Globals.end());
  sortUnique(Globals);
  Uses.append(Other.Uses.begin(), Other.Uses.end());
  sortUnique(Uses);
}

void FeatureRequirement::intersect(const FeatureRequirement &Other) {
  Instructions &= Other.Instructions;
  decltype(Shapes) CommonShapes;
  std::set_intersection(Shapes.begin(), Shapes.end(), Other.Shapes.begin(),
                        Other.Shapes.end(), std::back_inserter(CommonShapes));
  Shapes = std::move(CommonShapes);
  decltype(Edges) CommonEdges;
  std::set_intersection(Edges.begin(), Edges.end(), Other.Edges.begin(),
                        Other.Edges.end(), std::back_inserter(CommonEdges));
  Edges = std::move(CommonEdges);
  decltype(Siblings) CommonSiblings;
  std::set_intersection(Siblings.begin(), Siblings.end(),
                        Other.Siblings.begin(), Other.Siblings.end(),
                        std::back_inserter(CommonSiblings));
  Siblings = std::move(CommonSiblings);
  decltype(Uses) CommonUses;
  std::set_intersection(Uses.begin(), Uses.end(), Other.Uses.begin(),
                        Other.Uses.end(), std::back_inserter(CommonUses));
  Uses = std::move(CommonUses);
  decltype(Globals) CommonGlobals;
  std::set_intersection(Globals.begin(), Globals.end(), Other.Globals.begin(),
                        Other.Globals.end(), std::back_inserter(CommonGlobals));
  Globals = std::move(CommonGlobals);
}

static FeatureRequirement
requirementOf(const Value &Node, SmallPtrSetImpl<const Instruction *> &OnStack);

/// The width a pattern type fixes for the integers of the value it matches:
/// an integer type matches integers, or vectors of them, of its width.
static unsigned fixedWidth(const Type *Ty) {
  if (const auto *Integer = dyn_cast_or_null<IntegerType>(Ty))
    return Integer->getNumBits();
  return 0;
}

/// The shape of the instructions Node matches.
static ShapeRequirement shapeOf(const Instruction &Node) {
  Instruction::InstructionID ID = Node.getInstructionID();
  ShapeRequirement Shape{ID};
  // The matcher requires the named flags and, of the other supported flags,
  // the absence of those not captured.
  uint32_t Named = 0;
  for (const InstructionFlag &Flag : Node.getFlags()) {
    Named |= flagBit(Flag.ID);
    if (!Flag.Capture)
      Shape.Present |= flagBit(Flag.ID);
  }
  Shape.Absent = Instruction::getSupportedFlags(ID) & ~Named;

  // A type-only operand is matched against the result type, except for
  // alloca's and getelementptr's; a binary operator's operands have the type
  // of its result.
  for (const MatcherOperand &Operand : Node.getUnkeyedOperands()) {
    bool OfResult =
        Operand.IsInstructionOperand
            ? Instruction::getOperandSyntax(ID) ==
                  Instruction::OperandSyntax::Binary
            : ID != Instruction::I_alloca && ID != Instruction::I_getelementptr;
    if (!Operand.IsArray && OfResult && fixedWidth(Operand.Ty)) {
      Shape.Width = fixedWidth(Operand.Ty);
      break;
    }
  }
  return Shape;
}

/// What a match of Node needs. A node already being visited (a cycle in the
/// pattern) adds nothing; its features are required where the visit began.
static FeatureRequirement
requirementOfInstruction(const Instruction &Node,
                         SmallPtrSetImpl<const Instruction *> &OnStack) {
  if (Node.isComposite() || !OnStack.insert(&Node).second)
    return {};

  SmallVector<const MatcherOperand *, 4> ValueOperands;
  for (const MatcherOperand &Operand : Node.getUnkeyedOperands())
    if (Operand.IsInstructionOperand)
      ValueOperands.push_back(&Operand);

  FeatureRequirement Direct;
  Direct.Instructions = bit(Node.getInstructionID());
  ShapeRequirement Shape = shapeOf(Node);
  if (Shape.Present || Shape.Absent || Shape.Width)
    Direct.Shapes.push_back(Shape);
  // The matcher takes the operands of these from elsewhere than operands().
  bool UsesOperands = Node.getInstructionID() != Instruction::I_phi &&
                      Node.getInstructionID() != Instruction::I_extractvalue &&
                      Node.getInstructionID() != Instruction::I_insertvalue;
  for (const MatcherOperand *Operand : ValueOperands) {
    if (Operand->IsArray || !Operand->Val)
      continue;
    Direct.unite(requirementOf(*Operand->Val, OnStack));
    // A constant written once can match different constants (a scalar and a
    // splat), so only variables and instructions make siblings.
    if (UsesOperands && isa<MetaVariable, Instruction>(Operand->Val))
      Direct.Uses.push_back({Operand->Val, Node.getInstructionID()});
    // An operand with ':o' may match an instruction of another kind.
    const auto *Child = dyn_cast<Instruction>(Operand->Val);
    if (Child && !Child->isComposite() && !Child->getOrSelfOperandIndex())
      Direct.Edges.push_back(
          {Node.getInstructionID(), Child->getInstructionID()});
  }
  sortUnique(Direct.Edges);
  sortUnique(Direct.Uses);

  // With ':o', the target matches either Node or its or-self operand, so only
  // what both alternatives need is required.
  if (std::optional<unsigned> Index = Node.getOrSelfOperandIndex()) {
    const Value *OrSelf = Node.getOrSelfValue();
    if (!OrSelf && *Index < ValueOperands.size() &&
        !ValueOperands[*Index]->IsArray)
      OrSelf = ValueOperands[*Index]->Val;
    if (OrSelf)
      Direct.intersect(requirementOf(*OrSelf, OnStack));
    else
      Direct = {};
  }

  OnStack.erase(&Node);
  return Direct;
}

static FeatureRequirement
requirementOf(const Value &Node,
              SmallPtrSetImpl<const Instruction *> &OnStack) {
  if (const auto *I = dyn_cast<Instruction>(&Node))
    return requirementOfInstruction(*I, OnStack);
  FeatureRequirement Requirement;
  // A global matches only a global operand of the same name.
  if (const auto *Global = dyn_cast<GlobalValue>(&Node))
    Requirement.Globals.push_back(hashGlobalName(Global->getName()));
  return Requirement;
}

FeatureQuery FeatureQuery::compute(const PatternVariants &Variants) {
  FeatureQuery Query;
  for (const Pattern *Variant : Variants) {
    FeatureRequirement Requirement;
    SmallPtrSet<const Instruction *, 8> OnStack;
    for (const Instruction *Root : Variant->getRoots())
      Requirement.unite(requirementOf(*Root, OnStack));
    // Instructions using the same value are siblings.
    for (auto I = Requirement.Uses.begin(); I != Requirement.Uses.end(); ++I)
      for (auto J = std::next(I);
           J != Requirement.Uses.end() && J->first == I->first; ++J)
        Requirement.Siblings.push_back(FunctionFeatures::getEdgeKey(
            std::min(I->second, J->second), std::max(I->second, J->second)));
    sortUnique(Requirement.Siblings);
    Requirement.Uses.clear();
    Query.Variants.push_back(std::move(Requirement));
  }
  return Query;
}

bool FeatureQuery::mayMatch(const FunctionFeatures &Features) const {
  return any_of(Variants, [&](const FeatureRequirement &Requirement) {
    return Requirement.isSatisfiedBy(Features);
  });
}

} // namespace metaphir
} // namespace llvm
