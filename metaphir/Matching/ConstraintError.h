#ifndef METAPHIR_MATCHING_CONSTRAINTERROR_H
#define METAPHIR_MATCHING_CONSTRAINTERROR_H

#include "llvm/ADT/Twine.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

class Constraint;

namespace detail {

// Structured evaluation error carrying both the constraint (the error
// position) and the reason.
class ConstraintEvaluationError : public ErrorInfo<ConstraintEvaluationError> {
public:
  static char ID;
  const Constraint *Expression;
  std::string Message;

  ConstraintEvaluationError(const Constraint &Expression, const Twine &Message)
      : Expression(&Expression), Message(Message.str()) {}

  void log(raw_ostream &OS) const override;

  std::error_code convertToErrorCode() const override {
    return inconvertibleErrorCode();
  }
};

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTERROR_H