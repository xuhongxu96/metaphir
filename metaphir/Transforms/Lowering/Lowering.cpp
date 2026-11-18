//===- Lowering.cpp - Lower surface patterns
//--------------------------------===//
//
// See Lowering.h. The passes are in a file each; this one has what they have
// in common as a whole: the pipeline, its registration and the driver.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/Lowering.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Transforms/Lowering/CheckBindings.h"
#include "metaphir/Transforms/Lowering/DesugarMetaFlags.h"
#include "metaphir/Transforms/Lowering/ExpandMatchers.h"
#include "metaphir/Transforms/Lowering/LowerAlternatives.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

SmallVector<mlir::Operation *, 4> getPatternRoots(mlir::Block &Block) {
  using namespace mpir;
  using mlir::Operation;
  SmallVector<Operation *, 4> Roots;
  for (Operation &Op : Block) {
    if (!isa<InstOp, AltOp>(Op))
      continue;
    bool Used = any_of(Op.getResult(0).getUses(), [](mlir::OpOperand &Use) {
      Operation *Owner = Use.getOwner();
      if (isa<YieldOp>(Owner))
        return true;
      if (auto Inst = dyn_cast<InstOp>(Owner)) {
        for (const MatcherOperandView &O : getMatcherOperands(Inst))
          if (isValueOperand(O.Kind) && O.Val == Use.get())
            return true;
      }
      return false;
    });
    if (!Used)
      Roots.push_back(&Op);
  }
  return Roots;
}

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
