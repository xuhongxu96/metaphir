//===- ExpandMatchers.h - mpir-expand-matchers ------------------*- C++ -*-===//
//
// See Lowering.h.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_EXPANDMATCHERS_H
#define METAPHIR_TRANSFORMS_LOWERING_EXPANDMATCHERS_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

/// The mpir-expand-matchers pass. Replaces each use of a 'match' matcher by an
/// mpir.alt of the branches the use can match, inlined.
std::unique_ptr<mlir::Pass> createExpandMatchersPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_EXPANDMATCHERS_H
