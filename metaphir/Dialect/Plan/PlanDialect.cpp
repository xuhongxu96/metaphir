#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace llvm::metaphir::mpir_plan;

#include "metaphir/Dialect/Plan/PlanOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Plan/PlanOpsTypes.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Plan/PlanOps.cpp.inc"

void PlanDialect::initialize() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "metaphir/Dialect/Plan/PlanOpsTypes.cpp.inc"
      >();
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Plan/PlanOps.cpp.inc"
      >();
}
