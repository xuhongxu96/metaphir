#ifndef METAPHIR_MATCHING_FEATURES_H
#define METAPHIR_MATCHING_FEATURES_H

#include "metaphir/IR/Instruction.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include <algorithm>
#include <cstdint>
#include <tuple>
#include <utility>

namespace llvm {
class Function;
class GlobalValue;
namespace metaphir {

class PatternVariants;

/// A summary of a function for filtering it before matching: which built-in
/// instruction matchers accept some instruction, with which flags and result
/// widths, which pairs of them are connected by an operand edge or use the
/// same value, and which globals are operands.
class FunctionFeatures {
public:
  /// Bit I is set when some instruction matches instruction matcher I.
  uint64_t Instructions = 0;
  /// Sorted, unique shape keys (see getShapeKey).
  SmallVector<uint32_t, 8> Shapes;
  /// Sorted, unique edge keys (see getEdgeKey).
  SmallVector<uint16_t, 8> Edges;
  /// Sorted, unique sibling keys: getEdgeKey(A, B) with A <= B for
  /// instructions matched by A and B that use the same value.
  SmallVector<uint16_t, 8> Siblings;
  /// Sorted, unique hashes of the globals that are operands of instructions.
  SmallVector<uint64_t, 4> Globals;

  /// Result widths are kept up to this; wider ones are recorded as it.
  static constexpr unsigned MaxWidth = 255;

  /// The key of an instruction matched by ID that has, of the flags ID
  /// supports, those in Flags (bits by InstructionFlag::FlagID), and whose
  /// result is an integer, or a vector of integers, of Width bits (0 for
  /// other results).
  static uint32_t getShapeKey(Instruction::InstructionID ID, uint32_t Flags,
                              unsigned Width) {
    return uint32_t(ID) << 26 | Flags << 8 | std::min(Width, MaxWidth);
  }
  static Instruction::InstructionID getShapeID(uint32_t Key) {
    return Instruction::InstructionID(Key >> 26);
  }
  static uint32_t getShapeFlags(uint32_t Key) { return Key >> 8 & 0x3ffff; }
  static unsigned getShapeWidth(uint32_t Key) { return Key & 0xff; }

  /// The key of an edge from an instruction matched by User to its operand
  /// matched by Operand.
  static uint16_t getEdgeKey(Instruction::InstructionID User,
                             Instruction::InstructionID Operand) {
    return uint16_t(User) * 64 + Operand;
  }

  static FunctionFeatures compute(const Function &F);

  bool mayHaveEdge(Instruction::InstructionID User,
                   Instruction::InstructionID Operand) const;
  bool hasGlobal(uint64_t Hash) const;

  /// Adds Other's features, e.g. to summarize a module by its functions.
  void merge(const FunctionFeatures &Other);

  bool operator==(const FunctionFeatures &Other) const {
    return Instructions == Other.Instructions && Shapes == Other.Shapes &&
           Edges == Other.Edges && Siblings == Other.Siblings &&
           Globals == Other.Globals;
  }
};

/// The hash under which a pattern global named Name is recorded; a target
/// global's is that of the name the matcher compares with.
uint64_t hashGlobalName(StringRef Name);
uint64_t hashGlobal(const llvm::GlobalValue &Global);

/// An instruction a match needs: one matched by ID, with all the Present
/// and none of the Absent flags, whose result has Width bits (unless 0).
struct ShapeRequirement {
  Instruction::InstructionID ID;
  uint32_t Present = 0;
  uint32_t Absent = 0;
  unsigned Width = 0;

  bool isSatisfiedBy(const FunctionFeatures &Features) const;

  auto tie() const { return std::make_tuple(ID, Present, Absent, Width); }
  bool operator<(const ShapeRequirement &Other) const {
    return tie() < Other.tie();
  }
  bool operator==(const ShapeRequirement &Other) const {
    return tie() == Other.tie();
  }
};

/// Features every function with a match of a pattern has.
struct FeatureRequirement {
  uint64_t Instructions = 0;
  /// Sorted and unique.
  SmallVector<ShapeRequirement, 2> Shapes;
  /// Sorted and unique.
  SmallVector<std::pair<Instruction::InstructionID, Instruction::InstructionID>,
              4>
      Edges;
  /// Sorted and unique.
  SmallVector<uint16_t, 2> Siblings;
  /// Sorted and unique.
  SmallVector<uint64_t, 2> Globals;
  /// While a pattern's requirement is computed, the values its instructions
  /// certainly use, and by which instruction matchers; FeatureQuery turns
  /// them into Siblings.
  SmallVector<std::pair<const Value *, Instruction::InstructionID>, 4> Uses;

  bool isTrivial() const {
    return Instructions == 0 && Shapes.empty() && Edges.empty() &&
           Siblings.empty() && Globals.empty();
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
