#ifndef METAPHIR_MATCHING_CONSTRAINTOPS_H
#define METAPHIR_MATCHING_CONSTRAINTOPS_H

#include "metaphir/Matching/ConstraintInterpreter.h"

namespace llvm {
namespace metaphir {

class Constraint;
class Instantiation;

namespace detail {

// Structured evaluation error carrying both the constraint (the error
// position) and the reason, so consumers can report them separately instead
// of parsing them out of a formatted message.
class ConstraintEvaluationError : public ErrorInfo<ConstraintEvaluationError> {
public:
  static char ID;
  const Constraint *Expression;
  std::string Message;

  ConstraintEvaluationError(const Constraint &Expression, std::string Message)
      : Expression(&Expression), Message(std::move(Message)) {}

  void log(raw_ostream &OS) const override;
  std::error_code convertToErrorCode() const override {
    return inconvertibleErrorCode();
  }
};

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

} // namespace metaphir
} // namespace llvm

#endif
