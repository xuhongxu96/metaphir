#ifndef METAPHIR_MATCHING_CONSTRAINTOPS_H
#define METAPHIR_MATCHING_CONSTRAINTOPS_H

#include "metaphir/Matching/ConstraintInterpreter.h"

namespace llvm {
namespace metaphir {

class Constraint;
class Instantiation;

namespace detail {

Error evaluationError(const Constraint &Expression, const Twine &Message);
Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression);
Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression);
Expected<const llvm::Value *>
requireValue(Expected<ConstraintValue> Result, const Constraint &Expression);
ConstraintValue integerResult(APInt Value, bool IsUnsigned);

} // namespace detail

Expected<ConstraintValue>
evaluateIsa(const ConstraintInterpreter &Interpreter,
            ArrayRef<Constraint *> Arguments, const Instantiation &State,
            const Constraint &Expression);
Expected<ConstraintValue>
evaluateLshr(const ConstraintInterpreter &Interpreter,
             ArrayRef<Constraint *> Arguments, const Instantiation &State,
             const Constraint &Expression);
Expected<ConstraintValue>
evaluateAshr(const ConstraintInterpreter &Interpreter,
             ArrayRef<Constraint *> Arguments, const Instantiation &State,
             const Constraint &Expression);

} // namespace metaphir
} // namespace llvm

#endif
