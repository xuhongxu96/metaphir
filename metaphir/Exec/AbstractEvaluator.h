//===- AbstractEvaluator.h - Evaluate mpir_expr on features -----*- C++ -*-===//
//
// Evaluates constraint expressions of an mpir_index.query on a function's
// features: ExprEvaluator in the abstract domain, whose leaves are the sites
// of IR values and the types a typing binds, and whose operators apply their
// abstract() faces (Operators/) where an operand is not known. A constraint
// is false only if no match in the function can satisfy it.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_ABSTRACTEVALUATOR_H
#define METAPHIR_EXEC_ABSTRACTEVALUATOR_H

#include "metaphir/Matching/Binding.h"
#include "metaphir/Matching/Features.h"
#include "metaphir/Matching/Operators/AbstractCall.h"
#include "mlir/IR/Value.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

class AbstractEvaluator {
public:
  /// Evaluates on Features, with the query's type variables bound to Types
  /// (unbound where a binding is std::monostate). Both must outlive this.
  AbstractEvaluator(const FunctionFeatures &Features, ArrayRef<Binding> Types)
      : Features(Features), Types(Types) {}

  /// Evaluates E (see ExprEvaluator).
  Expected<AbstractValue> evaluate(mlir::Value E) const;

private:
  const FunctionFeatures &Features;
  ArrayRef<Binding> Types;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_ABSTRACTEVALUATOR_H
