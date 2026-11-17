//===- ConstraintOperators.td - The built-in constraint operators -*- tablegen -*-===//
//
// Every operator of a constraint expression: its spelling and how it is
// written, the sort it gives and takes, and its arity. The order is the
// operator IDs'. The operators of the constant classes and comparison
// predicates come in at their place in it. Generated into Constraint.inc by
// metaphir-tblgen -gen-constraint-operators.
//
// Arguments past the first ArgumentSorts.size() have sort RestSort.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def OpLogicalOr : Operator<"LogicalOr", "||", "Binary", "Boolean", 2> {
  let RestSort = "Boolean";
}
def OpLogicalAnd : Operator<"LogicalAnd", "&&", "Binary", "Boolean", 2> {
  let RestSort = "Boolean";
}
def OpEqual : BitWidthOperator<"Equal", "==", "Binary", "Boolean", 2> {
  let ArgumentSorts = ["Unknown", "Unknown", "Integer"];
  let RestSort = "Unknown";
}
def OpNotEqual : BitWidthOperator<"NotEqual", "!=", "Binary", "Boolean", 2> {
  let ArgumentSorts = ["Unknown", "Unknown", "Integer"];
  let RestSort = "Unknown";
}
def OpAdd : BitWidthOperator<"Add", "+", "Binary", "Integer", 2> {
  let RestSort = "Integer";
}
def OpSubtract : BitWidthOperator<"Subtract", "-", "Binary", "Integer", 2> {
  let RestSort = "Integer";
}
def OpMultiply : BitWidthOperator<"Multiply", "*", "Binary", "Integer", 2> {
  let RestSort = "Integer";
}
def OpNot : Operator<"Not", "!", "Unary", "Boolean", 1> {
  let RestSort = "Boolean";
}
def OpNegate : BitWidthOperator<"Negate", "-", "Unary", "Integer", 1> {
  let RestSort = "Integer";
}
def OpSLT : Operator<"SLT", "slt", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpULT : Operator<"ULT", "ult", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpSLE : Operator<"SLE", "sle", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpULE : Operator<"ULE", "ule", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpSGT : Operator<"SGT", "sgt", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpUGT : Operator<"UGT", "ugt", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpSGE : Operator<"SGE", "sge", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpUGE : Operator<"UGE", "uge", "Call", "Boolean", 2> {
  let RestSort = "Integer";
}
def OpSDiv : BitWidthOperator<"SDiv", "sdiv", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpUDiv : BitWidthOperator<"UDiv", "udiv", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpSRem : BitWidthOperator<"SRem", "srem", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpURem : BitWidthOperator<"URem", "urem", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpLshr : BitWidthOperator<"Lshr", "lshr", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpAshr : BitWidthOperator<"Ashr", "ashr", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpShl : BitWidthOperator<"Shl", "shl", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpAnd : BitWidthOperator<"And", "and", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpOr : BitWidthOperator<"Or", "or", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpXor : BitWidthOperator<"Xor", "xor", "Call", "Integer", 2> {
  let RestSort = "Integer";
}
def OpIsa : Operator<"Isa", "isa", "Call", "Boolean", 2> {
  let ArgumentSorts = ["Value"];
  let RestSort = "String";
}
def OpOpcode : Operator<"Opcode", "opcode", "Call", "String", 1> {
  let RestSort = "Value";
}
def OpLog2 : Operator<"Log2", "log2", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpPopcount : Operator<"Popcount", "popcount", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpIsAnyIntegralConstant : Operator<"IsAnyIntegralConstant", "isAnyIntegralConstant", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpIsForbidPoison : Operator<"IsForbidPoison", "isForbidPoison", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpIsConstantSplat : Operator<"IsConstantSplat", "isConstantSplat", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpIsScalar : Operator<"IsScalar", "isScalar", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpHasOneUse : Operator<"HasOneUse", "hasOneUse", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpHasOneUser : Operator<"HasOneUser", "hasOneUser", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpHasNUses : Operator<"HasNUses", "hasNUses", "Call", "Boolean", 2> {
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}
def OpHasNUsesOrMore : Operator<"HasNUsesOrMore", "hasNUsesOrMore", "Call", "Boolean", 2> {
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}

include "metaphir/IR/ConstantClasses.td"

def OpIsImmConstant : Operator<"IsImmConstant", "isImmConstant", "Call", "Boolean", 1> {
  let RestSort = "Unknown";
}
def OpIntrinsic : Operator<"Intrinsic", "intrinsic", "Call", "String", 1> {
  let RestSort = "Value";
}
def OpPredicate : Operator<"Predicate", "predicate", "Call", "String", 1> {
  let RestSort = "Value";
}

