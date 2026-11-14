//===- ExprDialect.h - The mpir_expr dialect --------------------*- C++ -*-===//
//
// Constraint expressions as MLIR (see ExprOps.td).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_EXPR_EXPRDIALECT_H
#define METAPHIR_DIALECT_EXPR_EXPRDIALECT_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constraint.h"
#include "llvm/ADT/APSInt.h"

#include "metaphir/Dialect/Expr/ExprOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Expr/ExprOps.h.inc"

#endif // METAPHIR_DIALECT_EXPR_EXPRDIALECT_H
