#ifndef METAPHIR_PARSER_MIR_TOKEN_H
#define METAPHIR_PARSER_MIR_TOKEN_H

#include "metaphir/Parser/MIRToken.inc"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

/// The lexer's tokens. Their data is generated from MIRTokenKinds.td and the
/// tables that define keywords (MIRToken.inc); this reads it.
namespace tok {

inline StringRef getTokenKindName(Kind Kind) { return KindNames[Kind]; }

/// Which of the lexer's value accessors holds the token's value, if any.
inline ValueKind getValueKind(Kind Kind) {
  for (const TokenValue &T : TokenValues)
    if (T.Token == Kind)
      return T.Value;
  return ValueKind::None;
}

/// The keyword spelled Keyword, or Identifier if it is none.
inline Kind lookupKeyword(StringRef Keyword) {
  static const StringMap<Kind> Map = [] {
    StringMap<Kind> Map;
    for (const KeywordSpelling &K : Keywords)
      Map[K.Spelling] = K.Token;
    return Map;
  }();
  auto It = Map.find(Keyword);
  return It == Map.end() ? Identifier : It->second;
}

/// The setting spelled Name, or Identifier if it is none.
inline Kind lookupPatternSetting(StringRef Name) {
  for (const KeywordSpelling &K : PatternSettingKeywords)
    if (K.Spelling == Name)
      return K.Token;
  return Identifier;
}

} // namespace tok
} // namespace metaphir
} // namespace llvm

#endif
