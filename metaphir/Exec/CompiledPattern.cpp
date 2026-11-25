#include "metaphir/Exec/CompiledPattern.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Exec/RetrievalCompiler.h"
#include "metaphir/Parser/PatternParser.h"
#include "metaphir/Transforms/Lowering/Lowering.h"
#include "metaphir/Transforms/ToIndex/Passes.h"
#include "metaphir/Transforms/ToPlan/Passes.h"
#include "mlir/Pass/PassManager.h"

namespace llvm {
namespace metaphir {

std::unique_ptr<CompiledPattern>
CompiledPattern::compile(std::unique_ptr<MemoryBuffer> Buffer, raw_ostream &Err,
                         const char *ProgName, PipelineOptions Options,
                         function_ref<void(SourceMgr &)> SetUp) {
  auto Compiled = std::make_unique<CompiledPattern>();
  if (SetUp)
    SetUp(Compiled->Source);
  // Each pattern has a context of its own, which the threads that share the
  // pattern share.
  Compiled->Context = std::make_unique<mlir::MLIRContext>();
  SMDiagnostic Diag;
  Compiled->Module = parsePatternBuffer(std::move(Buffer), Compiled->Source,
                                        *Compiled->Context, Diag);
  if (!Compiled->Module) {
    Diag.print(ProgName, Err, /*ShowColors=*/false);
    return nullptr;
  }
  if (mlir::failed(lowerPatternModule(*Compiled->Module, Compiled->Source, Err,
                                      ProgName)))
    return nullptr;
  mlir::PassManager PM(Compiled->Context.get());
  PM.addPass(createToPlanPass());
  PM.addPass(createToIndexPass());
  if (Options.Structuralize)
    PM.addPass(createIndexStructuralizePass());
  PM.addPass(createIndexRetrievalPass());
  if (Options.Factor)
    PM.addPass(createIndexFactorPass());
  // The passes leave a verified module, and a pattern that parsed has an
  // instruction, so it has a matcher and a query. The checks are for bugs.
  // LCOV_EXCL_START
  if (mlir::failed(PM.run(*Compiled->Module))) {
    if (ProgName)
      Err << ProgName << ": ";
    Err << "error: the pattern cannot be compiled\n";
    return nullptr;
  }
  for (auto Plan : Compiled->Module->getOps<mpir_plan::MatcherOp>())
    Compiled->Program = PlanProgram::compile(Plan);
  bool HasRetrieval = false;
  for (auto Query : Compiled->Module->getOps<mpir_index::QueryOp>()) {
    Compiled->Query = std::make_unique<IndexQuery>(Query);
    for (auto Retrieve :
         Query.getBody().front().getOps<mpir_index::RetrieveOp>()) {
      Compiled->Retrieval = compileRetrieval(Retrieve);
      HasRetrieval = true;
    }
  }
  if (!Compiled->Program || !Compiled->Query || !HasRetrieval) {
    if (ProgName)
      Err << ProgName << ": ";
    Err << "error: the pattern has no instructions\n";
    return nullptr;
  }
  // LCOV_EXCL_STOP
  return Compiled;
}

std::unique_ptr<IndexQuery> CompiledPattern::makeQuery() const {
  // Reading the module does not change it.
  mlir::ModuleOp M =
      const_cast<mlir::OwningOpRef<mlir::ModuleOp> &>(Module).get();
  for (auto Query : M.getOps<mpir_index::QueryOp>())
    return std::make_unique<IndexQuery>(Query);
  return nullptr;
}

std::unique_ptr<CompiledPattern>
CompiledPattern::compileFile(StringRef Filename, raw_ostream &Err,
                             const char *ProgName, PipelineOptions Options,
                             function_ref<void(SourceMgr &)> SetUp) {
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Filename);
  if (!Buffer) {
    SMDiagnostic(Filename, SourceMgr::DK_Error,
                 "cannot read file: " + Buffer.getError().message())
        .print(ProgName, Err, /*ShowColors=*/false);
    return nullptr;
  }
  return compile(std::move(*Buffer), Err, ProgName, Options, SetUp);
}

} // namespace metaphir
} // namespace llvm
