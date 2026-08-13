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
  if (Argc != 2) {
    errs() << "usage: metaphir-lex <input>\n";
    return 1;
  }

  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Argv[1]);
  if (!Buffer) {
    errs() << Argv[1] << ": " << Buffer.getError().message() << '\n';
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
