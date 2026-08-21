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

namespace {

// UnEscapeLexed - Run through the specified buffer and change \xx codes to the
// appropriate character.
void UnEscapeLexed(std::string &Str) {
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
bool isLabelChar(char C) {
  return isalnum(static_cast<unsigned char>(C)) || C == '-' || C == '$' ||
         C == '.' || C == '_';
}

/// isLabelTail - Return true if this pointer points to a valid end of a label.
const char *isLabelTail(const char *CurPtr) {
  while (true) {
    if (CurPtr[0] == ':')
      return CurPtr + 1;
    if (!isLabelChar(CurPtr[0]))
      return nullptr;
    ++CurPtr;
  }
}

} // namespace

//===----------------------------------------------------------------------===//
// Helper functions.
//===----------------------------------------------------------------------===//

// atoull - Convert an ascii string of decimal digits into the unsigned long
// long representation... this does not have to do input error checking,
// because we know that the input will be matched by a suitable regex...
//
uint64_t MIRLexer::atoull(const char *Buffer, const char *End) {
  uint64_t Result = 0;
  for (; Buffer != End; Buffer++) {
    uint64_t OldRes = Result;
    Result *= 10;
    Result += *Buffer - '0';
    if (Result < OldRes) { // overflow detected.
      LexError("constant bigger than 64 bits detected");
      return 0;
    }
  }
  return Result;
}

uint64_t MIRLexer::HexIntToVal(const char *Buffer, const char *End) {
  uint64_t Result = 0;
  for (; Buffer != End; ++Buffer) {
    uint64_t OldRes = Result;
    Result *= 16;
    Result += hexDigitValue(*Buffer);

    if (Result < OldRes) { // overflow detected.
      LexError("constant bigger than 64 bits detected");
      return 0;
    }
  }
  return Result;
}

void MIRLexer::HexToIntPair(const char *Buffer, const char *End,
                            uint64_t Pair[2]) {
  Pair[0] = 0;
  if (End - Buffer >= 16) {
    for (int i = 0; i < 16; i++, Buffer++) {
      assert(Buffer != End);
      Pair[0] *= 16;
      Pair[0] += hexDigitValue(*Buffer);
    }
  }
  Pair[1] = 0;
  for (int i = 0; i < 16 && Buffer != End; i++, Buffer++) {
    Pair[1] *= 16;
    Pair[1] += hexDigitValue(*Buffer);
  }
  if (Buffer != End)
    LexError("constant bigger than 128 bits detected");
}

/// FP80HexToIntPair - translate an 80 bit FP80 number (20 hexits) into
/// { low64, high16 } as usual for an APInt.
void MIRLexer::FP80HexToIntPair(const char *Buffer, const char *End,
                                uint64_t Pair[2]) {
  Pair[1] = 0;
  for (int i = 0; i < 4 && Buffer != End; i++, Buffer++) {
    assert(Buffer != End);
    Pair[1] *= 16;
    Pair[1] += hexDigitValue(*Buffer);
  }
  Pair[0] = 0;
  for (int i = 0; i < 16 && Buffer != End; i++, Buffer++) {
    Pair[0] *= 16;
    Pair[0] += hexDigitValue(*Buffer);
  }
  if (Buffer != End)
    LexError("constant bigger than 128 bits detected");
}

// Both the lexer and parser can issue error messages. If the lexer issues a
// lexer error, since we do not terminate execution immediately, usually that
// is followed by the parser issuing a parser error. However, the error issued
// by the lexer is more relevant in that case as opposed to potentially more
// generic parser error. So instead of always recording the last error message
// use the `Priority` to establish a priority, with Lexer > Parser > None. We
// record the issued message only if the message has same or higher priority
// than the existing one. This prevents lexer errors from being overwritten by
// parser errors.
void MIRLexer::Error(LocTy ErrorLoc, const Twine &Msg,
                     MIRLexer::ErrorPriority Priority) {
  if (Priority < ErrorInfo.Priority)
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
  CurPtr = CurBuf.begin();
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
  tok::Kind Kind = InConstraint ? MIRConstraintLexer(*this).Lex() : LexToken();
  if (Kind == tok::ConstraintMarker)
    InConstraint = true;
  else if (Kind == tok::Newline || Kind == tok::Eof)
    InConstraint = false;
  return CurKind = Kind;
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
      return tok::Error;
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
      return tok::Error;
    case '/':
      if (CurPtr[0] != '*')
        return tok::Error;
      ++CurPtr;
      if (SkipCComment())
        return tok::Error;
      continue;
    case '?':
      return LexQuestion();
    }
  }
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

  return tok::Error;
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
  if (!isdigit(static_cast<unsigned char>(CurPtr[0])))
    return tok::Error;

  for (++CurPtr; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  uint64_t Val = atoull(TokStart + 1, CurPtr);
  if ((unsigned)Val != Val)
    LexError("invalid value number (too large)");
  UIntVal = unsigned(Val);
  return Token;
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
  if (kind == tok::Error || kind == tok::Eof)
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
///    !foo
///    !
tok::Kind MIRLexer::LexExclaim() {
  // Lex a metadata name as a MetadataVar.
  if (isalpha(static_cast<unsigned char>(CurPtr[0])) || CurPtr[0] == '-' ||
      CurPtr[0] == '$' || CurPtr[0] == '.' || CurPtr[0] == '_' ||
      CurPtr[0] == '\\') {
    ++CurPtr;
    while (isalnum(static_cast<unsigned char>(CurPtr[0])) || CurPtr[0] == '-' ||
           CurPtr[0] == '$' || CurPtr[0] == '.' || CurPtr[0] == '_' ||
           CurPtr[0] == '\\')
      ++CurPtr;

    StrVal.assign(TokStart + 1, CurPtr); // Skip !
    UnEscapeLexed(StrVal);
    return tok::MetadataVar;
  }
  return tok::exclaim;
}

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
    uint64_t NumBits = atoull(StartChar, CurPtr);
    if (NumBits < 1) {
      LexError("bitwidth for integer or byte type out of range");
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

  // Check for [us]0x[0-9A-Fa-f]+ which are Hexadecimal constant generated by
  // the CFE to avoid forcing it to deal with 64-bit numbers. Also check for
  // f0x[0-9A-Fa-f]+, which is the floating-point hexadecimal literal constant.
  if ((TokStart[0] == 'u' || TokStart[0] == 's' || TokStart[0] == 'f') &&
      TokStart[1] == '0' && TokStart[2] == 'x' &&
      isxdigit(static_cast<unsigned char>(TokStart[3]))) {
    bool IsFloatConst = TokStart[0] == 'f';
    size_t Len = CurPtr - TokStart - 3;
    uint32_t Bits = Len * 4;
    StringRef HexStr(TokStart + 3, Len);
    if (!all_of(HexStr, isxdigit)) {
      // Bad token, return it as an error.
      CurPtr = TokStart + 3;
      return tok::Error;
    }
    APInt Tmp(Bits, HexStr, 16);
    uint32_t ActiveBits = Tmp.getActiveBits();
    if (!IsFloatConst && ActiveBits > 0 && ActiveBits < Bits)
      Tmp = Tmp.trunc(ActiveBits);
    APSIntVal = APSInt(Tmp, TokStart[0] != 's');
    return IsFloatConst ? tok::FloatHexLiteral : tok::APSInt;
  }

  StrVal.assign(TokStart, CurPtr);
  return tok::Identifier;
}

/// Lex all tokens that start with a 0x prefix, knowing they match and are not
/// labels.
///    HexFPLiteral      [-+]?0x[0-9A-Fa-f]+.[0-9A-Fa-f]*[pP][-+]?[0-9]+
///    HexFPConstant     0x[0-9A-Fa-f]+
///    HexFP80Constant   0xK[0-9A-Fa-f]+
///    HexFP128Constant  0xL[0-9A-Fa-f]+
///    HexPPC128Constant 0xM[0-9A-Fa-f]+
///    HexHalfConstant   0xH[0-9A-Fa-f]+
///    HexBFloatConstant 0xR[0-9A-Fa-f]+
tok::Kind MIRLexer::Lex0x() {
  CurPtr = TokStart + 2;

  char Kind;
  if ((CurPtr[0] >= 'K' && CurPtr[0] <= 'M') || CurPtr[0] == 'H' ||
      CurPtr[0] == 'R') {
    Kind = *CurPtr++;
  } else {
    Kind = 'J';
  }

  if (!isxdigit(static_cast<unsigned char>(CurPtr[0]))) {
    // Bad token, return it as an error.
    CurPtr = TokStart + 1;
    return tok::Error;
  }

  while (isxdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (*CurPtr == '.') {
    // HexFPLiteral, following C's %a syntax
    return LexFloatStr();
  }

  if (Kind == 'J') {
    // HexFPConstant - Floating point constant represented in IEEE format as a
    // hexadecimal number for when exponential notation is not precise enough.
    // Half, BFloat, Float, and double only.
    APFloatVal = APFloat(APFloat::IEEEdouble(),
                         APInt(64, HexIntToVal(TokStart + 2, CurPtr)));
    return tok::APFloat;
  }

  uint64_t Pair[2];
  switch (Kind) {
  default:
    llvm_unreachable("Unknown kind!");
  case 'K':
    // F80HexFPConstant - x87 long double in hexadecimal format (10 bytes)
    FP80HexToIntPair(TokStart + 3, CurPtr, Pair);
    APSIntVal = APInt(80, Pair);
    return tok::FloatHexLiteral;
  case 'L':
    // F128HexFPConstant - IEEE 128-bit in hexadecimal format (16 bytes)
    HexToIntPair(TokStart + 3, CurPtr, Pair);
    APSIntVal = APInt(128, Pair);
    return tok::FloatHexLiteral;
  case 'M':
    // PPC128HexFPConstant - PowerPC 128-bit in hexadecimal format (16 bytes)
    HexToIntPair(TokStart + 3, CurPtr, Pair);
    APSIntVal = APInt(128, Pair);
    return tok::FloatHexLiteral;
  case 'H': {
    uint64_t Val = HexIntToVal(TokStart + 3, CurPtr);
    if (!llvm::isUInt<16>(Val)) {
      LexError("hexadecimal constant too large for half (16-bit)");
      return tok::Error;
    }
    APSIntVal = APInt(16, Val);
    return tok::FloatHexLiteral;
  }
  case 'R': {
    // Brain floating point
    uint64_t Val = HexIntToVal(TokStart + 3, CurPtr);
    if (!llvm::isUInt<16>(Val)) {
      LexError("hexadecimal constant too large for bfloat (16-bit)");
      return tok::Error;
    }
    APSIntVal = APInt(16, Val);
    return tok::FloatHexLiteral;
  }
  }
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
  // If the letter after the negative is not a number, this is probably a label.
  if (!isdigit(static_cast<unsigned char>(TokStart[0])) &&
      !isdigit(static_cast<unsigned char>(CurPtr[0]))) {
    // Okay, this is not a number after the -, it's probably a label.
    if (const char *End = isLabelTail(CurPtr)) {
      StrVal.assign(TokStart, End - 1);
      CurPtr = End;
      return tok::LabelStr;
    }

    return tok::Error;
  }

  // At this point, it is either a label, int or fp constant.

  // Skip digits, we have at least one.
  for (; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  // Check if this is a fully-numeric label:
  if (isdigit(TokStart[0]) && CurPtr[0] == ':') {
    uint64_t Val = atoull(TokStart, CurPtr);
    ++CurPtr; // Skip the colon.
    if ((unsigned)Val != Val)
      LexError("invalid value number (too large)");
    UIntVal = unsigned(Val);
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
  // If the letter after the negative is a number, this is probably not a
  // label.
  if (!isdigit(static_cast<unsigned char>(CurPtr[0])))
    return tok::Error;

  // Skip digits.
  for (++CurPtr; isdigit(static_cast<unsigned char>(CurPtr[0])); ++CurPtr)
    /*empty*/;

  // At this point, we need a '.'.
  if (CurPtr[0] != '.') {
    CurPtr = TokStart + 1;
    return tok::Error;
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

/// Lex all tokens that start with a + or - that could be a float literal.
///    HexFPLiteral      [-+]?0x[0-9A-Fa-f]+.[0-9A-Fa-f]*[pP][-+]?[0-9]+
///    HexFPSpecial      [-+](inf|qnan|s?nan\(0x[0-9A-Fa-f]+\))
tok::Kind MIRLexer::LexFloatStr() {
  // At the point we enter this function, we may have seen a few characters
  // already, but how many differs based on the entry point. Rewind to the
  // beginning just in case.
  CurPtr = TokStart;

  // Check for optional sign.
  if (*CurPtr == '-' || *CurPtr == '+')
    ++CurPtr;

  if (*CurPtr != '0') {
    // Check for keywords.
    const char *LabelStart = CurPtr;
    while (isLabelChar(*CurPtr))
      ++CurPtr;
    StringRef Label(LabelStart, CurPtr - LabelStart);

    // Basic special values.
    if (Label == "inf") {
      // Copy from the beginning, to include the sign.
      StrVal.assign(TokStart, CurPtr - TokStart);
      return tok::FloatLiteral;
    }

    // APFloat::convertFromString doesn't support qnan, so translate it to a
    // nan payload string it does support.
    if (Label == "qnan") {
      StrVal = *TokStart == '-' ? "-nan(0)" : "nan(0)";
      return tok::FloatLiteral;
    }

    // NaN with payload.
    if ((Label == "nan" || Label == "snan") && *CurPtr == '(') {
      const char *Payload = ++CurPtr;
      while (*CurPtr && *CurPtr != ')')
        ++CurPtr;

      // If no close parenthesis, it's a bad token, return it as an error.
      if (*CurPtr++ != ')') {
        CurPtr = TokStart + 1;
        LexError("unclosed nan literal");
        return tok::Error;
      }

      StringRef PayloadStr(Payload, CurPtr - Payload);
      APInt Val;
      if (PayloadStr.consume_front("0x") && PayloadStr.getAsInteger(16, Val)) {
        StrVal.assign(TokStart, CurPtr - TokStart);
        // Drop the leading + from the string, as APFloat::convertFromString
        // doesn't support leading + sign.
        if (StrVal[0] == '+')
          StrVal.erase(0, 1);
        return tok::FloatLiteral;
      }
    }

    // Bad token, return it as an error.
    LexError("bad payload format for nan literal");
    CurPtr = TokStart + 1;
    return tok::Error;
  }
  ++CurPtr;

  if (*CurPtr++ != 'x') {
    // Bad token, return it as an error.
    CurPtr = TokStart + 1;
    return tok::Error;
  }

  if (!isxdigit(static_cast<unsigned char>(CurPtr[0]))) {
    // Bad token, return it as an error.
    CurPtr = TokStart + 1;
    return tok::Error;
  }

  while (isxdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (*CurPtr != '.') {
    // Bad token, return it as an error.
    CurPtr = TokStart + 1;
    return tok::Error;
  }

  ++CurPtr; // Eat the .
  while (isxdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  if (*CurPtr != 'p' && *CurPtr != 'P') {
    // Bad token, return it as an error.
    CurPtr = TokStart + 1;
    return tok::Error;
  }

  ++CurPtr;
  if (*CurPtr == '+' || *CurPtr == '-')
    ++CurPtr;
  while (isdigit(static_cast<unsigned char>(CurPtr[0])))
    ++CurPtr;

  StrVal.assign(TokStart, CurPtr - TokStart);
  return tok::FloatLiteral;
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
