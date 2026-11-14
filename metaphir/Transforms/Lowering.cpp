//===- Lowering.cpp - Lower surface patterns ------------------------------===//
//
// See Lowering.h. These passes do what PatternLowering does to MetaphIR IR,
// with one difference of representation: where PatternLowering makes one
// whole pattern per choice (each branch of each matcher use, each operand
// order of ':c'), these make an mpir.alt where the choice is, and share the
// rest of the pattern.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Pattern/SurfacePrinter.h"
#include "metaphir/IR/MetaFlag.h"
#include "mlir/IR/Builders.h"
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

static Sort sortOf(Value V) { return cast<SortType>(V.getType()).getSort(); }

static SortType sortType(mlir::MLIRContext *Context, Sort S) {
  return SortType::get(Context, S);
}

template <typename T> static std::string toString(const T &Print) {
  std::string Result;
  raw_string_ostream OS(Result);
  Print(OS);
  return Result;
}

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

/// Accessors shared by mpir.inst and mpir.use.
struct MatcherUse {
  Operation *Op;

  explicit MatcherUse(Operation *Op) : Op(Op) {}
  InstOp inst() const { return dyn_cast<InstOp>(Op); }
  UseOp use() const { return dyn_cast<UseOp>(Op); }

#define FORWARD(Type, Name)                                                    \
  Type Name() const { return inst() ? inst().Name() : use().Name(); }
  FORWARD(std::optional<StringRef>, getResultName)
  FORWARD(std::optional<mlir::ArrayAttr>, getMetaflags)
  FORWARD(std::optional<mlir::ArrayAttr>, getOperandMetaflags)
  FORWARD(ArrayRef<int32_t>, getFlags)
  FORWARD(ArrayRef<int32_t>, getFlagModes)
  FORWARD(mlir::OperandRange, getFlagCaptures)
  FORWARD(ArrayRef<int32_t>, getOperandKinds)
  FORWARD(std::optional<bool>, getTreatIntAsVec)
#undef FORWARD
  Value getCapture() const {
    return inst() ? Value(inst().getCapture()) : Value(use().getCapture());
  }
  Value getParentBlock() const {
    return inst() ? Value(inst().getParentBlock())
                  : Value(use().getParentBlock());
  }
  Value result() const { return Op->getResult(0); }
};

/// The pieces of an mpir.inst or mpir.use, for building another.
struct MatcherParts {
  std::string ResultName;
  bool HasResultName = false;
  SmallVector<int32_t, 4> Flags, Modes;
  SmallVector<Value, 2> FlagCaptures;
  SmallVector<MatcherOperandView, 8> Operands;
  SmallVector<Attribute, 4> MetaFlags;
  SmallVector<Attribute, 8> OperandMetaFlags;
  std::optional<bool> TreatIntAsVec;
  Value Capture;
  Value ParentBlock;

  static MatcherParts of(MatcherUse U) {
    MatcherParts P;
    if (std::optional<StringRef> Name = U.getResultName()) {
      P.ResultName = Name->str();
      P.HasResultName = true;
    }
    P.Flags.assign(U.getFlags().begin(), U.getFlags().end());
    P.Modes.assign(U.getFlagModes().begin(), U.getFlagModes().end());
    for (Value V : U.getFlagCaptures())
      P.FlagCaptures.push_back(V);
    P.Operands = getMatcherOperands(U.Op);
    if (std::optional<mlir::ArrayAttr> Flags = U.getMetaflags())
      P.MetaFlags.assign(Flags->begin(), Flags->end());
    if (std::optional<mlir::ArrayAttr> Flags = U.getOperandMetaflags())
      P.OperandMetaFlags.assign(Flags->begin(), Flags->end());
    P.TreatIntAsVec = U.getTreatIntAsVec();
    P.Capture = U.getCapture();
    P.ParentBlock = U.getParentBlock();
    return P;
  }

