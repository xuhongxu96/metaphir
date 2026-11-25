#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace llvm::metaphir::mpir_plan;

#include "metaphir/Dialect/Plan/PlanOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Plan/PlanOpsTypes.cpp.inc"

#include "metaphir/Dialect/Plan/PlanEnums.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Plan/PlanOps.cpp.inc"

LogicalResult LetOp::verify() {
  // The condition is what the interpreter checks when the slot is bound
  // already: the slot's binding (read as the value is) == the value.
  auto Equal = getCondition().getDefiningOp<mpir_expr::CallOp>();
  auto Read = Equal && Equal.getOperatorID() == constraint::O_Equal &&
                      Equal.getArgs().size() == 2 &&
                      Equal.getArgs()[1] == getValue()
                  ? Equal.getArgs()[0].getDefiningOp<mpir_expr::ReadOp>()
                  : nullptr;
  auto Slot = Read ? Read.getValue().getDefiningOp<SlotOp>() : nullptr;
  if (!Slot || Slot.getSlot() != getSlot())
    return emitOpError("condition must be that slot ")
           << getSlot() << "'s binding is the value";
  return success();
}

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
