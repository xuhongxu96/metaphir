#include "metaphir/Matching/ConcreteDomain.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

using namespace detail;

ConcreteDomain::ConcreteDomain()
    : Analysis(std::make_unique<ValueTrackContext>()) {}

ConcreteDomain::~ConcreteDomain() = default;

void ConcreteDomain::resetAnalyses() { Analysis->reset(); }

void ConcreteDomain::requireCompleteUses(const llvm::Value &V) {
  // Only constants other than plain data are used across functions.
  if (UseListCompleter && isa<llvm::Constant>(V) && !isa<ConstantData>(V))
    UseListCompleter();
}

/// Names Expression's variable in a diagnostic.
static std::string describeVariable(const VariableConstraint &Expression,
                                    StringRef Msg) {
  const metaphir::Value &Variable = *Expression.getVariable();
  if (const auto *MV = dyn_cast<MetaVariable>(&Variable))
    return (Twine("meta variable '?") + MV->getName() + "' " + Msg).str();
  std::string Str;
  raw_string_ostream OS(Str);
  OS << Variable;
  return (Twine("variable '") + OS.str() + "' " + Msg).str();
}

Expected<ConstraintValue>
ConcreteDomain::variable(const VariableConstraint &Expression,
                         const Instantiation &State) const {
  const Instantiation::Binding *Binding =
      State.lookup(*Expression.getVariable());
  if (!Binding)
    return make_error<ConstraintEvaluationError>(
        Expression, describeVariable(Expression, "is not instantiated"));
  return detail::bindingValue(Expression, *Binding);
}

Expected<ConstraintValue>
detail::bindingValue(const VariableConstraint &Expression,
                     const Instantiation::Binding &Binding) {
  auto FormatMsg = [&](StringRef Msg) {
    return describeVariable(Expression, Msg);
  };
  switch (Expression.getResultType()) {
  case Constraint::IntegerResult:
    if (const auto *Integer = std::get_if<APSInt>(&Binding.Data))
      return ConstraintValue::getInteger(*Integer);
    // An IR constant is read as a signed number, as in coerceValueToInteger.
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getInteger(
            APSInt(CI->getValue(), /*isUnsigned=*/false));
    break;
  case Constraint::BooleanResult:
    if (const auto *Boolean = std::get_if<bool>(&Binding.Data))
      return ConstraintValue::getBoolean(*Boolean);
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getBoolean(CI->isOne());
    break;
  case Constraint::StringResult:
    if (const auto *Predicate = std::get_if<CmpInst::Predicate>(&Binding.Data))
      return ConstraintValue::getString(CmpInst::getPredicateName(*Predicate));
    if (const auto *ID = std::get_if<Intrinsic::ID>(&Binding.Data))
      return ConstraintValue::getString(Intrinsic::getBaseName(*ID));
    break;
  case Constraint::TypeResult:
    if (const auto *Type = std::get_if<const llvm::Type *>(&Binding.Data))
      return ConstraintValue::getType(*Type);
    break;
  case Constraint::ValueResult:
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      return ConstraintValue::getValue(*Value);
    break;
  case Constraint::TypeArrayResult:
    if (const auto *Types =
            std::get_if<Instantiation::TypeArray>(&Binding.Data))
      return ConstraintValue::getTypeArray(*Types);
    break;
  case Constraint::ValueArrayResult:
    if (const auto *Values =
            std::get_if<Instantiation::ValueArray>(&Binding.Data))
      return ConstraintValue::getValueArray(*Values);
    break;
  case Constraint::Unknown:
    return std::visit(
        [&](const auto &Val) -> Expected<ConstraintValue> {
          using T = std::decay_t<decltype(Val)>;
          if constexpr (std::is_same_v<T, const llvm::Value *>)
            return ConstraintValue::getValue(Val);
          else if constexpr (std::is_same_v<T, const llvm::Type *>)
            return ConstraintValue::getType(Val);
          else if constexpr (std::is_same_v<T, APSInt>)
            return ConstraintValue::getInteger(Val);
          else if constexpr (std::is_same_v<T, bool>)
            return ConstraintValue::getBoolean(Val);
          else if constexpr (std::is_same_v<T, CmpInst::Predicate>)
            return ConstraintValue::getString(CmpInst::getPredicateName(Val));
          else if constexpr (std::is_same_v<T, Intrinsic::ID>)
            return ConstraintValue::getString(Intrinsic::getBaseName(Val));
          else if constexpr (std::is_same_v<T, Instantiation::TypeArray>)
            return ConstraintValue::getTypeArray(Val);
          else if constexpr (std::is_same_v<T, Instantiation::ValueArray>)
            return ConstraintValue::getValueArray(Val);
          else
            return make_error<ConstraintEvaluationError>(
                Expression, FormatMsg("has an incompatible binding"));
        },
        Binding.Data);
  default:
    llvm_unreachable("variable constraint has no result type");
  }

  return make_error<ConstraintEvaluationError>(
      Expression, FormatMsg("has an incompatible binding"));
}

Expected<ConstraintValue>
ConcreteDomain::array(const ArrayConstraint &Expression,
                      SmallVector<ConstraintValue, 2> Elements) const {
  return detail::arrayValue(Expression, std::move(Elements));
}

