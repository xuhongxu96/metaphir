//===- RetrievalCompiler.h - Compile index retrievals -----------*- C++ -*-===//
//
// The retrieval plan of an mpir_index.retrieve, for finding candidate
// functions in an index. The plan is in metaphir-index-core, which reads
// indexes without MLIR; compiling it from the dialect is here.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_RETRIEVALCOMPILER_H
#define METAPHIR_EXEC_RETRIEVALCOMPILER_H

#include "metaphir/Index/Retrieval.h"

namespace llvm {
namespace metaphir {

namespace mpir_index {
class RetrieveOp;
} // namespace mpir_index

/// The retrieval plan of Retrieve's set expression.
RetrievalPlan compileRetrieval(mpir_index::RetrieveOp Retrieve);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_RETRIEVALCOMPILER_H
