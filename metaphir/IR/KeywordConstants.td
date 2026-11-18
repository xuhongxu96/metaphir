//===- KeywordConstants.td - Keyword constants and predicates -*- tablegen -*-===//
//
// The constants a pattern can spell as keywords ('null', 'poison', ...) and
// the comparison predicates. Generated into Constants.inc and
// KeywordConstantMatch.inc by metaphir-tblgen -gen-keyword-constants and
// -gen-keyword-constant-matcher.
//
//===----------------------------------------------------------------------===//

/// A constant or comparison predicate a pattern spells as a keyword. The
/// record's name is the enumerator of keyword_constant::KeywordID, after K_.
class KeywordConstant<string spelling> {
  string Spelling = spelling;
  /// The llvm class of the values a matchable constant matches, or empty.
  string LLVMClass = "";
}

class MatchableConstant<string spelling> : KeywordConstant<spelling>;

class PredicateKeyword<string spelling> : KeywordConstant<spelling>;

/// How an aggregate constant is delimited: an array ('[...]'), a struct
/// ('{...}') or a vector ('<...>'). The delimiters' order is persisted: the
/// mpir dialect's SeqTypeOp numbers its kinds the same way. The record's name
/// is the enumerator of aggregate_constant::Delimiter.
class AggregateConstant<string spelling> {
  string ID = NAME;
  /// How the mpir dialect spells the kind.
  string Spelling = spelling;
}

def Null : MatchableConstant<"null"> {
  let LLVMClass = "ConstantPointerNull";
}
def Poison : MatchableConstant<"poison"> {
  let LLVMClass = "PoisonValue";
}
def Undef : MatchableConstant<"undef"> {
  let LLVMClass = "UndefValue";
}
def ZeroInitializer : MatchableConstant<"zeroinitializer"> {
  let LLVMClass = "ConstantAggregateZero";
}
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
def Square : AggregateConstant<"array">;
def Brace : AggregateConstant<"struct">;
def Angle : AggregateConstant<"vector">;