  /// Builds an mpir.inst (with Opcode) or an mpir.use (with Matcher).
  Operation *build(OpBuilder &Builder, Location Loc, StringRef OpName,
                   mlir::NamedAttribute Key, bool SwappedPredicate = false) {
    mlir::MLIRContext *Context = Builder.getContext();
    mlir::OperationState State(Loc, OpName);
    State.addAttribute(Key.getName(), Key.getValue());
    if (HasResultName)
      State.addAttribute("result_name", Builder.getStringAttr(ResultName));
    State.addAttribute("flags", Builder.getDenseI32ArrayAttr(Flags));
    State.addAttribute("flag_modes", Builder.getDenseI32ArrayAttr(Modes));
    SmallVector<int32_t, 8> Kinds;
    SmallVector<Value, 8> Values;
    for (const MatcherOperandView &Op : Operands) {
      Kinds.push_back(int32_t(Op.Kind));
      if (Op.Type)
        Values.push_back(Op.Type);
      if (Op.Val)
        Values.push_back(Op.Val);
    }
    State.addAttribute("operand_kinds", Builder.getDenseI32ArrayAttr(Kinds));
    if (!MetaFlags.empty())
      State.addAttribute("metaflags", Builder.getArrayAttr(MetaFlags));
    if (any_of(OperandMetaFlags,
               [](Attribute A) { return !cast<mlir::ArrayAttr>(A).empty(); }))
      State.addAttribute("operand_metaflags",
                         Builder.getArrayAttr(OperandMetaFlags));
    if (TreatIntAsVec)
      State.addAttribute("treat_int_as_vec",
                         Builder.getBoolAttr(*TreatIntAsVec));
    if (SwappedPredicate)
      State.addAttribute("swapped_predicate", Builder.getUnitAttr());
    if (Capture)
      State.addOperands(Capture);
    if (ParentBlock)
      State.addOperands(ParentBlock);
    State.addOperands(FlagCaptures);
    State.addOperands(Values);
    State.addAttribute(
        "operandSegmentSizes",
        Builder.getDenseI32ArrayAttr({Capture ? 1 : 0, ParentBlock ? 1 : 0,
                                      int32_t(FlagCaptures.size()),
                                      int32_t(Values.size())}));
    State.addTypes(sortType(Context, Sort::Instruction));
    return Builder.create(State);
  }
};

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

/// Whether Flag is ':c' or ':o', which are choices rather than constraints.
static bool isChoiceFlag(MetaFlagAttr Flag) {
  MetaFlag::MetaFlagID ID = MetaFlag::getMetaFlagID(Flag.getName());
  return ID == MetaFlag::MF_c || ID == MetaFlag::MF_o;
}

