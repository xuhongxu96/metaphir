#include "metaphir/Matching/Features.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/OpcodePredicates.h"
#include "metaphir/Matching/Operators/Arithmetic.h"
#include "metaphir/Matching/Operators/ValuePredicates.h"
#include "metaphir/Matching/Operators/ValueTracking.h"
#include "metaphir/Matching/ValueTrackContext.h"
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

static constexpr unsigned NumInstructionIDs = Instruction::NumInstructionIDs;
static_assert(NumInstructionIDs <= 64,
              "instruction matchers must fit in a 64-bit mask");

static constexpr unsigned NumFlagIDs = InstructionFlag::NumFlagIDs;
static_assert(NumFlagIDs <= 32, "flags must fit in a 32-bit mask");

static uint32_t flagBit(unsigned Flag) { return uint32_t(1) << Flag; }

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

bool FunctionFeatures::hasFact(Instruction::InstructionID ID, unsigned Slot,
                               Atom A) const {
  return std::binary_search(Facts.begin(), Facts.end(),
                            getFactKey(ID, Slot, A));
}

std::optional<unsigned>
FunctionFeatures::getMeasure(Instruction::InstructionID ID, unsigned Slot,
                             Measure M) const {
  uint32_t Key = getMeasureKey(ID, Slot, M, 0);
  auto It = llvm::lower_bound(Measures, Key);
  if (It == Measures.end() || (*It & ~0xffu) != Key)
    return std::nullopt;
  return *It & 0xff;
}

/// Merges the sorted measure lists Other into Measures, keeping for each site
/// and measure the most or the least value, as the measure records.
static void mergeMeasures(SmallVectorImpl<uint32_t> &Measures,
                          ArrayRef<uint32_t> Other) {
  SmallVector<uint32_t, 16> Merged;
  Merged.reserve(Measures.size() + Other.size());
  std::merge(Measures.begin(), Measures.end(), Other.begin(), Other.end(),
             std::back_inserter(Merged));
  Measures.clear();
  for (uint32_t Key : Merged) {
    if (!Measures.empty() && (Measures.back() & ~0xffu) == (Key & ~0xffu)) {
      uint32_t Site = Key & ~0xffu;
      unsigned Value = mergeMeasure(FunctionFeatures::getMeasureOfKey(Key),
                                    Measures.back() & 0xffu, Key & 0xffu);
      Measures.back() = Site | Value;
      continue;
    }
    Measures.push_back(Key);
  }
}

void FunctionFeatures::merge(const FunctionFeatures &Other) {
  Instructions |= Other.Instructions;
  unionSorted<Signature>(Signatures, Other.Signatures);
  unionSorted<uint32_t>(Facts, Other.Facts);
  mergeMeasures(Measures, Other.Measures);
  HasValueFacts &= Other.HasValueFacts;
  Fine &= Other.Fine;
  unionSorted<uint16_t>(Edges, Other.Edges);
  unionSorted<uint16_t>(Siblings, Other.Siblings);
  unionSorted<uint64_t>(Globals, Other.Globals);
}

namespace {
/// Collects the facts of the sites of one instruction's value.
class SiteSink : public FactSink {
public:
  SiteSink(FunctionFeatures &Features,
           DenseMap<uint32_t, unsigned> &MeasureValues)
      : Features(Features), MeasureValues(MeasureValues) {}

  /// Sets the sites to Slot of each instruction matcher in IDs.
  void setSites(uint64_t IDs, unsigned Slot) {
    this->IDs = IDs;
    this->Slot = Slot;
  }

  void add(Atom A) override {
    for (uint64_t Each = IDs; Each; Each &= Each - 1)
      Features.Facts.push_back(FunctionFeatures::getFactKey(
          Instruction::InstructionID(llvm::countr_zero(Each)), Slot, A));
  }

  void measure(Measure M, unsigned Value) override {
    Value = std::min(Value, MaxMeasure);
    for (uint64_t Each = IDs; Each; Each &= Each - 1) {
      uint32_t Key = FunctionFeatures::getMeasureKey(
          Instruction::InstructionID(llvm::countr_zero(Each)), Slot, M, 0);
      auto [It, Inserted] = MeasureValues.try_emplace(Key, Value);
      if (!Inserted)
        It->second = mergeMeasure(M, It->second, Value);
    }
  }

private:
  FunctionFeatures &Features;
  DenseMap<uint32_t, unsigned> &MeasureValues;
  uint64_t IDs = 0;
  unsigned Slot = 0;
};
} // namespace

FunctionFeatures FunctionFeatures::compute(const Function &F,
                                           const FeatureOptions &Options) {
  FunctionFeatures Features;
  DenseMap<uint32_t, unsigned> MeasureValues;
  SiteSink Sink(Features, MeasureValues);
  // Value tracking is anchored at each site's instruction; the analyses are
  // those the matcher uses.
  std::optional<detail::ValueTrackContext> Analysis;
  if (Options.ValueFacts)
    Analysis.emplace();
  unsigned ValueFactsLeft = Options.ValueFactsBudget;
  auto Record = [&](const llvm::Value &V, const llvm::Instruction &I,
                    unsigned Slot) {
    std::optional<SimplifyQuery> Query;
    if (Analysis && ValueFactsLeft) {
      --ValueFactsLeft;
      Query.emplace(Analysis->getQuery(&I));
    }
    RecordCall Call(V, Slot, Sink, Query ? &*Query : nullptr);
    OpEqual::record(Call);
    recordValuePredicates(Call);
    if (Query)
      recordValueTracking(Call);
  };

  // Pattern instructions only match instructions (never constant
  // expressions), and a matched instruction's operands are among its
  // operands(), so these are all the edges a match can use.
  // The instruction matchers of the users of each value.
  DenseMap<const llvm::Value *, uint64_t> Users;
  SmallVector<const llvm::Value *, 4> MatcherOperands;
  for (const llvm::Instruction &I : instructions(F)) {
    uint64_t Mask = instructionMask(I);
    Features.Instructions |= Mask;
    if (Mask) {
      collectMatcherOperands(I, MatcherOperands);
      Signature Sig;
      Sig.Result = encodeType(*I.getType());
      for (auto [Slot, Operand] : enumerate(MatcherOperands)) {
        if (Slot < NumOperandSlots)
          Sig.Operands[Slot] = encodeType(*Operand->getType());
        Sink.setSites(Mask, std::min<unsigned>(Slot, NumOperandSlots - 1));
        Record(*Operand, I, std::min<unsigned>(Slot, NumOperandSlots - 1));
      }
      Sink.setSites(Mask, ResultSlot);
      Record(I, I, ResultSlot);
      for (uint64_t IDs = Mask; IDs; IDs &= IDs - 1) {
        Sig.ID = Instruction::InstructionID(llvm::countr_zero(IDs));
        Sig.Flags = supportedFlags(Sig.ID, I);
        Features.Signatures.push_back(Sig);
      }
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
  for (const auto &[Key, Value] : MeasureValues)
    Features.Measures.push_back(Key | Value);
  Features.HasValueFacts = Options.ValueFacts && ValueFactsLeft;
  sortUnique(Features.Signatures);
  sortUnique(Features.Facts);
  llvm::sort(Features.Measures);
  sortUnique(Features.Edges);
  sortUnique(Features.Siblings);
  sortUnique(Features.Globals);
  return Features;
}

} // namespace metaphir
} // namespace llvm
