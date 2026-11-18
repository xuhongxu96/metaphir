//===- CheckBindings.h - mpir-check-bindings --------------------*- C++ -*-===//
//
// See Lowering.h.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_CHECKBINDINGS_H
#define METAPHIR_TRANSFORMS_LOWERING_CHECKBINDINGS_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

/// The mpir-check-bindings pass. Checks that a named meta variable is bound
/// whichever alternative ':o' takes.
std::unique_ptr<mlir::Pass> createCheckBindingsPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_CHECKBINDINGS_H
