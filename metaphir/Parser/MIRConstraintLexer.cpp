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
        while (isalnum(static_cast<unsigned char>(Lexer.CurPtr[0])) ||
               Lexer.CurPtr[0] == '_')
          ++Lexer.CurPtr;
        Lexer.StrVal.assign(Lexer.TokStart, Lexer.CurPtr);
#define MIR_BOOLEAN_KEYWORD(Kind)                                              \
  if (Lexer.StrVal == #Kind)                                                   \
    return tok::kw_##Kind;
#include "metaphir/Parser/MIRKeywords.def"
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
