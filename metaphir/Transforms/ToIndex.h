//===- ToIndex.h - Compile lowered patterns into index queries --*- C++ -*-===//
//
// mpir-to-index: each lowered mpir.pattern of a module gets an
// mpir_index.query after it: what a function's features must have for the
// pattern to match it.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_TOINDEX_H
#define METAPHIR_TRANSFORMS_TOINDEX_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

std::unique_ptr<mlir::Pass> createToIndexPass();
void registerToIndexPass();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_TOINDEX_H
