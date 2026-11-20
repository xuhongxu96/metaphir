//===- Passes.h - Lowering passes -------------------------------*- C++ -*-===//
//
// Lowering: surface mpir → lowered mpir.
// Passes.td declares the passes: what each reads and writes, and the
// dialects each depends on. This declares create<Name>() for each, and
// registerLoweringPasses().
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_PASSES_H
#define METAPHIR_TRANSFORMS_LOWERING_PASSES_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

#define GEN_PASS_DECL
#include "metaphir/Transforms/Lowering/Passes.h.inc"

#define GEN_PASS_REGISTRATION
#include "metaphir/Transforms/Lowering/Passes.h.inc"

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_PASSES_H
