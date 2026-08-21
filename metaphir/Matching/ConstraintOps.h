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

Expected<ConstraintValue> evaluateIsa(const ConstraintInterpreter &Interpreter,
                                      ArrayRef<Constraint *> Arguments,
                                      const Instantiation &State,
                                      const Constraint &Expression);

Expected<ConstraintValue>
evaluateOpcode(const ConstraintInterpreter &Interpreter,
               ArrayRef<Constraint *> Arguments, const Instantiation &State,
               const Constraint &Expression);

Expected<ConstraintValue> evaluateLog2(const ConstraintInterpreter &Interpreter,
                                       ArrayRef<Constraint *> Arguments,
                                       const Instantiation &State,
                                       const Constraint &Expression);

Expected<ConstraintValue>
evaluatePopcount(const ConstraintInterpreter &Interpreter,
                 ArrayRef<Constraint *> Arguments, const Instantiation &State,
                 const Constraint &Expression);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTOPS_H
