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
#include "metaphir/Exec/PlanMatcher.h"
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

struct CompiledPattern {
  /// The pattern's source, which the module's locations point into.
  SourceMgr Source;
  std::unique_ptr<mlir::MLIRContext> Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module;
  std::unique_ptr<PlanProgram> Program;
  std::unique_ptr<IndexQuery> Query;

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