include "metaphir/IR/CmpPredicateOperators.td"

def OpFlippedSignednessPredicate : Operator<"FlippedSignednessPredicate", "flippedSignednessPredicate", "Call", "String", 1> {
  let RestSort = "String";
}
def OpCountlZero : BitWidthOperator<"CountlZero", "countl_zero", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpCountrZero : BitWidthOperator<"CountrZero", "countr_zero", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpCountlOne : BitWidthOperator<"CountlOne", "countl_one", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpCountrOne : BitWidthOperator<"CountrOne", "countr_one", "Call", "Integer", 1> {
  let RestSort = "Integer";
}
def OpBitWidth : Operator<"BitWidth", "bitWidth", "Call", "Integer", 1> {
  let RestSort = "Unknown";
}
def OpNoOverflow : ValueTrackOperator<"NoOverflow", "noOverflow", "Call", "Boolean", 3> {
  let ArgumentSorts = ["String"];
  let RestSort = "Value";
}
def OpKnownBits : ValueTrackOperator<"KnownBits", "knownBits", "Call", "BitVector", 1> {
  let RestSort = "Value";
}
def OpIsKnownNonZero : ValueTrackOperator<"IsKnownNonZero", "isKnownNonZero", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownNegative : ValueTrackOperator<"IsKnownNegative", "isKnownNegative", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBeUndef : ValueTrackOperator<"IsGuaranteedNotToBeUndef", "isGuaranteedNotToBeUndef", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownNonNegative : ValueTrackOperator<"IsKnownNonNegative", "isKnownNonNegative", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownPositive : ValueTrackOperator<"IsKnownPositive", "isKnownPositive", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownPowerOfTwo : ValueTrackOperator<"IsKnownPowerOfTwo", "isKnownPowerOfTwo", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownPowerOfTwoOrZero : ValueTrackOperator<"IsKnownPowerOfTwoOrZero", "isKnownPowerOfTwoOrZero", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBePoison : ValueTrackOperator<"IsGuaranteedNotToBePoison", "isGuaranteedNotToBePoison", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBeUndefOrPoison : ValueTrackOperator<"IsGuaranteedNotToBeUndefOrPoison", "isGuaranteedNotToBeUndefOrPoison", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpMaskedValueIsZero : ValueTrackOperator<"MaskedValueIsZero", "maskedValueIsZero", "Call", "Boolean", 2> {
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}
def OpInSignedRange : ValueTrackOperator<"InSignedRange", "inSignedRange", "Call", "Boolean", 3> {
  let ArgumentSorts = ["Value", "Integer", "Integer"];
  let RestSort = "Value";
}
def OpInUnsignedRange : ValueTrackOperator<"InUnsignedRange", "inUnsignedRange", "Call", "Boolean", 3> {
  let ArgumentSorts = ["Value", "Integer", "Integer"];
  let RestSort = "Value";
}
def OpNumSignBits : ValueTrackOperator<"NumSignBits", "numSignBits", "Call", "Integer", 1> {
  let RestSort = "Value";
}
def OpMaxSignificantBits : ValueTrackOperator<"MaxSignificantBits", "maxSignificantBits", "Call", "Integer", 1> {
  let RestSort = "Value";
}
def OpIsKnownNeverNaN : ValueTrackOperator<"IsKnownNeverNaN", "isKnownNeverNaN", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownNeverInfinity : ValueTrackOperator<"IsKnownNeverInfinity", "isKnownNeverInfinity", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpIsKnownNeverInfOrNaN : ValueTrackOperator<"IsKnownNeverInfOrNaN", "isKnownNeverInfOrNaN", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpCannotBeNegativeZero : ValueTrackOperator<"CannotBeNegativeZero", "cannotBeNegativeZero", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpCannotBeOrderedLessThanZero : ValueTrackOperator<"CannotBeOrderedLessThanZero", "cannotBeOrderedLessThanZero", "Call", "Boolean", 1> {
  let RestSort = "Value";
}
def OpKnownZeros : Operator<"KnownZeros", "knownZeros", "Call", "Integer", 1> {
  let RestSort = "BitVector";
}
def OpKnownOnes : Operator<"KnownOnes", "knownOnes", "Call", "Integer", 1> {
  let RestSort = "BitVector";
}
def : OperatorAlias<OpAdd, "add", "Call">;
def : OperatorAlias<OpSubtract, "sub", "Call">;
def : OperatorAlias<OpMultiply, "mul", "Call">;
def : OperatorAlias<OpNegate, "neg", "Call">;
def : OperatorAlias<OpEqual, "eq", "Call">;
def : OperatorAlias<OpNotEqual, "ne", "Call">;
