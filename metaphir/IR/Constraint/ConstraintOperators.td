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

include "metaphir/IR/Constraint/ConstraintBase.td"

def OpLogicalOr : Operator<"||"> {
  let Kind = "Binary";
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Boolean";
}
def OpLogicalAnd : Operator<"&&"> {
  let Kind = "Binary";
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Boolean";
}
def OpEqual : BitWidthOperator<"=="> {
  let Kind = "Binary";
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Unknown", "Unknown", "Integer"];
  let RestSort = "Unknown";
}
def OpNotEqual : BitWidthOperator<"!="> {
  let Kind = "Binary";
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Unknown", "Unknown", "Integer"];
  let RestSort = "Unknown";
}
def OpAdd : BitWidthOperator<"+"> {
  let Kind = "Binary";
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSubtract : BitWidthOperator<"-"> {
  let Kind = "Binary";
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpMultiply : BitWidthOperator<"*"> {
  let Kind = "Binary";
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpNot : Operator<"!"> {
  let Kind = "Unary";
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Boolean";
}
def OpNegate : BitWidthOperator<"-"> {
  let Kind = "Unary";
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpSLT : Operator<"slt"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpULT : Operator<"ult"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSLE : Operator<"sle"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpULE : Operator<"ule"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSGT : Operator<"sgt"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpUGT : Operator<"ugt"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSGE : Operator<"sge"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpUGE : Operator<"uge"> {
  let Result = "Boolean";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSDiv : BitWidthOperator<"sdiv"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpUDiv : BitWidthOperator<"udiv"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpSRem : BitWidthOperator<"srem"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpURem : BitWidthOperator<"urem"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpLshr : BitWidthOperator<"lshr"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpAshr : BitWidthOperator<"ashr"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpShl : BitWidthOperator<"shl"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpAnd : BitWidthOperator<"and"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpOr : BitWidthOperator<"or"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpXor : BitWidthOperator<"xor"> {
  let Result = "Integer";
  let Arity = 2;
  let RestSort = "Integer";
}
def OpIsa : Operator<"isa"> {
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Value"];
  let RestSort = "String";
}
def OpOpcode : Operator<"opcode"> {
  let Result = "String";
  let Arity = 1;
  let RestSort = "Value";
}
def OpLog2 : Operator<"log2"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpPopcount : Operator<"popcount"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpIsAnyIntegralConstant : Operator<"isAnyIntegralConstant"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpIsForbidPoison : Operator<"isForbidPoison"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpIsConstantSplat : Operator<"isConstantSplat"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpIsScalar : Operator<"isScalar"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpHasOneUse : Operator<"hasOneUse"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpHasOneUser : Operator<"hasOneUser"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpHasNUses : Operator<"hasNUses"> {
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}
def OpHasNUsesOrMore : Operator<"hasNUsesOrMore"> {
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}

include "metaphir/IR/Constraint/ConstantClasses.td"

def OpIsImmConstant : Operator<"isImmConstant"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpIntrinsic : Operator<"intrinsic"> {
  let Result = "String";
  let Arity = 1;
  let RestSort = "Value";
}
def OpPredicate : Operator<"predicate"> {
  let Result = "String";
  let Arity = 1;
  let RestSort = "Value";
}

include "metaphir/IR/Constraint/CmpPredicateOperators.td"

def OpFlippedSignednessPredicate : Operator<"flippedSignednessPredicate"> {
  let Result = "CmpPredicate";
  let Arity = 1;
  let RestSort = "String";
}
def OpCountlZero : BitWidthOperator<"countl_zero"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpCountrZero : BitWidthOperator<"countr_zero"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpCountlOne : BitWidthOperator<"countl_one"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpCountrOne : BitWidthOperator<"countr_one"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Integer";
}
def OpBitWidth : Operator<"bitWidth"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Unknown";
}
def OpNoOverflow : ValueTrackOperator<"noOverflow"> {
  let Result = "Boolean";
  let Arity = 3;
  let ArgumentSorts = ["String"];
  let RestSort = "Value";
}
def OpKnownBits : ValueTrackOperator<"knownBits"> {
  let Result = "BitVector";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNonZero : ValueTrackOperator<"isKnownNonZero"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNegative : ValueTrackOperator<"isKnownNegative"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBeUndef : ValueTrackOperator<"isGuaranteedNotToBeUndef"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNonNegative : ValueTrackOperator<"isKnownNonNegative"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownPositive : ValueTrackOperator<"isKnownPositive"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownPowerOfTwo : ValueTrackOperator<"isKnownPowerOfTwo"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownPowerOfTwoOrZero : ValueTrackOperator<"isKnownPowerOfTwoOrZero"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBePoison : ValueTrackOperator<"isGuaranteedNotToBePoison"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsGuaranteedNotToBeUndefOrPoison : ValueTrackOperator<"isGuaranteedNotToBeUndefOrPoison"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpMaskedValueIsZero : ValueTrackOperator<"maskedValueIsZero"> {
  let Result = "Boolean";
  let Arity = 2;
  let ArgumentSorts = ["Value", "Integer"];
  let RestSort = "Value";
}
def OpInSignedRange : ValueTrackOperator<"inSignedRange"> {
  let Result = "Boolean";
  let Arity = 3;
  let ArgumentSorts = ["Value", "Integer", "Integer"];
  let RestSort = "Value";
}
def OpInUnsignedRange : ValueTrackOperator<"inUnsignedRange"> {
  let Result = "Boolean";
  let Arity = 3;
  let ArgumentSorts = ["Value", "Integer", "Integer"];
  let RestSort = "Value";
}
def OpNumSignBits : ValueTrackOperator<"numSignBits"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Value";
}
def OpMaxSignificantBits : ValueTrackOperator<"maxSignificantBits"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNeverNaN : ValueTrackOperator<"isKnownNeverNaN"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNeverInfinity : ValueTrackOperator<"isKnownNeverInfinity"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpIsKnownNeverInfOrNaN : ValueTrackOperator<"isKnownNeverInfOrNaN"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpCannotBeNegativeZero : ValueTrackOperator<"cannotBeNegativeZero"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpCannotBeOrderedLessThanZero : ValueTrackOperator<"cannotBeOrderedLessThanZero"> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "Value";
}
def OpKnownZeros : Operator<"knownZeros"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "BitVector";
}
def OpKnownOnes : Operator<"knownOnes"> {
  let Result = "Integer";
  let Arity = 1;
  let RestSort = "BitVector";
}
def : OperatorAlias<OpAdd, "add">;
def : OperatorAlias<OpSubtract, "sub">;
def : OperatorAlias<OpMultiply, "mul">;
def : OperatorAlias<OpNegate, "neg">;
def : OperatorAlias<OpEqual, "eq">;
def : OperatorAlias<OpNotEqual, "ne">;
