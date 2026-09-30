#ifndef METAPHIR_MATCHING_INDEXDOMAIN_H
#define METAPHIR_MATCHING_INDEXDOMAIN_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConcreteDomain.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Support/Error.h"
#include <optional>
#include <type_traits>

namespace llvm {
namespace metaphir {

class FunctionFeatures;

/// What the pattern's values are on a function's features: the sites of IR
/// values, and the types (and widths) bound for one way the function's
/// instruction signatures can be joined.
class AbstractBindings {
public:
  const AbstractValue *lookup(const Value &V) const {
    auto It = Values.find(&V);
    return It == Values.end() ? nullptr : &It->second;
  }
  void bind(const Value &V, AbstractValue A) {
    Values.insert_or_assign(&V, std::move(A));
  }

  /// The type variables' bindings, if any.
  const Instantiation *Types = nullptr;

private:
  DenseMap<const Value *, AbstractValue> Values;
};

namespace detail {
template <class Op, class = void> struct HasAbstract : std::false_type {};
template <class Op>
struct HasAbstract<Op, std::void_t<decltype(&Op::abstract)>> : std::true_type {
};
} // namespace detail

/// A function's features as a domain of ConstraintEvaluator, where a
/// constraint is false only if no match in the function can satisfy it.
///
/// Operators on concrete operands compute their result as on the IR; on
/// others, they apply their abstract() faces, or are unknown. A concrete
/// boolean B stands for "B, or an evaluation error": either rejects a match
/// when B is false. An error is one the IR evaluation certainly has.
class IndexDomain {
public:
  using Value = AbstractValue;
  using State = AbstractBindings;
  /// The pattern instruction a value-tracking operator is anchored at, if it
  /// is certainly matched as itself; otherwise null.
  using Context = const Instruction *;

  /// Certain holds the pattern instructions every match matches as
  /// themselves.
  IndexDomain(const FunctionFeatures &Features,
              const SmallPtrSetImpl<const Instruction *> &Certain)
      : Features(Features), Certain(Certain) {}

  Value fromConcrete(ConstraintValue V) const {
    return AbstractValue::concrete(std::move(V));
  }
  Expected<Value> variable(const VariableConstraint &Expression,
                           const State &S) const;
  Expected<Value> array(const ArrayConstraint &Expression,
                        SmallVector<Value, 2> Elements) const;
  Expected<Value> arrayAccess(const ArrayAccessConstraint &Access, Value Array,
                              Value Index) const;

  template <class Op>
  Expected<Value> apply(ArrayRef<Value> Operands,
                        const OperatorConstraint &Expression) const {
    if (std::optional<SmallVector<ConstraintValue, 2>> Concrete =
            allConcrete(Operands)) {
      Expected<ConstraintValue> Result = Op::concrete(
          ConcreteCall{*Concrete, Expression, [](const llvm::Value &) {
                         return std::optional<ModuleUses>();
                       }});
      if (!Result)
        return Result.takeError();
      return AbstractValue::concrete(std::move(*Result));
    }
    if constexpr (detail::HasAbstract<Op>::value)
      return Op::abstract(AbstractCall{Operands, Expression, Features});
    return AbstractValue::unknown();
  }

  Expected<Context> explicitContext(Value, const OperatorConstraint &) const {
    return nullptr;
  }
  Expected<Context> defaultContext(const OperatorConstraint &Expression,
                                   const State &) const;
  template <class Op>
  Expected<Value> applyValueTrack(ArrayRef<Value> Operands, Context CtxI,
                                  const OperatorConstraint &Expression) const {
    if constexpr (detail::HasAbstract<Op>::value)
      if (CtxI)
        return Op::abstract(AbstractCall{Operands, Expression, Features, CtxI});
    return AbstractValue::unknown();
  }

  Expected<std::optional<Value>> decides(Constraint::OperatorID ID,
                                         const Value &Left,
                                         const OperatorConstraint &Expression);
  Expected<Value> combine(Constraint::OperatorID ID, Value Left,
                          Expected<Value> Right,
                          const OperatorConstraint &Expression);

  Error bindParameter(State &S, const MetaVariable &Parameter, Value Argument,
                      const OperatorConstraint &) const {
    S.bind(Parameter, std::move(Argument));
    return Error::success();
  }

private:
  /// The operands' concrete values, if all are concrete.
  static std::optional<SmallVector<ConstraintValue, 2>>
  allConcrete(ArrayRef<Value> Operands);

  const FunctionFeatures &Features;
  const SmallPtrSetImpl<const Instruction *> &Certain;
};

} // namespace metaphir
} // namespace llvm

#endif
