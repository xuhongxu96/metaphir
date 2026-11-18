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

include "metaphir/IR/Constraint/ConstraintBase.td"

def OpIsZero : ConstantClass<"isZero"> {
  let Matcher = "m_Zero";
  let IntegerTest = "V.isZero()";
}
def OpIsAllOnes : ConstantClass<"isAllOnes"> {
  let Matcher = "m_AllOnes";
  let IntegerTest = "V.isAllOnes()";
}
def OpIsPower2 : ConstantClass<"isPower2"> {
  let Matcher = "m_Power2";
  let IntegerTest = "V.isPowerOf2()";
}
def OpIsPower2OrZero : UnrecordedConstantClass<"isPower2OrZero"> {
  let Matcher = "m_Power2OrZero";
  let IntegerTest = "V.isZero() || V.isPowerOf2()";
}
def OpIsNegatedPower2 : ConstantClass<"isNegatedPower2"> {
  let Matcher = "m_NegatedPower2";
}
def OpIsNegatedPower2OrZero : UnrecordedConstantClass<"isNegatedPower2OrZero"> {
  let Matcher = "m_NegatedPower2OrZero";
}
// A low bit mask is a non-empty run of ones starting at bit 0.
def OpIsLowBitMask : ConstantClass<"isLowBitMask"> {
  let Matcher = "m_LowBitMask";
  let IntegerTest = "V.isMask()";
}
def OpIsLowBitMaskOrZero : UnrecordedConstantClass<"isLowBitMaskOrZero"> {
  let Matcher = "m_LowBitMaskOrZero";
  let IntegerTest = "V.isZero() || V.isMask()";
}
def OpIsShiftedMask : ConstantClass<"isShiftedMask"> {
  let Matcher = "m_ShiftedMask";
}
def OpIsSignMask : ConstantClass<"isSignMask"> {
  let Matcher = "m_SignMask";
}
def OpIsMaxSignedValue : ConstantClass<"isMaxSignedValue"> {
  let Matcher = "m_MaxSignedValue";
}
// The sign classes read a plain integer by its signedness, as APSInt does.
def OpIsNegative : ConstantClass<"isNegative"> {
  let Matcher = "m_Negative";
  let IntegerTest = "V.isNegative()";
}
def OpIsNonNegative : ConstantClass<"isNonNegative"> {
  let Matcher = "m_NonNegative";
  let IntegerTest = "V.isNonNegative()";
}
def OpIsStrictlyPositive : ConstantClass<"isStrictlyPositive"> {
  let Matcher = "m_StrictlyPositive";
  let IntegerTest = "V.isStrictlyPositive()";
}
def OpIsNonPositive : UnrecordedConstantClass<"isNonPositive"> {
  let Matcher = "m_NonPositive";
  let IntegerTest = "!V.isStrictlyPositive()";
}
def OpIsNonZeroInt : UnrecordedConstantClass<"isNonZeroInt"> {
  let Matcher = "m_NonZeroInt";
  let IntegerTest = "!V.isZero()";
}
def OpIsAnyZeroFP : ConstantClass<"isAnyZeroFP"> {
  let Matcher = "m_AnyZeroFP";
}
def OpIsPosZeroFP : UnrecordedConstantClass<"isPosZeroFP"> {
  let Matcher = "m_PosZeroFP";
}
def OpIsNegZeroFP : UnrecordedConstantClass<"isNegZeroFP"> {
  let Matcher = "m_NegZeroFP";
}
def OpIsInf : UnrecordedConstantClass<"isInf"> {
  let Matcher = "m_Inf";
}
def OpIsNaN : UnrecordedConstantClass<"isNaN"> {
  let Matcher = "m_NaN";
}
def OpIsPoison : ConstantClass<"isPoison"> {
  let Matcher = "m_Poison";
}
// m_Undef matches poison too.
def OpIsUndef : ConstantClass<"isUndef"> {
  let Matcher = "m_Undef";
}