mlir::FailureOr<Value> Desugarer::lower(MetaFlagAttr Flag, Value Subject) {
  StringRef Name = Flag.getName().getValue();
  Location Loc(Flag.getLoc());
  if (!Subject)
    return error(Flag) << "metaflag ':" << Name
                       << "' has no value to use as its subject";
  mlir::MLIRContext *Context = Builder.getContext();
  auto BooleanType = sortType(Context, Sort::Boolean);
  switch (MetaFlag::getMetaFlagID(Name)) {
  case MetaFlag::MF_not: {
    auto Inner = dyn_cast<MetaFlagAttr>(Flag.getArgs()[0]);
    mlir::FailureOr<Value> Lowered = lower(Inner, Subject);
    if (mlir::failed(Lowered))
      return mlir::failure();
    return Value(mpir_expr::CallOp::create(
        Builder, Loc, BooleanType, unsigned(Constraint::O_Not),
        unsigned(Constraint::Unary), ValueRange{*Lowered}, Value()));
  }
  case MetaFlag::MF_or: {
    Value Result;
    for (Attribute A : Flag.getArgs()) {
      mlir::FailureOr<Value> Lowered = lower(cast<MetaFlagAttr>(A), Subject);
      if (mlir::failed(Lowered))
        return mlir::failure();
      Result = Result ? Value(mpir_expr::CallOp::create(
                            Builder, Loc, BooleanType,
                            unsigned(Constraint::O_LogicalOr),
                            unsigned(Constraint::Binary),
                            ValueRange{Result, *Lowered}, Value()))
                      : *Lowered;
    }
    return Result;
  }
  case MetaFlag::MF_c:
  case MetaFlag::MF_o:
    llvm_unreachable("choice flags are not constraints");
  case MetaFlag::UnknownMetaFlag:
    break;
  }
  auto Def = dyn_cast_or_null<MetaFlagDefOp>(
      mlir::SymbolTable::lookupSymbolIn(Module, Name));
  if (!Def)
    return error(Flag) << "unknown metaflag ':" << Name << "'";
  return lowerDefined(Flag, Def, Subject);
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
  Location Loc(Flag.getLoc());

  // What each parameter is bound to: the subject, then the arguments.
  SmallVector<Value, 4> Bound;
  Bound.push_back(Subject);
  for (Attribute A : Args) {
    auto Int = dyn_cast<mlir::IntegerAttr>(A);
    if (!Int)
      return error(Flag) << "metaflag ':" << Name
                         << "' expects integer arguments";
    Bound.push_back(Value());
  }

  // Clone the body, reading the parameters as what they are bound to.
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
    if (!SubjectDef || isa<VarOp>(SubjectDef)) {
      // A meta variable is read as its own sort, once known.
      Sort S = sortOf(Subject);
      Sort ReadSort =
          S != Sort::Unknown ? getRepresentation(resolveSort(S)) : sortOf(Read);
      Mapping.map(Read.getResult(),
                  mpir_expr::ReadOp::create(
                      Builder, ReadLoc, sortType(Context, ReadSort), Subject));
      continue;
    }
    if (isa<InstOp, UseOp, AltOp>(SubjectDef)) {
      Mapping.map(Read.getResult(),
                  mpir_expr::ReadOp::create(Builder, ReadLoc,
                                            sortType(Context, Sort::Value),
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
  (void)Loc;
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
  SmallVector<Operation *, 16> Matchers;
  for (Operation &Op : Block)
    if (isa<InstOp, UseOp>(Op))
      Matchers.push_back(&Op);

  for (Operation *Op : Matchers) {
    MatcherUse U(Op);
    if (FirstRequire)
      Builder.setInsertionPoint(FirstRequire);
    else
      Builder.setInsertionPointToEnd(&Block);
    auto Desugar = [&](ArrayRef<Attribute> Flags, Value Subject,
                       Value Anchor) -> LogicalResult {
      for (Attribute A : Flags) {
        auto Flag = cast<MetaFlagAttr>(A);
        if (isChoiceFlag(Flag))
          continue;
        mlir::FailureOr<Value> C = lower(Flag, Subject);
        if (mlir::failed(C))
          return mlir::failure();
        DenseSet<Operation *> Visited;
        setDefaultAnchor(*C, Anchor, Visited);
        auto Require = RequireOp::create(Builder, Location(Flag.getLoc()), *C);
        // Checked before the pattern's own constraints, as what the flags
        // say a binding is decides whether the others can be evaluated.
        Require->setAttr("from_metaflag", Builder.getUnitAttr());
      }
      return mlir::success();
    };

    Value Subject = U.getCapture() ? U.getCapture() : U.result();
    SmallVector<Attribute, 4> Kept;
    if (std::optional<mlir::ArrayAttr> Flags = U.getMetaflags()) {
      if (mlir::failed(Desugar(Flags->getValue(), Subject, U.result())))
        return mlir::failure();
      for (Attribute A : *Flags)
        if (isChoiceFlag(cast<MetaFlagAttr>(A)))
          Kept.push_back(A);
    }
    if (std::optional<mlir::ArrayAttr> PerOperand = U.getOperandMetaflags()) {
      SmallVector<MatcherOperandView, 8> Operands = getMatcherOperands(Op);
      for (auto [Index, A] : enumerate(*PerOperand))
        if (mlir::failed(Desugar(cast<mlir::ArrayAttr>(A).getValue(),
                                 Operands[Index].Kind == OperandKind::TypeOnly
                                     ? Value()
                                     : Operands[Index].Val,
                                 U.result())))
          return mlir::failure();
      Op->removeAttr("operand_metaflags");
    }
    if (Kept.empty())
      Op->removeAttr("metaflags");
    else
      Op->setAttr("metaflags", Builder.getArrayAttr(Kept));
  }
  return mlir::success();
}

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
                                     ArrayRef<Attribute> CallerOperandFlags,
                                     StringRef UsePrefix, AltOp Alt);
};
} // namespace

