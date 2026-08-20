#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/IR/Constraints.h"
#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/Matching/Instantiation.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

using namespace detail;

ConstraintValue::ValueKind ConstraintValue::getKind() const {
  if (std::holds_alternative<APSInt>(Data))
    return Integer;
  if (std::holds_alternative<bool>(Data))
    return Boolean;
  if (std::holds_alternative<std::string>(Data))
    return String;
  if (std::holds_alternative<const llvm::Type *>(Data))
    return Type;
  if (std::holds_alternative<const llvm::Value *>(Data))
    return Value;
  if (std::holds_alternative<Instantiation::TypeArray>(Data))
    return TypeArray;
  if (std::holds_alternative<Instantiation::ValueArray>(Data))
    return ValueArray;
  assert(std::holds_alternative<StringArrayStorage>(Data));
  return StringArray;
}

const APSInt &ConstraintValue::getInteger() const {
  return std::get<APSInt>(Data);
}

bool ConstraintValue::getBoolean() const { return std::get<bool>(Data); }

StringRef ConstraintValue::getString() const {
  return std::get<std::string>(Data);
}

const llvm::Type *ConstraintValue::getType() const {
  return std::get<const llvm::Type *>(Data);
}

const llvm::Value *ConstraintValue::getValue() const {
  return std::get<const llvm::Value *>(Data);
}

const Instantiation::TypeArray &ConstraintValue::getTypeArray() const {
  return std::get<Instantiation::TypeArray>(Data);
}

const Instantiation::ValueArray &ConstraintValue::getValueArray() const {
  return std::get<Instantiation::ValueArray>(Data);
}

const ConstraintValue::StringArrayStorage &
ConstraintValue::getStringArray() const {
  return std::get<StringArrayStorage>(Data);
}

