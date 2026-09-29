#include "metaphir/Matching/IntegerSemantics.h"
#include <algorithm>

namespace llvm {
namespace metaphir {
namespace detail {

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

ConstraintValue integerResult(APInt Value, bool IsUnsigned) {
  return ConstraintValue::getInteger(APSInt(std::move(Value), IsUnsigned));
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
