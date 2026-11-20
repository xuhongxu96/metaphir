//===- CheckBindings.cpp - mpir-check-bindings ----------------------------===//
//
// See Lowering.h: a named meta variable is bound whichever alternatives
// match: those of ':o', and the branches of a matcher a use matches by.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/CheckBindings.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/BuiltinOps.h"

namespace llvm {
namespace metaphir {
namespace lowering {

using mlir::Location;
using mlir::LogicalResult;
using mlir::Operation;
using mlir::Value;
using namespace mpir;

//===----------------------------------------------------------------------===//
// mpir-check-bindings
//===----------------------------------------------------------------------===//

namespace {
/// The meta variables matching a value binds, whichever alternatives match.
struct Bindings {
  SetVector<Value> Variables;
  SmallVector<Value, 8> Pending;
  DenseSet<Operation *> Visited;
  /// The variables an mpir.alt binds in some alternatives but not all, each
  /// with the first such alt, to report.
  DenseMap<Value, AltOp> *Partial;

  explicit Bindings(DenseMap<Value, AltOp> &Into) : Partial(&Into) {}

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
  void addAlternatives(AltOp Alt);
  void run() {
    while (!Pending.empty())
      addValue(Pending.pop_back_val());
  }
};
} // namespace

/// The variables matching Region binds: what its matchers bind, and its
/// mpir.bind and mpir.let.
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
    addAlternatives(Alt);
    return;
  }
  if (!isa<InstOp, UseOp>(Def))
    return;
  auto U = cast<MatcherOpInterface>(Def);
  addVariable(U.getCapture());
  addVariable(U.getParentBlock());
  for (Value Capture : U.getFlagCaptures())
    addVariable(Capture);
  for (const MatcherOperandView &Op : getMatcherOperands(U)) {
    addType(Op.Type);
    if (Op.Val)
      Pending.push_back(Op.Val);
  }
}

void Bindings::addAlternatives(AltOp Alt) {
  // An alternative's bindings are found on their own: a variable is bound by
  // the alt only if every alternative binds it.
  SmallVector<Bindings, 2> Regions;
  for (mlir::Region &Region : Alt->getRegions())
    collectRegion(Regions.emplace_back(*Partial), Region);
  for (const Bindings &Region : Regions)
    for (Value Var : Region.Variables) {
      // A variable defined in an alternative is read only there.
      Operation *VarDef = Var.getDefiningOp();
      if (VarDef && Alt->isProperAncestor(VarDef))
        continue;
      if (all_of(Regions, [&](const Bindings &Other) {
            return Other.Variables.contains(Var);
          }))
        addVariable(Var);
      else
        Partial->try_emplace(Var, Alt);
    }
}

static void collectRegion(Bindings &Into, mlir::Region &Region) {
  for (Operation &Op : Region.front()) {
    if (auto Yield = dyn_cast<YieldOp>(Op))
      Into.Pending.push_back(Yield.getValue());
    else if (auto Bind = dyn_cast<BindOp>(Op))
      Into.addVariable(Bind.getVariable());
    else if (auto Let = dyn_cast<LetOp>(Op))
      Into.addVariable(Let.getVariable());
  }
  Into.run();
}

static LogicalResult checkBindings(PatternOp Pattern) {
  mlir::Block &Block = Pattern.getBody().front();
  DenseMap<Value, AltOp> Partial;
  Bindings Always(Partial);
  // Every matcher of the pattern itself is matched, also one an alternative
  // does not reach: it is then searched for on its own. A 'let' binds its
  // variable whichever alternatives match.
  for (Operation &Op : Block) {
    if (isa<InstOp, UseOp, AltOp>(Op))
      Always.Pending.push_back(Op.getResult(0));
    else if (auto Let = dyn_cast<LetOp>(Op))
      Always.addVariable(Let.getVariable());
  }
  Always.run();
  LogicalResult Result = mlir::success();
  Pattern.walk([&](VarOp Var) {
    StringRef Name = Var.getVarName();
    if (mlir::failed(Result) || Name.empty() || Name.starts_with("_") ||
        Always.Variables.contains(Var))
      return;
    AltOp Alt = Partial.lookup(Var);
    if (!Alt)
      return;
    Location Loc = getSourceRange(Var.getLoc()).Start.isValid() ? Var.getLoc()
                                                                : Alt.getLoc();
    mlir::emitError(Loc) << "meta variable '?" << Name
                         << "' is not bound by every alternative; name it '?_"
                         << Name << "' if it need not be bound";
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
    return "Check that every alternative binds the named meta variables";
  }
  void runOnOperation() override {
    for (PatternOp Pattern : getOperation().getOps<PatternOp>())
      if (mlir::failed(checkBindings(Pattern)))
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