/// The positions of the archetype's parameters among a use's operands:
/// (parameter, operand) pairs for its types, then for its values.
static void archetypePositions(
    Instruction::OperandSyntax Syntax, unsigned Arity,
    SmallVectorImpl<std::pair<unsigned, unsigned>> &TypePositions,
    SmallVectorImpl<std::pair<unsigned, unsigned>> &ValuePositions) {
  switch (Syntax) {
  case Instruction::OperandSyntax::Nary:
    for (unsigned I = 0; I != Arity; ++I) {
      TypePositions.push_back({2 * I, I});
      ValuePositions.push_back({2 * I + 1, I});
    }
    break;
  case Instruction::OperandSyntax::Binary:
    TypePositions.push_back({0, 0});
    ValuePositions.push_back({1, 0});
    ValuePositions.push_back({2, 1});
    break;
  case Instruction::OperandSyntax::Cast:
    TypePositions.push_back({0, 0});
    ValuePositions.push_back({1, 0});
    TypePositions.push_back({2, 1});
    break;
  case Instruction::OperandSyntax::Custom:
    llvm_unreachable("composite matchers use a shared archetype");
  }
}

mlir::FailureOr<bool>
Expander::inlineBranch(UseOp Use, MatcherOp Matcher, BranchOp Branch,
                       ArrayRef<MatcherOperandView> CallerOps,
                       ArrayRef<Attribute> CallerOperandFlags,
                       StringRef UsePrefix, AltOp Alt) {
  mlir::MLIRContext *Context = Builder.getContext();
  mlir::Block &Body = Branch.getBody().front();
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

  mlir::IRMapping Mapping;
  // Branch arguments bound to a type, and the width variable an 'i?n'
  // parameter's argument also stands for.
  DenseMap<Value, Value> ArgTypes;

  SmallVector<std::pair<unsigned, unsigned>, 8> TypePositions, ValuePositions;
  archetypePositions(Instruction::OperandSyntax(Matcher.getSyntax()),
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
                                         sortType(Context, Sort::Value),
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

  // The root: what the branch yields.
  auto Yield = *Body.getOps<YieldOp>().begin();
  MatcherUse Root(Yield.getValue().getDefiningOp());

  // Bind the matcher's supported flags. For each one, the use either omits
  // it, requires it, negates it, or captures it; a branch may also fix its
  // value. FlagValue is what the root's capture of the flag stands for: a
  // boolean constant or a meta variable.
  MatcherUse UseView(Use);
  SmallVector<std::pair<Value, bool>, 2> FixedFlags;
  DenseMap<int32_t, std::pair<Value, std::optional<bool>>> FlagValues;
  ArrayRef<int32_t> UseFlags = Use.getFlags();
  ArrayRef<int32_t> UseModes = Use.getFlagModes();
  SmallVector<Value, 4> UseCaptures;
  {
    unsigned Next = 0;
    for (int32_t Mode : UseModes)
      UseCaptures.push_back(FlagMode(Mode) == FlagMode::Captured
                                ? Use.getFlagCaptures()[Next++]
                                : Value());
  }
  ArrayRef<int32_t> FixedIDs = Branch.getFixedFlags();
  ArrayRef<bool> FixedValues = Branch.getFixedFlagValues();
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPoint(Alt);
  for (int32_t FlagID : Matcher.getSupportedFlags()) {
    const int32_t *UseFlag = find(UseFlags, FlagID);
    std::optional<unsigned> UseIndex;
    if (UseFlag != UseFlags.end())
      UseIndex = UseFlag - UseFlags.begin();
    // A flag forwarded from an enclosing use that omitted it is omitted too.
    if (UseIndex && isWildcardCapture(UseCaptures[*UseIndex]))
      UseIndex.reset();
    std::optional<bool> Fixed;
    if (const int32_t *F = find(FixedIDs, FlagID); F != FixedIDs.end())
      Fixed = FixedValues[F - FixedIDs.begin()];

    std::pair<Value, std::optional<bool>> FlagValue;
    Value UseCapture = UseIndex ? UseCaptures[*UseIndex] : Value();
    if (UseIndex && !UseCapture) {
      bool Required = FlagMode(UseModes[*UseIndex]) != FlagMode::Negated;
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
          Builder, Use.getLoc(), sortType(Context, Sort::Boolean),
          Builder.getStringAttr(
              (OmittedFlagPrefix + UsePrefix + "$" +
               InstructionFlag::getName(InstructionFlag::FlagID(FlagID)))
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
                Builder, Use.getLoc(), sortType(Context, Sort::Value),
                mlir::IntegerAttr::get(Type, APInt(1, *FlagValue.second))));
      }
    }
  }

  // The root's capture is the use's capture, when the use names one.
  if (Root.getCapture() && Use.getCapture())
    Mapping.map(Root.getCapture(), Use.getCapture());

  // The branch's 'i?n' type patterns of a type parameter stand for the type
  // the use passes.
  DenseMap<Operation *, Value> ReplacedTypes;
  for (Operation &Op : Body)
    if (auto MetaInt = dyn_cast<MetaIntTypeOp>(Op))
      if (auto Arg = dyn_cast<mlir::BlockArgument>(MetaInt.getWidth()))
        if (Value Ty = ArgTypes.lookup(Arg))
          ReplacedTypes[&Op] = Ty;

  mlir::Block &Region = Alt->getRegion(Alt->getNumRegions() - 1).emplaceBlock();
  Builder.setInsertionPointToEnd(&Region);
  Location CallerLoc = Use.getLoc();
  std::optional<bool> UseTreatIntAsVec = Use.getTreatIntAsVec();
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
    // An instruction matcher: renamed after the use, placed in its block,
    // with its settings over the use's.
    MatcherUse BI(&Op);
    bool IsRoot = &Op == Root.Op;
    MatcherParts Parts = MatcherParts::of(BI);
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
      Parts.HasResultName = bool(Use.getResultName());
      Parts.ResultName = Use.getResultName().value_or("").str();
      if (Use.getCapture())
        Parts.Capture = Use.getCapture();
    } else if (Parts.HasResultName) {
      Parts.ResultName = (UsePrefix + "$" + Parts.ResultName).str();
    }
    // Flags: a supported flag on the root takes the use's flag.
    SmallVector<int32_t, 4> Flags, Modes;
    SmallVector<Value, 2> Captures;
    unsigned NextCapture = 0;
    for (auto [Flag, Mode] : zip(Parts.Flags, Parts.Modes)) {
      Value Capture = FlagMode(Mode) == FlagMode::Captured
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
        Modes.push_back(int32_t(FlagMode::Captured));
        Captures.push_back(Var);
      } else {
        Modes.push_back(
            int32_t(*Constant ? FlagMode::Required : FlagMode::Negated));
      }
    }
    Parts.Flags = Flags;
    Parts.Modes = Modes;
    Parts.FlagCaptures = Captures;
    Location Loc = mlir::CallSiteLoc::get(Op.getLoc(), CallerLoc);
    Operation *New =
        isa<InstOp>(Op)
            ? Parts.build(Builder, Loc, InstOp::getOperationName(),
                          Builder.getNamedAttr(
                              "opcode", cast<InstOp>(Op).getOpcodeAttr()))
            : Parts.build(Builder, Loc, UseOp::getOperationName(),
                          Builder.getNamedAttr(
                              "matcher", cast<UseOp>(Op).getMatcherAttr()));
    Mapping.map(Op.getResult(0), New->getResult(0));
  }
  // What the branch fixes of the flags the use captures.
  for (auto [Capture, Value] : FixedFlags) {
    auto Type = mlir::IntegerType::get(Context, 1, mlir::IntegerType::Unsigned);
    mlir::Value Constant =
        IntOp::create(Builder, CallerLoc, sortType(Context, Sort::Value),
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
  (void)CallerOperandFlags;
  return true;
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
  unsigned NumRegions = 0;
  for (BranchOp Branch : Matcher.getBody().front().getOps<BranchOp>())
    (void)Branch, NumRegions += Commutative ? 2 : 1;
  if (OrSelf)
    ++NumRegions;
  mlir::OperationState State(Use.getLoc(), AltOp::getOperationName());
  State.addTypes(Use.getType());
  for (unsigned I = 0; I != NumRegions; ++I)
    State.addRegion();
  auto Alt = cast<AltOp>(Builder.create(State));
  if (std::optional<StringRef> Name = Use.getResultName())
    Alt->setAttr("result_name", Builder.getStringAttr(*Name));

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
      mlir::OperationState Scratch(Use.getLoc(), AltOp::getOperationName());
      Scratch.addTypes(Use.getType());
      Scratch.addRegion();
      OpBuilder::InsertionGuard Guard(Builder);
      Builder.setInsertionPoint(Alt);
      auto Temp = cast<AltOp>(Builder.create(Scratch));
      mlir::FailureOr<bool> Fits =
          inlineBranch(Use, Matcher, Branch, Ops, {}, UsePrefix, Temp);
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
    Alt->setAttr("or_self_of", Builder.getStringAttr(Use.getMatcher()));
    Filled.push_back(Index);
  }
  // Drop the regions of branches that cannot fit, keeping the order.
  if (Filled.size() != Alt->getNumRegions()) {
    mlir::OperationState Compact(Use.getLoc(), AltOp::getOperationName());
    Compact.addTypes(Use.getType());
    Compact.addAttributes(Alt->getAttrs());
    for (unsigned I = 0; I != Filled.size(); ++I)
      Compact.addRegion();
    auto New = cast<AltOp>(Builder.create(Compact));
    for (auto [To, From] : enumerate(Filled))
      New->getRegion(To).takeBody(Alt->getRegion(From));
    Alt.erase();
    Alt = New;
  }
  Use.getResult().replaceAllUsesWith(Alt.getResult());
  Use.erase();
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// mpir-lower-alternatives
//===----------------------------------------------------------------------===//

/// Replaces ':c' and ':o' on Inst by mpir.alt.
static void lowerChoices(InstOp Inst) {
  bool Commutative = Inst.isCommutative();
  std::optional<unsigned> OrSelf = Inst.getOrSelfIndex();
  if (!Commutative && !OrSelf)
    return;
  OpBuilder Builder(Inst);
  Location Loc = Inst.getLoc();
  MatcherParts Parts = MatcherParts::of(MatcherUse(Inst));
  Parts.MetaFlags.clear();
  Parts.OperandMetaFlags.clear();

  // The value operands, by their position among them.
  SmallVector<unsigned, 4> ValuePositions;
  for (auto [Index, Op] : enumerate(Parts.Operands))
    if (isValueOperand(Op.Kind))
      ValuePositions.push_back(Index);
  std::optional<std::pair<unsigned, unsigned>> Swapped;
  if (Commutative) {
    unsigned NumOperands = ValuePositions.size();
    if (Inst.getOpcode().getValue() == Instruction::I_call && NumOperands == 3)
      Swapped = {1u, 2u};
    else if (NumOperands == 2)
      Swapped = {0u, 1u};
  }
  auto Key = Builder.getNamedAttr("opcode", Inst.getOpcodeAttr());
  auto Build = [&](bool Swap) -> Value {
    MatcherParts P = Parts;
    bool SwappedPredicate = false;
    if (Swap) {
      std::swap(P.Operands[ValuePositions[Swapped->first]],
                P.Operands[ValuePositions[Swapped->second]]);
      Instruction::InstructionID ID = Inst.getOpcode().getValue();
      SwappedPredicate = ID == Instruction::I_icmp || ID == Instruction::I_fcmp;
    }
    return P
        .build(Builder, Loc, InstOp::getOperationName(), Key, SwappedPredicate)
        ->getResult(0);
  };

  auto MakeAlt = [&](unsigned NumRegions) {
    mlir::OperationState State(Loc, AltOp::getOperationName());
    State.addTypes(Inst.getType());
    for (unsigned I = 0; I != NumRegions; ++I)
      State.addRegion();
    auto Alt = cast<AltOp>(Builder.create(State));
    if (std::optional<StringRef> Name = Inst.getResultName())
      Alt->setAttr("result_name", Builder.getStringAttr(*Name));
    return Alt;
  };
  auto Fill = [&](AltOp Alt, unsigned Index, function_ref<Value()> Body) {
    mlir::Block &Block = Alt->getRegion(Index).emplaceBlock();
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Block);
    YieldOp::create(Builder, Loc, Body());
  };

  // The instruction itself: in its order, or (with ':c') either.
  auto Itself = [&]() -> Value {
    if (!Swapped)
      return Build(false);
    AltOp Orders = MakeAlt(2);
    Fill(Orders, 0, [&] { return Build(false); });
    Fill(Orders, 1, [&] { return Build(true); });
    return Orders.getResult();
  };
  Value Result;
  if (OrSelf) {
    AltOp Alt = MakeAlt(2);
    Fill(Alt, 0, Itself);
    Fill(Alt, 1, [&]() -> Value {
      Value Operand;
      unsigned Position = *OrSelf;
      for (const MatcherOperandView &Op : Parts.Operands)
        if (isValueOperand(Op.Kind) && Position-- == 0) {
          Operand = Op.Val;
          break;
        }
      if (Parts.Capture)
        BindOp::create(Builder, Loc, Parts.Capture, Operand);
      return Operand;
    });
    Alt->setAttr("or_self_of", Builder.getStringAttr(Instruction::getOpcodeName(
                                   Inst.getOpcode().getValue())));
    Result = Alt.getResult();
  } else {
    Result = Itself();
  }
  Inst.getResult().replaceAllUsesWith(Result);
  Inst.erase();
}

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
      Bindings Itself;
      collectRegion(Itself, Alt->getRegion(0));
      for (Value Var : Itself.Variables)
        BoundBy->try_emplace(Var, Alt);
      collectRegion(*this, Alt->getRegion(1));
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

} // namespace lowering