ConstraintValue ConstraintValue::getInteger(APSInt Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue ConstraintValue::getBoolean(bool Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getString(StringRef Value) {
  return ConstraintValue(Value.str());
}

ConstraintValue ConstraintValue::getType(const llvm::Type *Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getValue(const llvm::Value *Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getTypeArray(Instantiation::TypeArray Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue
ConstraintValue::getValueArray(Instantiation::ValueArray Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue ConstraintValue::getStringArray(StringArrayStorage Value) {
  return ConstraintValue(std::move(Value));
}

Expected<ConstraintValue>
ConstraintInterpreter::evaluate(const Constraint &Expression,
                                const Instantiation &State) const {
  switch (Expression.getConstraintID()) {
  case Constraint::Integer: {
    int64_t Value = cast<IntegerConstraint>(Expression).getValue();
    return ConstraintValue::getInteger(
        APSInt(APInt(64, static_cast<uint64_t>(Value), true), Value >= 0));
  }
  case Constraint::Boolean:
    return ConstraintValue::getBoolean(
        cast<BooleanConstraint>(Expression).getValue());
  case Constraint::String:
    return ConstraintValue::getString(
        cast<StringConstraint>(Expression).getValue());
  case Constraint::Array: {
    const auto &Array = cast<ArrayConstraint>(Expression);
    if (Expression.getResultType() == Constraint::TypeArrayResult) {
      Instantiation::TypeArray Types;
      for (const Constraint *Element : Array.getElements()) {
        Expected<ConstraintValue> Result = evaluate(*Element, State);
        if (!Result)
          return Result.takeError();
        if (Result->getKind() != ConstraintValue::Type)
          llvm_unreachable("type array constraint has a non-type element");
        Types.push_back(Result->getType());
      }
      return ConstraintValue::getTypeArray(std::move(Types));
    }
    if (Expression.getResultType() == Constraint::ValueArrayResult) {
      Instantiation::ValueArray Values;
      for (const Constraint *Element : Array.getElements()) {
        Expected<ConstraintValue> Result = evaluate(*Element, State);
        if (!Result)
          return Result.takeError();
        if (Result->getKind() != ConstraintValue::Value)
          llvm_unreachable("value array constraint has a non-value element");
        Values.push_back(Result->getValue());
      }
      return ConstraintValue::getValueArray(std::move(Values));
    }
    if (Expression.getResultType() == Constraint::StringArrayResult) {
      ConstraintValue::StringArrayStorage Strings;
      for (const Constraint *Element : Array.getElements()) {
        Expected<std::string> Result =
            requireString(evaluate(*Element, State), Expression);
        if (!Result)
          return Result.takeError();
        Strings.push_back(std::move(*Result));
      }
      return ConstraintValue::getStringArray(std::move(Strings));
    }
    llvm_unreachable("array constraint has a non-array result type");
  }
  case Constraint::Variable: {
    const MetaVariable &Variable =
        *cast<VariableConstraint>(Expression).getVariable();
    const Instantiation::Binding *Binding = State.lookup(Variable);
    if (!Binding)
      return evaluationError(Expression, Twine("meta variable '?") +
                                             Variable.getName() +
                                             "' is not instantiated");
    if (Expression.getResultType() == Constraint::IntegerResult) {
      if (const auto *Integer = std::get_if<APInt>(&Binding->Data))
        return ConstraintValue::getInteger(APSInt(*Integer, false));
    } else if (Expression.getResultType() == Constraint::BooleanResult) {
      if (const auto *Boolean = std::get_if<bool>(&Binding->Data))
        return ConstraintValue::getBoolean(*Boolean);
    } else if (Expression.getResultType() == Constraint::StringResult) {
      if (const auto *Predicate =
              std::get_if<CmpInst::Predicate>(&Binding->Data))
        return ConstraintValue::getString(
            CmpInst::getPredicateName(*Predicate));
      if (const auto *ID = std::get_if<Intrinsic::ID>(&Binding->Data))
        return ConstraintValue::getString(Intrinsic::getBaseName(*ID));
    } else if (Expression.getResultType() == Constraint::TypeResult) {
      if (const auto *Type = std::get_if<const llvm::Type *>(&Binding->Data))
        return ConstraintValue::getType(*Type);
    } else if (Expression.getResultType() == Constraint::ValueResult) {
      if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
        return ConstraintValue::getValue(*Value);
    } else if (Expression.getResultType() == Constraint::TypeArrayResult) {
      if (const auto *Types =
              std::get_if<Instantiation::TypeArray>(&Binding->Data))
        return ConstraintValue::getTypeArray(*Types);
    } else if (Expression.getResultType() == Constraint::ValueArrayResult) {
      if (const auto *Values =
              std::get_if<Instantiation::ValueArray>(&Binding->Data))
        return ConstraintValue::getValueArray(*Values);
    } else {
      llvm_unreachable("variable constraint has no result type");
    }
    return evaluationError(Expression, Twine("meta variable '?") +
                                           Variable.getName() +
                                           "' has an incompatible binding");
  }
  case Constraint::ArrayAccess: {
    const auto &Access = cast<ArrayAccessConstraint>(Expression);
    Expected<ConstraintValue> Array = evaluate(*Access.getArray(), State);
    if (!Array)
      return Array.takeError();
    Expected<APSInt> Index =
        requireInteger(evaluate(*Access.getIndex(), State), Expression);
    if (!Index)
      return Index.takeError();
    if (Index->isSigned() && Index->isNegative())
      return evaluationError(Expression, "array index is negative");
    uint64_t Position = Index->getLimitedValue();
    if (Array->getKind() == ConstraintValue::TypeArray) {
      const Instantiation::TypeArray &Types = Array->getTypeArray();
      if (Position >= Types.size())
        return evaluationError(Expression, "array index is out of bounds");
      return ConstraintValue::getType(Types[Position]);
    }
    if (Array->getKind() == ConstraintValue::ValueArray) {
      const Instantiation::ValueArray &Values = Array->getValueArray();
      if (Position >= Values.size())
        return evaluationError(Expression, "array index is out of bounds");
      return ConstraintValue::getValue(Values[Position]);
    }
    if (Array->getKind() == ConstraintValue::StringArray) {
      const ConstraintValue::StringArrayStorage &Strings =
          Array->getStringArray();
      if (Position >= Strings.size())
        return evaluationError(Expression, "array index is out of bounds");
      return ConstraintValue::getString(Strings[Position]);
    }
    llvm_unreachable("array access constraint has a non-array operand");
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call:
    break;
  }

  const auto &Operator = cast<OperatorConstraint>(Expression);
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  if (std::optional<Constraint::OperatorSchema> Schema =
          Constraint::getOperatorSchema(Operator.getOperatorID()))
    assert(Arguments.size() >= Schema->MinArity &&
           Arguments.size() <= Schema->MaxArity &&
           "built-in constraint operator has invalid arity");

  auto EvaluateBitWidth =
      [&](unsigned Index) -> Expected<std::optional<unsigned>> {
    if (Arguments.size() <= Index)
      return std::nullopt;
    Expected<APSInt> Width =
        requireInteger(evaluate(*Arguments[Index], State), Expression);
    if (!Width)
      return Width.takeError();
    if (Width->isNegative() || Width->isZero())
      return evaluationError(Expression, "bitwidth must be positive");
    return static_cast<unsigned>(Width->getLimitedValue());
  };
  switch (Operator.getOperatorID()) {
#define MIR_CONSTRAINT_INTERPRETED_OPERATOR(ID, Name, Kind, Result, Arity)     \
  case Constraint::O_##ID:                                                     \
    return evaluate##ID(*this, Arguments, State, Expression);
#include "metaphir/IR/ConstraintOperators.def"
  case Constraint::O_LogicalOr:
  case Constraint::O_LogicalAnd: {
    Expected<bool> Left =
        requireBoolean(evaluate(*Arguments[0], State), Expression);
    if (!Left)
      return Left.takeError();
    bool IsOr = Operator.getOperatorID() == Constraint::O_LogicalOr;
    if ((*Left && IsOr) || (!*Left && !IsOr))
      return ConstraintValue::getBoolean(*Left);
    Expected<bool> Right =
        requireBoolean(evaluate(*Arguments[1], State), Expression);
    if (!Right)
      return Right.takeError();
    return ConstraintValue::getBoolean(*Right);
  }
  case Constraint::O_Not: {
    Expected<bool> Operand =
        requireBoolean(evaluate(*Arguments[0], State), Expression);
    if (!Operand)
      return Operand.takeError();
    return ConstraintValue::getBoolean(!*Operand);
  }
  case Constraint::O_Negate: {
    Expected<std::optional<unsigned>> BitWidth = EvaluateBitWidth(1);
    if (!BitWidth)
      return BitWidth.takeError();
    Expected<APSInt> Operand =
        requireInteger(evaluate(*Arguments[0], State), Expression);
    if (!Operand)
      return Operand.takeError();
    if (*BitWidth)
      *Operand = castToBitWidth(*Operand, **BitWidth);
    if (*BitWidth)
      return integerResult(-static_cast<const APInt &>(*Operand),
                           Operand->isUnsigned());
    APSInt Extended = extend(*Operand, Operand->getBitWidth() + 1, false);
    return integerResult(-static_cast<const APInt &>(Extended), false);
  }
  case Constraint::O_Lshr:
  case Constraint::O_Ashr:
  case Constraint::O_Shl: {
    Expected<std::optional<unsigned>> BitWidth = EvaluateBitWidth(2);
    if (!BitWidth)
      return BitWidth.takeError();
    Expected<APSInt> Value =
        requireInteger(evaluate(*Arguments[0], State), Expression);
    if (!Value)
      return Value.takeError();
    if (*BitWidth)
      *Value = castToBitWidth(*Value, **BitWidth);
    Expected<APSInt> Amount =
        requireInteger(evaluate(*Arguments[1], State), Expression);
    if (!Amount)
      return Amount.takeError();
    if ((Amount->isSigned() && Amount->isNegative()) ||
        Amount->uge(Value->getBitWidth()))
      return evaluationError(Expression, "shift amount is out of range");
    const APInt &Integer = *Value;
    APInt Result;
    switch (Operator.getOperatorID()) {
    case Constraint::O_Lshr:
      Result = Integer.lshr(Amount->getLimitedValue());
      break;
    case Constraint::O_Ashr:
      Result = Integer.ashr(Amount->getLimitedValue());
      break;
    case Constraint::O_Shl:
      Result = Integer.shl(Amount->getLimitedValue());
      break;
    default:
      llvm_unreachable("invalid shift operator");
    }
    return integerResult(std::move(Result),
                         Operator.getOperatorID() != Constraint::O_Ashr &&
                             Value->isUnsigned());
  }
  case Constraint::UnknownOperator:
    return evaluationError(Expression, Twine("unknown operator '") +
                                           Operator.getOperator() + "'");
  default:
    break;
  }

  Expected<ConstraintValue> LeftResult = evaluate(*Arguments[0], State);
  if (!LeftResult)
    return LeftResult.takeError();
  Expected<ConstraintValue> RightResult = evaluate(*Arguments[1], State);
  if (!RightResult)
    return RightResult.takeError();

  if (Operator.getOperatorID() == Constraint::O_Equal ||
      Operator.getOperatorID() == Constraint::O_NotEqual) {
    Expected<bool> Equal = evaluateEquality(
        std::move(*LeftResult), std::move(*RightResult), Expression);
    if (!Equal)
      return Equal.takeError();
    return ConstraintValue::getBoolean(
        Operator.getOperatorID() == Constraint::O_Equal ? *Equal : !*Equal);
  }

  Expected<APSInt> Left = requireInteger(std::move(LeftResult), Expression);
  if (!Left)
    return Left.takeError();
  Expected<APSInt> Right = requireInteger(std::move(RightResult), Expression);
  if (!Right)
    return Right.takeError();

  std::optional<unsigned> BitWidth;
  if (Expected<std::optional<unsigned>> Width = EvaluateBitWidth(2)) {
    BitWidth = *Width;
  } else {
    return Width.takeError();
  }

  bool Unsigned = Left->isUnsigned() && Right->isUnsigned();
  unsigned ExtraBits = 0;
  if (BitWidth) {
    *Left = castToBitWidth(*Left, *BitWidth);
    *Right = castToBitWidth(*Right, *BitWidth);
  } else {
    switch (Operator.getOperatorID()) {
    case Constraint::O_Multiply:
      ExtraBits = std::min(Left->getBitWidth(), Right->getBitWidth());
      break;
    case Constraint::O_Add:
    case Constraint::O_Subtract:
      ExtraBits = 1;
      break;
    default:
      break;
    }
  }
  auto [LHS, RHS] = widen(*Left, *Right, ExtraBits);
  const APInt &L = LHS;
  const APInt &R = RHS;

  switch (Operator.getOperatorID()) {
  case Constraint::O_Add:
    return integerResult(L + R, Unsigned);
  case Constraint::O_Subtract:
    return integerResult(L - R, false);
  case Constraint::O_Multiply:
    return integerResult(L * R, Unsigned);
  case Constraint::O_And:
    return integerResult(L & R, Unsigned);
  case Constraint::O_Or:
    return integerResult(L | R, Unsigned);
  case Constraint::O_Xor:
    return integerResult(L ^ R, Unsigned);
  case Constraint::O_SDiv:
  case Constraint::O_UDiv:
  case Constraint::O_SRem:
  case Constraint::O_URem:
    if (R.isZero())
      return evaluationError(Expression, "division by zero");
    if (Operator.getOperatorID() == Constraint::O_SDiv)
      return integerResult(L.sdiv(R), false);
    if (Operator.getOperatorID() == Constraint::O_UDiv)
      return integerResult(L.udiv(R), true);
    if (Operator.getOperatorID() == Constraint::O_SRem)
      return integerResult(L.srem(R), false);
    return integerResult(L.urem(R), true);
  case Constraint::O_SLT:
    return ConstraintValue::getBoolean(L.slt(R));
  case Constraint::O_ULT:
    return ConstraintValue::getBoolean(L.ult(R));
  case Constraint::O_SLE:
    return ConstraintValue::getBoolean(L.sle(R));
  case Constraint::O_ULE:
    return ConstraintValue::getBoolean(L.ule(R));
  case Constraint::O_SGT:
    return ConstraintValue::getBoolean(L.sgt(R));
  case Constraint::O_UGT:
    return ConstraintValue::getBoolean(L.ugt(R));
  case Constraint::O_SGE:
    return ConstraintValue::getBoolean(L.sge(R));
  case Constraint::O_UGE:
    return ConstraintValue::getBoolean(L.uge(R));
  default:
    llvm_unreachable("constraint operator handled before integer evaluation");
  }
}

} // namespace metaphir
} // namespace llvm
