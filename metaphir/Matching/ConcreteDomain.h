#ifndef METAPHIR_MATCHING_CONCRETEDOMAIN_H
#define METAPHIR_MATCHING_CONCRETEDOMAIN_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "llvm/Support/Error.h"
#include <functional>
#include <memory>
#include <optional>

namespace llvm {
class Instruction;
namespace metaphir {

class MetaVariable;

namespace detail {
/// The value a variable bound to Binding has, as Expression reads it.
Expected<ConstraintValue> bindingValue(const VariableConstraint &Expression,
                                       const Instantiation::Binding &Binding);
/// The array of Elements, as Expression builds it.
Expected<ConstraintValue> arrayValue(const ArrayConstraint &Expression,
                                     SmallVector<ConstraintValue, 2> Elements);
/// The element of Array at Index.
Expected<ConstraintValue> arrayElement(const ArrayAccessConstraint &Access,
                                       ConstraintValue Array,
                                       ConstraintValue Index);
} // namespace detail

/// The IR as a domain of ConstraintEvaluator: variables are bound to what a
/// match instantiated them to, and operators compute their results, with
/// value tracking anchored at the context instruction's binding.
class ConcreteDomain {
public:
  using Value = ConstraintValue;
  using State = Instantiation;
  using Context = const llvm::Instruction *;

  ConcreteDomain();
  ~ConcreteDomain();

  /// Drops the analyses cached for value-tracking operators. Call it before
  /// the functions they were built for are freed.
  void resetAnalyses();
  /// See ConstraintInterpreter::setUseListCompleter.
  void setUseListCompleter(std::function<void()> Completer) {
    UseListCompleter = std::move(Completer);
  }
  /// Makes V's use list complete before it is inspected.
  void requireCompleteUses(const llvm::Value &V);

  Value fromConcrete(ConstraintValue V) const { return V; }
  Expected<Value> variable(const VariableConstraint &Expression,
                           const State &S) const;
  Expected<Value> array(const ArrayConstraint &Expression,
                        SmallVector<Value, 2> Elements) const;
  Expected<Value> arrayAccess(const ArrayAccessConstraint &Access, Value Array,
                              Value Index) const;

  template <class Op>
  Expected<Value> apply(ArrayRef<Value> Operands,
                        const OperatorConstraint &Expression) {
    return Op::concrete(
        ConcreteCall{Operands, Expression,
                     [this](const llvm::Value &V) { requireCompleteUses(V); }});
  }

  Expected<Context> explicitContext(Value Explicit,
                                    const OperatorConstraint &Expression) const;
  Expected<Context> defaultContext(const OperatorConstraint &Expression,
                                   const State &S) const;
  template <class Op>
  Expected<Value> applyValueTrack(ArrayRef<Value> Operands, Context CtxI,
                                  const OperatorConstraint &Expression) {
    SimplifyQuery Query = Analysis->getQuery(CtxI);
    return Op::concrete(ConcreteCall{
        Operands, Expression,
        [this](const llvm::Value &V) { requireCompleteUses(V); }, &Query});
  }

  Expected<std::optional<Value>> decides(Constraint::OperatorID ID,
                                         const Value &Left,
                                         const OperatorConstraint &Expression);
  Expected<Value> combine(Constraint::OperatorID ID, Value Left,
                          Expected<Value> Right,
                          const OperatorConstraint &Expression);

  Error bindParameter(State &S, const MetaVariable &Parameter, Value Argument,
                      const OperatorConstraint &Expression) const;

private:
  // Lazily-constructed per-function analyses for value-tracking operators.
  std::unique_ptr<detail::ValueTrackContext> Analysis;
  std::function<void()> UseListCompleter;
};

} // namespace metaphir
} // namespace llvm

#endif
