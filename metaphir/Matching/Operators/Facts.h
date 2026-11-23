#ifndef METAPHIR_MATCHING_OPERATORS_FACTS_H
#define METAPHIR_MATCHING_OPERATORS_FACTS_H

#include "metaphir/Matching/Operators/Facts.inc"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/KnownBits.h"
#include <algorithm>
#include <cstdint>
#include <optional>

namespace llvm {
struct SimplifyQuery;
class Value;
namespace metaphir {

// What a corpus index records about the values at a site: an instruction
// kind (a built-in instruction matcher) and one of its matcher operand
// positions (the last covers the rest), or its result. A fact is
// recorded for a site when some instruction of the function has it there.

constexpr unsigned NumOperandPositions = 3;
constexpr unsigned ResultPosition = NumOperandPositions;

/// A fact about the values at a site: a predicate holds for one of them, it
/// is an integer constant of some small value, or it is of some LLVM value
/// class.
class Atom {
public:
  using Predicate = fact::Predicate;

  static constexpr unsigned NumPredicates = fact::NumPredicates;
  /// The predicates before the value-tracking ones.
  static constexpr unsigned NumPlainPredicates = fact::NumPlainPredicates;

  /// Integer constants are recorded when their value, read signed or
  /// unsigned, is in [MinLiteral, MaxLiteral].
  static constexpr int64_t MinLiteral = -128;
  static constexpr int64_t MaxLiteral = 127;

  /* implicit */ constexpr Atom(Predicate P) : Code(PredicateBase + P) {}

  static StringRef getName(Predicate P) { return fact::PredicateNames[P]; }

  /// An integer constant of value V, if such constants are recorded.
  static std::optional<Atom> literal(int64_t V);
  /// A value of the ClassIndex-th class of LLVMValueClasses.td.
  static Atom valueClass(unsigned ClassIndex);

  /// An encoding of the atom that fits in 12 bits.
  uint16_t getCode() const { return Code; }
  /// The atom getCode encoded as Code.
  static Atom fromCode(uint16_t Code) { return Atom(Code); }

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

inline StringRef getMeasureName(Measure M) {
  return MeasureInfos[size_t(M)].Name;
}

/// The order of M, as Facts.td declares it for every measure.
inline MeasureOrder getMeasureOrder(Measure M) {
  return MeasureInfos[size_t(M)].Order;
}

/// The number a site keeps for M from two of its values' numbers.
inline unsigned mergeMeasure(Measure M, unsigned A, unsigned B) {
  return getMeasureOrder(M) == MeasureOrder::Most ? std::max(A, B)
                                                  : std::min(A, B);
}

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
  RecordCall(const llvm::Value &Value, unsigned Position, FactSink &Sink,
             const SimplifyQuery *Query = nullptr)
      : Value(Value), Position(Position), Sink(Sink), Query(Query) {}

  const llvm::Value &Value;
  /// An operand position, or ResultPosition.
  unsigned Position;
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
