#ifndef METAPHIR_MATCHING_OPERATORS_FACTS_H
#define METAPHIR_MATCHING_OPERATORS_FACTS_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/KnownBits.h"
#include <cstdint>
#include <optional>

namespace llvm {
struct SimplifyQuery;
class Value;
namespace metaphir {

// What a corpus index records about the values at a site: an instruction
// kind (a built-in instruction matcher) and one of its matcher operand
// positions (a slot; the last slot covers the rest), or its result. A fact is
// recorded for a site when some instruction of the function has it there.

constexpr unsigned NumOperandSlots = 3;
constexpr unsigned ResultSlot = NumOperandSlots;

/// A fact about the values at a site: a predicate holds for one of them, it
/// is an integer constant of some small value, or it is of some LLVM value
/// class.
class Atom {
public:
  enum Predicate : uint8_t {
    IsZero,
    IsAllOnes,
    IsPowerOfTwo,
    IsLowBitMask,
    IsZeroFP,
    IsIntegralConstant,
    IsPoison,
    IsForbidPoison,
    IsConstantSplat,
    HasOneUse,
    HasOneUser,
    // Value tracking, anchored at the site's instruction.
    IsKnownNonZero,
    IsKnownNegative,
    IsKnownNonNegative,
    IsKnownPositive,
    IsKnownPowerOfTwo,
    /// Value tracking was skipped for a value at the site; its facts there
    /// are unknown.
    ValueTrackingSkipped,
    NumPredicates
  };

  /// Integer constants are recorded when their value, read signed or
  /// unsigned, is in [MinLiteral, MaxLiteral].
  static constexpr int64_t MinLiteral = -128;
  static constexpr int64_t MaxLiteral = 127;

  /* implicit */ constexpr Atom(Predicate P) : Code(PredicateBase + P) {}

  static StringRef getName(Predicate P);

  /// An integer constant of value V, if such constants are recorded.
  static std::optional<Atom> literal(int64_t V);
  /// A value of the ClassIndex-th class of LLVMValueClasses.def.
  static Atom valueClass(unsigned ClassIndex);

  /// Whether the atom is recorded from value tracking.
  bool isValueTracking() const {
    return Code >= PredicateBase + IsKnownNonZero &&
           Code < PredicateBase + NumPredicates;
  }

  /// An encoding of the atom that fits in 12 bits.
  uint16_t getCode() const { return Code; }

  bool operator==(const Atom &Other) const { return Code == Other.Code; }
  bool operator<(const Atom &Other) const { return Code < Other.Code; }

private:
  static constexpr uint16_t LiteralBase = 0;
  static constexpr uint16_t PredicateBase = 0x100;
  static constexpr uint16_t ClassBase = 0x140;
  static constexpr uint16_t End = 0x1000;
  static_assert(MaxLiteral - MinLiteral < PredicateBase - LiteralBase);
  static_assert(NumPredicates <= ClassBase - PredicateBase);

  explicit constexpr Atom(uint16_t Code) : Code(Code) {}

  uint16_t Code;
};

/// Numbers recorded for a site: the most, or the least, of the values there.
enum class Measure : uint8_t {
  /// The most known trailing zero bits.
  TrailingZeros,
  /// The fewest bits that are not known leading zeros.
  ActiveBits,
  /// The fewest bits holding the signed range computeConstantRange finds.
  RangeSignedBits,
  NumMeasures
};

StringRef getMeasureName(Measure M);

/// Whether the recorded number for M is the most of the site's values;
/// otherwise it is the least.
inline bool isMaximum(Measure M) { return M == Measure::TrailingZeros; }

/// Measures are recorded up to this; larger ones are recorded as it.
constexpr unsigned MaxMeasure = 255;

/// Collects the facts of a site.
class FactSink {
public:
  virtual ~FactSink();
  virtual void add(Atom A) = 0;
  virtual void measure(Measure M, unsigned Value) = 0;
};

/// A value at a site, for the operators to record facts about.
struct RecordCall {
  RecordCall(const llvm::Value &Value, unsigned Slot, FactSink &Sink,
             const SimplifyQuery *Query = nullptr)
      : Value(Value), Slot(Slot), Sink(Sink), Query(Query) {}

  const llvm::Value &Value;
  /// An operand slot, or ResultSlot.
  unsigned Slot;
  FactSink &Sink;
  /// Value tracking anchored at the site's instruction, when recording its
  /// facts.
  const SimplifyQuery *Query = nullptr;

  /// The known bits of Value, computed once for all the operators.
  const KnownBits &knownBits() const;

private:
  mutable std::optional<KnownBits> Known;
};

} // namespace metaphir
} // namespace llvm

#endif
