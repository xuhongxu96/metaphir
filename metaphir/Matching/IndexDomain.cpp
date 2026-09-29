#include "metaphir/Matching/IndexDomain.h"
#include "metaphir/Matching/ConstraintCoercion.h"

namespace llvm {
namespace metaphir {

using namespace detail;

std::optional<SmallVector<ConstraintValue, 2>>
IndexDomain::allConcrete(ArrayRef<AbstractValue> Operands) {
  SmallVector<ConstraintValue, 2> Concrete;
  for (const AbstractValue &Operand : Operands) {
    if (!Operand.isConcrete())
      return std::nullopt;
    Concrete.push_back(Operand.getConcrete());
  }
  return Concrete;
}

Expected<AbstractValue>
IndexDomain::variable(const VariableConstraint &Expression,
                      const AbstractBindings &S) const {
  const metaphir::Value &Variable = *Expression.getVariable();
  if (const AbstractValue *Bound = S.lookup(Variable))
    return *Bound;
  if (S.Types)
    if (const Instantiation::Binding *Binding = S.Types->lookup(Variable)) {
      Expected<ConstraintValue> Value = bindingValue(Expression, *Binding);
      if (!Value)
        return Value.takeError();
      return AbstractValue::concrete(std::move(*Value));
    }
  // Whatever the IR binds it to is not known here.
  return AbstractValue::unknown();
}

Expected<AbstractValue>
IndexDomain::array(const ArrayConstraint &Expression,
                   SmallVector<AbstractValue, 2> Elements) const {
  std::optional<SmallVector<ConstraintValue, 2>> Concrete =
      allConcrete(Elements);
  if (!Concrete)
    return AbstractValue::unknown();
  Expected<ConstraintValue> Array =
      arrayValue(Expression, std::move(*Concrete));
  if (!Array)
    return Array.takeError();
  return AbstractValue::concrete(std::move(*Array));
}

Expected<AbstractValue>
IndexDomain::arrayAccess(const ArrayAccessConstraint &Access,
                         AbstractValue Array, AbstractValue Index) const {
  if (!Array.isConcrete() || !Index.isConcrete())
    return AbstractValue::unknown();
  Expected<ConstraintValue> Element =
      arrayElement(Access, Array.getConcrete(), Index.getConcrete());
  if (!Element)
    return Element.takeError();
  return AbstractValue::concrete(std::move(*Element));
}

Expected<const Instruction *>
IndexDomain::defaultContext(const OperatorConstraint &Expression,
                            const AbstractBindings &) const {
  const Instruction *Pattern = Expression.getContextInstruction();
  return Pattern && Certain.count(Pattern) ? Pattern : nullptr;
}

Expected<std::optional<AbstractValue>>
IndexDomain::decides(Constraint::OperatorID ID, const AbstractValue &Left,
                     const OperatorConstraint &Expression) {
  if (!Left.isConcrete())
    return std::nullopt;
  Expected<bool> Boolean = requireBoolean(Left.getConcrete(), Expression);
  if (!Boolean)
    return Boolean.takeError();
  if (*Boolean == (ID == Constraint::O_LogicalOr))
    return AbstractValue::concrete(ConstraintValue::getBoolean(*Boolean));
  return std::nullopt;
}

Expected<AbstractValue>
IndexDomain::combine(Constraint::OperatorID ID, AbstractValue Left,
                     Expected<AbstractValue> Right,
                     const OperatorConstraint &Expression) {
  bool IsOr = ID == Constraint::O_LogicalOr;
  // The right side: true, false (including an error, which rejects), or
  // unknown.
  std::optional<bool> RightValue;
  if (!Right) {
    consumeError(Right.takeError());
    RightValue = false;
  } else if (Right->isConcrete()) {
    Expected<bool> Boolean = requireBoolean(Right->getConcrete(), Expression);
    if (Boolean)
      RightValue = *Boolean;
    else {
      consumeError(Boolean.takeError());
      RightValue = false;
    }
  }
  auto Boolean = [](bool B) {
    return AbstractValue::concrete(ConstraintValue::getBoolean(B));
  };
  // A concrete left side did not decide the result, so the right side is it.
  if (Left.isConcrete())
    return RightValue ? Boolean(*RightValue) : AbstractValue::unknown();
  // With the left side unknown, a false right side decides '&&', and a true
  // one decides '||'.
  if (RightValue && *RightValue == IsOr)
    return Boolean(*RightValue);
  return AbstractValue::unknown();
}

} // namespace metaphir
} // namespace llvm
