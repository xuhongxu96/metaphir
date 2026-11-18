//===- Facts.td - What a corpus index records at a site ------*- tablegen -*-===//
//
// The facts and measures the index records about the values at a site. The
// recorded constant classes (ConstantClasses.td) are facts too and come first,
// then these facts, then the value-tracking ones, which come last. Generated
// into Facts.inc by metaphir-tblgen -gen-facts.
//
// A measure is a number recorded for the site. Its order says which of its
// values' numbers the site keeps: Most, when a larger number satisfies more
// queries, or Least, when a smaller one does.
//
//===----------------------------------------------------------------------===//

include "metaphir/Matching/FactBase.td"

def IsAnyIntegralConstant : Fact<"isAnyIntegralConstant">;
def IsImmConstant : Fact<"isImmConstant">;
def IsForbidPoison : Fact<"isForbidPoison">;
def IsConstantSplat : Fact<"isConstantSplat">;
def HasOneUse : Fact<"hasOneUse">;
def HasOneUser : Fact<"hasOneUser">;

def IsKnownNonZero : ValueTrackingFact<"isKnownNonZero">;
def IsKnownNegative : ValueTrackingFact<"isKnownNegative">;
def IsKnownNonNegative : ValueTrackingFact<"isKnownNonNegative">;
def IsKnownPositive : ValueTrackingFact<"isKnownPositive">;
def IsKnownPowerOfTwo : ValueTrackingFact<"isKnownPowerOfTwo">;
def IsKnownPowerOfTwoOrZero : ValueTrackingFact<"isKnownPowerOfTwoOrZero">;
def ValueTrackingSkipped : ValueTrackingFact<"valueTrackingSkipped">;

def TrailingZeros : Measure<"trailingZeros"> {
  let Order = "Most";
}
def ActiveBits : Measure<"activeBits"> {
  let Order = "Least";
}
def RangeSignedBits : Measure<"rangeSignedBits"> {
  let Order = "Least";
}
def RangeUnsignedBits : Measure<"rangeUnsignedBits"> {
  let Order = "Least";
}
