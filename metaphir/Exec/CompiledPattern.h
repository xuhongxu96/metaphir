//===- CompiledPattern.h - A pattern, ready to match ------------*- C++ -*-===//
//
// A pattern parsed into the mpir dialect and run through the pipeline:
// lowered, with its match plan (mpir_plan) and its index query (mpir_index,
// with what the constraints say of instructions required as features, and
// its retrieval from the posting lists), each compiled for running.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_COMPILEDPATTERN_H
#define METAPHIR_EXEC_COMPILEDPATTERN_H

#include "metaphir/Exec/IndexQuery.h"
#include "metaphir/Exec/PlanProgram.h"
#include "metaphir/Index/Retrieval.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OwningOpRef.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include <memory>

namespace llvm {
namespace metaphir {

/// Which passes the pipeline runs besides those it needs; all by default.
struct PipelineOptions {
  /// mpir-index-structuralize.
  bool Structuralize = true;
  /// mpir-index-factor.
  bool Factor = true;
};

/// Once compiled, the module is only read: threads may share a compiled
/// pattern, each matching with a PlanMatcher of its own, and filtering with
/// an IndexQuery of its own (see makeQuery).
struct CompiledPattern {
  /// The pattern's source, which the module's locations point into.
  SourceMgr Source;
  std::unique_ptr<mlir::MLIRContext> Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module;
  std::unique_ptr<PlanProgram> Program;
  std::unique_ptr<IndexQuery> Query;
  /// How an index finds the functions the query may admit.
  RetrievalPlan Retrieval;

  /// Another IndexQuery of the module's query, as Query, for another thread.
  std::unique_ptr<IndexQuery> makeQuery() const;

  /// Compiles the pattern in Buffer. Errors are printed to Err, as the
  /// parser prints them (with ProgName, if given); null on error. Warnings
  /// go to Source's diagnostic handler, which the caller may set through
  /// SetUp before parsing.
  static std::unique_ptr<CompiledPattern>
  compile(std::unique_ptr<MemoryBuffer> Buffer, raw_ostream &Err,
          const char *ProgName = nullptr, PipelineOptions Options = {},
          function_ref<void(SourceMgr &)> SetUp = nullptr);
  /// Compiles the pattern in the file Filename.
  static std::unique_ptr<CompiledPattern>
  compileFile(StringRef Filename, raw_ostream &Err,
              const char *ProgName = nullptr, PipelineOptions Options = {},
              function_ref<void(SourceMgr &)> SetUp = nullptr);
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_COMPILEDPATTERN_H
