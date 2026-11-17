#ifndef METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H
#define METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H

#include "metaphir/Matching/Operators/CmpPredicateOps.inc"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators on comparison predicates (CmpPredicateOperators.td): pure
// functions of their operand, the same on the IR and on the index.

struct OpFlippedSignednessPredicate {
  static constexpr bool ShortCircuits = false;
  static Expected<ConstraintValue> concrete(const ConcreteCall &Call);
};

} // namespace metaphir
} // namespace llvm

#endif
