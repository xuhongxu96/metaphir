#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/MatchersDetail.h"
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
enum CoercionOp {
  UnknownCoercion = 0,
#define MIR_COERCION(Src, Dst, Op) Coerce##Op,
#include "metaphir/IR/ConstraintCoercions.def"
};
} // namespace

// The coercion lattice as a dense [Src][Dst] matrix. Each cell holds the
// coercion operator converting a source kind into a destination kind, or
// UnknownCoercion when no such conversion exists. The matrix is zero-filled
// (UnknownCoercion) and the admissible edges are stamped in from
// Coercions.def, so lookup is O(1) and the whole lattice stays explicit.
static const std::array<std::array<CoercionOp, ConstraintValue::NumValueKinds>,
                        ConstraintValue::NumValueKinds>
    CoercionMatrix = [] {
      std::array<std::array<CoercionOp, ConstraintValue::NumValueKinds>,
                 ConstraintValue::NumValueKinds>
          Matrix{};
#define MIR_COERCION(Src, Dst, Op)                                             \
  Matrix[ConstraintValue::Src][ConstraintValue::Dst] = Coerce##Op;
#include "metaphir/IR/ConstraintCoercions.def"
      return Matrix;
    }();

static std::optional<CoercionOp> lookupRule(ConstraintValue::ValueKind Src,
                                            ConstraintValue::ValueKind Dst) {
  CoercionOp Op = CoercionMatrix[Src][Dst];
  return Op == UnknownCoercion ? std::nullopt : std::optional<CoercionOp>(Op);
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
static Expected<ConstraintValue>
coerceBooleanToInteger(const ConstraintValue &V, const Constraint &) {
  return integerResult(APInt(1, V.getBoolean()), true);
}

static Expected<ConstraintValue>
coerceIntegerToBoolean(const ConstraintValue &V, const Constraint &) {
  return ConstraintValue::getBoolean(!V.getInteger().isZero());
}

static Expected<ConstraintValue>
coerceValueToInteger(const ConstraintValue &V, const Constraint &Expression) {
  // Constants are treated as signed, so that 'slt' on a negative constant is
  // correct; the unsigned operators still compare the bit pattern.
  if (std::optional<APInt> Integer = getConstantInteger(*V.getValue()))
    return integerResult(*Integer, false);
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-valued constant operand");
}

static Expected<ConstraintValue> coerceTypeToString(const ConstraintValue &V,
                                                    const Constraint &) {
  std::string Text;
  raw_string_ostream OS(Text);
  V.getType()->print(OS);
  return ConstraintValue::getString(OS.str());
}

static Expected<ConstraintValue> coerceValueToString(const ConstraintValue &V,
                                                     const Constraint &) {
  std::string Text;
  raw_string_ostream OS(Text);
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(V.getValue()))
    Instruction->print(OS);
  else
    V.getValue()->printAsOperand(OS, false);
  return ConstraintValue::getString(OS.str());
}

static Expected<ConstraintValue>
coerceTypeArrayToStringArray(const ConstraintValue &V, const Constraint &) {
  ConstraintValue::StringArrayStorage Strings;
  for (const llvm::Type *Type : V.getTypeArray()) {
    std::string Text;
    raw_string_ostream OS(Text);
    Type->print(OS);
    Strings.push_back(OS.str());
  }
  return ConstraintValue::getStringArray(std::move(Strings));
}

static Expected<ConstraintValue>
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

APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned) {
  APSInt Result = Value.extend(Width);
  Result.setIsUnsigned(IsUnsigned);
  return Result;
}

std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits) {
  bool IsUnsigned = Left.isUnsigned() && Right.isUnsigned();
  // When the result is signed, an unsigned operand needs one more bit so
  // that a value with its top bit set stays positive.
  auto Needed = [IsUnsigned](const APSInt &V) {
    return V.getBitWidth() + (!IsUnsigned && V.isUnsigned() ? 1 : 0);
  };
  unsigned Width = std::max(Needed(Left), Needed(Right)) + ExtraBits;
  return {extend(Left, Width, IsUnsigned), extend(Right, Width, IsUnsigned)};
}

APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth) {
  return Value.extOrTrunc(BitWidth);
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
#include "metaphir/IR/ConstraintCoercions.def"
    }
    llvm_unreachable("unknown coercion operator");
  }

  return make_error<ConstraintEvaluationError>(
      Expression,
      Twine("expected ") + targetName(Target) + "-coercible operand");
}

Expected<bool> requireBoolean(const ConstraintValue &Value,
                              const Constraint &Expression) {
  Expected<ConstraintValue> Boolean =
      coerce(Value, ConstraintValue::Boolean, Expression);
  if (!Boolean)
    return Boolean.takeError();
  return Boolean->getBoolean();
}

Expected<APSInt> requireInteger(const ConstraintValue &Value,
                                const Constraint &Expression) {
  Expected<ConstraintValue> Integer =
      coerce(Value, ConstraintValue::Integer, Expression);
  if (!Integer)
    return Integer.takeError();
  return Integer->getInteger();
}

Expected<std::string> requireString(const ConstraintValue &Value,
                                    const Constraint &Expression) {
  Expected<ConstraintValue> String =
      coerce(Value, ConstraintValue::String, Expression);
  if (!String)
    return String.takeError();
  return String->getString().str();
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(const ConstraintValue &Value, const Constraint &Expression) {
  Expected<ConstraintValue> StringArray =
      coerce(Value, ConstraintValue::StringArray, Expression);
  if (!StringArray)
    return StringArray.takeError();
  return StringArray->getStringArray();
}

Expected<const llvm::Value *> requireValue(const ConstraintValue &Value,
                                           const Constraint &Expression) {
  if (Value.getKind() != ConstraintValue::Value)
    return make_error<ConstraintEvaluationError>(
        Expression, "expected an LLVM value operand");
  return Value.getValue();
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
  auto RequireInteger = [](const ConstraintValue &V, const Constraint &E) {
    return requireInteger(V, E);
  };
  auto RequireString = [](const ConstraintValue &V, const Constraint &E) {
    return requireString(V, E);
  };
  auto RequireStringArray = [](const ConstraintValue &V, const Constraint &E) {
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
