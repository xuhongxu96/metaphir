#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpImplementation.h"

using namespace mlir;
using namespace llvm::metaphir;
using namespace llvm::metaphir::mpir_expr;

#include "metaphir/Dialect/Expr/ExprOpsDialect.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Expr/ExprOps.cpp.inc"

void ExprDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Expr/ExprOps.cpp.inc"
      >();
}

static mpir::SortType sortType(OpBuilder &Builder, Sort S) {
  return mpir::SortType::get(Builder.getContext(), S);
}

void IntOp::build(OpBuilder &Builder, OperationState &State,
                  const llvm::APSInt &Value) {
  auto Type = IntegerType::get(Builder.getContext(), Value.getBitWidth(),
                               Value.isUnsigned() ? IntegerType::Unsigned
                                                  : IntegerType::Signed);
  build(Builder, State, sortType(Builder, Sort::Integer),
        IntegerAttr::get(Type, Value));
}

llvm::APSInt IntOp::getAPSInt() {
  IntegerAttr Value = getValueAttr();
  return llvm::APSInt(Value.getValue(), Value.getType().isUnsignedInteger());
}

void BoolOp::build(OpBuilder &Builder, OperationState &State, bool Value) {
  build(Builder, State, sortType(Builder, Sort::Boolean),
        Builder.getBoolAttr(Value));
}

void StrOp::build(OpBuilder &Builder, OperationState &State,
                  llvm::StringRef Value) {
  build(Builder, State, sortType(Builder, Sort::String),
        Builder.getStringAttr(Value));
}

LogicalResult CallOp::verify() {
  std::optional<Constraint::OperatorSchema> Schema =
      Constraint::getOperatorSchema(getOperatorID());
  if (!Schema)
    return emitOpError("has an unknown operator ") << getOp();
  if (getArgs().size() < Schema->MinArity ||
      getArgs().size() > Schema->MaxArity)
    return emitOpError("'")
           << Constraint::getOperatorName(getOperatorID()) << "' takes "
           << Schema->MinArity << " to " << Schema->MaxArity << " arguments";
  return success();
}

LogicalResult ApplyOp::verifySymbolUses(SymbolTableCollection &Symbols) {
  if (!Symbols.lookupNearestSymbolFrom<mpir::ConstraintDefOp>(*this,
                                                              getCalleeAttr()))
    return emitOpError("calls unknown constraint '") << getCallee() << "'";
  return success();
}
