//===- KeywordConstants.td - Keyword constants and predicates -*- tablegen -*-===//
//
// The constants a pattern can spell as keywords ('null', 'poison', ...) and
// the comparison predicates. Generated into Constants.inc and
// KeywordConstantMatch.inc by metaphir-tblgen -gen-keyword-constants and
// -gen-keyword-constant-matcher.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def Null : MatchableConstant<"null", "ConstantPointerNull">;
def Poison : MatchableConstant<"poison", "PoisonValue">;
def Undef : MatchableConstant<"undef", "UndefValue">;
def ZeroInitializer : MatchableConstant<"zeroinitializer", "ConstantAggregateZero">;
def False : PredicateKeyword<"false">;
def True : PredicateKeyword<"true">;
def OEQ : PredicateKeyword<"oeq">;
def OGT : PredicateKeyword<"ogt">;
def OGE : PredicateKeyword<"oge">;
def OLT : PredicateKeyword<"olt">;
def OLE : PredicateKeyword<"ole">;
def ONE : PredicateKeyword<"one">;
def ORD : PredicateKeyword<"ord">;
def UEQ : PredicateKeyword<"ueq">;
def UGT : PredicateKeyword<"ugt">;
def UGE : PredicateKeyword<"uge">;
def ULT : PredicateKeyword<"ult">;
def ULE : PredicateKeyword<"ule">;
def UNE : PredicateKeyword<"une">;
def UNO : PredicateKeyword<"uno">;
def EQ : PredicateKeyword<"eq">;
def NE : PredicateKeyword<"ne">;
def SGT : PredicateKeyword<"sgt">;
def SGE : PredicateKeyword<"sge">;
def SLT : PredicateKeyword<"slt">;
def SLE : PredicateKeyword<"sle">;

// The ways an aggregate constant is delimited.
def : AggregateConstant<"Square", "array">;
def : AggregateConstant<"Brace", "struct">;
def : AggregateConstant<"Angle", "vector">;
