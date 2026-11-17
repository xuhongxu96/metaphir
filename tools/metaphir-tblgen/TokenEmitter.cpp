//===- TokenEmitter.cpp - the lexer's tokens
//-------------------------------===//
//
// -gen-tokens: metaphir/Parser/MIRToken.inc, the data of the token kinds and
// of the lexer's keywords; metaphir/Parser/MIRToken.h reads it. A keyword is a
// token kind of its own, in the order the tables list below, so each table's
// keywords are consecutive and a token's ID in its table is its distance from
// the table's first keyword.
// -gen-keyword-tokens: metaphir/Parser/KeywordTokens.inc, the ranges of those
// keywords, checked against the IDs they should name; KeywordTokens.h reads
// it.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringSet.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

/// A table of keywords: its records, and how each one is spelled.
struct KeywordTable {
  StringRef Name;
  SmallVector<const Record *, 32> Records;
  StringRef SpellingField; // Empty: the record's name.

  std::string spelling(const Record *R) const {
    return SpellingField.empty() ? R->getName().str()
                                 : R->getValueAsString(SpellingField).str();
  }
};

/// The keyword tables in the order of the token kinds. The matchable
/// constants come with the lexer's own keywords, as 'null' does.
struct KeywordTables {
  KeywordTable Keywords, MatchableConstants, Predicates, Types, Instructions,
      Flags, Settings;
  SmallVector<const KeywordTable *, 8> all() const {
    return {&Keywords, &MatchableConstants, &Predicates,
            &Types,    &Instructions,       &Flags,
            &Settings};
  }
};

KeywordTables getKeywordTables(const RecordKeeper &Records) {
  KeywordTables T;
  T.Keywords = {"Keyword", getDefinitionsInOrder(Records, "Keyword"),
                "Spelling"};
  T.MatchableConstants = {"MatchableConstant",
                          getDefinitionsInOrder(Records, "MatchableConstant"),
                          "Spelling"};
  T.Predicates = {"PredicateKeyword",
                  getDefinitionsInOrder(Records, "PredicateKeyword"),
                  "Spelling"};
  T.Types = {"PrimitiveType", getDefinitionsInOrder(Records, "PrimitiveType"),
             "Spelling"};
  T.Instructions = {"InstructionMatcher",
                    getDefinitionsInOrder(Records, "InstructionMatcher"), ""};
  T.Flags = {"Flag", getDefinitionsInOrder(Records, "Flag"), ""};
  T.Settings = {"PatternSetting",
                getDefinitionsInOrder(Records, "PatternSetting"), ""};
  // A spelling is one token, so two tables cannot share one.
  StringSet<> Seen;
  for (const KeywordTable *Table : T.all())
    for (const Record *R : Table->Records)
      if (!Seen.insert(Table->spelling(R)).second)
        PrintFatalError(R, "the keyword '" + Table->spelling(R) +
                               "' is defined twice");
  return T;
}

void emitTokens(const RecordKeeper &Records, raw_ostream &OS) {
  auto Tokens = getDefinitionsInOrder(Records, "TokenKind");
  KeywordTables Tables = getKeywordTables(Records);

  SmallVector<std::string, 160> Kinds;
  for (const Record *T : Tokens)
    Kinds.push_back(T->getName().str());
  for (const KeywordTable *Table : Tables.all())
    for (const Record *R : Table->Records)
      Kinds.push_back("kw_" + Table->spelling(R));

  beginHeader(OS, Records, "The lexer's tokens",
              "METAPHIR_PARSER_MIR_TOKEN_INC", {"llvm/ADT/StringRef.h"},
              {"tok"});
  OS << "// The data of the tokens; metaphir/Parser/MIRToken.h reads it.\n\n"
        "enum Kind {\n";
  for (const Record *T : Tokens) {
    OS << "  " << T->getName() << ",";
    if (!T->getValueAsString("Comment").empty())
      OS << "  // " << T->getValueAsString("Comment");
    OS << "\n";
  }
  for (const KeywordTable *Table : Tables.all())
    for (const Record *R : Table->Records)
      OS << "  kw_" << Table->spelling(R) << ",\n";
  OS << "};\n\n";
  emitArray<decltype(Kinds), std::string>(
      OS, "StringRef KindNames[]", Kinds,
      [](raw_ostream &OS, const std::string &K) { OS << '"' << K << '"'; });

  // The lexer's accessor for a token's value, for the tokens that have one.
  SmallVector<const Record *, 16> Valued;
  SmallVector<std::string, 8> Values;
  for (const Record *T : Tokens) {
    std::string Value = T->getValueAsString("Value").str();
    if (Value.empty())
      continue;
    Valued.push_back(T);
    if (!is_contained(Values, Value))
      Values.push_back(Value);
  }
  OS << "/// Which of the lexer's value accessors holds a token's value.\n"
        "enum class ValueKind {\n  None,\n";
  for (const std::string &Value : Values)
    OS << "  " << Value << ",\n";
  OS << "};\n\nstruct TokenValue {\n  Kind Token;\n  ValueKind Value;\n};\n\n";
  emitArray<decltype(Valued), const Record *>(
      OS, "TokenValue TokenValues[]", Valued,
      [](raw_ostream &OS, const Record *const &T) {
        OS << "{" << T->getName()
           << ", ValueKind::" << T->getValueAsString("Value") << "}";
      });

  OS << "/// A keyword and the token it is.\nstruct KeywordSpelling {\n"
        "  StringRef Spelling;\n  Kind Token;\n};\n\n";
  struct Keyword {
    std::string Spelling;
  };
  SmallVector<Keyword, 128> Keywords, Settings;
  for (const KeywordTable *Table : Tables.all())
    for (const Record *R : Table->Records)
      (Table == &Tables.Settings ? Settings : Keywords)
          .push_back({Table->spelling(R)});
  auto FormatKeyword = [](raw_ostream &OS, const Keyword &K) {
    OS << "{\"" << K.Spelling << "\", kw_" << K.Spelling << "}";
  };
  OS << "/// The keywords the lexer reads as identifiers.\n";
  emitArray<decltype(Keywords), Keyword>(OS, "KeywordSpelling Keywords[]",
                                         Keywords, FormatKeyword);
  OS << "/// The pattern settings, which follow ';;'.\n";
  emitArray<decltype(Settings), Keyword>(
      OS, "KeywordSpelling PatternSettingKeywords[]", Settings, FormatKeyword);
  endHeader(OS, "METAPHIR_PARSER_MIR_TOKEN_INC", {"tok"});
}