SmallVector<mlir::Operation *, 4> getPatternRoots(mlir::Block &Block) {
  using namespace mpir;
  using mlir::Operation;
  SmallVector<Operation *, 4> Roots;
  for (Operation &Op : Block) {
    if (!isa<InstOp, AltOp>(Op))
      continue;
    bool Used = any_of(Op.getResult(0).getUses(), [](mlir::OpOperand &Use) {
      Operation *Owner = Use.getOwner();
      if (isa<YieldOp>(Owner))
        return true;
      if (auto Inst = dyn_cast<InstOp>(Owner)) {
        for (const MatcherOperandView &O : getMatcherOperands(Inst))
          if (isValueOperand(O.Kind) && O.Val == Use.get())
            return true;
      }
      return false;
    });
    if (!Used)
      Roots.push_back(&Op);
  }
  return Roots;
}

namespace lowering {

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

//===----------------------------------------------------------------------===//
// Passes
//===----------------------------------------------------------------------===//

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

struct LowerAlternativesPass
    : public mlir::PassWrapper<LowerAlternativesPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(LowerAlternativesPass)
  StringRef getArgument() const override { return "mpir-lower-alternatives"; }
  StringRef getDescription() const override {
    return "Turn ':c' and ':o' into mpir.alt";
  }
  void runOnOperation() override {
    for (PatternOp Pattern : getOperation().getOps<PatternOp>()) {
      SmallVector<InstOp, 16> Insts;
      Pattern.walk([&](InstOp Inst) {
        if (Inst.getMetaflags())
          Insts.push_back(Inst);
      });
      for (InstOp Inst : Insts)
        lowerChoices(Inst);
    }
  }
};

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

