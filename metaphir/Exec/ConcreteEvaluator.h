//===- ConcreteEvaluator.h - Evaluate mpir_expr on the IR -------*- C++ -*-===//
//
// Evaluates constraint expressions of the mpir_expr dialect on what a match
// bound: ExprEvaluator in the concrete domain, whose leaves are the match's
// slots and whose operators apply their concrete() faces (Operators/).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_CONCRETEEVALUATOR_H
#define METAPHIR_EXEC_CONCRETEEVALUATOR_H

#include "metaphir/Matching/Binding.h"
#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/UseOracle.h"
#include "mlir/IR/Value.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/Support/Error.h"
#include <memory>

namespace llvm {
namespace metaphir {

namespace detail {
class ValueTrackContext;
} // namespace detail

/// What a variable bound to Binding is when Read (an mpir_expr.read) reads
/// it, as detail::bindingValue reads it.
Expected<ConstraintValue> readBinding(mlir::Value Read, const Binding &Binding);

class ConcreteEvaluator {
public:
  /// What a pattern value (an mpir_plan.slot) is bound to; null if unbound.
  using SlotLookup = function_ref<const Binding *(unsigned Slot)>;

  ConcreteEvaluator();
  ~ConcreteEvaluator();

  /// Sets what tells how constants are used in their module, when the IR
  /// matched has only part of it: uses of a global or constant expression
  /// can be in any function. Oracle must outlive the evaluation.
  void setUseOracle(UseOracle *Oracle) { Uses = Oracle; }
  /// Drops the analyses cached for value-tracking operators.
  void resetAnalyses();

  /// Evaluates E (see ExprEvaluator) on the bindings of a match's slots.
  Expected<ConstraintValue> evaluate(mlir::Value E, SlotLookup Slots);

private:
  std::optional<ModuleUses> getModuleUses(const llvm::Value &V);

  /// The analyses value tracking caches across evaluations.
  const std::unique_ptr<detail::ValueTrackContext> Analysis;
  UseOracle *Uses = nullptr;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_CONCRETEEVALUATOR_H
