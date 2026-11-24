#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/ConstantInteger.h"
#include "metaphir/Matching/ConstraintCoercions.inc"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <array>
#include <optional>

namespace llvm {
namespace metaphir {

namespace detail {

// The coercion lattice as a dense [Src][Dst] matrix of the conversions in
// ConstraintCoercions.td, so lookup is O(1) and the whole lattice stays
// explicit. A cell is null when there is no such conversion.
static CoercionFn getCoercion(ConstraintValue::ValueKind Src,
                              ConstraintValue::ValueKind Dst) {
  using Matrix =
      std::array<std::array<CoercionFn, ConstraintValue::NumValueKinds>,
                 ConstraintValue::NumValueKinds>;
  static const Matrix M = [] {
    Matrix M{};
    for (const Coercion &C : Coercions)
      M[C.Src][C.Dst] = C.Convert;
    return M;
  }();
  return M[Src][Dst];
}

// Name of a coercion target with its indefinite article, used in the
// "expected a/an <name>-coercible operand" diagnostics.
static StringRef targetName(ConstraintValue::ValueKind Target) {
  switch (Target) {
  case ConstraintValue::Boolean:
    return "a boolean";
  case ConstraintValue::Integer:
    return "an integer";
  case ConstraintValue::String:
    return "a string";
  case ConstraintValue::StringArray:
    return "a string-array";
  case ConstraintValue::Type:
    return "a type";
  case ConstraintValue::Value:
    return "a value";
  case ConstraintValue::TypeArray:
    return "a type-array";
  case ConstraintValue::ValueArray:
    return "a value-array";
  case ConstraintValue::BitVector:
    return "a bit-vector";
  case ConstraintValue::NumValueKinds:
    break;
  }
  llvm_unreachable("invalid constraint value kind");
}

// Low-level converters. Each implements one edge of the coercion lattice and
// is responsible for both producing the destination value and reporting the
// precise reason a value cannot be converted.
Expected<ConstraintValue> coerceBooleanToInteger(const ConstraintValue &V,
                                                 mlir::Value) {
  return integerResult(APInt(1, V.getBoolean()), true);
}

Expected<ConstraintValue> coerceIntegerToBoolean(const ConstraintValue &V,
                                                 mlir::Value) {
  return ConstraintValue::getBoolean(!V.getInteger().isZero());
}

Expected<ConstraintValue> coerceValueToInteger(const ConstraintValue &V,
                                               mlir::Value Expression) {
  // Constants are treated as signed, so that 'slt' on a negative constant is
  // correct; the unsigned operators still compare the bit pattern.
  if (std::optional<APInt> Integer = getConstantInteger(*V.getValue()))
    return integerResult(*Integer, false);
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-valued constant operand");
}

Expected<ConstraintValue> coerceTypeToString(const ConstraintValue &V,
                                             mlir::Value) {
  std::string Text;
  raw_string_ostream OS(Text);
  V.getType()->print(OS);
  return ConstraintValue::getString(OS.str());
}

/// A value as a string: an instruction as it is printed, any other value as
/// an operand. Every value has one.
static std::string valueText(const llvm::Value *Value) {
  std::string Text;
  raw_string_ostream OS(Text);
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(Value))
    Instruction->print(OS);
  else
    Value->printAsOperand(OS, false);
  return Text;
}

Expected<ConstraintValue> coerceValueToString(const ConstraintValue &V,
                                              mlir::Value) {
  return ConstraintValue::getString(valueText(V.getValue()));
}

Expected<ConstraintValue> coerceTypeArrayToStringArray(const ConstraintValue &V,
                                                       mlir::Value) {
  ConstraintValue::StringArrayStorage Strings;
  for (const llvm::Type *Type : V.getTypeArray()) {
    std::string Text;
    raw_string_ostream OS(Text);
    Type->print(OS);
    Strings.push_back(OS.str());
  }
  return ConstraintValue::getStringArray(std::move(Strings));
}

Expected<ConstraintValue>
coerceValueArrayToStringArray(const ConstraintValue &V, mlir::Value) {
  ConstraintValue::StringArrayStorage Strings;
  for (const llvm::Value *Value : V.getValueArray())
    Strings.push_back(valueText(Value));
  return ConstraintValue::getStringArray(std::move(Strings));
}

bool isNumeric(const ConstraintValue &V) {
  if (V.getKind() == ConstraintValue::Value)
    return getConstantInteger(*V.getValue()).has_value();
  return canCoerceTo(V, ConstraintValue::Integer);
}

bool isStringLike(const ConstraintValue &V) {
  return canCoerceTo(V, ConstraintValue::String);
}

bool isStringArrayLike(const ConstraintValue &V) {
  return canCoerceTo(V, ConstraintValue::StringArray);
}

bool canCoerceTo(const ConstraintValue &V, ConstraintValue::ValueKind Target) {
  return V.getKind() == Target || getCoercion(V.getKind(), Target);
}

Expected<ConstraintValue> coerce(ConstraintValue V,
                                 ConstraintValue::ValueKind Target,
                                 mlir::Value Expression) {
  if (V.getKind() == Target)
    return V;

  if (CoercionFn Coerce = getCoercion(V.getKind(), Target))
    return Coerce(V, Expression);

  return make_error<ConstraintEvaluationError>(
      Expression,
      Twine("expected ") + targetName(Target) + "-coercible operand");
}

Expected<bool> requireBoolean(const ConstraintValue &Value,
                              mlir::Value Expression) {
  Expected<ConstraintValue> Boolean =
      coerce(Value, ConstraintValue::Boolean, Expression);
  if (!Boolean)
    return Boolean.takeError();
  return Boolean->getBoolean();
}

Expected<APSInt> requireInteger(const ConstraintValue &Value,
                                mlir::Value Expression) {
  Expected<ConstraintValue> Integer =
      coerce(Value, ConstraintValue::Integer, Expression);
  if (!Integer)
    return Integer.takeError();
  return Integer->getInteger();
}

Expected<std::string> requireString(const ConstraintValue &Value,
                                    mlir::Value Expression) {
  Expected<ConstraintValue> String =
      coerce(Value, ConstraintValue::String, Expression);
  if (!String)
    return String.takeError();
  return String->getString().str();
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(const ConstraintValue &Value, mlir::Value Expression) {
  Expected<ConstraintValue> StringArray =
      coerce(Value, ConstraintValue::StringArray, Expression);
  if (!StringArray)
    return StringArray.takeError();
  return StringArray->getStringArray();
}

Expected<const llvm::Value *> requireValue(const ConstraintValue &Value,
                                           mlir::Value Expression) {
  if (Value.getKind() != ConstraintValue::Value)
    return make_error<ConstraintEvaluationError>(
        Expression, "expected an LLVM value operand");
  return Value.getValue();
}

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                mlir::Value Expression) {
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
    case ConstraintValue::BitVector:
      return Left.getKnownBits() == Right.getKnownBits();
    case ConstraintValue::NumValueKinds:
      break;
    }
    llvm_unreachable("invalid constraint value kind");
  }

  // Coerces both operands with Require and compares the results. Both
  // coercions are checked, so neither error is dropped.
  auto Compare = [&](auto Require) -> Expected<bool> {
    auto L = Require(Left, Expression);
    auto R = Require(Right, Expression);
    if (!L || !R)
      return joinErrors(L.takeError(), R.takeError());
    if constexpr (std::is_same_v<std::decay_t<decltype(*L)>, APSInt>)
      return APSInt::isSameValue(*L, *R);
    else
      return *L == *R;
  };
  auto RequireInteger = [](const ConstraintValue &V, mlir::Value E) {
    return requireInteger(V, E);
  };
  auto RequireString = [](const ConstraintValue &V, mlir::Value E) {
    return requireString(V, E);
  };
  auto RequireStringArray = [](const ConstraintValue &V, mlir::Value E) {
    return requireStringArray(V, E);
  };

  if (isNumeric(Left) && isNumeric(Right))
    return Compare(RequireInteger);
  if (isStringLike(Left) && isStringLike(Right))
    return Compare(RequireString);
  if (isStringArrayLike(Left) && isStringArrayLike(Right))
    return Compare(RequireStringArray);

  return make_error<ConstraintEvaluationError>(
      Expression, "equality operands have different types");
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
