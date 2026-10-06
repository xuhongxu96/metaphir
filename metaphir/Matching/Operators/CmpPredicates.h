#ifndef METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H
#define METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H

#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators on comparison predicates (CmpPredicateOperators.def): pure
// functions of their operand, the same on the IR and on the index.

#define MIR_DECLARE_OPERATOR(ID)                                               \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };

#define MIR_CMP_PREDICATE_TEST(ID, Name, Test) MIR_DECLARE_OPERATOR(ID)
#define MIR_CMP_PREDICATE_MAP(ID, Name, Map) MIR_DECLARE_OPERATOR(ID)
#include "metaphir/IR/CmpPredicateOperators.def"
MIR_DECLARE_OPERATOR(FlippedSignednessPredicate)

#undef MIR_DECLARE_OPERATOR

} // namespace metaphir
} // namespace llvm

#endif
