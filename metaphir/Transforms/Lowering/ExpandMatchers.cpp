//===- ExpandMatchers.cpp - mpir-expand-matchers --------------------------===//
//
// See Lowering.h: a use of a matcher becomes an mpir.alt of its branches.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/ExpandMatchers.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Transforms/Lowering/LoweringUtils.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"

namespace llvm {
namespace metaphir {
namespace lowering {

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

/// The fresh variable a use that omits a flag passes for it to the matcher's
/// root; a use nested in that body then also omits it.
static constexpr StringLiteral OmittedFlagPrefix = "_flag$";

static bool isWildcardCapture(Value Capture) {
  if (!Capture)
    return false;
  auto Var = Capture.getDefiningOp<VarOp>();
  return Var && Var.getVarName().starts_with(OmittedFlagPrefix);
}

namespace {
class Expander {
public:
  explicit Expander(mlir::MLIRContext *Context) : Builder(Context) {}

  /// Replaces Use by an mpir.alt of the branches it can match.
  LogicalResult expand(UseOp Use);

private:
  OpBuilder Builder;
  unsigned NextAnonymousUse = 0;

  /// Inlines Branch of the matcher into a new region of Alt, for the use
  /// with CallerOps. Returns false if the branch cannot fit the use.
  mlir::FailureOr<bool> inlineBranch(UseOp Use, MatcherOp Matcher,
                                     BranchOp Branch,
                                     ArrayRef<MatcherOperandView> CallerOps,
                                     StringRef UsePrefix, AltOp Alt);
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
/// Inlines one branch of a matcher into a region of an mpir.alt, for one use
/// of the matcher.
class BranchInliner {
public:
  BranchInliner(OpBuilder &Builder, UseOp Use, MatcherOp Matcher,
                BranchOp Branch, ArrayRef<MatcherOperandView> CallerOps,
                StringRef UsePrefix, AltOp Alt)
      : Builder(Builder), Context(Builder.getContext()), Use(Use),
        Matcher(Matcher), Branch(Branch), CallerOps(CallerOps),
        UsePrefix(UsePrefix), Alt(Alt), Body(Branch.getBody().front()),
        Yield(*Body.getOps<YieldOp>().begin()),
        Root(cast<MatcherOpInterface>(Yield.getValue().getDefiningOp())),
        CallerLoc(Use.getLoc()) {}

