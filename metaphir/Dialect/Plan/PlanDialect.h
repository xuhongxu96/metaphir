//===- PlanDialect.h - The mpir_plan dialect --------------------*- C++ -*-===//
//
// Match plans (see PlanOps.td).
//
// Its slots and type patterns are the pattern's (see Pattern/Bindings.h).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PLAN_PLANDIALECT_H
#define METAPHIR_DIALECT_PLAN_PLANDIALECT_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "metaphir/Dialect/Plan/PlanEnums.h.inc"

#include "metaphir/Dialect/Plan/PlanOpsDialect.h.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Plan/PlanOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Plan/PlanOps.h.inc"

#endif // METAPHIR_DIALECT_PLAN_PLANDIALECT_H
