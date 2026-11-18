//===- DesugarMetaFlags.cpp - mpir-desugar-metaflags ----------------------===//
//
// See Lowering.h: metaflags become constraints (mpir.require).
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/DesugarMetaFlags.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Transforms/Lowering/LoweringUtils.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"

namespace llvm {
namespace metaphir {
namespace lowering {

using namespace mpir;

/// A non-negative literal is unsigned and a negative one signed, each at
/// least 64 bits wide, as constraint literals are.
static APSInt normalizeLiteral(const APSInt &Number) {
  bool Negative = Number.isSigned() && Number.isNegative();
  return Negative
             ? APSInt(Number.sextOrTrunc(
                          std::max(64u, Number.getSignificantBits())),
                      /*isUnsigned=*/false)
             : APSInt(Number.zextOrTrunc(std::max(64u, Number.getActiveBits())),
                      /*isUnsigned=*/true);
}

//===----------------------------------------------------------------------===//
// mpir-desugar-metaflags
//===----------------------------------------------------------------------===//

/// Anchors the value-tracking operators of the expression C that have none at
/// Anchor, as setDefaultContextInstruction does.
static void setDefaultAnchor(Value C, Value Anchor,
                             DenseSet<Operation *> &Visited) {
  Operation *Def = C.getDefiningOp();
  if (!Def || !isa<mpir_expr::ExprDialect>(Def->getDialect()) ||
      !Visited.insert(Def).second)
    return;
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def))
    if (!Call.getAnchor() && Anchor)
      Call.getAnchorMutable().assign(Anchor);
  if (isa<mpir_expr::ReadOp>(Def))
    return;
  for (Value Operand : Def->getOperands())
    if (Operand != Anchor)
      setDefaultAnchor(Operand, Anchor, Visited);
}

namespace {
class Desugarer {
public:
  Desugarer(mlir::ModuleOp Module)
      : Module(Module), Builder(Module.getContext()) {}

  /// Desugars the metaflags of the matchers in Block, inserting their
  /// constraints before the block's first constraint.
  LogicalResult desugarBlock(mlir::Block &Block);

private:
  mlir::ModuleOp Module;
  OpBuilder Builder;

