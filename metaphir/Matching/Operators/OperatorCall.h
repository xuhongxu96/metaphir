#ifndef METAPHIR_MATCHING_OPERATORS_OPERATORCALL_H
#define METAPHIR_MATCHING_OPERATORS_OPERATORCALL_H

#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/UseOracle.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include <optional>

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
  /// How a value used across functions is used in its module, if its use
  /// list is not complete.
  function_ref<std::optional<ModuleUses>(const llvm::Value &)> GetModuleUses;
  /// The value-tracking query, for value-tracking operators only.
  const SimplifyQuery *Query = nullptr;
};

} // namespace metaphir
} // namespace llvm

#endif
