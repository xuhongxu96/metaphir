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

APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned);
std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits = 0);
APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth);

bool isNumeric(const ConstraintValue &V);
bool isStringLike(const ConstraintValue &V);
bool isStringArrayLike(const ConstraintValue &V);

Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                              const Constraint &Expression);
Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression);
Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression);
Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result,
                   const Constraint &Expression);
Expected<const llvm::Value *> requireValue(Expected<ConstraintValue> Result,
                                           const Constraint &Expression);
ConstraintValue integerResult(APInt Value, bool IsUnsigned);

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                const Constraint &Expression);

} // namespace detail

Expected<ConstraintValue> evaluateIsa(const ConstraintInterpreter &Interpreter,
                                      ArrayRef<Constraint *> Arguments,
                                      const Instantiation &State,
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

#endif
