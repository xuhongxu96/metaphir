//===- PlanDialect.h - The mpir_plan dialect --------------------*- C++ -*-===//
//
// Match plans (see PlanOps.td).
//
// A type pattern of mpir_plan.check_type is an ArrayAttr whose first element
// is its TypePatternKind, then:
//
//   Primitive      Type::TypeID
//   Integer        width, byte (0 or 1)
//   MetaInteger    slot of the width, byte
//   Variable       slot
//   Pointer        address space (-1 for any), opaque (0 or 1)
//   Sequence       kind (0 array, 1 vector, 2 scalable vector), count,
//                  slot of the count (-1 if the count is fixed), element
//   Struct         packed, elements...
//   Function       variadic, return type, parameters...
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

namespace llvm {
namespace metaphir {
namespace mpir_plan {

enum class TypePatternKind : int64_t {
  Primitive = 0,
  Integer = 1,
  MetaInteger = 2,
  Variable = 3,
  Pointer = 4,
  Sequence = 5,
  Struct = 6,
  Function = 7,
};

} // namespace mpir_plan
} // namespace metaphir
} // namespace llvm

#include "metaphir/Dialect/Plan/PlanOpsDialect.h.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Plan/PlanOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Plan/PlanOps.h.inc"

#endif // METAPHIR_DIALECT_PLAN_PLANDIALECT_H
