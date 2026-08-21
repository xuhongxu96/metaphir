#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/IR/Constraints.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

namespace detail {

namespace {

std::string printValue(const llvm::Value &Value) {
  std::string Text;
  raw_string_ostream OS(Text);
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(&Value))
    Instruction->print(OS);
  else
    Value.printAsOperand(OS, false);
  return OS.str();
}

} // namespace

APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned) {
  APSInt Result = Value.extend(Width);
  Result.setIsUnsigned(IsUnsigned);
  return Result;
}

std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits) {
  unsigned Width =
      std::max(Left.getBitWidth(), Right.getBitWidth()) + ExtraBits;
  bool IsUnsigned = Left.isUnsigned() && Right.isUnsigned();
  return {extend(Left, Width, IsUnsigned), extend(Right, Width, IsUnsigned)};
}

APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth) {
  return APSInt(Value.zextOrTrunc(BitWidth), Value.isUnsigned());
}

bool isNumeric(const ConstraintValue &V) {
  auto Kind = V.getKind();
  if (Kind == ConstraintValue::Integer || Kind == ConstraintValue::Boolean)
    return true;
  if (Kind == ConstraintValue::Value)
    return isa<llvm::ConstantInt>(V.getValue());
  return false;
}

bool isStringLike(const ConstraintValue &V) {
  auto Kind = V.getKind();
  return Kind == ConstraintValue::String || Kind == ConstraintValue::Type ||
         Kind == ConstraintValue::Value;
}

bool isStringArrayLike(const ConstraintValue &V) {
  auto Kind = V.getKind();
  return Kind == ConstraintValue::StringArray ||
         Kind == ConstraintValue::TypeArray ||
         Kind == ConstraintValue::ValueArray;
}

Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                              const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::Boolean)
    return Result->getBoolean();
  if (Result->getKind() == ConstraintValue::Integer)
    return !Result->getInteger().isZero();
  return make_error<ConstraintEvaluationError>(
      Expression, "expected a boolean-coercible operand");
}

Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::Integer)
    return Result->getInteger();
  if (Result->getKind() == ConstraintValue::Boolean)
    return APSInt(APInt(1, Result->getBoolean()), true);

  // A value binding that is a constant integer can be coerced to an integer
  // so shift amounts / constants captured as Value metas can be used in
  // arithmetic constraints.
  if (Result->getKind() == ConstraintValue::Value) {
    if (const auto *Integer = dyn_cast<ConstantInt>(Result->getValue()))
      return APSInt(Integer->getValue(), true);
    return make_error<ConstraintEvaluationError>(
        Expression, "expected an integer-valued constant operand");
  }

  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-coercible operand");
}

Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::String)
    return Result->getString().str();
  std::string Text;
  raw_string_ostream OS(Text);
  if (Result->getKind() == ConstraintValue::Type)
    Result->getType()->print(OS);
  else if (Result->getKind() == ConstraintValue::Value)
    return printValue(*Result->getValue());
  else
    return make_error<ConstraintEvaluationError>(
        Expression, "expected a string-coercible operand");
  return OS.str();
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result,
                   const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::StringArray)
    return Result->getStringArray();

  ConstraintValue::StringArrayStorage Strings;

  if (Result->getKind() == ConstraintValue::TypeArray) {
    for (const llvm::Type *Type : Result->getTypeArray()) {
      std::string Text;
      raw_string_ostream OS(Text);
      Type->print(OS);
      Strings.push_back(OS.str());
    }
    return Strings;
  }

  if (Result->getKind() == ConstraintValue::ValueArray) {
    for (const llvm::Value *Value : Result->getValueArray()) {
      Expected<std::string> String =
          requireString(ConstraintValue::getValue(Value), Expression);
      if (!String)
        return String.takeError();
      Strings.push_back(std::move(*String));
    }
    return Strings;
  }

  return make_error<ConstraintEvaluationError>(
      Expression, "expected a string-array-coercible operand");
}

Expected<const llvm::Value *> requireValue(Expected<ConstraintValue> Result,
                                           const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() != ConstraintValue::Value)
    return make_error<ConstraintEvaluationError>(
        Expression, "expected an LLVM value operand");
  return Result->getValue();
}

ConstraintValue integerResult(APInt Value, bool IsUnsigned) {
  return ConstraintValue::getInteger(APSInt(std::move(Value), IsUnsigned));
}

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                const Constraint &Expression) {
  if (Left.getKind() == Right.getKind()) {
    switch (Left.getKind()) {
    case ConstraintValue::Integer:
      return APSInt::isSameValue(Left.getInteger(), Right.getInteger());
    case ConstraintValue::Boolean:
      return Left.getBoolean() == Right.getBoolean();
    case ConstraintValue::String:
      return Left.getString() == Right.getString();
    case ConstraintValue::Type:
      return Left.getType() == Right.getType();
    case ConstraintValue::Value:
      return Left.getValue() == Right.getValue();
    case ConstraintValue::TypeArray:
      return Left.getTypeArray() == Right.getTypeArray();
    case ConstraintValue::ValueArray:
      return Left.getValueArray() == Right.getValueArray();
    case ConstraintValue::StringArray:
      return Left.getStringArray() == Right.getStringArray();
    }
    llvm_unreachable("invalid constraint value kind");
  }

  if (isNumeric(Left) && isNumeric(Right)) {
    Expected<APSInt> L = requireInteger(std::move(Left), Expression);
    Expected<APSInt> R = requireInteger(std::move(Right), Expression);
    if (!L)
      return L.takeError();
    if (!R)
      return R.takeError();
    return APSInt::isSameValue(*L, *R);
  }

  if (isStringLike(Left) && isStringLike(Right)) {
    Expected<std::string> L = requireString(std::move(Left), Expression);
    Expected<std::string> R = requireString(std::move(Right), Expression);
    if (!L)
      return L.takeError();
    if (!R)
      return R.takeError();
    return *L == *R;
  }

  if (isStringArrayLike(Left) && isStringArrayLike(Right)) {
    Expected<ConstraintValue::StringArrayStorage> L =
        requireStringArray(std::move(Left), Expression);
    Expected<ConstraintValue::StringArrayStorage> R =
        requireStringArray(std::move(Right), Expression);
    if (!L)
      return L.takeError();
    if (!R)
      return R.takeError();
    return *L == *R;
  }

  return make_error<ConstraintEvaluationError>(
      Expression, "equality operands have different types");
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
