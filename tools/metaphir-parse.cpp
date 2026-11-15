//===- metaphir-parse.cpp - Parse a MetaphIR pattern and print it ---------===//

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SurfacePrinter.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRParser.h"
#include "metaphir/Parser/PatternParser.h"
#include "mlir/IR/MLIRContext.h"
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

enum class Engine { Classic, MLIR };
static cl::opt<Engine>
    UseEngine("engine", cl::desc("The implementation to parse with"),
              cl::values(clEnumValN(Engine::Classic, "classic", "MetaphIR IR"),
                         clEnumValN(Engine::MLIR, "mlir", "the mpir dialect")),
              cl::init(Engine::MLIR), cl::cat(Category));

enum class Emit { Surface, MLIR };
static cl::opt<Emit> EmitKind(
    "emit", cl::desc("What to print (with --engine=mlir)"),
    cl::values(clEnumValN(Emit::Surface, "surface", "the pattern as parsed"),
               clEnumValN(Emit::MLIR, "mlir", "the module, as MLIR")),
    cl::init(Emit::Surface), cl::cat(Category));

static int parseWithMLIR(StringRef ToolName) {
  SourceMgr SM;
  SMDiagnostic Diag;
  mlir::MLIRContext Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module =
      parsePatternFile(InputFilename, SM, Context, Diag);
  if (!Module) {
    Diag.print(ToolName.data(), errs());
    return 1;
  }
  if (EmitKind == Emit::MLIR) {
    Module->print(outs());
    outs() << '\n';
    return 0;
  }
  mpir::PatternOp Pattern;
  for (mlir::Operation &Op : *Module->getBody())
    if (auto P = dyn_cast<mpir::PatternOp>(Op))
      Pattern = P;
  printSurfacePattern(outs(), Pattern);
  return 0;
}

int main(int Argc, char **Argv) {
  InitLLVM X(Argc, Argv);
  cl::HideUnrelatedOptions(Category);
  cl::SetVersionPrinter(
      [](raw_ostream &OS) { OS << "MetaphIR " METAPHIR_VERSION "\n"; });
  StringRef ToolName = sys::path::filename(Argv[0]);
  cl::ParseCommandLineOptions(Argc, Argv,
                              "Parse a MetaphIR pattern and print it\n");

  if (UseEngine == Engine::MLIR)
    return parseWithMLIR(ToolName);

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
