//===- CheckBindings.cpp - mpir-check-bindings
//------------------------------===//
//
// See Lowering.h: a named meta variable is bound whichever alternative ':o'
// takes.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/CheckBindings.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/Transforms/Lowering/LoweringUtils.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Pass/PassRegistry.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {
namespace lowering {

using mlir::Attribute;
using mlir::Location;
using mlir::LogicalResult;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using mlir::ValueRange;
using namespace mpir;

//===----------------------------------------------------------------------===//
// mpir-check-bindings
//===----------------------------------------------------------------------===//

namespace {
/// The meta variables matching a value binds.
struct Bindings {
  SetVector<Value> Variables;
  SmallVector<Value, 8> Pending;
  DenseSet<Operation *> Visited;
  /// For an mpir.alt of ':o': the variables matching itself binds, and the
  /// alternative, to report.
  DenseMap<Value, AltOp> *BoundBy = nullptr;

  void addVariable(Value V) {
    if (V && !V.getDefiningOp<IntOp>())
      Variables.insert(V);
  }
  void addType(Value T) {
    if (!T)
      return;
    Operation *Def = T.getDefiningOp();
    if (!Def || isa<VarOp>(Def)) {
      addVariable(T);
      return;
    }
    for (Value Operand : Def->getOperands())
      addType(Operand);
  }
  void addValue(Value V);
  void run() {
    while (!Pending.empty())
      addValue(Pending.pop_back_val());
  }
};
} // namespace

/// The variables matching Region binds: what its matchers bind, and its
/// mpir.bind.
static void collectRegion(Bindings &Into, mlir::Region &Region);

void Bindings::addValue(Value V) {
  if (!V)
    return;
  Operation *Def = V.getDefiningOp();
  if (!Def || isa<VarOp>(Def)) {
    addVariable(V);
    return;
  }
  if (!Visited.insert(Def).second)
    return;
  if (auto Aggregate = dyn_cast<AggregateOp>(Def)) {
    for (auto [Index, E] : enumerate(Aggregate.getElements()))
      Index % 2 ? addValue(E) : addType(E);
    return;
  }
  if (auto Alt = dyn_cast<AltOp>(Def)) {
    if (Alt->hasAttr("or_self_of") && BoundBy) {
      // Matching its operand binds what the second alternative does;
      // matching itself, the first.
      // The alternative in which the matcher matches its operand.
      unsigned OperandRegion =
          Alt->getAttrOfType<mlir::IntegerAttr>("or_self_region").getInt();
      Bindings Itself;
      for (unsigned R = 0; R != Alt->getNumRegions(); ++R)
        if (R != OperandRegion)
          collectRegion(Itself, Alt->getRegion(R));
      for (Value Var : Itself.Variables)
        BoundBy->try_emplace(Var, Alt);
      collectRegion(*this, Alt->getRegion(OperandRegion));
      return;
    }
    for (mlir::Region &Region : Alt->getRegions())
      collectRegion(*this, Region);
    return;
  }
  if (!isa<InstOp, UseOp>(Def))
    return;
  MatcherUse U(Def);
  addVariable(U.getCapture());
  addVariable(U.getParentBlock());
  for (Value Capture : U.getFlagCaptures())
    addVariable(Capture);
  for (const MatcherOperandView &Op : getMatcherOperands(Def)) {
    addType(Op.Type);
    if (Op.Val)
      Pending.push_back(Op.Val);
  }
}

static void collectRegion(Bindings &Into, mlir::Region &Region) {
  for (Operation &Op : Region.front()) {
    if (auto Yield = dyn_cast<YieldOp>(Op))
      Into.Pending.push_back(Yield.getValue());
    else if (auto Bind = dyn_cast<BindOp>(Op))
      Into.addVariable(Bind.getVariable());
  }
  Into.run();
}

static LogicalResult checkOrSelfBindings(PatternOp Pattern) {
  mlir::Block &Block = Pattern.getBody().front();
  DenseMap<Value, AltOp> BoundBy;
  Bindings Always;
  Always.BoundBy = &BoundBy;
  for (Operation *Root : getPatternRoots(Block))
    Always.Pending.push_back(Root->getResult(0));
  Always.run();
  // Matchers in alternatives are reached from their alt; those of a region
  // not reached from its yield are roots of their own.
  LogicalResult Result = mlir::success();
  Pattern.walk(
      [&](VarOp Var) {
        StringRef Name = Var.getVarName();
        if (mlir::failed(Result) || Name.empty() || Name.starts_with("_") ||
            Always.Variables.contains(Var))
          return;
        AltOp OrSelf = BoundBy.lookup(Var);
        if (!OrSelf)
          return;
        Location Loc = getSourceRange(Var.getLoc()).Start.isValid()
                           ? Var.getLoc()
                           : OrSelf.getLoc();
        mlir::emitError(Loc)
            << "meta variable '?" << Name << "' is not bound when ':o' lets '"
            << OrSelf->getAttrOfType<mlir::StringAttr>("or_self_of").getValue()
            << "' match its operand; name it '?_" << Name
            << "' if it need not be bound";
        Result = mlir::failure();
      });
  return Result;
}

namespace {
struct CheckBindingsPass
    : public mlir::PassWrapper<CheckBindingsPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(CheckBindingsPass)
  StringRef getArgument() const override { return "mpir-check-bindings"; }
  StringRef getDescription() const override {
    return "Check that ':o' leaves no named meta variable unbound";
  }
  void runOnOperation() override {
    for (PatternOp Pattern : getOperation().getOps<PatternOp>())
      if (mlir::failed(checkOrSelfBindings(Pattern)))
        return signalPassFailure();
  }
};
} // namespace

} // namespace lowering

std::unique_ptr<mlir::Pass> createCheckBindingsPass() {
  return std::make_unique<lowering::CheckBindingsPass>();
}

} // namespace metaphir
} // namespace llvm
