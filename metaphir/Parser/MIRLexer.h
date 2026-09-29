#ifndef METAPHIR_PARSER_MIR_LEXER_H
#define METAPHIR_PARSER_MIR_LEXER_H

#include "metaphir/Parser/MIRToken.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/Support/SMLoc.h"
#include "llvm/Support/SourceMgr.h"
#include <string>

namespace llvm {

class SMDiagnostic;

namespace metaphir {

class Type;
class MIRContext;
class MIRLexer;
class MIRConstraintLexer;

class MIRLexer {
public:
  using LocTy = SMLoc;

  explicit MIRLexer(StringRef StartBuf, SourceMgr &SM, SMDiagnostic &,
                    MIRContext &C);
  tok::Kind Lex();
  /// Rewinds to Loc, the start of a token previously returned in pattern
  /// syntax, and lexes it again. Gives the parser one-token lookahead.
  tok::Kind resetTo(LocTy Loc) {
    CurPtr = Loc.getPointer();
    return Lex();
  }
  LocTy getLoc() const { return SMLoc::getFromPointer(TokStart); }
  tok::Kind getKind() const { return CurKind; }
  const std::string &getStrVal() const { return StrVal; }
  Type *getTyVal() const { return TyVal; }
  unsigned getUIntVal() const { return UIntVal; }
  char getMetaIntPrefix() const { return MetaIntPrefix; }
  const APSInt &getAPSIntVal() const { return APSIntVal; }
  const APFloat &getAPFloatVal() const { return APFloatVal; }

  /// Get the line, column position of the start of the current token,
  /// zero-indexed
  std::pair<unsigned, unsigned> getTokLineColumnPos() {
    auto LC = SM.getLineAndColumn(SMLoc::getFromPointer(TokStart));
    return {LC.first - 1, LC.second - 1};
  }
  /// Get the line, column position of the end of the previous token,
  /// zero-indexed exclusive
  std::pair<unsigned, unsigned> getPrevTokEndLineColumnPos() {
    auto LC = SM.getLineAndColumn(SMLoc::getFromPointer(PrevTokEnd));
    return {LC.first - 1, LC.second - 1};
  }

  // This returns true as a convenience for the parser functions that return
  // true on error.
  bool ParseError(LocTy ErrorLoc, const Twine &Msg) {
    Error(ErrorLoc, Msg, ErrorPriority::Parser);
    return true;
  }
  bool ParseError(const Twine &Msg) { return ParseError(getLoc(), Msg); }

  void Warning(LocTy WarningLoc, const Twine &Msg) const;
  void Warning(const Twine &Msg) const { return Warning(getLoc(), Msg); }

  /// The diagnostic that receives this lexer's (and its parser's) errors.
  SMDiagnostic &getDiagnostic() const { return ErrorInfo.Error; }

  /// Whether an error has been reported, by the lexer or the parser.
  bool hasError() const { return ErrorInfo.Priority != ErrorPriority::None; }

  /// The source text of the current token.
  StringRef getTokenText() const {
    return StringRef(TokStart, CurPtr - TokStart);
  }

private:
  friend class MIRConstraintLexer;

  enum class ErrorPriority {
    None,   // No error message present.
    Parser, // Errors issued by parser.
    Lexer,  // Errors issued by lexer.
  };

  struct ErrorInfo {
    ErrorPriority Priority = ErrorPriority::None;
    SMDiagnostic &Error;

    explicit ErrorInfo(SMDiagnostic &Error) : Error(Error) {}
  };

  const char *CurPtr;
  StringRef CurBuf;

  /// The end (exclusive) of the previous token.
  const char *PrevTokEnd = nullptr;

  ErrorInfo ErrorInfo;
  SourceMgr &SM;
  MIRContext &Context;

  /// Constraint expressions use a different token set than pattern syntax
  /// (see MIRConstraintLexer), so the lexer tracks which sublanguage it is
  /// in. Two contexts select it, with different lifetimes:
  ///
  ///   ;; <expr>                 -- a marker introduces a single line
  ///   constraint f(v) { <expr> } -- a definition body spans lines
  ///
  /// Tracking both here keeps tokenization independent of the parser, so
  /// tools that drive the lexer directly see the same tokens.
  ///
  /// Set between a ';;' marker and the end of that line.
  bool InConstraintLine = false;
  /// Set between the braces of a 'constraint'/'metaflag' definition body.
  bool InConstraintBody = false;
  /// Set after a 'constraint'/'metaflag' keyword, until its body's '{' is
  /// seen. Distinguishes those bodies from a 'match' body, whose braces hold
  /// pattern syntax.
  bool ExpectConstraintBody = false;

  bool inConstraint() const { return InConstraintLine || InConstraintBody; }
  void updateConstraintContext(tok::Kind Kind);

  // Information about the current token.
  const char *TokStart = nullptr;
  tok::Kind CurKind = tok::Error;
  std::string StrVal;
  unsigned UIntVal = 0;
  char MetaIntPrefix = 'i';
  Type *TyVal = nullptr;
  APFloat APFloatVal{0.0};
  APSInt APSIntVal{0};

  tok::Kind LexToken();

  int getNextChar();
  void SkipLineComment();
  bool SkipCComment();
  tok::Kind ReadString(tok::Kind Kind);
  bool ReadVarName();

  tok::Kind LexIdentifier();
  tok::Kind LexDigitOrNegative();
  tok::Kind LexPositive();
  tok::Kind LexAt();
  tok::Kind LexDollar();
  tok::Kind LexExclaim();
  tok::Kind LexPercent();
  tok::Kind LexUIntID(tok::Kind Token);
  tok::Kind LexVar(tok::Kind Var, tok::Kind VarID);
  tok::Kind LexQuote();
  tok::Kind Lex0x();
  tok::Kind LexColon();
  tok::Kind LexQuestion();
  /// Reports CurChar as not starting any token and returns tok::Error.
  tok::Kind LexUnexpected(int CurChar);

  /// Stores the decimal Digits in UIntVal; reports an error and returns false
  /// if they do not fit.
  bool lexValueNumber(StringRef Digits);

  void Error(LocTy ErrorLoc, const Twine &Msg, ErrorPriority Origin);

  void LexError(LocTy ErrorLoc, const Twine &Msg) {
    Error(ErrorLoc, Msg, ErrorPriority::Lexer);
  }
  void LexError(const Twine &Msg) { LexError(getLoc(), Msg); }
};
} // namespace metaphir
} // namespace llvm

#endif
