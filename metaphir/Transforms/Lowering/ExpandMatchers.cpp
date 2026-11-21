//===- ExpandMatchers.cpp - mpir-expand-matchers --------------------------===//
//
// See Passes.td: a use of a matcher becomes an mpir.alt of its branches.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Transforms/Lowering/Passes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "llvm/ADT/SmallString.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_EXPANDMATCHERSPASS
#include "metaphir/Transforms/Lowering/Passes.h.inc"
namespace lowering {

using mlir::Location;
using mlir::LogicalResult;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;

//===----------------------------------------------------------------------===//
// Type patterns
//===----------------------------------------------------------------------===//

/// Whether T is a type pattern only a match decides: '?T' or 'i?n'.
static bool isMetaType(Value T) {
  Operation *Def = T.getDefiningOp();
  return !Def || isa<VarOp, MetaIntTypeOp>(Def);
}

/// Whether two type patterns are the same type, as uniqued MetaphIR types
/// are identical: the same structure, with the same variables.
static bool isSameType(Value A, Value B) {
  if (A == B)
    return true;
  Operation *DA = A.getDefiningOp(), *DB = B.getDefiningOp();
  if (!DA || !DB || DA->getName() != DB->getName() || isa<VarOp>(DA))
    return false;
  if (DA->getAttrDictionary() != DB->getAttrDictionary() ||
      DA->getNumOperands() != DB->getNumOperands())
    return false;
  for (auto [OA, OB] : zip(DA->getOperands(), DB->getOperands()))
    if (!isSameType(OA, OB))
      return false;
  return true;
}

//===----------------------------------------------------------------------===//
// mpir-expand-matchers
//===----------------------------------------------------------------------===//

namespace {
class Expander {
public:
  explicit Expander(mlir::MLIRContext *Context) : Builder(Context) {}

  /// Replaces Use by an mpir.alt of the branches it can match.
  LogicalResult expand(UseOp Use);

private:
  OpBuilder Builder;
  unsigned NextAnonymousUse = 0;

  /// Inlines Branch of the matcher into a new block of Bodies, for the use
  /// with CallerOps. The block is null if the branch cannot fit the use.
  mlir::FailureOr<mlir::Block *>
  inlineBranch(UseOp Use, MatcherOp Matcher, BranchOp Branch,
               ArrayRef<MatcherOperandView> CallerOps, StringRef UsePrefix,
               mlir::Region &Bodies);
};
} // namespace

/// The positions of the archetype's parameters among a use's operands:
/// (parameter, operand) pairs for its types, then for its values.
static void archetypePositions(
    instruction::OperandSyntax Syntax, unsigned Arity,
    SmallVectorImpl<std::pair<unsigned, unsigned>> &TypePositions,
    SmallVectorImpl<std::pair<unsigned, unsigned>> &ValuePositions) {
  switch (Syntax) {
  case instruction::OperandSyntax::Nary:
    for (unsigned I = 0; I != Arity; ++I) {
      TypePositions.push_back({2 * I, I});
      ValuePositions.push_back({2 * I + 1, I});
    }
    break;
  case instruction::OperandSyntax::Binary:
    TypePositions.push_back({0, 0});
    ValuePositions.push_back({1, 0});
    ValuePositions.push_back({2, 1});
    break;
  case instruction::OperandSyntax::Cast:
    TypePositions.push_back({0, 0});
    ValuePositions.push_back({1, 0});
    TypePositions.push_back({2, 1});
    break;
  case instruction::OperandSyntax::Custom:
    llvm_unreachable("composite matchers use a shared archetype");
  }
}

namespace {
/// Inlines one branch of a matcher into a block that will be a region of an
/// mpir.alt, for one use of the matcher.
class BranchInliner {
public:
  BranchInliner(OpBuilder &Builder, UseOp Use, MatcherOp Matcher,
                BranchOp Branch, ArrayRef<MatcherOperandView> CallerOps,
                StringRef UsePrefix, mlir::Region &Bodies)
      : Builder(Builder), Context(Builder.getContext()), Use(Use),
        Matcher(Matcher), Branch(Branch), CallerOps(CallerOps),
        UsePrefix(UsePrefix), Bodies(Bodies), Body(Branch.getBody().front()),
        Yield(*Body.getOps<YieldOp>().begin()),
        Root(cast<MatcherOpInterface>(Yield.getValue().getDefiningOp())),
        CallerLoc(Use.getLoc()) {}

