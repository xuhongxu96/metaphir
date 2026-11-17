#ifndef METAPHIR_PARSER_KEYWORD_TOKENS_H
#define METAPHIR_PARSER_KEYWORD_TOKENS_H

#include "metaphir/Parser/KeywordTokens.inc"
#include <optional>

namespace llvm {
namespace metaphir {

/// What a keyword token names in the table that defines it. The ranges are
/// generated (KeywordTokens.inc), each checked against the IDs it names.
namespace tok {

inline std::optional<primitive_type::TypeID> getPrimitiveType(Kind K) {
  return getKeywordID<primitive_type::TypeID>(K, TypeKeywords);
}

inline std::optional<instruction_flag::FlagID> getSemanticFlag(Kind K) {
  return getKeywordID<instruction_flag::FlagID>(K, FlagKeywords);
}

inline std::optional<instruction::InstructionID> getInstruction(Kind K) {
  return getKeywordID<instruction::InstructionID>(K, InstructionKeywords);
}

/// A keyword constant that is matched, such as 'null'.
inline std::optional<keyword_constant::KeywordID> getConstantKeyword(Kind K) {
  return getKeywordID<keyword_constant::KeywordID>(K, ConstantKeywords);
}

/// A comparison predicate keyword, such as 'slt'.
inline std::optional<keyword_constant::KeywordID> getPredicateKeyword(Kind K) {
  return getKeywordID<keyword_constant::KeywordID>(K, PredicateKeywords,
                                                   PredicateIDOffset);
}

inline std::optional<pattern_setting::Setting> getPatternSetting(Kind K) {
  for (const PatternSettingKeyword &S : PatternSettingKeywordIDs)
    if (S.Token == K)
      return S.Setting;
  return std::nullopt;
}

} // namespace tok
} // namespace metaphir
} // namespace llvm

#endif
