#include "metaphir/Matching/Features.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/OpcodePredicates.h"
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

static uint64_t bit(Instruction::InstructionID ID) { return uint64_t(1) << ID; }

/// The instruction matchers that accept I.
static uint64_t instructionMask(const llvm::Instruction &I) {
  uint64_t Mask = 0;
  for (unsigned ID = 0; ID != NumInstructionIDs; ++ID)
    if (matchesInstructionID(Instruction::InstructionID(ID), I))
      Mask |= uint64_t(1) << ID;
  return Mask;
}

/// The two Bloom filter bits of an edge.
static std::pair<unsigned, unsigned>
edgeBits(Instruction::InstructionID User, Instruction::InstructionID Operand) {
  uint64_t Hash = (uint64_t(User) * 64 + Operand + 1) * 0x9E3779B97F4A7C15ULL;
  constexpr unsigned NumBits = FunctionFeatures::NumEdgeWords * 64;
  return {unsigned(Hash >> 55) % NumBits, unsigned(Hash >> 46) % NumBits};
}

template <typename T> static void sortUnique(SmallVectorImpl<T> &Values) {
  llvm::sort(Values);
  Values.erase(std::unique(Values.begin(), Values.end()), Values.end());
}

uint64_t hashGlobalName(StringRef Name) { return xxh3_64bits(Name); }

uint64_t hashGlobal(const llvm::GlobalValue &Global) {
  // Mirrors SubtreeMatcher: a pattern's llvm.* name stands for an intrinsic's
  // base name, any other name for the global's own.
  if (const auto *F = dyn_cast<Function>(&Global); F && F->isIntrinsic())
    return hashGlobalName(Intrinsic::getBaseName(F->getIntrinsicID()));
  return hashGlobalName(Global.getName());
}

void FunctionFeatures::addEdge(Instruction::InstructionID User,
                               Instruction::InstructionID Operand) {
  auto [First, Second] = edgeBits(User, Operand);
  Edges[First / 64] |= uint64_t(1) << (First % 64);
  Edges[Second / 64] |= uint64_t(1) << (Second % 64);
}

bool FunctionFeatures::mayHaveEdge(Instruction::InstructionID User,
                                   Instruction::InstructionID Operand) const {
  auto [First, Second] = edgeBits(User, Operand);
  return (Edges[First / 64] >> (First % 64) & 1) &&
         (Edges[Second / 64] >> (Second % 64) & 1);
}

bool FunctionFeatures::hasGlobal(uint64_t Hash) const {
  return std::binary_search(Globals.begin(), Globals.end(), Hash);
}

void FunctionFeatures::merge(const FunctionFeatures &Other) {
  Instructions |= Other.Instructions;
  for (unsigned Word = 0; Word != NumEdgeWords; ++Word)
    Edges[Word] |= Other.Edges[Word];
  Globals.append(Other.Globals.begin(), Other.Globals.end());
  sortUnique(Globals);
}

FunctionFeatures FunctionFeatures::compute(const Function &F) {
  FunctionFeatures Features;
  // Pattern instructions only match instructions (never constant
  // expressions), and a matched instruction's operands are among its
  // operands(), so these are all the edges a match can use.
  for (const llvm::Instruction &I : instructions(F)) {
    uint64_t Mask = instructionMask(I);
    Features.Instructions |= Mask;
    for (const Use &Operand : I.operands()) {
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
          Features.addEdge(
              Instruction::InstructionID(llvm::countr_zero(Users)),
              Instruction::InstructionID(llvm::countr_zero(Operands)));
    }
  }
  sortUnique(Features.Globals);
  return Features;
}

bool FeatureRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  if ((Instructions & ~Features.Instructions) != 0)
    return false;
  for (auto [User, Operand] : Edges)
    if (!Features.mayHaveEdge(User, Operand))
      return false;
  return all_of(Globals,
                [&](uint64_t Hash) { return Features.hasGlobal(Hash); });
}

void FeatureRequirement::unite(const FeatureRequirement &Other) {
  Instructions |= Other.Instructions;
  Edges.append(Other.Edges.begin(), Other.Edges.end());
  sortUnique(Edges);
  Globals.append(Other.Globals.begin(), Other.Globals.end());
  sortUnique(Globals);
}

void FeatureRequirement::intersect(const FeatureRequirement &Other) {
  Instructions &= Other.Instructions;
  decltype(Edges) CommonEdges;
  std::set_intersection(Edges.begin(), Edges.end(), Other.Edges.begin(),
                        Other.Edges.end(), std::back_inserter(CommonEdges));
  Edges = std::move(CommonEdges);
  decltype(Globals) CommonGlobals;
  std::set_intersection(Globals.begin(), Globals.end(), Other.Globals.begin(),
                        Other.Globals.end(), std::back_inserter(CommonGlobals));
  Globals = std::move(CommonGlobals);
}

static FeatureRequirement
requirementOf(const Value &Node, SmallPtrSetImpl<const Instruction *> &OnStack);

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
  for (const MatcherOperand *Operand : ValueOperands) {
    if (Operand->IsArray || !Operand->Val)
      continue;
    Direct.unite(requirementOf(*Operand->Val, OnStack));
    // An operand with ':o' may match an instruction of another kind.
    const auto *Child = dyn_cast<Instruction>(Operand->Val);
    if (Child && !Child->isComposite() && !Child->getOrSelfOperandIndex())
      Direct.Edges.push_back(
          {Node.getInstructionID(), Child->getInstructionID()});
  }
  sortUnique(Direct.Edges);

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