  /// Inlines the branch into a new block of Bodies. The block is null if the
  /// branch cannot fit the use.
  mlir::FailureOr<mlir::Block *> run();

private:
  /// Binds the branch's type arguments to the types the use passes, and its
  /// value arguments to its operands. Returns false if a type cannot fit.
  mlir::FailureOr<bool> bindTypes();
  /// Binds the matcher's supported flags to what the use says of them.
  /// Returns false if the use and the branch disagree on one.
  /// What the captures of a supported flag in the branch stand for: a meta
  /// variable, or a boolean constant if Var is null.
  struct FlagValue {
    Value Var;
    std::optional<bool> Constant;
  };
  bool bindFlags();
  /// The capture the use passes for its flag at UseIndex, or null.
  Value useCaptureAt(unsigned UseIndex);
  /// The value of a supported flag, or nothing if the branch fixes it to
  /// what the use rules out.
  std::optional<FlagValue> resolveFlag(instruction_flag::FlagID FlagID);
  /// Maps the captures of the flag in the branch's matchers to its value.
  void mapCaptures(instruction_flag::FlagID FlagID, const FlagValue &Resolved);
  /// What the root's capture and the branch's 'i?n' type patterns stand for.
  void bindRootAndWidths();
  /// Copies the branch's operations into the new region.
  void inlineBody();
  /// Copies an instruction matcher of the branch, renamed after the use, with
  /// its settings over the use's.
  void inlineMatcher(Operation &Op);
  /// Binds what the branch fixes of the flags the use captures, and yields
  /// the root.
  void finish();

  OpBuilder &Builder;
  mlir::MLIRContext *Context;
  UseOp Use;
  MatcherOp Matcher;
  BranchOp Branch;
  ArrayRef<MatcherOperandView> CallerOps;
  StringRef UsePrefix;
  /// Where the blocks of the mpir.alt to come are built.
  mlir::Region &Bodies;
  /// The block the branch is inlined into.
  mlir::Block *Out = nullptr;
  mlir::Block &Body;
  /// The root: what the branch yields.
  YieldOp Yield;
  MatcherOpInterface Root;
  Location CallerLoc;

