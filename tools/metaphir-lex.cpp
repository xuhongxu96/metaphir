#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Type.h"
#include "metaphir/Parser/MIRLexer.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::metaphir;

template <typename T>
static void printTokenValue(raw_ostream &OS, const T &Value) {
  OS << " " << Value;
}

static void printTokenValue(raw_ostream &OS, Type *Value) {
  if (Value)
    OS << " " << *Value;
}

int main(int Argc, char **Argv) {
  bool PrintLineNumbers = false;
  const char *Filename = nullptr;
  for (int i = 1; i < Argc; ++i) {
    if (StringRef(Argv[i]) == "--line-numbers") {
      PrintLineNumbers = true;
    } else if (!Filename) {
      Filename = Argv[i];
    } else {
      errs() << "usage: metaphir-lex [--line-numbers] <input>\n";
      return 1;
    }
  }

  if (!Filename) {
    errs() << "usage: metaphir-lex [--line-numbers] <input>\n";
    return 1;
  }

  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Filename);
  if (!Buffer) {
    errs() << Filename << ": " << Buffer.getError().message() << '\n';
    return 1;
  }

  SourceMgr SM;
  SM.AddNewSourceBuffer(std::move(*Buffer), SMLoc());
  SMDiagnostic Error;
  MIRContext Context;
  MIRLexer Lexer(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM, Error,
                 Context);

  while (true) {
    tok::Kind Kind = Lexer.Lex();
    if (Kind == tok::Newline)
      continue;
    if (PrintLineNumbers) {
      unsigned Line = SM.FindLineNumber(Lexer.getLoc(), SM.getMainFileID());
      outs() << Line << ": ";
    }
    outs() << getTokenKindName(Kind);
    switch (Kind) {

#define MIR_TOKEN_KIND_HAS_VALUE(Name, Value)                                  \
  case tok::Name:                                                              \
    printTokenValue(outs(), Lexer.get##Value());                               \
    break;
#include "metaphir/Parser/MIRTokenKinds.def"

    default:
      break;
    }
    outs() << '\n';
    if (Kind == tok::Kind::Eof)
      return 0;
    if (Kind == tok::Kind::Error) {
      Error.print(Argv[0], errs());
      return 1;
    }
  }
}
