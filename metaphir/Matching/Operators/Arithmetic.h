#ifndef METAPHIR_MATCHING_OPERATORS_ARITHMETIC_H
#define METAPHIR_MATCHING_OPERATORS_ARITHMETIC_H

#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators on integers, booleans and equality: pure functions of their
// operands, the same on the IR and on the index.

/// '&&' and '||', which ConstraintEvaluator evaluates itself, as they
/// short-circuit.
struct OpLogicalOr {
  static constexpr bool ShortCircuits = true;
};
struct OpLogicalAnd {
  static constexpr bool ShortCircuits = true;
};

#define MIR_DECLARE_OPERATOR(ID)                                               \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };

/// '==', whose index facts are the small integer constants at a site.
struct OpEqual {
  static constexpr bool ShortCircuits = false;
  static Expected<ConstraintValue> concrete(const ConcreteCall &Call);
  static void record(const RecordCall &Call);
  static AbstractValue abstract(const AbstractCall &Call);
};

MIR_DECLARE_OPERATOR(NotEqual)
MIR_DECLARE_OPERATOR(Not)
MIR_DECLARE_OPERATOR(Negate)
MIR_DECLARE_OPERATOR(Add)
MIR_DECLARE_OPERATOR(Subtract)
MIR_DECLARE_OPERATOR(Multiply)
MIR_DECLARE_OPERATOR(SDiv)
MIR_DECLARE_OPERATOR(UDiv)
MIR_DECLARE_OPERATOR(SRem)
MIR_DECLARE_OPERATOR(URem)
MIR_DECLARE_OPERATOR(And)
MIR_DECLARE_OPERATOR(Or)
MIR_DECLARE_OPERATOR(Xor)
MIR_DECLARE_OPERATOR(BitEqual)
MIR_DECLARE_OPERATOR(SLT)
MIR_DECLARE_OPERATOR(ULT)
MIR_DECLARE_OPERATOR(SLE)
MIR_DECLARE_OPERATOR(ULE)
MIR_DECLARE_OPERATOR(SGT)
MIR_DECLARE_OPERATOR(UGT)
MIR_DECLARE_OPERATOR(SGE)
MIR_DECLARE_OPERATOR(UGE)
MIR_DECLARE_OPERATOR(Lshr)
MIR_DECLARE_OPERATOR(Ashr)
MIR_DECLARE_OPERATOR(Shl)
MIR_DECLARE_OPERATOR(Log2)
MIR_DECLARE_OPERATOR(Popcount)
MIR_DECLARE_OPERATOR(CountlZero)
MIR_DECLARE_OPERATOR(CountrZero)
MIR_DECLARE_OPERATOR(CountlOne)
MIR_DECLARE_OPERATOR(CountrOne)

#undef MIR_DECLARE_OPERATOR

} // namespace metaphir
} // namespace llvm

#endif
