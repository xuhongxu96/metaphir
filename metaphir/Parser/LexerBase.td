//===- LexerBase.td - Classes for the lexer's tokens ------------*- tablegen -*-===//

#ifndef METAPHIR_PARSER_LEXER_BASE_TD
#define METAPHIR_PARSER_LEXER_BASE_TD

/// A token with no keyword spelling; the record's name is the tok::Kind
/// enumerator.
class TokenKind<string comment> {
  string Comment = comment;
  /// The Lexer accessor of the token's value, or empty if it has none.
  string Value = "";
}

class ValuedTokenKind<string value, string comment> : TokenKind<comment> {
  let Value = value;
}

/// A keyword of the lexer that no other table defines. It is the token
/// tok::kw_<Spelling>.
class Keyword<string spelling> {
  string Spelling = spelling;
}

#endif // METAPHIR_PARSER_LEXER_BASE_TD
