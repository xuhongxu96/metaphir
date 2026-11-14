//===- ExprEvaluator.h - Evaluate mpir_expr on the IR -----------*- C++ -*-===//
//
// Evaluates constraint expressions of the mpir_expr dialect on what a match
// bound, as ConstraintEvaluator<ConcreteDomain> evaluates MetaphIR
// constraints: with the same operator descriptors (Operators/), coercions
// and errors.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_EXPREVALUATOR_H
#define METAPHIR_EXEC_EXPREVALUATOR_H

#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/UseOracle.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/Support/Error.h"
#include <memory>

namespace llvm {
namespace metaphir {

namespace detail {
class ValueTrackContext;
} // namespace detail

/// The expression E names in errors: printed in the pattern language.
ExprRef getExprRef(mlir::Value E);

/// What a variable bound to Binding is when Read (an mpir_expr.read) reads
/// it, as detail::bindingValue reads it.
Expected<ConstraintValue> readBinding(mlir::Value Read,
                                      const Instantiation::Binding &Binding);

class ExprEvaluator {
public:
  /// What a pattern value (an mpir_plan.slot) is bound to; null if unbound.
  using SlotLookup =
      function_ref<const Instantiation::Binding *(unsigned Slot)>;

  ExprEvaluator();
  ~ExprEvaluator();

  /// See ConstraintInterpreter::setUseOracle.
  void setUseOracle(UseOracle *Oracle) { Uses = Oracle; }
  /// Drops the analyses cached for value-tracking operators.
  void resetAnalyses();

  Expected<ConstraintValue> evaluate(mlir::Value E, SlotLookup Slots);

  struct Frame;

private:
  Expected<ConstraintValue> eval(mlir::Value E, Frame &F);
  Expected<SmallVector<ConstraintValue, 2>> evalAll(mlir::ValueRange Values,
                                                    Frame &F);
  /// What V, a slot or a definition's parameter, is bound to.
  const Instantiation::Binding *lookup(mlir::Value V, Frame &F);
  Expected<ConstraintValue> evalCall(mlir::Operation *Call, Frame &F);
  Expected<ConstraintValue> evalApply(mlir::Operation *Apply, Frame &F);
  std::optional<ModuleUses> getModuleUses(const llvm::Value &V);

  std::unique_ptr<detail::ValueTrackContext> Analysis;
  UseOracle *Uses = nullptr;
  unsigned CallDepth = 0;
  static constexpr unsigned MaxCallDepth = 256;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_EXPREVALUATOR_H
