#include "metaphir/Dialect/Index/IndexDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"

using namespace mlir;
using namespace llvm::metaphir::mpir_index;

#include "metaphir/Dialect/Index/IndexOpsDialect.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Index/IndexOps.cpp.inc"

void IndexDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Index/IndexOps.cpp.inc"
      >();
}
