#ifndef METAPHIR_MATCHING_CONSTRAINTOPS_H
#define METAPHIR_MATCHING_CONSTRAINTOPS_H

#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/ConstraintInterpreter.h"

namespace llvm {
namespace metaphir {

class Constraint;
class Instantiation;

// Interpreted built-in constraint operators. Each is implemented as a small,
// self-contained evaluator with a uniform signature: given the interpreter
// (for recursive sub-expression evaluation), the raw argument list, the
// instantiation state, and the enclosing operator node, it returns the
// operator's value or a structured evaluation error.

Expected<ConstraintValue> evaluateIsa(ConstraintInterpreter &Interpreter,
                                      ArrayRef<Constraint *> Arguments,
                                      const Instantiation &State,
                                      const Constraint &Expression);

Expected<ConstraintValue> evaluateOpcode(ConstraintInterpreter &Interpreter,
                                         ArrayRef<Constraint *> Arguments,
                                         const Instantiation &State,
                                         const Constraint &Expression);

Expected<ConstraintValue> evaluateLog2(ConstraintInterpreter &Interpreter,
                                       ArrayRef<Constraint *> Arguments,
                                       const Instantiation &State,
                                       const Constraint &Expression);

Expected<ConstraintValue> evaluatePopcount(ConstraintInterpreter &Interpreter,
                                           ArrayRef<Constraint *> Arguments,
                                           const Instantiation &State,
                                           const Constraint &Expression);

// Value-tracking backed operators. Each is a pure evaluator invoked by
// ConstraintInterpreter::evaluateValueTrack: given the already-evaluated
// operand values, the query context, and the operator node, it produces the
// operator's value or a structured error.

Expected<ConstraintValue> evaluateNoOverflow(ArrayRef<ConstraintValue> Values,
                                             const SimplifyQuery &Query,
                                             const Constraint &Expression);

Expected<ConstraintValue> evaluateKnownBits(ArrayRef<ConstraintValue> Values,
                                            const SimplifyQuery &Query,
                                            const Constraint &Expression);

Expected<ConstraintValue> evaluateKnownZeros(ConstraintInterpreter &Interpreter,
                                             ArrayRef<Constraint *> Arguments,
                                             const Instantiation &State,
                                             const Constraint &Expression);

Expected<ConstraintValue> evaluateKnownOnes(ConstraintInterpreter &Interpreter,
                                            ArrayRef<Constraint *> Arguments,
                                            const Instantiation &State,
                                            const Constraint &Expression);

Expected<ConstraintValue>
evaluateIsKnownNonZero(ArrayRef<ConstraintValue> Values,
                       const SimplifyQuery &Query,
                       const Constraint &Expression);

Expected<ConstraintValue>
evaluateIsKnownNegative(ArrayRef<ConstraintValue> Values,
                        const SimplifyQuery &Query,
                        const Constraint &Expression);

Expected<ConstraintValue>
evaluateIsKnownNonNegative(ArrayRef<ConstraintValue> Values,
                           const SimplifyQuery &Query,
                           const Constraint &Expression);

Expected<ConstraintValue>
evaluateIsKnownPositive(ArrayRef<ConstraintValue> Values,
                        const SimplifyQuery &Query,
                        const Constraint &Expression);

Expected<ConstraintValue>
evaluateIsKnownPowerOfTwo(ArrayRef<ConstraintValue> Values,
                          const SimplifyQuery &Query,
                          const Constraint &Expression);

Expected<ConstraintValue>
evaluateMaskedValueIsZero(ArrayRef<ConstraintValue> Values,
                          const SimplifyQuery &Query,
                          const Constraint &Expression);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTOPS_H
