#include "metaphir/Parser/MIRLexer.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/Parser/MIRConstraintLexer.h"
#include "metaphir/Parser/MIRToken.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/SourceMgr.h"
#include <cassert>
#include <cctype>
#include <cstdio>

namespace llvm {
namespace metaphir {

// UnEscapeLexed - Run through the specified buffer and change \xx codes to the
// appropriate character.
static void UnEscapeLexed(std::string &Str) {
  if (Str.empty())
    return;

  char *Buffer = &Str[0], *EndBuffer = Buffer + Str.size();
  char *BOut = Buffer;
  for (char *BIn = Buffer; BIn != EndBuffer;) {
    if (BIn[0] == '\\') {
      if (BIn < EndBuffer - 1 && BIn[1] == '\\') {
        *BOut++ = '\\'; // Two \ becomes one
        BIn += 2;
      } else if (BIn < EndBuffer - 2 &&
                 isxdigit(static_cast<unsigned char>(BIn[1])) &&
                 isxdigit(static_cast<unsigned char>(BIn[2]))) {
        *BOut = hexDigitValue(BIn[1]) * 16 + hexDigitValue(BIn[2]);
        BIn += 3; // Skip over handled chars
        ++BOut;
      } else {
        *BOut++ = *BIn++;
      }
    } else {
      *BOut++ = *BIn++;
    }
  }
  Str.resize(BOut - Buffer);
}

/// isLabelChar - Return true for [-a-zA-Z$._0-9].
static bool isLabelChar(char C) {
  return isalnum(static_cast<unsigned char>(C)) || C == '-' || C == '$' ||
         C == '.' || C == '_';
}

/// isLabelTail - Return true if this pointer points to a valid end of a label.
static const char *isLabelTail(const char *CurPtr) {
  while (true) {
    if (CurPtr[0] == ':')
      return CurPtr + 1;
    if (!isLabelChar(CurPtr[0]))
      return nullptr;
    ++CurPtr;
  }
}

/// Describes a character for a diagnostic: printable characters are quoted,
/// others are written as a hexadecimal escape.
static std::string describeChar(int C) {
  if (isprint(C))
    return (Twine("'") + Twine(static_cast<char>(C)) + "'").str();
  std::string Result = "'\\x";
  Result += hexdigit((C >> 4) & 0xF, /*LowerCase=*/false);
  Result += hexdigit(C & 0xF, /*LowerCase=*/false);
  Result += "'";
  return Result;
}

// Both the lexer and parser can issue error messages. If the lexer issues a
// lexer error, since we do not terminate execution immediately, usually that
// is followed by the parser issuing a parser error. However, the error issued
// by the lexer is more relevant in that case as opposed to potentially more
// generic parser error. So instead of always recording the last error message
// use the `Priority` to establish a priority, with Lexer > Parser > None. We
// record the issued message only if the message has higher priority than the
// existing one. This prevents lexer errors from being overwritten by parser
// errors, and keeps the first (most specific) error of a given priority.
void MIRLexer::Error(LocTy ErrorLoc, const Twine &Msg,
                     MIRLexer::ErrorPriority Priority) {
  if (Priority <= ErrorInfo.Priority)
    return;
  ErrorInfo.Error = SM.GetMessage(ErrorLoc, SourceMgr::DK_Error, Msg);
  ErrorInfo.Priority = Priority;
}

void MIRLexer::Warning(LocTy WarningLoc, const Twine &Msg) const {
  SM.PrintMessage(WarningLoc, SourceMgr::DK_Warning, Msg);
}

//===----------------------------------------------------------------------===//
// Lexer definition.
//===----------------------------------------------------------------------===//

MIRLexer::MIRLexer(StringRef StartBuf, SourceMgr &SM, SMDiagnostic &Err,
                   MIRContext &C)
    : CurBuf(StartBuf), ErrorInfo(Err), SM(SM), Context(C) {
  // The lexer reads one character past a token to classify it, and relies on
  // the NUL terminator that MemoryBuffer guarantees to stop at the end.
  assert(*CurBuf.end() == '\0' && "lexer buffer must be NUL-terminated");
  CurPtr = TokStart = CurBuf.begin();
}

int MIRLexer::getNextChar() {
  char CurChar = *CurPtr++;
  switch (CurChar) {
  default:
    return (unsigned char)CurChar;
  case 0:
    // A nul character in the stream is either the end of the current buffer or
    // a random nul in the file.  Disambiguate that here.
    if (CurPtr - 1 != CurBuf.end())
      return 0; // Just whitespace.

    // Otherwise, return end of file.
    --CurPtr; // Another call to lex will return EOF again.
    return EOF;
  }
}

tok::Kind MIRLexer::Lex() {
  tok::Kind Kind =
      inConstraint() ? MIRConstraintLexer(*this).Lex() : LexToken();
  updateConstraintContext(Kind);
  return CurKind = Kind;
}

/// Track whether the next token belongs to a constraint expression or to
/// pattern syntax. See the flag declarations in MIRLexer.h.
void MIRLexer::updateConstraintContext(tok::Kind Kind) {
  switch (Kind) {
  case tok::ConstraintMarker:
    InConstraintLine = true;
    break;
  case tok::Newline:
    // A marker only covers its own line; a definition body spans lines.
    InConstraintLine = false;
    break;
  case tok::kw_constraint:
  case tok::kw_metaflag:
    ExpectConstraintBody = true;
    break;
  case tok::lbrace:
    // Only a 'constraint'/'metaflag' body holds an expression; a 'match'
    // body holds instructions.
    if (ExpectConstraintBody) {
      ExpectConstraintBody = false;
      InConstraintBody = true;
    }
    break;
  case tok::rbrace:
    InConstraintBody = false;
    break;
  case tok::Eof:
    InConstraintLine = false;
    InConstraintBody = false;
    ExpectConstraintBody = false;
    break;
  default:
    break;
  }
}

tok::Kind MIRLexer::LexToken() {
  // Set token end to next location, since the end is exclusive.
  PrevTokEnd = CurPtr;
  while (true) {
    TokStart = CurPtr;

    int CurChar = getNextChar();
    switch (CurChar) {
    default:
      // Handle letters: [a-zA-Z_]
      if (isalpha(static_cast<unsigned char>(CurChar)) || CurChar == '_')
        return LexIdentifier();
      return LexUnexpected(CurChar);
    case EOF:
      return tok::Eof;
    case 0:
    case ' ':
    case '\t':
      continue;
    case '\n':
      return tok::Newline;
    case '\r':
      if (CurPtr[0] == '\n')
        ++CurPtr;
      return tok::Newline;
    case '+':
      return LexPositive();
    case '@':
      return LexAt();
    case '$':
      return LexDollar();
    case '%':
      return LexPercent();
    case '"':
      return LexQuote();
    case '.':
      if (const char *Ptr = isLabelTail(CurPtr)) {
        CurPtr = Ptr;
        StrVal.assign(TokStart, CurPtr - 1);
        return tok::LabelStr;
      }
      if (CurPtr[0] == '.' && CurPtr[1] == '.') {
        CurPtr += 2;
        return tok::dotdotdot;
      }
      return LexUnexpected(CurChar);
    case ';':
      if (CurPtr[0] == ';') {
        ++CurPtr;
        return tok::ConstraintMarker;
      }
      SkipLineComment();
      continue;
    case '!':
      return LexExclaim();
    case ':':
      return LexColon();
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
    case '-':
      return LexDigitOrNegative();
    case '=':
      return tok::equal;
    case '[':
      return tok::lsquare;
    case ']':
      return tok::rsquare;
    case '{':
      return tok::lbrace;
    case '}':
      return tok::rbrace;
    case '<':
      return tok::less;
    case '>':
      return tok::greater;
    case '(':
      return tok::lparen;
    case ')':
      return tok::rparen;
    case ',':
      return tok::comma;
    case '*':
      return tok::star;
    case '|':
      return tok::bar;
    case '&':
      return LexUnexpected(CurChar);
    case '/':
      if (CurPtr[0] != '*')
        return LexUnexpected(CurChar);
      ++CurPtr;
      if (SkipCComment())
        return tok::Error;
      continue;
    case '?':
      return LexQuestion();
    }
  }
}

tok::Kind MIRLexer::LexUnexpected(int CurChar) {
  LexError(getLoc(), "unexpected character " + describeChar(CurChar));
  return tok::Error;
}

void MIRLexer::SkipLineComment() {
  while (true) {
    if (CurPtr[0] == '\n' || CurPtr[0] == '\r' || getNextChar() == EOF)
      return;
  }
}

/// This skips C-style /**/ comments. Returns true if there
/// was an error.
bool MIRLexer::SkipCComment() {
  while (true) {
    int CurChar = getNextChar();
    switch (CurChar) {
    case EOF:
      LexError("unterminated comment");
      return true;
    case '*':
      // End of the comment?
      CurChar = getNextChar();
      if (CurChar == '/')
        return false;
      if (CurChar == EOF) {
        LexError("unterminated comment");
        return true;
      }
    }
  }
}

/// Lex all tokens that start with an @ character.
///   GlobalVar   @\"[^\"]*\"
///   GlobalVar   @[-a-zA-Z$._][-a-zA-Z$._0-9]*
///   GlobalVarID @[0-9]+
tok::Kind MIRLexer::LexAt() {
  tok::Kind Kind = LexVar(tok::GlobalVar, tok::GlobalID);
  if (Kind == tok::GlobalVar && StrVal == "llvm." && CurPtr[0] == '?')
    return tok::IntrinsicPrefix;
  return Kind;
}

tok::Kind MIRLexer::LexDollar() {
  if (const char *Ptr = isLabelTail(TokStart)) {
    CurPtr = Ptr;
    StrVal.assign(TokStart, CurPtr - 1);
    return tok::LabelStr;
  }

  return LexUnexpected('$');
}

/// ReadString - Read a string until the closing quote.
tok::Kind MIRLexer::ReadString(tok::Kind Kind) {
  const char *Start = CurPtr;
  while (true) {
    int CurChar = getNextChar();

    if (CurChar == EOF) {
      LexError("end of file in string constant");
      return tok::Error;
    }
    if (CurChar == '"') {
      StrVal.assign(Start, CurPtr - 1);
      UnEscapeLexed(StrVal);
      return Kind;
    }
  }
}

/// ReadVarName - Read the rest of a token containing a variable name.
bool MIRLexer::ReadVarName() {
  const char *NameStart = CurPtr;
  if (isalpha(static_cast<unsigned char>(CurPtr[0])) || CurPtr[0] == '-' ||
      CurPtr[0] == '$' || CurPtr[0] == '.' || CurPtr[0] == '_') {
    ++CurPtr;
    while (isalnum(static_cast<unsigned char>(CurPtr[0])) || CurPtr[0] == '-' ||
           CurPtr[0] == '$' || CurPtr[0] == '.' || CurPtr[0] == '_')
      ++CurPtr;

    StrVal.assign(NameStart, CurPtr);
    return true;
  }
  return false;
}

// Lex an ID: [0-9]+. On success, the ID is stored in UIntVal and Token is
// returned, otherwise the Error token is returned.
tok::Kind MIRLexer::LexUIntID(tok::Kind Token) {
  if (!isdigit(static_cast<unsigned char>(CurPtr[0]))) {
    LexError("expected a name or a number after '" + Twine(TokStart[0]) + "'");
    return tok::Error;
  }

  for (++CurPtr; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  if (!lexValueNumber(StringRef(TokStart + 1, CurPtr - TokStart - 1)))
    return tok::Error;
  return Token;
}

bool MIRLexer::lexValueNumber(StringRef Digits) {
  unsigned Val = 0;
  if (Digits.getAsInteger(10, Val)) {
    LexError("value number is too large");
    return false;
  }
  UIntVal = Val;
  return true;
}

tok::Kind MIRLexer::LexVar(tok::Kind Var, tok::Kind VarID) {
  // Handle StringConstant: \"[^\"]*\"
  if (CurPtr[0] == '"') {
    ++CurPtr;

    while (true) {
      int CurChar = getNextChar();

      if (CurChar == EOF) {
        LexError("end of file in global variable name");
        return tok::Error;
      }
      if (CurChar == '"') {
        StrVal.assign(TokStart + 2, CurPtr - 1);
        UnEscapeLexed(StrVal);
        if (StringRef(StrVal).contains(0)) {
          LexError("NUL character is not allowed in names");
          return tok::Error;
        }
        return Var;
      }
    }
  }

  // Handle VarName: [-a-zA-Z$._][-a-zA-Z$._0-9]*
  if (ReadVarName())
    return Var;

  // Handle VarID: [0-9]+
  return LexUIntID(VarID);
}

/// Lex all tokens that start with a % character.
///   LocalVar   ::= %\"[^\"]*\"
///   LocalVar   ::= %[-a-zA-Z$._][-a-zA-Z$._0-9]*
///   LocalVarID ::= %[0-9]+
tok::Kind MIRLexer::LexPercent() {
  return LexVar(tok::LocalVar, tok::LocalVarID);
}

/// Lex all tokens that start with a " character.
///   QuoteLabel        "[^"]+":
///   StringConstant    "[^"]*"
tok::Kind MIRLexer::LexQuote() {
  tok::Kind kind = ReadString(tok::StringConstant);
  if (kind == tok::Error)
    return kind;

  if (CurPtr[0] == ':') {
    ++CurPtr;
    if (StringRef(StrVal).contains(0)) {
      LexError("NUL character is not allowed in names");
      kind = tok::Error;
    } else {
      kind = tok::LabelStr;
    }
  }

  return kind;
}

/// Lex all tokens that start with a ! character.
tok::Kind MIRLexer::LexExclaim() { return tok::exclaim; }

/// Lex a label, integer or byte types, keyword, or hexadecimal integer
/// constant.
///    Label           [-a-zA-Z$._0-9]+:
///    ByteType        b[0-9]+
///    IntegerType     i[0-9]+
///    Keyword         sdiv, float, ...
///    HexIntConstant  [us]0x[0-9A-Fa-f]+
///    HexFloatConstant f0x[0-9A-Fa-f]+
tok::Kind MIRLexer::LexIdentifier() {
  const char *StartChar = CurPtr;
  const char IntOrByteIdentifier = CurPtr[-1];
  const char *IntOrByteEnd =
      (IntOrByteIdentifier == 'i' || IntOrByteIdentifier == 'b') ? nullptr
                                                                 : StartChar;
  const char *KeywordEnd = nullptr;

  if (!IntOrByteEnd && CurPtr[0] == '?') {
    MetaIntPrefix = IntOrByteIdentifier;
    ++CurPtr;
    if (ReadVarName()) {
      return tok::MetaIntVar;
    }
    LexError("invalid meta variable name for integer type");
    return tok::Error;
  }

  for (; isLabelChar(*CurPtr); ++CurPtr) {
    // If we decide this is an integer, remember the end of the sequence.
    if (!IntOrByteEnd && !isdigit(static_cast<unsigned char>(*CurPtr)))
      IntOrByteEnd = CurPtr;
    if (!KeywordEnd && !isalnum(static_cast<unsigned char>(*CurPtr)) &&
        *CurPtr != '_')
      KeywordEnd = CurPtr;
  }

  // If we stopped due to a colon, unless we were directed to ignore it,
  // this really is a label.
  if (*CurPtr == ':' &&
      !isLabelChar(CurPtr[1]) // Not a label if the next char is a label char,
                              // e.g., meta flags
      && CurPtr[1] != '?'     // meta-variable to capture flags like nsw, nuw
  ) {
    StrVal.assign(StartChar - 1, CurPtr++);
    return tok::LabelStr;
  }

  // Otherwise, this wasn't a label. If this was valid as a byte or an integer
  // type, return it.
  if (!IntOrByteEnd)
    IntOrByteEnd = CurPtr;
  if (IntOrByteEnd != StartChar) {
    CurPtr = IntOrByteEnd;
    unsigned NumBits = 0;
    if (StringRef(StartChar, CurPtr - StartChar).getAsInteger(10, NumBits) ||
        NumBits < 1 || NumBits > IntegerType::MaxBits) {
      LexError((IntOrByteIdentifier == 'i' ? "integer" : "byte") +
               Twine(" bit width must be between 1 and ") +
               Twine(IntegerType::MaxBits));
      return tok::Error;
    }
    if (IntOrByteIdentifier == 'i')
      TyVal = IntegerType::get(Context, NumBits);
    else
      TyVal = ByteType::get(Context, NumBits);

    return tok::Type;
  }

  // Otherwise, this was a letter sequence.  See which keyword this is.
  if (!KeywordEnd)
    KeywordEnd = CurPtr;
  CurPtr = KeywordEnd;
  --StartChar;
  StringRef Keyword(StartChar, CurPtr - StartChar);

#define KEYWORD(STR)                                                           \
  do {                                                                         \
    if (Keyword == #STR)                                                       \
      return tok::kw_##STR;                                                    \
  } while (false)

#define MIR_KEYWORD_TOKEN_KIND(Kind) KEYWORD(Kind);
#include "metaphir/Parser/MIRKeywords.def"

#define MIR_PREDICATE_KEYWORD(ID, Spelling) KEYWORD(Spelling);
#include "metaphir/IR/KeywordConstants.def"

#define MIR_TYPE_TOKEN_KIND(Kind) KEYWORD(Kind);
#include "metaphir/IR/Types.def"

#define MIR_INSTRUCTION_MATCHER_TOKEN_KIND(Kind) KEYWORD(Kind);
#include "metaphir/IR/InstructionMatchers.def"

#define MIR_FLAG_TOKEN_KIND(Kind) KEYWORD(Kind);
#include "metaphir/IR/Flags.def"

#undef KEYWORD

  // [us]0x[0-9A-Fa-f]+ is an integer written as a hexadecimal bit pattern:
  // 'u' reads the digits as an unsigned number, 's' as a two's complement
  // number of 4 bits per digit (so s0x7F is 127 and s0xFF is -1).
  if ((TokStart[0] == 'u' || TokStart[0] == 's') && TokStart[1] == '0' &&
      TokStart[2] == 'x' && isxdigit(static_cast<unsigned char>(TokStart[3]))) {
    bool IsSigned = TokStart[0] == 's';
    StringRef HexStr(TokStart + 3, CurPtr - TokStart - 3);
    if (!all_of(HexStr, isxdigit)) {
      LexError("invalid hexadecimal integer constant");
      return tok::Error;
    }
    APInt Tmp(HexStr.size() * 4, HexStr, 16);
    // Keep the value, but drop the redundant leading bits of the pattern.
    unsigned Bits =
        std::max(1u, IsSigned ? Tmp.getSignificantBits() : Tmp.getActiveBits());
    APSIntVal = APSInt(Tmp.trunc(Bits), /*isUnsigned=*/!IsSigned);
    return tok::APSInt;
  }

  StrVal.assign(TokStart, CurPtr);
  return tok::Identifier;
}

/// Lex all tokens that start with a 0x prefix, knowing they match and are not
/// labels.
///    HexFPConstant     0x[0-9A-Fa-f]+
/// This is a double constant written as its IEEE bit pattern, as LLVM prints
/// doubles that have no exact decimal form.
tok::Kind MIRLexer::Lex0x() {
  CurPtr = TokStart + 2;

  if ((CurPtr[0] >= 'K' && CurPtr[0] <= 'M') || CurPtr[0] == 'H' ||
      CurPtr[0] == 'R') {
    LexError("0x" + Twine(CurPtr[0]) +
             " floating-point constants are not supported");
    return tok::Error;
  }

  if (!isxdigit(static_cast<unsigned char>(CurPtr[0]))) {
    LexError("expected hexadecimal digits after '0x'");
    return tok::Error;
  }

  while (isxdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (*CurPtr == '.') {
    LexError("hexadecimal floating-point literals are not supported; write "
             "the IEEE bit pattern as 0x<hex digits>");
    return tok::Error;
  }

  uint64_t Bits = 0;
  if (StringRef(TokStart + 2, CurPtr - TokStart - 2).getAsInteger(16, Bits)) {
    LexError("hexadecimal constant is too large (more than 64 bits)");
    return tok::Error;
  }
  APFloatVal = APFloat(APFloat::IEEEdouble(), APInt(64, Bits));
  return tok::APFloat;
}

/// Lex tokens for a label or a numeric constant, possibly starting with -.
///    Label             [-a-zA-Z$._0-9]+:
///    NInteger          -[0-9]+
///    FPConstant        [-+]?[0-9]+[.][0-9]*([eE][-+]?[0-9]+)?
///    PInteger          [0-9]+
///    HexFPConstant     0x[0-9A-Fa-f]+
///    HexFP80Constant   0xK[0-9A-Fa-f]+
///    HexFP128Constant  0xL[0-9A-Fa-f]+
///    HexPPC128Constant 0xM[0-9A-Fa-f]+
tok::Kind MIRLexer::LexDigitOrNegative() {
  // If the character after the '-' is not a digit, this is probably a label.
  if (!isdigit(static_cast<unsigned char>(TokStart[0])) &&
      !isdigit(static_cast<unsigned char>(CurPtr[0]))) {
    // Okay, this is not a number after the -, it's probably a label.
    if (const char *End = isLabelTail(CurPtr)) {
      StrVal.assign(TokStart, End - 1);
      CurPtr = End;
      return tok::LabelStr;
    }

    return LexUnexpected('-');
  }

  // At this point, it is either a label, int or fp constant.

  // Skip digits, we have at least one.
  for (; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  // Check if this is a fully-numeric label:
  if (isdigit(static_cast<unsigned char>(TokStart[0])) && CurPtr[0] == ':') {
    StringRef Digits(TokStart, CurPtr - TokStart);
    ++CurPtr; // Skip the colon.
    if (!lexValueNumber(Digits))
      return tok::Error;
    return tok::LabelID;
  }

  // Check to see if this really is a string label, e.g. "-1:".
  if (isLabelChar(CurPtr[0]) || CurPtr[0] == ':') {
    if (const char *End = isLabelTail(CurPtr)) {
      StrVal.assign(TokStart, End - 1);
      CurPtr = End;
      return tok::LabelStr;
    }
  }

  // If the next character is a '.', then it is a fp value, otherwise its
  // integer.
  if (CurPtr[0] != '.') {
    if (TokStart[0] == '0' && TokStart[1] == 'x')
      return Lex0x();
    APSIntVal = APSInt(StringRef(TokStart, CurPtr - TokStart));
    return tok::APSInt;
  }

  ++CurPtr;

  // Skip over [0-9]*([eE][-+]?[0-9]+)?
  while (isdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (CurPtr[0] == 'e' || CurPtr[0] == 'E') {
    if (isdigit(static_cast<unsigned char>(CurPtr[1])) ||
        ((CurPtr[1] == '-' || CurPtr[1] == '+') &&
         isdigit(static_cast<unsigned char>(CurPtr[2])))) {
      CurPtr += 2;
      while (isdigit(static_cast<unsigned char>(CurPtr[0])))
        ++CurPtr;
    }
  }

  APFloatVal =
      APFloat(APFloat::IEEEdouble(), StringRef(TokStart, CurPtr - TokStart));
  return tok::APFloat;
}

/// Lex a floating point constant starting with +.
///    FPConstant  [-+]?[0-9]+[.][0-9]*([eE][-+]?[0-9]+)?
tok::Kind MIRLexer::LexPositive() {
  // A '+' only starts a floating-point constant.
  if (!isdigit(static_cast<unsigned char>(CurPtr[0])))
    return LexUnexpected('+');

  // Skip digits.
  for (++CurPtr; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  // At this point, we need a '.'.
  if (CurPtr[0] != '.') {
    CurPtr = TokStart + 1;
    return LexUnexpected('+');
  }

  ++CurPtr;

  // Skip over [0-9]*([eE][-+]?[0-9]+)?
  while (isdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (CurPtr[0] == 'e' || CurPtr[0] == 'E') {
    if (isdigit(static_cast<unsigned char>(CurPtr[1])) ||
        ((CurPtr[1] == '-' || CurPtr[1] == '+') &&
         isdigit(static_cast<unsigned char>(CurPtr[2])))) {
      CurPtr += 2;
      while (isdigit(static_cast<unsigned char>(CurPtr[0])))
        ++CurPtr;
    }
  }

  APFloatVal =
      APFloat(APFloat::IEEEdouble(), StringRef(TokStart, CurPtr - TokStart));
  return tok::APFloat;
}

/// Lex all tokens that start with an ? character.
tok::Kind MIRLexer::LexQuestion() {
  if (ReadVarName()) {
    return tok::MetaVar;
  }
  LexError("invalid meta variable name");
  return tok::Error;
}

/// Meta flags
tok::Kind MIRLexer::LexColon() {
  switch (CurPtr[0]) {
  case '?':
    ++CurPtr;
    if (ReadVarName()) {
      return tok::MetaCaptureVar;
    }
    LexError("invalid meta capture variable name");
    return tok::Error;
  default:
    if (ReadVarName()) {
      return tok::MetaFlag;
    }
    return tok::colon;
  }
}

} // namespace metaphir
} // namespace llvm
