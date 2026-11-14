#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/IR/Constraint.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

ExprRef::ExprRef(const Constraint &C)
    : Node(&C), Print([](raw_ostream &OS, const void *Node) {
        OS << *static_cast<const Constraint *>(Node);
      }) {}

namespace detail {

char ConstraintEvaluationError::ID = 0;

void ConstraintEvaluationError::log(raw_ostream &OS) const {
  OS << "cannot evaluate constraint '";
  Expression.print(OS);
  OS << "': " << Message;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
