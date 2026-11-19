//===- KeywordConstantEmitter.cpp - keyword constants and predicates
//-------===//
//
// -gen-keyword-constants: metaphir/IR/Constants.inc, the IDs and spellings.
// -gen-keyword-constant-matcher: metaphir/Exec/KeywordConstantMatch.inc,
// which llvm::Values the matchable constants match.
// -gen-predicate-keywords: metaphir/IR/PredicateKeywords.inc, the
// CmpInst::Predicates the predicate keywords spell.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitKeywordConstants(const RecordKeeper &Records, raw_ostream &OS) {
  auto Constants = getDefinitionsInOrder(Records, "KeywordConstant");
  // The lexer numbers the matchable constants' keywords before the
  // predicates', and relies on the IDs following the same order.
  bool SawPredicate = false;
  for (const Record *C : Constants) {
    bool Predicate = C->isSubClassOf("PredicateKeyword");
    if (SawPredicate && !Predicate)
      PrintFatalError(C, "define the matchable constants before the "
                         "predicate keywords");
    SawPredicate |= Predicate;
  }

  auto Aggregates = getDefinitionsInOrder(Records, "AggregateConstant");
  beginHeader(OS, Records, "The keyword constants and aggregate constants",
              "METAPHIR_IR_CONSTANTS_INC", {"llvm/ADT/StringRef.h"});
  OS << "// The data of the constants; metaphir/IR/Constants.h reads it.\n\n"
        "namespace keyword_constant {\nenum KeywordID {\n";
  for (const Record *C : Constants)
    OS << "  K_" << C->getName() << ",\n";
  OS << "};\n\n/// The spelling of each keyword constant, in the order of "
        "KeywordID.\n";
  emitArray<decltype(Constants), const Record *>(
      OS, "StringRef Spellings[]", Constants,
      [](raw_ostream &OS, const Record *const &C) {
        OS << '"' << C->getValueAsString("Spelling") << '"';
      });
  OS << "} // namespace keyword_constant\n\n"
        "/// How an aggregate constant is delimited.\n"
        "namespace aggregate_constant {\nenum Delimiter {\n";
  for (const Record *A : Aggregates)
    OS << "  " << A->getValueAsString("ID") << ",\n";
  OS << "};\n\n/// How the mpir dialect spells each kind, in the order of "
        "Delimiter.\n";
  emitArray<decltype(Aggregates), const Record *>(
      OS, "StringRef Names[]", Aggregates,
      [](raw_ostream &OS, const Record *const &A) {
        OS << '"' << A->getValueAsString("Spelling") << '"';
      });
  OS << "} // namespace aggregate_constant\n\n";
  endHeader(OS, "METAPHIR_IR_CONSTANTS_INC");
}

void emitKeywordConstantMatcher(const RecordKeeper &Records, raw_ostream &OS) {
  auto Constants = getDefinitionsInOrder(Records, "MatchableConstant");
  beginHeader(OS, Records, "Matching the keyword constants",
              "METAPHIR_EXEC_KEYWORD_CONSTANT_MATCH_INC",
              {"llvm/IR/Constants.h"}, {"keyword_constant"});
  OS << "/// Whether V is the matchable constant of each keyword constant ID "
        "(those\n/// IDs come first).\n";
  emitArray<decltype(Constants), const Record *>(
      OS, "bool (*ConstantChecks[])(const llvm::Value &V)", Constants,
      [](raw_ostream &OS, const Record *const &C) {
        OS << "[](const llvm::Value &V) { return isa<llvm::"
           << C->getValueAsString("LLVMClass") << ">(V); }";
      });
  endHeader(OS, "METAPHIR_EXEC_KEYWORD_CONSTANT_MATCH_INC",
            {"keyword_constant"});
}

void emitPredicateKeywords(const RecordKeeper &Records, raw_ostream &OS) {
  // Each predicate keyword spells at most one predicate of each compare.
  auto Predicates = getDefinitionsInOrder(Records, "PredicateKeyword");
  for (const Record *K : Predicates) {
    std::vector<StringRef> Spelled = K->getValueAsListOfStrings("Predicates");
    if (Spelled.empty())
      PrintFatalError(K, "a predicate keyword spells a predicate");
    unsigned FCmp =
        count_if(Spelled, [](StringRef P) { return P.starts_with("FCMP_"); });
    unsigned ICmp =
        count_if(Spelled, [](StringRef P) { return P.starts_with("ICMP_"); });
    if (FCmp > 1 || ICmp > 1 || FCmp + ICmp != Spelled.size())
      PrintFatalError(K, "a predicate keyword spells at most one FCMP_ and "
                         "one ICMP_ predicate");
  }

  beginHeader(OS, Records, "The predicates the predicate keywords spell",
              "METAPHIR_IR_PREDICATE_KEYWORDS_INC",
              {"metaphir/IR/Constants.h", "llvm/IR/InstrTypes.h", "optional"},
              {"keyword_constant"});
  OS << "/// The keyword that spells P.\n"
        "inline std::optional<KeywordID>\n"
        "getPredicateKeyword(llvm::CmpInst::Predicate P) {\n  switch (P) {\n";
  for (const Record *K : Predicates) {
    for (StringRef P : K->getValueAsListOfStrings("Predicates"))
      OS << "  case llvm::CmpInst::" << P << ":\n";
    OS << "    return K_" << K->getName() << ";\n";
  }
  OS << "  default:\n    return std::nullopt;\n  }\n}\n\n"
        "/// The predicate ID spells in a compare of floating-point values\n"
        "/// (FloatingPoint) or of integers, if it spells one there.\n"
        "inline std::optional<llvm::CmpInst::Predicate>\n"
        "getPredicate(KeywordID ID, bool FloatingPoint) {\n  switch (ID) {\n";
  for (const Record *K : Predicates) {
    StringRef FCmp, ICmp;
    for (StringRef P : K->getValueAsListOfStrings("Predicates"))
      (P.starts_with("FCMP_") ? FCmp : ICmp) = P;
    OS << "  case K_" << K->getName() << ":\n";
    auto Spelled = [&](StringRef P) {
      return P.empty() ? std::string("std::nullopt")
                       : ("llvm::CmpInst::" + P).str();
    };
    OS << "    if (FloatingPoint)\n      return " << Spelled(FCmp)
       << ";\n    return " << Spelled(ICmp) << ";\n";
  }
  OS << "  default:\n    return std::nullopt;\n  }\n}\n";
  endHeader(OS, "METAPHIR_IR_PREDICATE_KEYWORDS_INC", {"keyword_constant"});
}

TableGen::Emitter::Opt X("gen-keyword-constants", emitKeywordConstants,
                         "Generate the keyword constants");
TableGen::Emitter::Opt Y("gen-keyword-constant-matcher",
                         emitKeywordConstantMatcher,
                         "Generate the matcher of keyword constants");
TableGen::Emitter::Opt Z("gen-predicate-keywords", emitPredicateKeywords,
                         "Generate the predicates of the predicate keywords");

} // namespace
