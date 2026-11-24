#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpImplementation.h"

using namespace mlir;
using namespace llvm::metaphir;
using namespace llvm::metaphir::mpir_expr;

#include "metaphir/Dialect/Expr/ExprOpsDialect.cpp.inc"

/// How an operator is written, as constraint::OperatorKind numbers them.
static constexpr llvm::StringLiteral KindNames[] = {"unary", "binary", "call"};

/// 'binary "=="': how the operator is written, and its name.
static ParseResult parseOperator(OpAsmParser &Parser, IntegerAttr &Op,
                                 IntegerAttr &Kind) {
  SMLoc Loc = Parser.getCurrentLocation();
  StringRef KindName;
  std::string Name;
  if (Parser.parseKeyword(&KindName) || Parser.parseString(&Name))
    return failure();
  const auto *It = llvm::find(KindNames, KindName);
  if (It == std::end(KindNames))
    return Parser.emitError(Loc) << "expected unary, binary or call";
  auto K = constraint::OperatorKind(It - std::begin(KindNames));
  constraint::OperatorID ID = constraint::getOperatorID(Name, K);
  if (ID == constraint::UnknownOperator)
    return Parser.emitError(Loc)
           << "unknown " << KindName << " operator '" << Name << "'";
  Op = Parser.getBuilder().getI32IntegerAttr(ID);
  Kind = Parser.getBuilder().getI32IntegerAttr(K);
  return success();
}

static void printOperator(OpAsmPrinter &Printer, Operation *, IntegerAttr Op,
                          IntegerAttr Kind) {
  uint64_t K = Kind.getValue().getZExtValue();
  if (K < std::size(KindNames))
    Printer << KindNames[K];
  else
    Printer << "<invalid " << K << ">";
  Printer << ' ';
  Printer.printString(constraint::getOperatorName(
      constraint::OperatorID(Op.getValue().getZExtValue())));
}

#define GET_OP_CLASSES
#include "metaphir/Dialect/Expr/ExprOps.cpp.inc"

void ExprDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Expr/ExprOps.cpp.inc"
      >();
}

void IntOp::build(OpBuilder &Builder, OperationState &State,
                  const llvm::APSInt &Value) {
  auto Type = IntegerType::get(Builder.getContext(), Value.getBitWidth(),
                               Value.isUnsigned() ? IntegerType::Unsigned
                                                  : IntegerType::Signed);
  build(Builder, State,
        mpir::SortType::get(Builder.getContext(), Sort::Integer),
        IntegerAttr::get(Type, Value));
}

llvm::APSInt IntOp::getAPSInt() {
  IntegerAttr Value = getValueAttr();
  return llvm::APSInt(Value.getValue(), Value.getType().isUnsignedInteger());
}

llvm::APSInt mpir_expr::normalizeLiteral(const llvm::APSInt &Number) {
  bool Negative = Number.isSigned() && Number.isNegative();
  return Negative
             ? llvm::APSInt(Number.sextOrTrunc(
                                std::max(64u, Number.getSignificantBits())),
                            /*isUnsigned=*/false)
             : llvm::APSInt(
                   Number.zextOrTrunc(std::max(64u, Number.getActiveBits())),
                   /*isUnsigned=*/true);
}

Value mpir_expr::createLiteral(OpBuilder &Builder, Location Loc,
                               mpir::IntOp Constant, Sort ReadAs) {
  IntegerAttr Attr = Constant.getValueAttr();
  llvm::APSInt Number(Attr.getValue(), Attr.getType().isUnsignedInteger());
  if (ReadAs == Sort::Boolean && Number.getBitWidth() == 1)
    return BoolOp::create(Builder, Loc, !Number.isZero());
  return IntOp::create(Builder, Loc, normalizeLiteral(Number));
}

void BoolOp::build(OpBuilder &Builder, OperationState &State, bool Value) {
  build(Builder, State,
        mpir::SortType::get(Builder.getContext(), Sort::Boolean),
        Builder.getBoolAttr(Value));
}

void StrOp::build(OpBuilder &Builder, OperationState &State,
                  llvm::StringRef Value) {
  build(Builder, State, mpir::SortType::get(Builder.getContext(), Sort::String),
        Builder.getStringAttr(Value));
}

LogicalResult CallOp::verify() {
  std::optional<constraint::OperatorSchema> Schema =
      constraint::getOperatorSchema(getOperatorID());
  if (!Schema)
    return emitOpError("has an unknown operator ") << getOp();
  if (getArgs().size() < Schema->MinArity ||
      getArgs().size() > Schema->MaxArity)
    return emitOpError("'")
           << constraint::getOperatorName(getOperatorID()) << "' takes "
           << Schema->MinArity << " to " << Schema->MaxArity << " arguments";
  return success();
}

LogicalResult ApplyOp::verifySymbolUses(SymbolTableCollection &Symbols) {
  if (!Symbols.lookupNearestSymbolFrom<mpir::ConstraintDefOp>(*this,
                                                              getCalleeAttr()))
    return emitOpError("calls unknown constraint '") << getCallee() << "'";
  return success();
}
