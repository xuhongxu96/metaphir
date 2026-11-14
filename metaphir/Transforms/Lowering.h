//===- Lowering.h - Lower surface patterns ----------------------*- C++ -*-===//
//
// The passes that lower the surface form of a pattern (as parsed) to the
// lowered form the match plan is compiled from:
//
//   mpir-desugar-metaflags   metaflags become constraints (mpir.require)
//   mpir-expand-matchers     a use of a 'match' matcher becomes an mpir.alt of
//                            its branches, inlined (and both operand orders,
//                            with ':c')
//   mpir-lower-alternatives  ':c' and ':o' on built-in instruction matchers
//                            become mpir.alt
//   mpir-check-bindings      a named meta variable is bound whichever
//                            alternative ':o' takes
//
// The lowered form has no metaflags, no mpir.use and no ':c' or ':o': every
// choice a match makes is an mpir.alt.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_H
#define METAPHIR_TRANSFORMS_LOWERING_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Support/LLVM.h"
#include <memory>

namespace llvm {
class SourceMgr;
class raw_ostream;
namespace metaphir {

std::unique_ptr<mlir::Pass> createDesugarMetaFlagsPass();
std::unique_ptr<mlir::Pass> createExpandMatchersPass();
std::unique_ptr<mlir::Pass> createLowerAlternativesPass();
std::unique_ptr<mlir::Pass> createCheckBindingsPass();

/// The instruction matchers and alternatives of Block (of a lowered pattern,
/// or of an alternative) that no other matcher uses as an operand: those a
/// match of the block starts from.
SmallVector<mlir::Operation *, 4> getPatternRoots(mlir::Block &Block);

/// Adds the lowering passes, in order, to PM.
void buildLoweringPipeline(mlir::OpPassManager &PM);

/// Registers the passes and the "mpir-lower" pipeline with mlir-opt.
void registerLoweringPasses();

/// Lowers Module in place. Diagnostics are printed to OS as the parser
/// prints its own, from the pattern source in SM. Returns failure if
/// lowering reported an error.
mlir::LogicalResult lowerPatternModule(mlir::ModuleOp Module,
                                       const SourceMgr &SM, raw_ostream &OS,
                                       const char *ProgName = nullptr);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_H
