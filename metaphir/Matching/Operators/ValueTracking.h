#ifndef METAPHIR_MATCHING_OPERATORS_VALUETRACKING_H
#define METAPHIR_MATCHING_OPERATORS_VALUETRACKING_H

#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators backed by LLVM's value tracking. The ones declared with a
// context take ConcreteCall::Query, anchored at their context instruction;
// knownZeros and knownOnes only read a knownBits result.

#define MIR_DECLARE_OPERATOR(ID)                                               \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };

/// A value-tracking predicate the index records as Fact, anchored at the
/// site's instruction; abstract() is false where the index lacks it at the
/// sites of the context instruction.
#define MIR_DECLARE_RECORDED_PREDICATE(ID)                                     \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static constexpr Atom::Predicate Fact = Atom::ID;                          \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
    static void record(const RecordCall &Call);                                \
    static AbstractValue abstract(const AbstractCall &Call);                   \
  };

/// An operator the index records measures for.
#define MIR_DECLARE_MEASURED_OPERATOR(ID)                                      \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
    static void record(const RecordCall &Call);                                \
    static AbstractValue abstract(const AbstractCall &Call);                   \
  };

MIR_DECLARE_OPERATOR(NoOverflow)
MIR_DECLARE_OPERATOR(KnownBits)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownNonZero)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownNegative)
MIR_DECLARE_OPERATOR(IsGuaranteedNotToBeUndef)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownNonNegative)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownPositive)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownPowerOfTwo)
MIR_DECLARE_RECORDED_PREDICATE(IsKnownPowerOfTwoOrZero)
MIR_DECLARE_OPERATOR(IsGuaranteedNotToBePoison)
MIR_DECLARE_OPERATOR(IsGuaranteedNotToBeUndefOrPoison)
MIR_DECLARE_MEASURED_OPERATOR(MaskedValueIsZero)
MIR_DECLARE_MEASURED_OPERATOR(InSignedRange)
MIR_DECLARE_MEASURED_OPERATOR(InUnsignedRange)
MIR_DECLARE_OPERATOR(KnownZeros)
MIR_DECLARE_OPERATOR(KnownOnes)

/// Records the value-tracking facts of a value at a site: those of the
/// operators above, or ValueTrackingSkipped for values of types it does not
/// analyze.
void recordValueTracking(const RecordCall &Call);

#undef MIR_DECLARE_MEASURED_OPERATOR
#undef MIR_DECLARE_RECORDED_PREDICATE
#undef MIR_DECLARE_OPERATOR

} // namespace metaphir
} // namespace llvm

#endif