  /// Inlines the branch into the last region of Alt. Returns false if the
  /// branch cannot fit the use.
  mlir::FailureOr<bool> run();

private:
  /// Binds the branch's type arguments to the types the use passes, and its
  /// value arguments to its operands. Returns false if a type cannot fit.
  mlir::FailureOr<bool> bindTypes();
  /// Binds the matcher's supported flags to what the use says of them.
  /// Returns false if the use and the branch disagree on one.
  bool bindFlags();
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
  AltOp Alt;
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
  /// What the root's capture of each supported flag stands for: a boolean
  /// constant or a meta variable.
  DenseMap<int32_t, std::pair<Value, std::optional<bool>>> FlagValues;
  /// The branch's 'i?n' type patterns that stand for a type the use passes.
  DenseMap<Operation *, Value> ReplacedTypes;
};
} // namespace

mlir::FailureOr<bool> BranchInliner::run() {
  mlir::FailureOr<bool> Fits = bindTypes();
  if (mlir::failed(Fits) || !*Fits)
    return Fits;
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPoint(Alt);
  if (!bindFlags())
    return false;
  bindRootAndWidths();
  inlineBody();
  finish();
  return true;
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
    if (!CallerTy)
      continue;
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
               << toString(
                      [&](raw_ostream &OS) { printSurfaceValue(OS, Declared); })
               << "' for a parameter, but this use passes '"
               << toString(
                      [&](raw_ostream &OS) { printSurfaceValue(OS, CallerTy); })
               << "'";
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
          Builder.setInsertionPoint(Alt);
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
    int32_t ArgNumber = ParamArgs[ParamIndex];
    if (ArgNumber >= 0 && CallerOps[OpIndex].Val)
      Mapping.map(Body.getArgument(ArgNumber), CallerOps[OpIndex].Val);
  }
  return true;
}

bool BranchInliner::bindFlags() {
  // Bind the matcher's supported flags. For each one, the use either omits
  // it, requires it, negates it, or captures it; a branch may also fix its
  // value. FlagValue is what the root's capture of the flag stands for: a
  // boolean constant or a meta variable.
  ArrayRef<instruction_flag::FlagID> UseFlags = Use.getFlags();
  ArrayRef<FlagMode> UseModes = Use.getFlagModes();
  SmallVector<Value, 4> UseCaptures;
  {
    unsigned Next = 0;
    for (FlagMode Mode : UseModes)
      UseCaptures.push_back(
          Mode == FlagMode::Captured ? Use.getFlagCaptures()[Next++] : Value());
  }
  ArrayRef<instruction_flag::FlagID> FixedIDs = Branch.getFixedFlags();
  ArrayRef<bool> FixedValues = Branch.getFixedFlagValues();
  for (instruction_flag::FlagID FlagID : Matcher.getSupportedFlags()) {
    const instruction_flag::FlagID *UseFlag = find(UseFlags, FlagID);
    std::optional<unsigned> UseIndex;
    if (UseFlag != UseFlags.end())
      UseIndex = UseFlag - UseFlags.begin();
    // A flag forwarded from an enclosing use that omitted it is omitted too.
    if (UseIndex && isWildcardCapture(UseCaptures[*UseIndex]))
      UseIndex.reset();
    std::optional<bool> Fixed;
    if (const instruction_flag::FlagID *F = find(FixedIDs, FlagID);
        F != FixedIDs.end())
      Fixed = FixedValues[F - FixedIDs.begin()];

    std::pair<Value, std::optional<bool>> FlagValue;
    Value UseCapture = UseIndex ? UseCaptures[*UseIndex] : Value();
    if (UseIndex && !UseCapture) {
      bool Required = UseModes[*UseIndex] != FlagMode::Negated;
      if (Fixed && *Fixed != Required)
        return false;
      FlagValue.second = Required;
    } else if (Fixed) {
      if (UseIndex)
        FixedFlags.push_back({UseCapture, *Fixed});
      if (UseIndex)
        FlagValue.first = UseCapture;
      else
        FlagValue.second = *Fixed;
    } else if (UseIndex) {
      FlagValue.first = UseCapture;
    } else {
      FlagValue.first = VarOp::create(
          Builder, Use.getLoc(), SortType::get(Context, Sort::Boolean),
          Builder.getStringAttr(
              (OmittedFlagPrefix + UsePrefix + "$" +
               instruction_flag::getName(instruction_flag::FlagID(FlagID)))
                  .str()));
    }
    FlagValues[FlagID] = FlagValue;
    // The root's capture of the flag stands for FlagValue everywhere in the
    // body.
    unsigned Next = 0;
    for (auto [RootFlag, Mode] : zip(Root.getFlags(), Root.getFlagModes())) {
      if (FlagMode(Mode) != FlagMode::Captured)
        continue;
      Value Capture = Root.getFlagCaptures()[Next++];
      if (RootFlag != FlagID)
        continue;
      if (FlagValue.first) {
        Mapping.map(Capture, FlagValue.first);
      } else {
        auto Type =
            mlir::IntegerType::get(Context, 1, mlir::IntegerType::Unsigned);
        Mapping.map(
            Capture,
            IntOp::create(
                Builder, Use.getLoc(), SortType::get(Context, Sort::Value),
                mlir::IntegerAttr::get(Type, APInt(1, *FlagValue.second))));
      }
    }
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
          ReplacedTypes[&Op] = Ty;
}

void BranchInliner::inlineBody() {
  mlir::Block &Region = Alt->getRegion(Alt->getNumRegions() - 1).emplaceBlock();
  Builder.setInsertionPointToEnd(&Region);
  for (Operation &Op : Body) {
    if (isa<YieldOp>(Op))
      continue;
    if (auto It = ReplacedTypes.find(&Op); It != ReplacedTypes.end()) {
      Mapping.map(Op.getResult(0), It->second);
      continue;
    }
    if (auto Var = dyn_cast<VarOp>(Op)) {
      if (Mapping.contains(Var.getResult()))
        continue;
      // A local variable gets a fresh copy for this use, named after it.
      StringRef Name = Var.getVarName();
      std::string Copy =
          ((Name.starts_with("_") ? "_" : "") + UsePrefix + "$" + Name).str();
      Mapping.map(Var.getResult(),
                  VarOp::create(Builder, Var.getLoc(), Var.getType(),
                                Builder.getStringAttr(Copy)));
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
    Parts.ResultName.reset();
    if (std::optional<StringRef> Name = Use.getResultName())
      Parts.ResultName = Name->str();
    if (Use.getCapture())
      Parts.Capture = Use.getCapture();
  } else if (Parts.ResultName) {
    Parts.ResultName = (UsePrefix + "$" + *Parts.ResultName).str();
  }
  // Flags: a supported flag on the root takes the use's flag.
  SmallVector<instruction_flag::FlagID, 4> Flags;
  SmallVector<FlagMode, 4> Modes;
  SmallVector<Value, 2> Captures;
  unsigned NextCapture = 0;
  for (auto [Flag, Mode] : zip(Parts.Flags, Parts.Modes)) {
    Value Capture = Mode == FlagMode::Captured
                        ? Parts.FlagCaptures[NextCapture++]
                        : Value();
    if (!IsRoot || !is_contained(Matcher.getSupportedFlags(), Flag)) {
      Flags.push_back(Flag);
      Modes.push_back(Mode);
      if (Capture)
        Captures.push_back(Mapping.lookupOrDefault(Capture));
      continue;
    }
    auto [Var, Constant] = FlagValues.lookup(Flag);
    Flags.push_back(Flag);
    if (Var) {
      Modes.push_back(FlagMode::Captured);
      Captures.push_back(Var);
    } else {
      Modes.push_back(*Constant ? FlagMode::Required : FlagMode::Negated);
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

mlir::FailureOr<bool>
Expander::inlineBranch(UseOp Use, MatcherOp Matcher, BranchOp Branch,
                       ArrayRef<MatcherOperandView> CallerOps,
                       StringRef UsePrefix, AltOp Alt) {
  return BranchInliner(Builder, Use, Matcher, Branch, CallerOps, UsePrefix, Alt)
      .run();
}

LogicalResult Expander::expand(UseOp Use) {
  auto Matcher = mlir::SymbolTable::lookupNearestSymbolFrom<MatcherOp>(
      Use, Use.getMatcherAttr());
  std::string UsePrefix = Use.getResultName()
                              ? Use.getResultName()->str()
                              : ("#" + Twine(NextAnonymousUse++)).str();
  SmallVector<MatcherOperandView, 8> CallerOps = getMatcherOperands(Use);
  bool Commutative = Use.isCommutative();
  std::optional<unsigned> OrSelf = Use.getOrSelfIndex();

  Builder.setInsertionPoint(Use);
  unsigned NumRegions =
      range_size(Matcher.getBody().front().getOps<BranchOp>()) *
      (Commutative ? 2 : 1);
  if (OrSelf)
    ++NumRegions;
  mlir::StringAttr ResultName;
  if (std::optional<StringRef> Name = Use.getResultName())
    ResultName = Builder.getStringAttr(*Name);
  mlir::StringAttr OrSelfOf;
  if (OrSelf)
    OrSelfOf = Builder.getStringAttr(Use.getMatcher());
  AltOp Alt = AltOp::create(Builder, Use.getLoc(), Use.getType(), ResultName,
                            /*commuted=*/false, OrSelfOf,
                            /*or_self_region=*/mlir::IntegerAttr(), NumRegions);

  // The regions are filled in order; one left empty (a branch that does not
  // fit) is removed after.
  unsigned NextRegion = 0;
  SmallVector<unsigned, 4> Filled;
  // inlineBranch fills the last region of a scratch alt; move it into place.
  for (BranchOp Branch : Matcher.getBody().front().getOps<BranchOp>()) {
    for (unsigned Order = 0; Order != (Commutative ? 2u : 1u); ++Order) {
      SmallVector<MatcherOperandView, 8> Ops(CallerOps);
      if (Order == 1)
        std::swap(Ops[0], Ops[1]);
      OpBuilder::InsertionGuard Guard(Builder);
      Builder.setInsertionPoint(Alt);
      AltOp Temp = AltOp::create(Builder, Use.getLoc(), Use.getType(),
                                 mlir::StringAttr(), /*commuted=*/false,
                                 mlir::StringAttr(), mlir::IntegerAttr(), 1);
      mlir::FailureOr<bool> Fits =
          inlineBranch(Use, Matcher, Branch, Ops, UsePrefix, Temp);
      if (mlir::failed(Fits)) {
        Temp.erase();
        return mlir::failure();
      }
      unsigned Index = NextRegion++;
      if (*Fits) {
        Alt->getRegion(Index).takeBody(Temp->getRegion(0));
        Filled.push_back(Index);
      }
      Temp.erase();
    }
  }
  if (OrSelf) {
    // ':o(N)' lets the use match its Nth operand in place of the matcher.
    unsigned Index = NextRegion++;
    mlir::Block &Region = Alt->getRegion(Index).emplaceBlock();
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Region);
    Value Operand = CallerOps[*OrSelf].Val;
    if (Value Capture = Use.getCapture())
      BindOp::create(Builder, Use.getLoc(), Capture, Operand);
    YieldOp::create(Builder, Use.getLoc(), Operand);
    Filled.push_back(Index);
  }
  // Drop the regions of branches that cannot fit, keeping the order.
  if (Filled.size() != Alt->getNumRegions()) {
    AltOp New = AltOp::create(Builder, Use.getLoc(), Use.getType(),
                              Alt.getResultNameAttr(), Alt.getCommuted(),
                              Alt.getOrSelfOfAttr(), Alt.getOrSelfRegionAttr(),
                              Filled.size());
    for (auto [To, From] : enumerate(Filled))
      New->getRegion(To).takeBody(Alt->getRegion(From));
    Alt.erase();
    Alt = New;
  }
  // A use's ':o' has its operand last.
  if (OrSelf)
    Alt.setOrSelfRegionAttr(
        Builder.getI32IntegerAttr(Alt->getNumRegions() - 1));
  Use.getResult().replaceAllUsesWith(Alt.getResult());
  Use.erase();
  return mlir::success();
}

namespace {
struct ExpandMatchersPass
    : public mlir::PassWrapper<ExpandMatchersPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(ExpandMatchersPass)
  StringRef getArgument() const override { return "mpir-expand-matchers"; }
  StringRef getDescription() const override {
    return "Inline the uses of 'match' matchers as mpir.alt";
  }
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

std::unique_ptr<mlir::Pass> createExpandMatchersPass() {
  return std::make_unique<lowering::ExpandMatchersPass>();
}

} // namespace metaphir
} // namespace llvm
