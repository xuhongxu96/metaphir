//===- Lowering.h - Lower surface patterns ----------------------*- C++ -*-===//
//
// The lowering pipeline ("mpir-lower") and its driver. The passes, in the
// order it runs them, are declared in Passes.td: surface mpir (metaflags,
// mpir.use, ':c' and ':o') → lowered mpir, in which every choice a match makes
// is an mpir.alt.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_LOWERING_H
#define METAPHIR_TRANSFORMS_LOWERING_LOWERING_H

#include "metaphir/Transforms/Lowering/Passes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Support/LLVM.h"
#include <memory>

namespace llvm {
class SourceMgr;
class raw_ostream;
namespace metaphir {

/// Adds the lowering passes, in order, to PM.
void buildLoweringPipeline(mlir::OpPassManager &PM);

/// Registers the "mpir-lower" pipeline with mlir-opt; registerLoweringPasses()
/// registers its passes.
void registerLoweringPipeline();

/// Lowers Module in place. Diagnostics are printed to OS as the parser
/// prints its own, from the pattern source in SM. Returns failure if
/// lowering reported an error.
mlir::LogicalResult lowerPatternModule(mlir::ModuleOp Module,
                                       const SourceMgr &SM, raw_ostream &OS,
                                       const char *ProgName = nullptr);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_LOWERING_H
