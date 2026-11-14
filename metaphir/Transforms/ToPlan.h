//===- ToPlan.h - Compile lowered patterns into match plans -----*- C++ -*-===//
//
// mpir-to-plan: each lowered mpir.pattern of a module gets an
// mpir_plan.matcher after it, the plan that matches it.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_TOPLAN_H
#define METAPHIR_TRANSFORMS_TOPLAN_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

std::unique_ptr<mlir::Pass> createToPlanPass();
void registerToPlanPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_TOPLAN_H
