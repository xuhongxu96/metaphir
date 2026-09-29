//===- metaphir-parse.cpp - Parse a MetaphIR pattern and print it ---------===//

#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::metaphir;

static cl::OptionCategory Category("metaphir-parse options");
static cl::opt<std::string> InputFilename(cl::Positional, cl::Required,
                                          cl::desc("<pattern>"),
                                          cl::cat(Category));

int main(int Argc, char **Argv) {
  InitLLVM X(Argc, Argv);
  cl::HideUnrelatedOptions(Category);
  cl::SetVersionPrinter(
      [](raw_ostream &OS) { OS << "MetaphIR " METAPHIR_VERSION "\n"; });
  StringRef ToolName = sys::path::filename(Argv[0]);
  cl::ParseCommandLineOptions(Argc, Argv,
                              "Parse a MetaphIR pattern and print it\n");

  SourceMgr SM;
  SMDiagnostic Diag;
  MIRContext Context;
  Pattern *P = nullptr;
  if (parseMIRFile(InputFilename, SM, Context, P, Diag)) {
    Diag.print(ToolName.data(), errs());
    return 1;
  }
  outs() << *P;
  return 0;
}
