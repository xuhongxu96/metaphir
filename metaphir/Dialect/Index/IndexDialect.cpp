#include "metaphir/Dialect/Index/IndexDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace llvm::metaphir::mpir_index;

#include "metaphir/Dialect/Index/IndexOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Index/IndexOpsTypes.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Index/IndexOps.cpp.inc"

void IndexDialect::initialize() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "metaphir/Dialect/Index/IndexOpsTypes.cpp.inc"
      >();
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Index/IndexOps.cpp.inc"
      >();
}