std::unique_ptr<mlir::Pass> createDesugarMetaFlagsPass() {
  return std::make_unique<lowering::DesugarMetaFlagsPass>();
}
std::unique_ptr<mlir::Pass> createExpandMatchersPass() {
  return std::make_unique<lowering::ExpandMatchersPass>();
}
std::unique_ptr<mlir::Pass> createLowerAlternativesPass() {
  return std::make_unique<lowering::LowerAlternativesPass>();
}
std::unique_ptr<mlir::Pass> createCheckBindingsPass() {
  return std::make_unique<lowering::CheckBindingsPass>();
}

void buildLoweringPipeline(mlir::OpPassManager &PM) {
  PM.addPass(createDesugarMetaFlagsPass());
  PM.addPass(createExpandMatchersPass());
  PM.addPass(createLowerAlternativesPass());
  PM.addPass(createCheckBindingsPass());
}

void registerLoweringPasses() {
  mlir::PassRegistration<lowering::DesugarMetaFlagsPass>();
  mlir::PassRegistration<lowering::ExpandMatchersPass>();
  mlir::PassRegistration<lowering::LowerAlternativesPass>();
  mlir::PassRegistration<lowering::CheckBindingsPass>();
  mlir::PassPipelineRegistration<>("mpir-lower",
                                   "Lower surface patterns to the lowered form",
                                   buildLoweringPipeline);
}

mlir::LogicalResult lowerPatternModule(mlir::ModuleOp Module,
                                       const SourceMgr &SM, raw_ostream &OS,
                                       const char *ProgName) {
  mlir::MLIRContext *Context = Module.getContext();
  // Diagnostics print as the parser's do, at the pattern source they are
  // about.
  mlir::ScopedDiagnosticHandler Handler(Context, [&](mlir::Diagnostic &Diag) {
    SMRange Range = getSourceRange(Diag.getLocation());
    std::string Message = Diag.str();
    if (Range.Start.isValid() && SM.FindBufferContainingLoc(Range.Start)) {
      SmallVector<SMRange, 1> Ranges;
      if (Range.End.isValid() && Range.End != Range.Start)
        Ranges.push_back(Range);
      SM.GetMessage(Range.Start, SourceMgr::DK_Error, Message, Ranges)
          .print(ProgName, OS, /*ShowColors=*/false);
    } else {
      if (ProgName)
        OS << ProgName << ": ";
      OS << "error: " << Message << "\n";
    }
    return mlir::success();
  });
  mlir::PassManager PM(Context);
  buildLoweringPipeline(PM);
  return PM.run(Module);
}

} // namespace metaphir
} // namespace llvm