  mlir::IRMapping Mapping;
  /// Branch arguments bound to a type, and the width variable an 'i?n'
  /// parameter's argument also stands for.
  DenseMap<Value, Value> ArgTypes;
  /// Flags the branch fixes that the use captures: the capture, and the
  /// value.
  SmallVector<std::pair<Value, bool>, 2> FixedFlags;
  /// What the root's capture of each supported flag stands for.
  DenseMap<int32_t, FlagValue> FlagValues;
};
} // namespace

mlir::FailureOr<mlir::Block *> BranchInliner::run() {
  mlir::FailureOr<bool> Fits = bindTypes();
  if (mlir::failed(Fits))
    return mlir::failure();
  if (!*Fits)
    return nullptr;

  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPoint(Use);

  if (!bindFlags())
    return nullptr;

  bindRootAndWidths();
  inlineBody();
  finish();

  return Out;
}

mlir::FailureOr<bool> BranchInliner::bindTypes() {
  ArrayRef<int32_t> ParamArgs = Branch.getParamArgs();
  auto Signature = cast<SignatureOp>(
      *llvm::find_if(Matcher.getBody().front(),
                     [](Operation &Op) { return isa<SignatureOp>(Op); }));

  // The parameters' type patterns, in order (null for operands).
  SmallVector<Value, 4> ParamTypes;
  {
    unsigned NextType = 0;
    for (bool IsType : Matcher.getParamIsType())
      ParamTypes.push_back(IsType ? Signature.getTypes()[NextType++] : Value());
  }

  SmallVector<std::pair<unsigned, unsigned>, 8> TypePositions, ValuePositions;
  archetypePositions(instruction::OperandSyntax(Matcher.getSyntax()),
                     Matcher.getArity(), TypePositions, ValuePositions);
  for (auto [ParamIndex, OpIndex] : TypePositions) {
    Value CallerTy = CallerOps[OpIndex].Type;
    assert(CallerTy && "use without a type at a type position");

    int32_t ArgNumber = ParamArgs[ParamIndex];
    if (ArgNumber < 0) {
      // The declaration fixes this type. A use's meta type could only be
      // compared once matched, so the use must spell the type as well.
      Value Declared = ParamTypes[ParamIndex];
      if (isMetaType(CallerTy)) {
        Value V = CallerOps[OpIndex].Val;
        Location Loc = V ? V.getLoc() : Use.getLoc();
        if (!getSourceRange(Loc).Start.isValid())
          Loc = Use.getLoc();
        return mlir::emitError(Loc)
               << "matcher '" << Matcher.getSymName() << "' requires type '"
               << surfaceString(Declared)
               << "' for a parameter, but this use passes '"
               << surfaceString(CallerTy) << "'";
      }
      if (!isSameType(Declared, CallerTy))
        return false;
      continue;
    }

    Value Arg = Body.getArgument(ArgNumber);

    // A type parameter repeated for several operands must get one type.
    if (Value Bound = ArgTypes.lookup(Arg)) {
      if (!isSameType(Bound, CallerTy) && !isMetaType(Bound) &&
          !isMetaType(CallerTy))
        return false;
      continue;
    }
    ArgTypes[Arg] = CallerTy;

    // The width of an 'i?bits' parameter is also a value, usable in the
    // branch's constraints.
    if (Value Declared = ParamTypes[ParamIndex];
        Declared && Declared.getDefiningOp<MetaIntTypeOp>()) {
      if (auto MetaInt = CallerTy.getDefiningOp<MetaIntTypeOp>()) {
        Mapping.map(Arg, MetaInt.getWidth());
      } else {
        unsigned Width = 0;
        if (auto Int = CallerTy.getDefiningOp<IntTypeOp>())
          Width = Int.getWidth();
        if (Width) {
          OpBuilder::InsertionGuard Guard(Builder);
          Builder.setInsertionPoint(Use);
          auto Type =
              mlir::IntegerType::get(Context, 64, mlir::IntegerType::Unsigned);
          Value V = CallerOps[OpIndex].Val;
          Mapping.map(Arg, IntOp::create(Builder, V ? V.getLoc() : Use.getLoc(),
                                         SortType::get(Context, Sort::Value),
                                         mlir::IntegerAttr::get(Type, Width)));
        }
      }
    } else {
      Mapping.map(Arg, CallerTy);
    }
  }
  for (auto [ParamIndex, OpIndex] : ValuePositions) {
    // An operand parameter is always a named meta variable, so it has an
    // argument; only a type parameter written as a concrete type has none.
    int32_t ArgNumber = ParamArgs[ParamIndex];
    assert(ArgNumber >= 0);
    assert(CallerOps[OpIndex].Val && "use without a value at a value position");
    Mapping.map(Body.getArgument(ArgNumber), CallerOps[OpIndex].Val);
  }
  return true;
}

Value BranchInliner::useCaptureAt(unsigned UseIndex) {
  ArrayRef<FlagMode> Modes = Use.getFlagModes();
  if (Modes[UseIndex] != FlagMode::Captured)
    return Value();
  return Use
      .getFlagCaptures()[count(Modes.take_front(UseIndex), FlagMode::Captured)];
}

std::optional<BranchInliner::FlagValue>
BranchInliner::resolveFlag(instruction_flag::FlagID FlagID) {
  ArrayRef<instruction_flag::FlagID> UseFlags = Use.getFlags();
  const instruction_flag::FlagID *UseFlag = find(UseFlags, FlagID);
  std::optional<unsigned> UseIndex;
  if (UseFlag != UseFlags.end())
    UseIndex = UseFlag - UseFlags.begin();
  ArrayRef<instruction_flag::FlagID> FixedFlagIDs = Branch.getFixedFlags();
  std::optional<bool> FixedValue;
  if (const instruction_flag::FlagID *F = find(FixedFlagIDs, FlagID);
      F != FixedFlagIDs.end())
    FixedValue = Branch.getFixedFlagValues()[F - FixedFlagIDs.begin()];

  Value UseCapture = UseIndex ? useCaptureAt(*UseIndex) : Value();
  if (UseCapture) {
    // The use captures the flag; the branch may fix its value.
    if (FixedValue)
      FixedFlags.push_back({UseCapture, *FixedValue});
    return FlagValue{UseCapture, std::nullopt};
  }
  if (UseIndex) {
    // The use requires or negates the flag.
    bool Required = Use.getFlagModes()[*UseIndex] == FlagMode::Required;
    if (FixedValue && *FixedValue != Required)
      return std::nullopt;
    return FlagValue{Value(), Required};
  }
  if (FixedValue)
    return FlagValue{Value(), *FixedValue};
  // The use omits the flag, so the root's capture of it is a fresh variable.
  // The underscore keeps it out of reported matches.
  return FlagValue{
      VarOp::create(
          Builder, Use.getLoc(), SortType::get(Context, Sort::Boolean),
          Builder.getStringAttr(
              "_flag$" + UsePrefix + "$" +
              instruction_flag::getName(instruction_flag::FlagID(FlagID)))),
      std::nullopt};
}

void BranchInliner::mapCaptures(instruction_flag::FlagID FlagID,
                                const FlagValue &Resolved) {
  for (Operation &Op : Body) {
    auto M = dyn_cast<MatcherOpInterface>(Op);
    if (!M)
      continue;
    unsigned Next = 0;
    for (auto [Flag, Mode] : zip(M.getFlags(), M.getFlagModes())) {
      if (FlagMode(Mode) != FlagMode::Captured)
        continue;
      Value Capture = M.getFlagCaptures()[Next++];
      if (Flag != FlagID || Mapping.contains(Capture))
        continue;
      if (Resolved.Var) {
        Mapping.map(Capture, Resolved.Var);
        continue;
      }
      auto Type =
          mlir::IntegerType::get(Context, 1, mlir::IntegerType::Unsigned);
      Mapping.map(
          Capture,
          IntOp::create(
              Builder, Use.getLoc(), SortType::get(Context, Sort::Value),
              mlir::IntegerAttr::get(Type, APInt(1, *Resolved.Constant))));
    }
  }
}

bool BranchInliner::bindFlags() {
  // Bind the matcher's supported flags. For each one, the use either omits
  // it, requires it, negates it, or captures it; a branch may also fix its
  // value. The branch's captures of the flag then stand for the flag's value
  // everywhere in the body.
  for (instruction_flag::FlagID FlagID : Matcher.getSupportedFlags()) {
    std::optional<FlagValue> Resolved = resolveFlag(FlagID);
    if (!Resolved)
      return false;
    FlagValues[FlagID] = *Resolved;
    mapCaptures(FlagID, *Resolved);
  }
  return true;
}

void BranchInliner::bindRootAndWidths() {
  // The root's capture is the use's capture, when the use names one.
  if (Root.getCapture() && Use.getCapture())
    Mapping.map(Root.getCapture(), Use.getCapture());

  // The branch's 'i?n' type patterns of a type parameter stand for the type
  // the use passes.
  for (Operation &Op : Body)
    if (auto MetaInt = dyn_cast<MetaIntTypeOp>(Op))
      if (auto Arg = dyn_cast<mlir::BlockArgument>(MetaInt.getWidth()))
        if (Value Ty = ArgTypes.lookup(Arg))
          Mapping.map(MetaInt.getResult(), Ty);
}

void BranchInliner::inlineBody() {
  Out = &Bodies.emplaceBlock();
  Builder.setInsertionPointToEnd(Out);
  for (Operation &Op : Body) {
    if (isa<YieldOp>(Op))
      continue;
    // Already stood for by what the use passes: a bound variable, or a type
    // pattern replaced by the use's type.
    if (Op.getNumResults() && Mapping.contains(Op.getResult(0)))
      continue;
    if (auto Var = dyn_cast<VarOp>(Op)) {
      // A local variable gets a fresh copy for this use, named after it.
      StringRef Name = Var.getVarName();
      Mapping.map(Var.getResult(),
                  VarOp::create(
                      Builder, Var.getLoc(), Var.getType(),
                      Builder.getStringAttr((Name.starts_with("_") ? "_" : "") +
                                            UsePrefix + "$" + Name)));
      continue;
    }
    if (!isa<InstOp, UseOp>(Op)) {
      Operation *Clone = Builder.clone(Op, Mapping);
      Clone->setLoc(mlir::CallSiteLoc::get(Op.getLoc(), CallerLoc));
      continue;
    }
    inlineMatcher(Op);
  }
}

void BranchInliner::inlineMatcher(Operation &Op) {
  std::optional<bool> UseTreatIntAsVec = Use.getTreatIntAsVec();
  // An instruction matcher: renamed after the use, placed in its block,
  // with its settings over the use's.
  bool IsRoot = &Op == Root.getOperation();
  MatcherParts Parts = MatcherParts::of(cast<MatcherOpInterface>(Op));
  for (MatcherOperandView &O : Parts.Operands) {
    if (O.Type)
      O.Type = Mapping.lookupOrDefault(O.Type);
    if (O.Val)
      O.Val = Mapping.lookupOrDefault(O.Val);
  }
  if (Parts.Capture)
    Parts.Capture = Mapping.lookupOrDefault(Parts.Capture);
  Parts.ParentBlock = Use.getParentBlock();
  if (!Parts.TreatIntAsVec)
    Parts.TreatIntAsVec = UseTreatIntAsVec;
  if (IsRoot) {
    Parts.ResultName = Use.getResultNameAttr();
    if (Use.getCapture())
      Parts.Capture = Use.getCapture();
  } else if (Parts.ResultName) {
    Parts.ResultName =
        Builder.getStringAttr(UsePrefix + "$" + Parts.ResultName.getValue());
  }
  // Flags: a supported flag the branch captures takes the use's flag.
  SmallVector<instruction_flag::FlagID, 4> Flags;
  SmallVector<FlagMode, 4> Modes;
  SmallVector<Value, 2> Captures;
  unsigned NextCapture = 0;
  for (auto [Flag, Mode] : zip(Parts.Flags, Parts.Modes)) {
    Value Capture = Mode == FlagMode::Captured
                        ? Parts.FlagCaptures[NextCapture++]
                        : Value();
    if (Mode != FlagMode::Captured ||
        !is_contained(Matcher.getSupportedFlags(), Flag)) {
      Flags.push_back(Flag);
      Modes.push_back(Mode);
      if (Capture)
        Captures.push_back(Mapping.lookupOrDefault(Capture));
      continue;
    }
    FlagValue Resolved = FlagValues.lookup(Flag);
    Flags.push_back(Flag);
    if (Resolved.Var) {
      Modes.push_back(FlagMode::Captured);
      Captures.push_back(Resolved.Var);
    } else {
      Modes.push_back(*Resolved.Constant ? FlagMode::Required
                                         : FlagMode::Negated);
    }
  }
  Parts.Flags = Flags;
  Parts.Modes = Modes;
  Parts.FlagCaptures = Captures;
  Location Loc = mlir::CallSiteLoc::get(Op.getLoc(), CallerLoc);
  Value New =
      isa<InstOp>(Op)
          ? Parts.buildInst(Builder, Loc, cast<InstOp>(Op).getOpcodeAttr())
                .getResult()
          : Parts.buildUse(Builder, Loc, cast<UseOp>(Op).getMatcherAttr())
                .getResult();
  Mapping.map(Op.getResult(0), New);
}

void BranchInliner::finish() {
  // What the branch fixes of the flags the use captures.
  for (auto [Capture, Value] : FixedFlags) {
    auto Type = mlir::IntegerType::get(Context, 1, mlir::IntegerType::Unsigned);
    mlir::Value Constant =
        IntOp::create(Builder, CallerLoc, SortType::get(Context, Sort::Value),
                      mlir::IntegerAttr::get(Type, APInt(1, Value)));
    BindOp::create(Builder, CallerLoc, Capture, Constant);
  }
  Value NewRoot = Mapping.lookupOrDefault(Yield.getValue());
  // The use's capture names the root: constraints on the root, such as its
  // metaflags', read it by that name.
  if (Value Capture = Use.getCapture(); Capture && !Root.getCapture())
    for (mlir::OpOperand &Operand :
         llvm::make_early_inc_range(NewRoot.getUses()))
      if (isa<mpir_expr::ReadOp>(Operand.getOwner()))
        Operand.set(Capture);
  YieldOp::create(Builder, CallerLoc, NewRoot);
}

mlir::FailureOr<mlir::Block *>
Expander::inlineBranch(UseOp Use, MatcherOp Matcher, BranchOp Branch,
                       ArrayRef<MatcherOperandView> CallerOps,
                       StringRef UsePrefix, mlir::Region &Bodies) {
  return BranchInliner(Builder, Use, Matcher, Branch, CallerOps, UsePrefix,
                       Bodies)
      .run();
}

LogicalResult Expander::expand(UseOp Use) {
  auto Matcher = mlir::SymbolTable::lookupNearestSymbolFrom<MatcherOp>(
      Use, Use.getMatcherAttr());

  // A named use is prefixed by its name; one without is given a number.
  SmallString<16> AnonymousName;
  StringRef UsePrefix;
  if (std::optional<StringRef> Name = Use.getResultName()) {
    UsePrefix = *Name;
  } else {
    ("#" + Twine(NextAnonymousUse++)).toVector(AnonymousName);
    UsePrefix = AnonymousName;
  }

  SmallVector<MatcherOperandView, 8> CallerOps = getMatcherOperands(Use);

  bool Commutative = Use.isCommutative();
  std::optional<unsigned> OrSelf = Use.getOrSelfIndex();

  Builder.setInsertionPoint(Use);

  // The bodies of the alternatives
  mlir::Region Bodies;
  for (BranchOp Branch : Matcher.getBody().front().getOps<BranchOp>()) {
    for (unsigned Order = 0; Order != (Commutative ? 2u : 1u); ++Order) {
      SmallVector<MatcherOperandView, 8> Ops(CallerOps);
      if (Order == 1)
        std::swap(Ops[0], Ops[1]);
      if (mlir::failed(
              inlineBranch(Use, Matcher, Branch, Ops, UsePrefix, Bodies)))
        return mlir::failure();
    }
  }
  if (OrSelf) {
    // ':o(N)' lets the use match its Nth operand in place of the matcher.
    mlir::Block &Body = Bodies.emplaceBlock();
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Body);
    Value Operand = CallerOps[*OrSelf].Val;
    if (Value Capture = Use.getCapture())
      BindOp::create(Builder, Use.getLoc(), Capture, Operand);
    YieldOp::create(Builder, Use.getLoc(), Operand);
  }

