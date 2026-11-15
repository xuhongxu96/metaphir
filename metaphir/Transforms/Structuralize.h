//===- Structuralize.h - Constraints the index can look up ------*- C++ -*-===//
//
// mpir-index-structuralize: what an index query's constraints say of the
// kind of an instruction, or of the intrinsic a call calls, becomes features
// its variants require, which the corpus index has posting lists of.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_STRUCTURALIZE_H
#define METAPHIR_TRANSFORMS_STRUCTURALIZE_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

std::unique_ptr<mlir::Pass> createIndexStructuralizePass();
void registerIndexStructuralizePass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_STRUCTURALIZE_H
