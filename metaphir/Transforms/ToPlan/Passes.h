//===- Passes.h - ToPlan passes ---------------------------------*- C++ -*-===//
//
// ToPlan: lowered mpir → mpir_plan.
// Passes.td declares the passes: what each reads and writes, and the
// dialects each depends on. This declares create<Name>() for each, and
// registerToPlanPasses().
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_TOPLAN_PASSES_H
#define METAPHIR_TRANSFORMS_TOPLAN_PASSES_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

#define GEN_PASS_DECL
#include "metaphir/Transforms/ToPlan/Passes.h.inc"

#define GEN_PASS_REGISTRATION
#include "metaphir/Transforms/ToPlan/Passes.h.inc"

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_TOPLAN_PASSES_H