  mlir::StringAttr ResultName;
  if (std::optional<StringRef> Name = Use.getResultName())
    ResultName = Builder.getStringAttr(*Name);
  AltOp Alt = AltOp::create(Builder, Use.getLoc(), Use.getType(), ResultName,
                            range_size(Bodies));
  // Each block becomes the body of one alternative region, in order.
  for (mlir::Region &Alternative : Alt->getRegions())
    Alternative.getBlocks().splice(Alternative.end(), Bodies.getBlocks(),
                                   Bodies.begin());
  Use.getResult().replaceAllUsesWith(Alt.getResult());
  Use.erase();
  return mlir::success();
}

namespace {
struct ExpandMatchersPass : impl::ExpandMatchersPassBase<ExpandMatchersPass> {
  void runOnOperation() override {
    Expander E(&getContext());
    for (PatternOp Pattern : getOperation().getOps<PatternOp>()) {
      // Expanding a use inlines its branches, which may use matchers in
      // turn: expand until no use is left, first come first.
      while (true) {
        UseOp First;
        Pattern.walk([&](UseOp Use) {
          if (!First)
            First = Use;
          return mlir::WalkResult::interrupt();
        });
        if (!First)
          break;
        if (mlir::failed(E.expand(First)))
          return signalPassFailure();
      }
    }
  }
};
} // namespace

} // namespace lowering

} // namespace metaphir
} // namespace llvm
