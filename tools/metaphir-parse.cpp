//===- metaphir-parse.cpp - Parse a MetaphIR pattern and print it ---------===//

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Pattern/SurfacePrinter.h"
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

enum class Emit { Surface, MLIR };
static cl::opt<Emit> EmitKind(
    "emit", cl::desc("What to print"),
    cl::values(clEnumValN(Emit::Surface, "surface", "the pattern as parsed"),
               clEnumValN(Emit::MLIR, "mlir", "the module, as MLIR")),
    cl::init(Emit::Surface), cl::cat(Category));
static cl::opt<bool> NoStdLib(
    "no-stdlib",
    cl::desc("With --emit=mlir, leave out the standard library's definitions "
             "(the module printed then refers to some it does not have)"),
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
  mlir::MLIRContext Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module =
      parsePatternFile(InputFilename, SM, Context, Diag);
  if (!Module) {
    Diag.print(ToolName.data(), errs());
    return 1;
  }
  if (EmitKind == Emit::MLIR) {
    if (NoStdLib) {
      // The pattern's file is SM's main buffer; the library's is another.
      for (mlir::Operation &Op :
           llvm::make_early_inc_range(*Module->getBody())) {
        SMRange Range = getSourceRange(Op.getLoc());
        if (Range.Start.isValid() &&
            SM.FindBufferContainingLoc(Range.Start) != SM.getMainFileID())
          Op.erase();
      }
    }
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
