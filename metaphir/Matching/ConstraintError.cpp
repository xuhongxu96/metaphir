#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {
namespace detail {

char ConstraintEvaluationError::ID = 0;

void ConstraintEvaluationError::log(raw_ostream &OS) const {
  OS << "cannot evaluate constraint '";
  printSurfaceExpression(OS, Expression);
  OS << "': " << Message;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
