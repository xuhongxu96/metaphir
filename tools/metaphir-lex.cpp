//===- metaphir-lex.cpp - Print the tokens of a MetaphIR file -------------===//

#include "metaphir/Parser/MIRLexer.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::metaphir;

static cl::OptionCategory Category("metaphir-lex options");
static cl::opt<std::string> InputFilename(cl::Positional, cl::Required,
                                          cl::desc("<input>"),
                                          cl::cat(Category));
static cl::opt<bool>
    LineNumbers("line-numbers",
                cl::desc("Prefix each token with its line number"),
                cl::cat(Category));

template <typename T>
static void printTokenValue(raw_ostream &OS, const T &Value) {
  OS << " " << Value;
}

int main(int Argc, char **Argv) {
  InitLLVM X(Argc, Argv);
  cl::HideUnrelatedOptions(Category);
  cl::SetVersionPrinter(
      [](raw_ostream &OS) { OS << "MetaphIR " METAPHIR_VERSION "\n"; });
  StringRef ToolName = sys::path::filename(Argv[0]);
  cl::ParseCommandLineOptions(Argc, Argv,
                              "Print the tokens of a MetaphIR file\n");

  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(InputFilename);
  if (!Buffer) {
    errs() << ToolName << ": " << InputFilename << ": "
           << Buffer.getError().message() << '\n';
    return 1;
  }

  SourceMgr SM;
  unsigned BufferID = SM.AddNewSourceBuffer(std::move(*Buffer), SMLoc());
  SMDiagnostic Diag;
  MIRLexer Lexer(SM.getMemoryBuffer(BufferID)->getBuffer(), SM, Diag);

  while (true) {
    tok::Kind Kind = Lexer.Lex();
    if (Kind == tok::Newline)
      continue;
    if (LineNumbers)
      outs() << SM.FindLineNumber(Lexer.getLoc(), BufferID) << ": ";
    outs() << tok::getTokenKindName(Kind);
    switch (tok::getValueKind(Kind)) {
    case tok::ValueKind::None:
      break;
    case tok::ValueKind::UIntVal:
      printTokenValue(outs(), Lexer.getUIntVal());
      break;
    case tok::ValueKind::StrVal:
      printTokenValue(outs(), Lexer.getStrVal());
      break;
    case tok::ValueKind::TyVal:
      printTokenValue(outs(), Lexer.getTyVal());
      break;
    case tok::ValueKind::APFloatVal:
      printTokenValue(outs(), Lexer.getAPFloatVal());
      break;
    case tok::ValueKind::APSIntVal:
      printTokenValue(outs(), Lexer.getAPSIntVal());
      break;
    }
    outs() << '\n';
    if (Kind == tok::Eof || Kind == tok::Error)
      break;
  }

  if (!Lexer.hasError())
    return 0;
  // Keep the tokens before the error in order with it.
  outs().flush();
  Diag.print(ToolName.data(), errs());
  return 1;
}
