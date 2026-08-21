#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/IR/Constraint.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

namespace detail {

char ConstraintEvaluationError::ID = 0;

void ConstraintEvaluationError::log(raw_ostream &OS) const {
  OS << "cannot evaluate constraint '" << *Expression << "': " << Message;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm