#ifndef METAPHIR_MATCHING_CONSTRAINTERROR_H
#define METAPHIR_MATCHING_CONSTRAINTERROR_H

#include "llvm/ADT/Twine.h"
#include "llvm/Support/Error.h"

namespace llvm {
class raw_ostream;
namespace metaphir {

class Constraint;

/// The constraint expression an operator is evaluated for, which errors name:
/// a node of MetaphIR IR, or of another representation that prints itself.
class ExprRef {
public:
  using PrintFn = void (*)(raw_ostream &, const void *);

  /* implicit */ ExprRef(const Constraint &C);
  ExprRef(const void *Node, PrintFn Print) : Node(Node), Print(Print) {}

  void print(raw_ostream &OS) const { Print(OS, Node); }
  const void *getOpaqueNode() const { return Node; }

private:
  const void *Node;
  PrintFn Print;
};

namespace detail {

// Structured evaluation error carrying both the constraint (the error
// position) and the reason.
class ConstraintEvaluationError : public ErrorInfo<ConstraintEvaluationError> {
public:
  static char ID;
  ExprRef Expression;
  std::string Message;

  ConstraintEvaluationError(ExprRef Expression, const Twine &Message)
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