Expected<ConstraintValue>
detail::arrayValue(const ArrayConstraint &Expression,
                   SmallVector<ConstraintValue, 2> Elements) {
  switch (Expression.getResultType()) {
  case Constraint::TypeArrayResult: {
    Instantiation::TypeArray Types;
    for (const ConstraintValue &Element : Elements) {
      if (Element.getKind() != ConstraintValue::Type)
        llvm_unreachable("type array constraint has a non-type element");
      Types.push_back(Element.getType());
    }
    return ConstraintValue::getTypeArray(std::move(Types));
  }
  case Constraint::ValueArrayResult: {
    Instantiation::ValueArray Values;
    for (const ConstraintValue &Element : Elements) {
      if (Element.getKind() != ConstraintValue::Value)
        llvm_unreachable("value array constraint has a non-value element");
      Values.push_back(Element.getValue());
    }
    return ConstraintValue::getValueArray(std::move(Values));
  }
  case Constraint::StringArrayResult: {
    ConstraintValue::StringArrayStorage Strings;
    for (const ConstraintValue &Element : Elements) {
      Expected<std::string> String = requireString(Element, Expression);
      if (!String)
        return String.takeError();
      Strings.push_back(std::move(*String));
    }
    return ConstraintValue::getStringArray(std::move(Strings));
  }
  default:
    llvm_unreachable("array constraint has a non-array result type");
  }
}

Expected<ConstraintValue>
ConcreteDomain::arrayAccess(const ArrayAccessConstraint &Access,
                            ConstraintValue Array,
                            ConstraintValue IndexValue) const {
  return detail::arrayElement(Access, std::move(Array), std::move(IndexValue));
}

Expected<ConstraintValue>
detail::arrayElement(const ArrayAccessConstraint &Access, ConstraintValue Array,
                     ConstraintValue IndexValue) {
  Expected<APSInt> Index = requireInteger(IndexValue, Access);
  if (!Index)
    return Index.takeError();
  if (Index->isSigned() && Index->isNegative())
    return make_error<ConstraintEvaluationError>(Access,
                                                 "array index is negative");
  uint64_t Position = Index->getLimitedValue();

  switch (Array.getKind()) {
  case ConstraintValue::TypeArray: {
    const Instantiation::TypeArray &Types = Array.getTypeArray();
    if (Position >= Types.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getType(Types[Position]);
  }
  case ConstraintValue::ValueArray: {
    const Instantiation::ValueArray &Values = Array.getValueArray();
    if (Position >= Values.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getValue(Values[Position]);
  }
  case ConstraintValue::StringArray: {
    const ConstraintValue::StringArrayStorage &Strings = Array.getStringArray();
    if (Position >= Strings.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getString(Strings[Position]);
  }
  default:
    llvm_unreachable("array access constraint has a non-array operand");
  }
}

Expected<const llvm::Instruction *>
ConcreteDomain::explicitContext(ConstraintValue Explicit,
                                const OperatorConstraint &Expression) const {
  Expected<const llvm::Value *> Value = requireValue(Explicit, Expression);
  if (!Value)
    return Value.takeError();
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
    return Instruction;
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an instruction context operand");
}

Expected<const llvm::Instruction *>
ConcreteDomain::defaultContext(const OperatorConstraint &Expression,
                               const Instantiation &State) const {
  if (const metaphir::Instruction *Pattern = Expression.getContextInstruction())
    if (const Instantiation::Binding *Binding = State.lookup(*Pattern))
      if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
        if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
          return Instruction;
  return make_error<ConstraintEvaluationError>(
      Expression, "no context instruction for value-tracking operator "
                  "(place the constraint after an instruction or pass ?ctx "
                  "explicitly)");
}

Expected<std::optional<ConstraintValue>>
ConcreteDomain::decides(Constraint::OperatorID ID, const ConstraintValue &Left,
                        const OperatorConstraint &Expression) {
  Expected<bool> Boolean = requireBoolean(Left, Expression);
  if (!Boolean)
    return Boolean.takeError();
  bool IsOr = ID == Constraint::O_LogicalOr;
  if (*Boolean == IsOr)
    return ConstraintValue::getBoolean(*Boolean);
  return std::nullopt;
}

Expected<ConstraintValue>
ConcreteDomain::combine(Constraint::OperatorID, ConstraintValue,
                        Expected<ConstraintValue> Right,
                        const OperatorConstraint &Expression) {
  if (!Right)
    return Right.takeError();
  Expected<bool> Boolean = requireBoolean(*Right, Expression);
  if (!Boolean)
    return Boolean.takeError();
  return ConstraintValue::getBoolean(*Boolean);
}

Error ConcreteDomain::bindParameter(
    Instantiation &State, const MetaVariable &Parameter,
    ConstraintValue Argument, const OperatorConstraint &Expression) const {
  std::optional<Instantiation::Binding> Binding;
  switch (Argument.getKind()) {
  case ConstraintValue::Integer:
    Binding = Instantiation::Binding(Argument.getInteger());
    break;
  case ConstraintValue::Boolean:
    Binding = Instantiation::Binding(Argument.getBoolean());
    break;
  case ConstraintValue::Type:
    Binding = Instantiation::Binding(Argument.getType());
    break;
  case ConstraintValue::Value:
    Binding = Instantiation::Binding(Argument.getValue());
    break;
  case ConstraintValue::TypeArray:
    Binding = Instantiation::Binding(Argument.getTypeArray());
    break;
  case ConstraintValue::ValueArray:
    Binding = Instantiation::Binding(Argument.getValueArray());
    break;
  default:
    break;
  }
  if (!Binding)
    return make_error<ConstraintEvaluationError>(
        Expression, "unsupported argument type for user-defined constraint");
  State.bind(Parameter, std::move(*Binding));
  return Error::success();
}

} // namespace metaphir
} // namespace llvm
