//===- IndexDialect.h - The mpir_index dialect ------------------*- C++ -*-===//
//
// Index queries (see IndexOps.td).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_INDEX_INDEXDIALECT_H
#define METAPHIR_DIALECT_INDEX_INDEXDIALECT_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Site.h"
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "metaphir/Dialect/Index/IndexOpsDialect.h.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Index/IndexOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Index/IndexOps.h.inc"

namespace llvm {
namespace metaphir {
namespace mpir_index {

/// An mpir_index.sites element: [node, opcode, slots].
mlir::ArrayAttr encodeSite(mlir::MLIRContext *Context, const Site &S);
Site decodeSite(mlir::Attribute A);

} // namespace mpir_index
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_INDEX_INDEXDIALECT_H
