#ifndef METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H
#define METAPHIR_MATCHING_OPERATORS_CMPPREDICATES_H

#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators on comparison predicates, given as the strings '?pred' binds
// ("slt", "oeq", ...) and named after CmpInst's: pure functions of their
// operand, the same on the IR and on the index.

#define MIR_DECLARE_OPERATOR(ID)                                               \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };

MIR_DECLARE_OPERATOR(IsEquality)
MIR_DECLARE_OPERATOR(IsSigned)
MIR_DECLARE_OPERATOR(IsUnsigned)
MIR_DECLARE_OPERATOR(IsLT)
MIR_DECLARE_OPERATOR(IsGT)
MIR_DECLARE_OPERATOR(IsLE)
MIR_DECLARE_OPERATOR(IsGE)
MIR_DECLARE_OPERATOR(SwappedPredicate)
MIR_DECLARE_OPERATOR(InversePredicate)
MIR_DECLARE_OPERATOR(StrictPredicate)
MIR_DECLARE_OPERATOR(NonStrictPredicate)
MIR_DECLARE_OPERATOR(FlippedSignednessPredicate)

#undef MIR_DECLARE_OPERATOR

} // namespace metaphir
} // namespace llvm

#endif
