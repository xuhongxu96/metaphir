#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/IR/Constraints.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <array>
#include <optional>

namespace llvm {
namespace metaphir {

namespace detail {

namespace {

// Identifiers for each admissible coercion. This enum is the set of
// converters named by the Coercions.def entries; each enumerator is a single
// edge of the coercion lattice. UnknownCoercion marks an absent edge.
enum CoercionOp {
  UnknownCoercion = 0,
#define MIR_COERCION(Src, Dst, Op) Coerce##Op,
#include "metaphir/Matching/Coercions.def"
};

// The coercion lattice as a dense [Src][Dst] matrix. Each cell holds the
// coercion operator converting a source kind into a destination kind, or
// UnknownCoercion when no such conversion exists. The matrix is zero-filled
// (UnknownCoercion) and the admissible edges are stamped in from
// Coercions.def, so lookup is O(1) and the whole lattice stays explicit.
const std::array<std::array<CoercionOp, ConstraintValue::NumValueKinds>,
                 ConstraintValue::NumValueKinds>
    CoercionMatrix = [] {
      std::array<std::array<CoercionOp, ConstraintValue::NumValueKinds>,
                 ConstraintValue::NumValueKinds>
          Matrix{};
#define MIR_COERCION(Src, Dst, Op)                                             \
  Matrix[ConstraintValue::Src][ConstraintValue::Dst] = Coerce##Op;
#include "metaphir/Matching/Coercions.def"
      return Matrix;
    }();

std::optional<CoercionOp> lookupRule(ConstraintValue::ValueKind Src,
                                     ConstraintValue::ValueKind Dst) {
  CoercionOp Op = CoercionMatrix[Src][Dst];
  return Op == UnknownCoercion ? std::nullopt : std::optional<CoercionOp>(Op);
}

// Name of a coercion target with its indefinite article, used in the
// "expected a/an <name>-coercible operand" diagnostics.
StringRef targetName(ConstraintValue::ValueKind Target) {
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
  case ConstraintValue::NumValueKinds:
    break;
  }
  llvm_unreachable("invalid constraint value kind");
}

// Low-level converters. Each implements one edge of the coercion lattice and
// is responsible for both producing the destination value and reporting the
// precise reason a value cannot be converted.
Expected<ConstraintValue> coerceBooleanToInteger(const ConstraintValue &V,
                                                 const Constraint &Expression) {
  return integerResult(APInt(1, V.getBoolean()), true);
}

Expected<ConstraintValue> coerceIntegerToBoolean(const ConstraintValue &V,
                                                 const Constraint &Expression) {
  return ConstraintValue::getBoolean(!V.getInteger().isZero());
}

Expected<ConstraintValue> coerceValueToInteger(const ConstraintValue &V,
                                               const Constraint &Expression) {
  if (const auto *Integer = dyn_cast<ConstantInt>(V.getValue()))
    return integerResult(Integer->getValue(), true);
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-valued constant operand");
}

Expected<ConstraintValue> coerceTypeToString(const ConstraintValue &V,
                                             const Constraint &Expression) {
  std::string Text;
  raw_string_ostream OS(Text);
  V.getType()->print(OS);
  return ConstraintValue::getString(OS.str());
}

Expected<ConstraintValue> coerceValueToString(const ConstraintValue &V,
                                              const Constraint &Expression) {
  std::string Text;
  raw_string_ostream OS(Text);
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(V.getValue()))
    Instruction->print(OS);
  else
    V.getValue()->printAsOperand(OS, false);
  return ConstraintValue::getString(OS.str());
}

Expected<ConstraintValue>
coerceTypeArrayToStringArray(const ConstraintValue &V,
                             const Constraint &Expression) {
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
coerceValueArrayToStringArray(const ConstraintValue &V,
                              const Constraint &Expression) {
  ConstraintValue::StringArrayStorage Strings;
  for (const llvm::Value *Value : V.getValueArray()) {
    Expected<std::string> String =
        requireString(ConstraintValue::getValue(Value), Expression);
    if (!String)
      return String.takeError();
    Strings.push_back(std::move(*String));
  }
  return ConstraintValue::getStringArray(std::move(Strings));
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
  if (V.getKind() == ConstraintValue::Value)
    return isa<llvm::ConstantInt>(V.getValue());
  return canCoerceTo(V, ConstraintValue::Integer);
}

bool isStringLike(const ConstraintValue &V) {
  return canCoerceTo(V, ConstraintValue::String);
}

bool isStringArrayLike(const ConstraintValue &V) {
  return canCoerceTo(V, ConstraintValue::StringArray);
}

bool canCoerceTo(const ConstraintValue &V, ConstraintValue::ValueKind Target) {
  return V.getKind() == Target || lookupRule(V.getKind(), Target).has_value();
}

Expected<ConstraintValue> coerce(ConstraintValue V,
                                 ConstraintValue::ValueKind Target,
                                 const Constraint &Expression) {
  if (V.getKind() == Target)
    return V;

  if (std::optional<CoercionOp> Op = lookupRule(V.getKind(), Target)) {
    switch (*Op) {
    case UnknownCoercion:
      break;
#define MIR_COERCION(Src, Dst, Op)                                             \
  case Coerce##Op:                                                             \
    return coerce##Op(V, Expression);
#include "metaphir/Matching/Coercions.def"
    }
    llvm_unreachable("unknown coercion operator");
  }

  return make_error<ConstraintEvaluationError>(
      Expression,
      Twine("expected ") + targetName(Target) + "-coercible operand");
}

Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                              const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  Expected<ConstraintValue> Boolean =
      coerce(std::move(*Result), ConstraintValue::Boolean, Expression);
  if (!Boolean)
    return Boolean.takeError();
  return Boolean->getBoolean();
}

Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  Expected<ConstraintValue> Integer =
      coerce(std::move(*Result), ConstraintValue::Integer, Expression);
  if (!Integer)
    return Integer.takeError();
  return Integer->getInteger();
}

Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  Expected<ConstraintValue> String =
      coerce(std::move(*Result), ConstraintValue::String, Expression);
  if (!String)
    return String.takeError();
  return String->getString().str();
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result,
                   const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  Expected<ConstraintValue> StringArray =
      coerce(std::move(*Result), ConstraintValue::StringArray, Expression);
  if (!StringArray)
    return StringArray.takeError();
  return StringArray->getStringArray();
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
    case ConstraintValue::NumValueKinds:
      break;
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
