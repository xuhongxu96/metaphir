//===- KeywordConstantEmitter.cpp - keyword constants and predicates
//-------===//
//
// -gen-keyword-constants: metaphir/IR/Constants.inc, the IDs and spellings.
// -gen-keyword-constant-matcher: metaphir/Exec/KeywordConstantMatch.inc,
// which llvm::Values the matchable constants match.
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
        OS << '"' << A->getValueAsString("Name") << '"';
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

TableGen::Emitter::Opt X("gen-keyword-constants", emitKeywordConstants,
                         "Generate the keyword constants");
TableGen::Emitter::Opt Y("gen-keyword-constant-matcher",
                         emitKeywordConstantMatcher,
                         "Generate the matcher of keyword constants");

} // namespace
