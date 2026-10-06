#include "metaphir/Matching/Operators/Facts.h"
#include "llvm/Analysis/ValueTracking.h"
#include <iterator>

namespace llvm {
namespace metaphir {

static constexpr unsigned NumValueClasses = 0
#define MIR_LLVM_VALUE_CLASS(Class) +1
#include "metaphir/Matching/LLVMValueClasses.def"
    ;

StringRef Atom::getName(Predicate P) {
  static constexpr StringLiteral Names[] = {"isZero",
                                            "isAllOnes",
                                            "isPower2",
                                            "isLowBitMask",
                                            "isAnyZeroFP",
                                            "isAnyIntegralConstant",
                                            "isPoison",
                                            "isForbidPoison",
                                            "isConstantSplat",
                                            "isImmConstant",
                                            "isSignMask",
                                            "isMaxSignedValue",
                                            "isNegatedPower2",
                                            "isShiftedMask",
                                            "isNegative",
                                            "isNonNegative",
                                            "isStrictlyPositive",
                                            "isUndef",
                                            "hasOneUse",
                                            "hasOneUser",
                                            "isKnownNonZero",
                                            "isKnownNegative",
                                            "isKnownNonNegative",
                                            "isKnownPositive",
                                            "isKnownPowerOfTwo",
                                            "isKnownPowerOfTwoOrZero",
                                            "valueTrackingSkipped"};
  static_assert(std::size(Names) == NumPredicates,
                "every predicate needs a name");
  return Names[P];
}

StringRef getMeasureName(Measure M) {
  static constexpr StringLiteral Names[] = {
      "trailingZeros", "activeBits", "rangeSignedBits", "rangeUnsignedBits"};
  static_assert(std::size(Names) == size_t(Measure::NumMeasures),
                "every measure needs a name");
  return Names[size_t(M)];
}

std::optional<Atom> Atom::literal(int64_t V) {
  if (V < MinLiteral || V > MaxLiteral)
    return std::nullopt;
  return Atom(uint16_t(LiteralBase + (V - MinLiteral)));
}

Atom Atom::valueClass(unsigned ClassIndex) {
  assert(ClassIndex < NumValueClasses && "invalid LLVM value class index");
  static_assert(ClassBase + NumValueClasses <= End,
                "LLVM value classes must fit in an atom");
  return Atom(uint16_t(ClassBase + ClassIndex));
}

FactSink::~FactSink() = default;

const KnownBits &RecordCall::knownBits() const {
  assert(Query && "known bits without value tracking");
  if (!Known)
    Known = computeKnownBits(&Value, *Query);
  return *Known;
}

} // namespace metaphir
} // namespace llvm