/// The range of tokens of a table, and the check that each one names the ID
/// of the same record, whose enumerator is EnumeratorPrefix + the record's
/// name. Offset is the number of IDs before the table's first.
void emitKeywordRange(raw_ostream &OS, const KeywordTable &Table,
                      StringRef RangeName, StringRef IDType,
                      StringRef EnumeratorPrefix, StringRef Offset) {
  if (Table.Records.empty())
    PrintFatalError("the table of " + Table.Name + " is empty");
  OS << "inline constexpr KeywordRange " << RangeName << " = {kw_"
     << Table.spelling(Table.Records.front()) << ", kw_"
     << Table.spelling(Table.Records.back()) << "};\n";
  for (const Record *R : Table.Records)
    OS << "static_assert(getKeywordID<" << IDType << ">(kw_"
       << Table.spelling(R) << ", " << RangeName << ", " << Offset
       << ") == " << EnumeratorPrefix << R->getName() << ", \""
       << Table.spelling(R) << " names another " << Table.Name << "\");\n";
  OS << "\n";
}

void emitKeywordTokens(const RecordKeeper &Records, raw_ostream &OS) {
  KeywordTables Tables = getKeywordTables(Records);
  beginHeader(OS, Records, "What the keyword tokens name",
              "METAPHIR_PARSER_KEYWORD_TOKENS_INC",
              {"metaphir/IR/Constants.inc", "metaphir/IR/Instruction.inc",
               "metaphir/IR/PatternSettings.inc", "metaphir/IR/Types.inc",
               "metaphir/Parser/KeywordRange.h", "metaphir/Parser/MIRToken.h"},
              {"tok"});
  OS << "// The keyword tokens of each table, and what they name; "
        "metaphir/Parser/\n// KeywordTokens.h reads them.\n\n";
  emitKeywordRange(OS, Tables.Types, "TypeKeywords", "primitive_type::TypeID",
                   "primitive_type::", "0");
  emitKeywordRange(OS, Tables.Flags, "FlagKeywords", "instruction_flag::FlagID",
                   "instruction_flag::F_", "0");
  emitKeywordRange(OS, Tables.Instructions, "InstructionKeywords",
                   "instruction::InstructionID", "instruction::I_", "0");
  // The IDs of the keyword constants number the matchable constants first.
  OS << "/// The predicate keywords' IDs follow those of the matchable "
        "constants.\ninline constexpr unsigned PredicateIDOffset = "
     << Tables.MatchableConstants.Records.size() << ";\n\n";
  emitKeywordRange(OS, Tables.MatchableConstants, "ConstantKeywords",
                   "keyword_constant::KeywordID", "keyword_constant::K_", "0");
  emitKeywordRange(OS, Tables.Predicates, "PredicateKeywords",
                   "keyword_constant::KeywordID", "keyword_constant::K_",
                   "PredicateIDOffset");

  OS << "struct PatternSettingKeyword {\n  Kind Token;\n"
        "  pattern_setting::Setting Setting;\n};\n\n";
  emitArray<decltype(Tables.Settings.Records), const Record *>(
      OS, "PatternSettingKeyword PatternSettingKeywordIDs[]",
      Tables.Settings.Records, [](raw_ostream &OS, const Record *const &S) {
        OS << "{kw_" << S->getName() << ", pattern_setting::" << S->getName()
           << "}";
      });
  endHeader(OS, "METAPHIR_PARSER_KEYWORD_TOKENS_INC", {"tok"});
}

TableGen::Emitter::Opt X("gen-tokens", emitTokens,
                         "Generate the lexer's tokens");
TableGen::Emitter::Opt Y("gen-keyword-tokens", emitKeywordTokens,
                         "Generate what the keyword tokens name");

} // namespace
