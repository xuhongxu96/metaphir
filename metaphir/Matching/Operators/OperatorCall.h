#ifndef METAPHIR_MATCHING_OPERATORS_OPERATORCALL_H
#define METAPHIR_MATCHING_OPERATORS_OPERATORCALL_H

#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLFunctionalExtras.h"

namespace llvm {
struct SimplifyQuery;
class Value;
namespace metaphir {

class Constraint;

/// A built-in constraint operator applied to evaluated operands on the IR.
///
/// Every operator is a descriptor struct, Op<ID> for its ID in
/// ConstraintOperators.def, whose static concrete(const ConcreteCall &)
/// computes its result on the IR. How operands are evaluated is up to
/// ConstraintEvaluator, so the descriptors only apply the operator.
struct ConcreteCall {
  /// The evaluated operands, including an optional trailing bit width; a
  /// value-tracking operator's explicit context is not among them.
  ArrayRef<ConstraintValue> Operands;
  /// The operator, for diagnostics.
  const Constraint &Expression;
  /// Makes the use list of a value complete before it is inspected.
  function_ref<void(const llvm::Value &)> RequireCompleteUses;
  /// The value-tracking query, for value-tracking operators only.
  const SimplifyQuery *Query = nullptr;
};

} // namespace metaphir
} // namespace llvm

#endif
