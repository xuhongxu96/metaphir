#include "metaphir/Parser/MIRConstraintLexer.h"
#include "metaphir/Parser/MIRLexer.h"
#include <cctype>

namespace llvm {
namespace metaphir {

tok::Kind MIRConstraintLexer::Lex() {
  Lexer.PrevTokEnd = Lexer.CurPtr;
  while (true) {
    Lexer.TokStart = Lexer.CurPtr;
    int CurChar = Lexer.getNextChar();
    switch (CurChar) {
    default:
      if (isalpha(static_cast<unsigned char>(CurChar)) || CurChar == '_') {
        // Operator names may contain hyphens (e.g. user-defined names); a '-'
        // is only part of the identifier when immediately followed by an
        // alphanumeric character, so "a - b" still lexes as subtraction.
        while (isalnum(static_cast<unsigned char>(Lexer.CurPtr[0])) ||
               Lexer.CurPtr[0] == '_' ||
               (Lexer.CurPtr[0] == '-' &&
                isalnum(static_cast<unsigned char>(Lexer.CurPtr[1]))))
          ++Lexer.CurPtr;
        Lexer.StrVal.assign(Lexer.TokStart, Lexer.CurPtr);
        if (Lexer.StrVal == "true")
          return tok::kw_true;
        if (Lexer.StrVal == "false")
          return tok::kw_false;
#define MIR_PATTERN_SETTING_TOKEN_KIND(Name)                                   \
  if (Lexer.StrVal == #Name)                                                   \
    return tok::kw_##Name;
#include "metaphir/IR/PatternSettings.def"
        return tok::Identifier;
      }
      return tok::Error;
    case EOF:
      return tok::Eof;
    case 0:
    case ' ':
    case '\t':
      continue;
    case '\n':
      return tok::Newline;
    case '\r':
      if (Lexer.CurPtr[0] == '\n')
        ++Lexer.CurPtr;
      return tok::Newline;
    case ';':
      Lexer.SkipLineComment();
      continue;
    case '+':
      return tok::plus;
    case '-':
      return tok::minus;
    case '*':
      return tok::star;
    case '/':
      return tok::slash;
    case '%':
      return tok::percent;
    case '!':
      if (Lexer.CurPtr[0] == '=') {
        ++Lexer.CurPtr;
        return tok::notequal;
      }
      return tok::exclaim;
    case '=':
      if (Lexer.CurPtr[0] == '=') {
        ++Lexer.CurPtr;
        return tok::equalequal;
      }
      return tok::equal;
    case '|':
      if (Lexer.CurPtr[0] == '|') {
        ++Lexer.CurPtr;
        return tok::barbar;
      }
      return tok::bar;
    case '&':
      if (Lexer.CurPtr[0] == '&') {
        ++Lexer.CurPtr;
        return tok::ampamp;
      }
      return tok::Error;
    case '<':
      if (Lexer.CurPtr[0] == '=') {
        ++Lexer.CurPtr;
        return tok::lessequal;
      }
      return tok::less;
    case '>':
      if (Lexer.CurPtr[0] == '=') {
        ++Lexer.CurPtr;
        return tok::greaterequal;
      }
      return tok::greater;
    case '(':
      return tok::lparen;
    case ')':
      return tok::rparen;
    case ',':
      return tok::comma;
    case '"':
      return Lexer.LexQuote();
    case '[':
      return tok::lsquare;
    case ']':
      return tok::rsquare;
    // Braces delimit the body of a top-level 'constraint'/'metaflag'
    // definition, which is lexed entirely in constraint mode.
    case '{':
      return tok::lbrace;
    case '}':
      return tok::rbrace;
    case '?':
      return Lexer.LexQuestion();
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      return Lexer.LexDigitOrNegative();
    }
  }
}

} // namespace metaphir
} // namespace llvm
