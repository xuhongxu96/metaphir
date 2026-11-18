//===- Lowering.cpp - Lower surface patterns ------------------------------===//
//
// See Lowering.h. The passes are in a file each; this one has what they have
// in common as a whole: the pipeline, its registration and the driver.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/Lowering.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Transforms/Lowering/CheckBindings.h"
#include "metaphir/Transforms/Lowering/DesugarMetaFlags.h"
#include "metaphir/Transforms/Lowering/ExpandMatchers.h"
#include "metaphir/Transforms/Lowering/LowerAlternatives.h"
#include "mlir/Pass/PassManager.h"
#include "llvm/Support/SourceMgr.h"

namespace llvm {
namespace metaphir {

void buildLoweringPipeline(mlir::OpPassManager &PM) {
  PM.addPass(createDesugarMetaFlagsPass());
  PM.addPass(createExpandMatchersPass());
  PM.addPass(createLowerAlternativesPass());
  PM.addPass(createCheckBindingsPass());
}

void registerLoweringPasses() {
  mlir::registerPass(createDesugarMetaFlagsPass);
  mlir::registerPass(createExpandMatchersPass);
  mlir::registerPass(createLowerAlternativesPass);
  mlir::registerPass(createCheckBindingsPass);
  mlir::PassPipelineRegistration<>("mpir-lower",
                                   "Lower surface patterns to the lowered form",
                                   buildLoweringPipeline);
}

mlir::LogicalResult lowerPatternModule(mlir::ModuleOp Module,
                                       const SourceMgr &SM, raw_ostream &OS,
                                       const char *ProgName) {
  mlir::MLIRContext *Context = Module.getContext();
  // Diagnostics print as the parser's do, at the pattern source they are
  // about.
  mlir::ScopedDiagnosticHandler Handler(Context, [&](mlir::Diagnostic &Diag) {
    SMRange Range = getSourceRange(Diag.getLocation());
    std::string Message = Diag.str();
    // The passes report at single places: a variable, a use, a metaflag.
    if (Range.Start.isValid() && SM.FindBufferContainingLoc(Range.Start)) {
      SM.GetMessage(Range.Start, SourceMgr::DK_Error, Message)
          .print(ProgName, OS, /*ShowColors=*/false);
    } else {
      // An error about nothing in the source: none of the passes' own.
      // LCOV_EXCL_START
      if (ProgName)
        OS << ProgName << ": ";
      OS << "error: " << Message << "\n";
      // LCOV_EXCL_STOP
    }
    return mlir::success();
  });
  mlir::PassManager PM(Context);
  buildLoweringPipeline(PM);
  return PM.run(Module);
}

} // namespace metaphir
} // namespace llvm
