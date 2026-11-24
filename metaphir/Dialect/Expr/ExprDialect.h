//===- ExprDialect.h - The mpir_expr dialect --------------------*- C++ -*-===//
//
// Constraint expressions as MLIR (see ExprOps.td).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_EXPR_EXPRDIALECT_H
#define METAPHIR_DIALECT_EXPR_EXPRDIALECT_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Sort.h"
#include "llvm/ADT/APSInt.h"

#include "metaphir/Dialect/Expr/ExprOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Expr/ExprOps.h.inc"

namespace llvm {
namespace metaphir {
namespace mpir_expr {

/// A non-negative literal is unsigned and a negative one signed, each at
/// least 64 bits wide, as constraint literals are.
APSInt normalizeLiteral(const APSInt &Number);

/// The literal that reading the constant Constant as ReadAs gives: a boolean
/// if a one-bit constant is read as one, else an integer.
mlir::Value createLiteral(mlir::OpBuilder &Builder, mlir::Location Loc,
                          mpir::IntOp Constant, Sort ReadAs);

} // namespace mpir_expr
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_EXPR_EXPRDIALECT_H
