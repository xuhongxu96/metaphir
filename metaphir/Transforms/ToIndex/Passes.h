//===- Passes.h - ToIndex passes --------------------------------*- C++ -*-===//
//
// ToIndex: lowered mpir → mpir_index, and passes over mpir_index.
// Passes.td declares the passes: what each reads and writes, and the
// dialects each depends on. This declares create<Name>() for each, and
// registerToIndexPasses().
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_TOINDEX_PASSES_H
#define METAPHIR_TRANSFORMS_TOINDEX_PASSES_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

#define GEN_PASS_DECL
#include "metaphir/Transforms/ToIndex/Passes.h.inc"

#define GEN_PASS_REGISTRATION
#include "metaphir/Transforms/ToIndex/Passes.h.inc"

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_TOINDEX_PASSES_H
