#ifndef METAPHIR_MATCHING_FEATURES_H
#define METAPHIR_MATCHING_FEATURES_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/TypeCode.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>
#include <tuple>
#include <utility>

namespace llvm {
class Function;
class GlobalValue;
namespace metaphir {

/// An instruction's kind as a built-in instruction matcher, the flags it has
/// of those the matcher supports, and its types: its result's, and those of
/// its first matcher operands (see collectMatcherOperands).
struct Signature {
  Instruction::InstructionID ID = Instruction::InstructionID(0);
  uint32_t Flags = 0;
  TypeCode Result = NoType;
  std::array<TypeCode, NumOperandSlots> Operands = {NoType, NoType, NoType};

  auto tie() const { return std::make_tuple(ID, Flags, Result, Operands); }
  bool operator<(const Signature &Other) const { return tie() < Other.tie(); }
  bool operator==(const Signature &Other) const { return tie() == Other.tie(); }
};

/// Options for computing a function's features.
struct FeatureOptions {
  /// Whether to record value-tracking facts and measures.
  bool ValueFacts = false;
  /// The most values a function's value-tracking facts are recorded for;
  /// beyond it, they are unknown.
  unsigned ValueFactsBudget = 200000;
};

/// A summary of a function for filtering it before matching: which built-in
/// instruction matchers accept some instruction, and with which signatures;
/// which pairs of them are connected by an operand edge or use the same
/// value; which globals are operands; and what is known about the values at
/// each site (see Operators/Facts.h).
class FunctionFeatures {
public:
  /// Bit I is set when some instruction matches instruction matcher I.
  uint64_t Instructions = 0;
  /// Sorted and unique.
  SmallVector<Signature, 8> Signatures;
  /// Sorted, unique fact keys (see getFactKey).
  SmallVector<uint32_t, 16> Facts;
  /// Sorted measure keys (see getMeasureKey), one per site and measure.
  SmallVector<uint32_t, 8> Measures;
  /// Whether the value-tracking facts and measures were recorded; if not,
  /// they are unknown.
  bool HasValueFacts = false;
  /// Whether the fine features, Signatures, Facts and Measures, are here; an
  /// index may leave them unread. Without them, only the others are checked.
  bool Fine = true;
  /// Sorted, unique edge keys (see getEdgeKey).
  SmallVector<uint16_t, 8> Edges;
  /// Sorted, unique sibling keys: getEdgeKey(A, B) with A <= B for
  /// instructions matched by A and B that use the same value.
  SmallVector<uint16_t, 8> Siblings;
  /// Sorted, unique hashes of the globals that are operands of instructions.
  SmallVector<uint64_t, 4> Globals;

  /// The key of fact A at a site.
  static uint32_t getFactKey(Instruction::InstructionID ID, unsigned Slot,
                             Atom A) {
    return uint32_t(ID) << 14 | Slot << 12 | A.getCode();
  }
  /// The key of measure M at a site, with its value. The measure takes four
  /// bits and the value eight.
  static uint32_t getMeasureKey(Instruction::InstructionID ID, unsigned Slot,
                                Measure M, unsigned Value) {
    static_assert(unsigned(Measure::NumMeasures) <= 16,
                  "a measure key has four bits for the measure");
    static_assert(MaxMeasure <= 0xff, "a measure key has eight value bits");
    return uint32_t(ID) << 14 | Slot << 12 | uint32_t(M) << 8 |
           std::min(Value, MaxMeasure);
  }
  /// The measure of a key from getMeasureKey.
  static Measure getMeasureOfKey(uint32_t Key) {
    return Measure(Key >> 8 & 0xf);
  }

  /// The key of an edge from an instruction matched by User to its operand
  /// matched by Operand.
  static uint16_t getEdgeKey(Instruction::InstructionID User,
                             Instruction::InstructionID Operand) {
    return uint16_t(User) * 64 + Operand;
  }
  /// The instruction matchers of an edge or sibling key.
  static std::pair<Instruction::InstructionID, Instruction::InstructionID>
  splitEdgeKey(uint16_t Key) {
    return {Instruction::InstructionID(Key / 64),
            Instruction::InstructionID(Key % 64)};
  }

  static FunctionFeatures compute(const Function &F,
                                  const FeatureOptions &Options = {});

  bool mayHaveEdge(Instruction::InstructionID User,
                   Instruction::InstructionID Operand) const;
  bool hasGlobal(uint64_t Hash) const;
  bool hasFact(Instruction::InstructionID ID, unsigned Slot, Atom A) const;
  /// The value of measure M at a site, if recorded.
  std::optional<unsigned> getMeasure(Instruction::InstructionID ID,
                                     unsigned Slot, Measure M) const;

  /// Adds Other's features, e.g. to summarize a module by its functions.
  void merge(const FunctionFeatures &Other);

  bool operator==(const FunctionFeatures &Other) const {
    return Instructions == Other.Instructions &&
           Signatures == Other.Signatures && Facts == Other.Facts &&
           Measures == Other.Measures && HasValueFacts == Other.HasValueFacts &&
           Fine == Other.Fine && Edges == Other.Edges &&
           Siblings == Other.Siblings && Globals == Other.Globals;
  }
};

/// The hash under which a pattern global named Name is recorded; a target
/// global's is that of the name the matcher compares with.
uint64_t hashGlobalName(StringRef Name);
uint64_t hashGlobal(const llvm::GlobalValue &Global);

} // namespace metaphir
} // namespace llvm

#endif
