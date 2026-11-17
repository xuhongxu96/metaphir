//===- CmpPredicateOperators.td - Operators on predicates ---*- tablegen -*-===//
//
// Operators on comparison predicates, given as the strings '?pred' binds
// ("slt", "oeq", ...) and named after CmpInst's. A test is a boolean
// expression of the predicate P; a map is the predicate an expression of P
// gives. Included by ConstraintOperators.td at the place its operators go.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def OpIsEquality : CmpPredicateTest<"IsEquality", "isEquality", "CmpInst::isEquality(P)">;
def OpIsSigned : CmpPredicateTest<"IsSigned", "isSigned", "CmpInst::isSigned(P)">;
def OpIsUnsigned : CmpPredicateTest<"IsUnsigned", "isUnsigned", "CmpInst::isUnsigned(P)">;
// isLT and the like are ICmpInst's, so they are false for FP predicates.
def OpIsLT : CmpPredicateTest<"IsLT", "isLT", "ICmpInst::isLT(P)">;
def OpIsGT : CmpPredicateTest<"IsGT", "isGT", "ICmpInst::isGT(P)">;
def OpIsLE : CmpPredicateTest<"IsLE", "isLE", "ICmpInst::isLE(P)">;
def OpIsGE : CmpPredicateTest<"IsGE", "isGE", "ICmpInst::isGE(P)">;
def OpSwappedPredicate : CmpPredicateMap<"SwappedPredicate", "swappedPredicate", "CmpInst::getSwappedPredicate(P)">;
def OpInversePredicate : CmpPredicateMap<"InversePredicate", "inversePredicate", "CmpInst::getInversePredicate(P)">;
def OpStrictPredicate : CmpPredicateMap<"StrictPredicate", "strictPredicate", "CmpInst::getStrictPredicate(P)">;
def OpNonStrictPredicate : CmpPredicateMap<"NonStrictPredicate", "nonStrictPredicate", "CmpInst::getNonStrictPredicate(P)">;