  mlir::FailureOr<Value> lower(MetaFlagAttr Flag, Value Subject);
  mlir::FailureOr<Value> lowerDefined(MetaFlagAttr Flag, MetaFlagDefOp Def,
                                      Value Subject);
  mlir::InFlightDiagnostic error(MetaFlagAttr Flag) {
    return mlir::emitError(Location(Flag.getLoc()));
  }
};
} // namespace

mlir::FailureOr<Value> Desugarer::lower(MetaFlagAttr Flag, Value Subject) {
  StringRef Name = Flag.getName().getValue();
  Location Loc(Flag.getLoc());
  if (!Subject)
    return error(Flag) << "metaflag ':" << Name
                       << "' has no value to use as its subject";
  mlir::MLIRContext *Context = Builder.getContext();
  auto BooleanType = SortType::get(Context, Sort::Boolean);
  switch (metaflag::getMetaFlagID(Name)) {
  case metaflag::MF_not: {
    auto Inner = dyn_cast<MetaFlagAttr>(Flag.getArgs()[0]);
    mlir::FailureOr<Value> Lowered = lower(Inner, Subject);
    if (mlir::failed(Lowered))
      return mlir::failure();
    return Value(mpir_expr::CallOp::create(
        Builder, Loc, BooleanType, unsigned(constraint::O_Not),
        unsigned(constraint::Unary), ValueRange{*Lowered}, Value()));
  }
  case metaflag::MF_or: {
    Value Result;
    for (Attribute A : Flag.getArgs()) {
      mlir::FailureOr<Value> Lowered = lower(cast<MetaFlagAttr>(A), Subject);
      if (mlir::failed(Lowered))
        return mlir::failure();
      Result = Result ? Value(mpir_expr::CallOp::create(
                            Builder, Loc, BooleanType,
                            unsigned(constraint::O_LogicalOr),
                            unsigned(constraint::Binary),
                            ValueRange{Result, *Lowered}, Value()))
                      : *Lowered;
    }
    return Result;
  }
  case metaflag::MF_c:
  case metaflag::MF_o:
    llvm_unreachable("structural flags are not constraints");
  case metaflag::UnknownMetaFlag: {
    auto Def = dyn_cast_or_null<MetaFlagDefOp>(
        mlir::SymbolTable::lookupSymbolIn(Module, Name));
    if (!Def)
      return error(Flag) << "unknown metaflag ':" << Name << "'";
    return lowerDefined(Flag, Def, Subject);
  }
  }
}

mlir::FailureOr<Value>
Desugarer::lowerDefined(MetaFlagAttr Flag, MetaFlagDefOp Def, Value Subject) {
  StringRef Name = Flag.getName().getValue();
  ArrayRef<Attribute> Args = Flag.getArgs().getValue();
  unsigned NumArguments = Def.getParamNames().size() - 1;
  if (Args.size() != NumArguments)
    return error(Flag) << "metaflag ':" << Name << "' expects " << NumArguments
                       << " arguments, got " << Args.size();
  mlir::Block &Body = Def.getBody().front();
  mlir::MLIRContext *Context = Builder.getContext();

  for (Attribute A : Args)
    if (!isa<mlir::IntegerAttr>(A))
      return error(Flag) << "metaflag ':" << Name
                         << "' expects integer arguments";

  // Clone the body, reading the subject as it is, and the arguments as
  // literals.
  mlir::IRMapping Mapping;
  Value Result;
  for (Operation &Op : Body) {
    if (auto Yield = dyn_cast<YieldOp>(Op)) {
      Result = Mapping.lookupOrDefault(Yield.getValue());
      continue;
    }
    auto Read = dyn_cast<mpir_expr::ReadOp>(Op);
    auto Arg = Read ? dyn_cast<mlir::BlockArgument>(Read.getValue())
                    : mlir::BlockArgument();
    if (!Arg || Arg.getOwner() != &Body) {
      Builder.clone(Op, Mapping);
      continue;
    }
    unsigned Index = Arg.getArgNumber();
    Location ReadLoc = Read.getLoc();
    if (Index > 0) {
      // An integer argument, as a literal.
      int64_t Number = cast<mlir::IntegerAttr>(Args[Index - 1]).getInt();
      APSInt Literal = normalizeLiteral(
          APSInt(APInt(64, uint64_t(Number), /*isSigned=*/true),
                 /*isUnsigned=*/false));
      Mapping.map(Read.getResult(),
                  mpir_expr::IntOp::create(Builder, ReadLoc, Literal));
      continue;
    }
    Operation *SubjectDef = Subject.getDefiningOp();
    // SubjectDef is null for a block argument, which is a meta variable.
    if (!SubjectDef || isa<VarOp>(SubjectDef)) {
      // A meta variable is read as its own sort, once known.
      Sort S = sortOf(Subject);
      Sort ReadSort =
          S != Sort::Unknown ? getRepresentation(resolveSort(S)) : sortOf(Read);
      Mapping.map(Read.getResult(),
                  mpir_expr::ReadOp::create(Builder, ReadLoc,
                                            SortType::get(Context, ReadSort),
                                            Subject));
      continue;
    }
    if (isa<InstOp, UseOp, AltOp>(SubjectDef)) {
      Mapping.map(Read.getResult(),
                  mpir_expr::ReadOp::create(Builder, ReadLoc,
                                            SortType::get(Context, Sort::Value),
                                            Subject));
      continue;
    }
    if (auto Int = dyn_cast<IntOp>(SubjectDef)) {
      mlir::IntegerAttr Value = Int.getValueAttr();
      APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
      if (sortOf(Read) == Sort::Boolean && Number.getBitWidth() == 1)
        Mapping.map(Read.getResult(), mpir_expr::BoolOp::create(
                                          Builder, ReadLoc, !Number.isZero()));
      else
        Mapping.map(Read.getResult(),
                    mpir_expr::IntOp::create(Builder, ReadLoc,
                                             normalizeLiteral(Number)));
      continue;
    }
    return mlir::emitError(ReadLoc)
           << "'?" << getMetaVariableName(Arg) << "' is bound to '"
           << toString([&](raw_ostream &OS) { printSurfaceValue(OS, Subject); })
           << "', which a constraint cannot refer to";
  }
  return Result;
}

LogicalResult Desugarer::desugarBlock(mlir::Block &Block) {
  // Constraints from metaflags go before the others, in the order of the
  // matchers they are written on.
  Operation *FirstRequire = nullptr;
  for (Operation &Op : Block)
    if (isa<RequireOp, YieldOp>(Op)) {
      FirstRequire = &Op;
      break;
    }

  if (FirstRequire)
    Builder.setInsertionPoint(FirstRequire);
  else
    Builder.setInsertionPointToEnd(&Block);

  SmallVector<Operation *, 16> Matchers;
  for (Operation &Op : Block)
    if (isa<InstOp, UseOp>(Op))
      Matchers.push_back(&Op);

  auto Desugar = [&](ArrayRef<Attribute> Flags, Value Subject,
                     Value Anchor) -> LogicalResult {
    for (Attribute A : Flags) {
      auto Flag = cast<MetaFlagAttr>(A);
      if (metaflag::isStructural(Flag.getName()))
        continue;
      mlir::FailureOr<Value> C = lower(Flag, Subject);
      if (mlir::failed(C))
        return mlir::failure();
      DenseSet<Operation *> Visited;
      setDefaultAnchor(*C, Anchor, Visited);
      auto Require = RequireOp::create(Builder, Location(Flag.getLoc()), *C);
      // Checked before the pattern's own constraints, as what the flags
      // say a binding is decides whether the others can be evaluated.
      Require.setFromMetaflag(true);
    }
    return mlir::success();
  };

  for (Operation *Op : Matchers) {
    auto U = cast<MatcherOpInterface>(Op);

    SmallVector<Attribute, 4> Kept;
    if (std::optional<mlir::ArrayAttr> Flags = U.getMetaflags()) {
      if (mlir::failed(
              Desugar(Flags->getValue(), U.getResult(), U.getResult())))
        return mlir::failure();
      for (Attribute A : *Flags)
        if (metaflag::isStructural(cast<MetaFlagAttr>(A).getName()))
          Kept.push_back(A);
    }
    if (std::optional<mlir::ArrayAttr> PerOperand = U.getOperandMetaflags()) {
      SmallVector<MatcherOperandView, 8> Operands = getMatcherOperands(U);
      for (auto [Index, A] : enumerate(*PerOperand))
        if (mlir::failed(Desugar(cast<mlir::ArrayAttr>(A).getValue(),
                                 Operands[Index].Kind == OperandKind::TypeOnly
                                     ? Value()
                                     : Operands[Index].Val,
                                 U.getResult())))
          return mlir::failure();
      U.removeOperandMetaflagsAttr();
    }
    if (Kept.empty())
      U.removeMetaflagsAttr();
    else
      U.setMetaflagsAttr(Builder.getArrayAttr(Kept));
  }
  return mlir::success();
}

namespace {
struct DesugarMetaFlagsPass
    : public mlir::PassWrapper<DesugarMetaFlagsPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(DesugarMetaFlagsPass)
  StringRef getArgument() const override { return "mpir-desugar-metaflags"; }
  StringRef getDescription() const override {
    return "Turn metaflags into constraints";
  }
  void runOnOperation() override {
    Desugarer D(getOperation());
    SmallVector<mlir::Block *, 16> Blocks;
    getOperation().walk([&](Operation *Op) {
      if (isa<PatternOp, BranchOp>(Op))
        Blocks.push_back(&Op->getRegion(0).front());
    });
    for (mlir::Block *Block : Blocks)
      if (mlir::failed(D.desugarBlock(*Block)))
        return signalPassFailure();
  }
};
} // namespace

} // namespace lowering

std::unique_ptr<mlir::Pass> createDesugarMetaFlagsPass() {
  return std::make_unique<lowering::DesugarMetaFlagsPass>();
}

} // namespace metaphir
} // namespace llvm
