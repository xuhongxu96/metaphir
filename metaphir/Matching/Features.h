#ifndef METAPHIR_MATCHING_FEATURES_H
#define METAPHIR_MATCHING_FEATURES_H

#include "metaphir/IR/Instruction.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include <array>
#include <cstdint>
#include <utility>

namespace llvm {
class Function;
class GlobalValue;
namespace metaphir {

class PatternVariants;

/// A summary of a function for filtering it before matching: which built-in
/// instruction matchers accept some instruction, which pairs of them are
/// connected by an operand edge, and which globals are operands.
///
/// Edges are kept in a Bloom filter; a false positive only weakens filtering.
class FunctionFeatures {
public:
  static constexpr unsigned NumEdgeWords = 8;

  /// Bit I is set when some instruction matches instruction matcher I.
  uint64_t Instructions = 0;
  std::array<uint64_t, NumEdgeWords> Edges{};
  /// Sorted, unique hashes of the globals that are operands of instructions.
  SmallVector<uint64_t, 4> Globals;

  static FunctionFeatures compute(const Function &F);

  void addEdge(Instruction::InstructionID User,
               Instruction::InstructionID Operand);
  bool mayHaveEdge(Instruction::InstructionID User,
                   Instruction::InstructionID Operand) const;
  bool hasGlobal(uint64_t Hash) const;

  /// Adds Other's features, e.g. to summarize a module by its functions.
  void merge(const FunctionFeatures &Other);

  bool operator==(const FunctionFeatures &Other) const {
    return Instructions == Other.Instructions && Edges == Other.Edges &&
           Globals == Other.Globals;
  }
};

/// The hash under which a pattern global named Name is recorded; a target
/// global's is that of the name the matcher compares with.
uint64_t hashGlobalName(StringRef Name);
uint64_t hashGlobal(const llvm::GlobalValue &Global);

/// Features every function with a match of a pattern has.
struct FeatureRequirement {
  uint64_t Instructions = 0;
  /// Sorted and unique.
  SmallVector<std::pair<Instruction::InstructionID, Instruction::InstructionID>,
              4>
      Edges;
  /// Sorted and unique.
  SmallVector<uint64_t, 2> Globals;

  bool isTrivial() const {
    return Instructions == 0 && Edges.empty() && Globals.empty();
  }
  bool isSatisfiedBy(const FunctionFeatures &Features) const;

  /// Requires Other's features too.
  void unite(const FeatureRequirement &Other);
  /// Keeps only the features Other requires as well.
  void intersect(const FeatureRequirement &Other);
};

/// The features a function needs for a lowered pattern to match: those of
/// any one variant.
class FeatureQuery {
public:
  static FeatureQuery compute(const PatternVariants &Variants);

  ArrayRef<FeatureRequirement> getVariants() const { return Variants; }
  bool mayMatch(const FunctionFeatures &Features) const;
  bool mayMatchVariant(unsigned Index, const FunctionFeatures &Features) const {
    return Variants[Index].isSatisfiedBy(Features);
  }

private:
  SmallVector<FeatureRequirement, 2> Variants;
};

} // namespace metaphir
} // namespace llvm

#endif
