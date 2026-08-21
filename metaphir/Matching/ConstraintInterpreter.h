#ifndef METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H
#define METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H

#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/Support/Error.h"
#include <optional>

namespace llvm {
namespace metaphir {

class Constraint;
class Instantiation;
class ArrayConstraint;
class ArrayAccessConstraint;
class OperatorConstraint;
class VariableConstraint;

class ConstraintInterpreter {
public:
  Expected<ConstraintValue> evaluate(const Constraint &Expression,
                                     const Instantiation &State) const;

private:
  // Evaluates integer/boolean/string literal nodes.
  Expected<ConstraintValue> evalLiteral(const Constraint &Expression,
                                        const Instantiation &State) const;
  // Dispatches a variable reference by resolving it against the instantiation
  // state, checking that the bound value matches the expected result type.
  Expected<ConstraintValue> evalVariable(const VariableConstraint &Expression,
                                         const Instantiation &State) const;
  Expected<ConstraintValue> evalArray(const ArrayConstraint &Expression,
                                      const Instantiation &State) const;
  Expected<ConstraintValue> evalArrayAccess(const ArrayAccessConstraint &Access,
                                            const Instantiation &State) const;
  Expected<ConstraintValue> evalOperator(const OperatorConstraint &Operator,
                                         const Instantiation &State) const;
  Expected<ConstraintValue> evalLogical(const OperatorConstraint &Operator,
                                        const Instantiation &State) const;
  Expected<ConstraintValue> evalUnary(const OperatorConstraint &Operator,
                                      const Instantiation &State) const;
  Expected<ConstraintValue> evalShift(const OperatorConstraint &Operator,
                                      const Instantiation &State) const;
  Expected<ConstraintValue> evalArithmetic(const OperatorConstraint &Operator,
                                           const Instantiation &State) const;
  // Evaluates an optional trailing bitwidth argument. Returns std::nullopt when
  // the argument is absent (i.e. the operator was used without a bitwidth).
  Expected<std::optional<unsigned>>
  evalOptionalBitWidth(const OperatorConstraint &Operator,
                       unsigned ArgumentIndex,
                       const Instantiation &State) const;
};

} // namespace metaphir
} // namespace llvm

#endif
