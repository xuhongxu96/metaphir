//===- ConstantClasses.td - Constant classes --------------------*- tablegen -*-===//
//
// Constraint operators (with metaflags in the stdlib), each the PatternMatch.h
// matcher it is named after. On an LLVM value the class is
// PatternMatch::<Matcher>(); on a plain integer V (an APSInt) it is
// IntegerTest, or false when there is none: those classes depend on the bit
// width, which a plain integer has not. A recorded class is one the index
// records; an unrecorded one is too rare to record. Included by
// ConstraintOperators.td at the place its operators go.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def OpIsZero : ConstantClass<"IsZero", "isZero", "m_Zero", "V.isZero()">;
def OpIsAllOnes : ConstantClass<"IsAllOnes", "isAllOnes", "m_AllOnes", "V.isAllOnes()">;
def OpIsPower2 : ConstantClass<"IsPower2", "isPower2", "m_Power2", "V.isPowerOf2()">;
def OpIsPower2OrZero : UnrecordedConstantClass<"IsPower2OrZero", "isPower2OrZero", "m_Power2OrZero", "V.isZero() || V.isPowerOf2()">;
def OpIsNegatedPower2 : ConstantClass<"IsNegatedPower2", "isNegatedPower2", "m_NegatedPower2", "">;
def OpIsNegatedPower2OrZero : UnrecordedConstantClass<"IsNegatedPower2OrZero", "isNegatedPower2OrZero", "m_NegatedPower2OrZero", "">;
// A low bit mask is a non-empty run of ones starting at bit 0.
def OpIsLowBitMask : ConstantClass<"IsLowBitMask", "isLowBitMask", "m_LowBitMask", "V.isMask()">;
def OpIsLowBitMaskOrZero : UnrecordedConstantClass<"IsLowBitMaskOrZero", "isLowBitMaskOrZero", "m_LowBitMaskOrZero", "V.isZero() || V.isMask()">;
def OpIsShiftedMask : ConstantClass<"IsShiftedMask", "isShiftedMask", "m_ShiftedMask", "">;
def OpIsSignMask : ConstantClass<"IsSignMask", "isSignMask", "m_SignMask", "">;
def OpIsMaxSignedValue : ConstantClass<"IsMaxSignedValue", "isMaxSignedValue", "m_MaxSignedValue", "">;
// The sign classes read a plain integer by its signedness, as APSInt does.
def OpIsNegative : ConstantClass<"IsNegative", "isNegative", "m_Negative", "V.isNegative()">;
def OpIsNonNegative : ConstantClass<"IsNonNegative", "isNonNegative", "m_NonNegative", "V.isNonNegative()">;
def OpIsStrictlyPositive : ConstantClass<"IsStrictlyPositive", "isStrictlyPositive", "m_StrictlyPositive", "V.isStrictlyPositive()">;
def OpIsNonPositive : UnrecordedConstantClass<"IsNonPositive", "isNonPositive", "m_NonPositive", "!V.isStrictlyPositive()">;
def OpIsNonZeroInt : UnrecordedConstantClass<"IsNonZeroInt", "isNonZeroInt", "m_NonZeroInt", "!V.isZero()">;
def OpIsAnyZeroFP : ConstantClass<"IsAnyZeroFP", "isAnyZeroFP", "m_AnyZeroFP", "">;
def OpIsPosZeroFP : UnrecordedConstantClass<"IsPosZeroFP", "isPosZeroFP", "m_PosZeroFP", "">;
def OpIsNegZeroFP : UnrecordedConstantClass<"IsNegZeroFP", "isNegZeroFP", "m_NegZeroFP", "">;
def OpIsInf : UnrecordedConstantClass<"IsInf", "isInf", "m_Inf", "">;
def OpIsNaN : UnrecordedConstantClass<"IsNaN", "isNaN", "m_NaN", "">;
def OpIsPoison : ConstantClass<"IsPoison", "isPoison", "m_Poison", "">;
// m_Undef matches poison too.
def OpIsUndef : ConstantClass<"IsUndef", "isUndef", "m_Undef", "">;
