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

include "metaphir/IR/LanguageBase.td"

def : Fact<"IsAnyIntegralConstant", "isAnyIntegralConstant">;
def : Fact<"IsImmConstant", "isImmConstant">;
def : Fact<"IsForbidPoison", "isForbidPoison">;
def : Fact<"IsConstantSplat", "isConstantSplat">;
def : Fact<"HasOneUse", "hasOneUse">;
def : Fact<"HasOneUser", "hasOneUser">;

def : ValueTrackingFact<"IsKnownNonZero", "isKnownNonZero">;
def : ValueTrackingFact<"IsKnownNegative", "isKnownNegative">;
def : ValueTrackingFact<"IsKnownNonNegative", "isKnownNonNegative">;
def : ValueTrackingFact<"IsKnownPositive", "isKnownPositive">;
def : ValueTrackingFact<"IsKnownPowerOfTwo", "isKnownPowerOfTwo">;
def : ValueTrackingFact<"IsKnownPowerOfTwoOrZero", "isKnownPowerOfTwoOrZero">;
def : ValueTrackingFact<"ValueTrackingSkipped", "valueTrackingSkipped">;

def : Measure<"TrailingZeros", "trailingZeros", "Most">;
def : Measure<"ActiveBits", "activeBits", "Least">;
def : Measure<"RangeSignedBits", "rangeSignedBits", "Least">;
def : Measure<"RangeUnsignedBits", "rangeUnsignedBits", "Least">;
