//===- DesugarMetaFlags.h - mpir-desugar-metaflags --------------*- C++ -*-===//
//
// See Lowering.h.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_DESUGARMETAFLAGS_H
#define METAPHIR_TRANSFORMS_LOWERING_DESUGARMETAFLAGS_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

/// The mpir-desugar-metaflags pass. Turns the metaflags of the matchers into
/// constraints (mpir.require): a flag a metaflag definition has is the
/// definition's body, read on the flag's subject. ':c' and ':o', which are
/// structural, are left as they are.
std::unique_ptr<mlir::Pass> createDesugarMetaFlagsPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_DESUGARMETAFLAGS_H
