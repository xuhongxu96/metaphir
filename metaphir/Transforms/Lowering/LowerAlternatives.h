//===- LowerAlternatives.h - mpir-lower-alternatives ------------*- C++ -*-===//
//
// See Lowering.h.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_LOWERALTERNATIVES_H
#define METAPHIR_TRANSFORMS_LOWERING_LOWERALTERNATIVES_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

/// The mpir-lower-alternatives pass. Turns ':c' and ':o' on built-in
/// instruction matchers into mpir.alt.
std::unique_ptr<mlir::Pass> createLowerAlternativesPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_LOWERALTERNATIVES_H
