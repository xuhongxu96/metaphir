#include "metaphir/Exec/CompiledPattern.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Parser/PatternParser.h"
#include "metaphir/Transforms/Lowering.h"
#include "metaphir/Transforms/Retrieval.h"
#include "metaphir/Transforms/Structuralize.h"
#include "metaphir/Transforms/ToIndex.h"
#include "metaphir/Transforms/ToPlan.h"
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
  // Each pattern has a context of its own, and is used by one thread.
  Compiled->Context = std::make_unique<mlir::MLIRContext>(
      mlir::MLIRContext::Threading::DISABLED);
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
  if (mlir::failed(PM.run(*Compiled->Module))) {
    if (ProgName)
      Err << ProgName << ": ";
    Err << "error: the pattern cannot be compiled\n";
    return nullptr;
  }
  for (auto Plan : Compiled->Module->getOps<mpir_plan::MatcherOp>())
    Compiled->Program = PlanProgram::compile(Plan);
  for (auto Query : Compiled->Module->getOps<mpir_index::QueryOp>())
    Compiled->Query = std::make_unique<IndexQuery>(Query);
  if (!Compiled->Program || !Compiled->Query) {
    if (ProgName)
      Err << ProgName << ": ";
    Err << "error: the pattern has no instructions\n";
    return nullptr;
  }
  return Compiled;
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
