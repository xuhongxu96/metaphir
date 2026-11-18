//===- CmpPredicateOperators.td - Operators on predicates ---*- tablegen -*-===//
//
// Operators on comparison predicates, given as the strings '?pred' binds
// ("slt", "oeq", ...) and named after CmpInst's. A test is a boolean
// expression of the predicate P; a map is the predicate an expression of P
// gives. Included by ConstraintOperators.td at the place its operators go.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/Constraint/ConstraintBase.td"

def OpIsEquality : CmpPredicateTest<"isEquality"> {
  let Expression = "CmpInst::isEquality(P)";
}
def OpIsSigned : CmpPredicateTest<"isSigned"> {
  let Expression = "CmpInst::isSigned(P)";
}
def OpIsUnsigned : CmpPredicateTest<"isUnsigned"> {
  let Expression = "CmpInst::isUnsigned(P)";
}
// isLT and the like are ICmpInst's, so they are false for FP predicates.
def OpIsLT : CmpPredicateTest<"isLT"> {
  let Expression = "ICmpInst::isLT(P)";
}
def OpIsGT : CmpPredicateTest<"isGT"> {
  let Expression = "ICmpInst::isGT(P)";
}
def OpIsLE : CmpPredicateTest<"isLE"> {
  let Expression = "ICmpInst::isLE(P)";
}
def OpIsGE : CmpPredicateTest<"isGE"> {
  let Expression = "ICmpInst::isGE(P)";
}
def OpSwappedPredicate : CmpPredicateMap<"swappedPredicate"> {
  let Expression = "CmpInst::getSwappedPredicate(P)";
}
def OpInversePredicate : CmpPredicateMap<"inversePredicate"> {
  let Expression = "CmpInst::getInversePredicate(P)";
}
def OpStrictPredicate : CmpPredicateMap<"strictPredicate"> {
  let Expression = "CmpInst::getStrictPredicate(P)";
}
def OpNonStrictPredicate : CmpPredicateMap<"nonStrictPredicate"> {
  let Expression = "CmpInst::getNonStrictPredicate(P)";
}
