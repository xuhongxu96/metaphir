//===- Retrieval.h - Posting lookups of index queries -----------*- C++ -*-===//
//
// mpir-index-retrieval: the mpir_index.retrieve of each index query, which
// finds the functions its variants may match from the posting lists;
// mpir-index-factor: factors the lists every variant reads out of it.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_RETRIEVAL_H
#define METAPHIR_TRANSFORMS_RETRIEVAL_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace llvm {
namespace metaphir {

std::unique_ptr<mlir::Pass> createIndexRetrievalPass();
std::unique_ptr<mlir::Pass> createIndexFactorPass();
void registerIndexRetrievalPasses();

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_RETRIEVAL_H
