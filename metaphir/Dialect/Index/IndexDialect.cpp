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

ArrayAttr llvm::metaphir::mpir_index::encodeSite(MLIRContext *Context,
                                                 const Site &S) {
  Builder B(Context);
  return B.getArrayAttr({B.getI64IntegerAttr(S.Node), B.getI64IntegerAttr(S.ID),
                         B.getI64IntegerAttr(S.Positions)});
}

llvm::metaphir::Site llvm::metaphir::mpir_index::decodeSite(Attribute A) {
  auto Site = cast<ArrayAttr>(A);
  auto Element = [&](unsigned I) {
    return cast<IntegerAttr>(Site[I]).getInt();
  };
  return {Element(0), llvm::metaphir::instruction::InstructionID(Element(1)),
          uint8_t(Element(2))};
}
