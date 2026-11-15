#ifndef METAPHIR_MATCHING_CONSTRAINTERROR_H
#define METAPHIR_MATCHING_CONSTRAINTERROR_H

#include "mlir/IR/Value.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Error.h"

namespace llvm {
class raw_ostream;
namespace metaphir {

namespace detail {

/// An error evaluating a constraint: the expression (an mpir_expr value)
/// that failed, and why.
class ConstraintEvaluationError : public ErrorInfo<ConstraintEvaluationError> {
public:
  static char ID;
  mlir::Value Expression;
  std::string Message;

  ConstraintEvaluationError(mlir::Value Expression, const Twine &Message)
      : Expression(Expression), Message(Message.str()) {}

  void log(raw_ostream &OS) const override;

  std::error_code convertToErrorCode() const override {
    return inconvertibleErrorCode();
  }
};

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTERROR_H
