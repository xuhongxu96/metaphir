//===- CheckBindings.cpp - mpir-check-bindings ----------------------------===//
//
// See Passes.td: a named meta variable is bound whichever alternatives
// match: those of ':o', and the branches of a matcher a use matches by.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Transforms/Lowering/Passes.h"
#include "mlir/IR/BuiltinOps.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_CHECKBINDINGSPASS
#include "metaphir/Transforms/Lowering/Passes.h.inc"
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
/// What the walks of a pattern share.
struct AltBindings {
  /// The variables each mpir.alt binds whichever alternative matches: an
  /// alt reached again, from another alternative around it, is not walked
  /// again.
  DenseMap<Operation *, SetVector<Value>> Bound;
  /// The variables an mpir.alt binds in some alternatives but not all, each
  /// with the first such alt, to report.
  DenseMap<Value, AltOp> Partial;
};

/// The meta variables matching a value binds, whichever alternatives match.
struct Bindings {
  SetVector<Value> Variables;
  SmallVector<Value, 8> Pending;
  DenseSet<Operation *> Visited;
  AltBindings *Alts;

  explicit Bindings(AltBindings &Alts) : Alts(&Alts) {}

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
  auto Known = Alts->Bound.find(Alt);
  if (Known == Alts->Bound.end()) {
    // An alternative's bindings are found on their own: a variable is bound
    // by the alt only if every alternative binds it.
    SmallVector<Bindings, 2> Regions;
    for (mlir::Region &Region : Alt->getRegions())
      collectRegion(Regions.emplace_back(*Alts), Region);
    SetVector<Value> Bound;
    for (const Bindings &Region : Regions)
      for (Value Var : Region.Variables) {
        // A variable defined in an alternative is read only there.
        Operation *VarDef = Var.getDefiningOp();
        if (VarDef && Alt->isProperAncestor(VarDef))
          continue;
        if (all_of(Regions, [&](const Bindings &Other) {
              return Other.Variables.contains(Var);
            }))
          Bound.insert(Var);
        else
          Alts->Partial.try_emplace(Var, Alt);
      }
    Known = Alts->Bound.try_emplace(Alt, std::move(Bound)).first;
  }
  for (Value Var : Known->second)
    addVariable(Var);
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
  AltBindings Alts;
  Bindings Always(Alts);
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
    AltOp Alt = Alts.Partial.lookup(Var);
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
struct CheckBindingsPass : impl::CheckBindingsPassBase<CheckBindingsPass> {
  void runOnOperation() override {
    for (PatternOp Pattern : getOperation().getOps<PatternOp>())
      if (mlir::failed(checkBindings(Pattern)))
        return signalPassFailure();
  }
};
} // namespace

} // namespace lowering

} // namespace metaphir
} // namespace llvm
