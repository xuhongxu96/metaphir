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

/// A comparison predicate, and the CmpInst::Predicates it spells: one of
/// fcmp's, one of icmp's, or both ('ugt' is FCMP_UGT and ICMP_UGT).
class PredicateKeyword<string spelling, list<string> predicates>
    : KeywordConstant<spelling> {
  list<string> Predicates = predicates;
}

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
def False : PredicateKeyword<"false", ["FCMP_FALSE"]>;
def True : PredicateKeyword<"true", ["FCMP_TRUE"]>;
def OEQ : PredicateKeyword<"oeq", ["FCMP_OEQ"]>;
def OGT : PredicateKeyword<"ogt", ["FCMP_OGT"]>;
def OGE : PredicateKeyword<"oge", ["FCMP_OGE"]>;
def OLT : PredicateKeyword<"olt", ["FCMP_OLT"]>;
def OLE : PredicateKeyword<"ole", ["FCMP_OLE"]>;
def ONE : PredicateKeyword<"one", ["FCMP_ONE"]>;
def ORD : PredicateKeyword<"ord", ["FCMP_ORD"]>;
def UEQ : PredicateKeyword<"ueq", ["FCMP_UEQ"]>;
def UGT : PredicateKeyword<"ugt", ["FCMP_UGT", "ICMP_UGT"]>;
def UGE : PredicateKeyword<"uge", ["FCMP_UGE", "ICMP_UGE"]>;
def ULT : PredicateKeyword<"ult", ["FCMP_ULT", "ICMP_ULT"]>;
def ULE : PredicateKeyword<"ule", ["FCMP_ULE", "ICMP_ULE"]>;
def UNE : PredicateKeyword<"une", ["FCMP_UNE"]>;
def UNO : PredicateKeyword<"uno", ["FCMP_UNO"]>;
def EQ : PredicateKeyword<"eq", ["ICMP_EQ"]>;
def NE : PredicateKeyword<"ne", ["ICMP_NE"]>;
def SGT : PredicateKeyword<"sgt", ["ICMP_SGT"]>;
def SGE : PredicateKeyword<"sge", ["ICMP_SGE"]>;
def SLT : PredicateKeyword<"slt", ["ICMP_SLT"]>;
def SLE : PredicateKeyword<"sle", ["ICMP_SLE"]>;

// The ways an aggregate constant is delimited.
def Square : AggregateConstant<"array">;
def Brace : AggregateConstant<"struct">;
def Angle : AggregateConstant<"vector">;
