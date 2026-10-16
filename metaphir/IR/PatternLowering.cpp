#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Pattern.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

/// The fresh variable a use that omits a flag passes for it to the matcher's
/// root (see inlineBranch); a use nested in that body then also omits it.
static constexpr StringLiteral OmittedFlagPrefix = "_flag$";
static bool isWildcardCapture(const MetaVariable *Capture) {
  return Capture && Capture->getName().starts_with(OmittedFlagPrefix);
}

static bool isMetaType(const Type *T) {
  return isa<MetaIRType>(T) || isa<MetaIntegerType>(T);
}

template <typename T> static std::string toString(const T &Object) {
  std::string Result;
  raw_string_ostream(Result) << Object;
  return Result;
}

static Error makeError(SourceRange Range, const Twine &Message) {
  return make_error<LoweringError>(Range, Message);
}

char LoweringError::ID = 0;

void printLoweringErrors(Error E, const SourceMgr &SM,
                         const MIRContext &Context, raw_ostream &OS,
                         const char *ProgName, bool ShowColors) {
  auto Print = [&](const SourceMgr *Holder, SMLoc Loc, ArrayRef<SMRange> Ranges,
                   const Twine &Message) {
    if (Holder) {
      Holder->GetMessage(Loc, SourceMgr::DK_Error, Message, Ranges)
          .print(ProgName, OS, ShowColors);
      return;
    }
    if (ProgName)
      OS << ProgName << ": ";
    OS << "error: " << Message << "\n";
  };
  handleAllErrors(
      std::move(E),
      [&](const LoweringError &L) {
        const SourceMgr *Holder = nullptr;
        if (L.Range.Begin.isValid()) {
          if (SM.FindBufferContainingLoc(L.Range.Begin))
            Holder = &SM;
          else if (Context.getLibrarySourceMgr().FindBufferContainingLoc(
                       L.Range.Begin))
            Holder = &Context.getLibrarySourceMgr();
        }
        SmallVector<SMRange, 1> Ranges;
        if (L.Range.End.isValid())
          Ranges.push_back(SMRange(L.Range.Begin, L.Range.End));
        Print(Holder, L.Range.Begin, Ranges, L.Message);
      },
      [&](const ErrorInfoBase &Other) {
        Print(nullptr, SMLoc(), {}, Other.message());
      });
}

namespace {

/// A substitution of pattern entities, applied to a matcher branch when it is
/// inlined at a use and to a metaflag body when it is desugared. Meta
/// variables are identified by object, never by name, so a substitution can
/// not capture an unrelated variable that happens to share a spelling.
class Substitution {
public:
  explicit Substitution(MIRContext &Context) : Context(Context) {}

  /// Replacement values of meta variables. A type variable (of a MetaIRType
  /// or the width of a MetaIntegerType) may be mapped to another meta
  /// variable here, which renames it.
  DenseMap<const MetaVariable *, Value *> Values;
  /// Replacement types of type variables.
  DenseMap<const MetaVariable *, Type *> Types;
  /// Replacement instructions.
  DenseMap<const Instruction *, Instruction *> Instructions;

  Value *value(Value *V) const;
  Type *type(Type *T) const;
  /// For positions that must hold a meta variable (captures, operand arrays):
  /// V's replacement if that is a meta variable, V otherwise.
  MetaVariable *variable(MetaVariable *V) const;
  Expected<Constraint *> constraint(Constraint *C) const;
  const Instruction *contextInstruction(const Instruction *I) const {
    return I ? Instructions.lookup_or(I, const_cast<Instruction *>(I))
             : nullptr;
  }

  /// The operands of I with this substitution applied, keyed and unkeyed.
  SmallVector<MatcherOperand, 8> operands(const Instruction &I) const;

private:
  MIRContext &Context;
};

} // namespace

Value *Substitution::value(Value *V) const {
  if (!V)
    return nullptr;
  if (auto *MV = dyn_cast<MetaVariable>(V))
    if (Value *Replacement = Values.lookup(MV))
      V = Replacement;
  if (auto *I = dyn_cast<Instruction>(V))
    return Instructions.lookup_or(I, I);
  if (auto *Aggregate = dyn_cast<AggregateConstant>(V)) {
    SmallVector<Type *, 8> ElementTypes;
    SmallVector<Value *, 8> Elements;
    bool Changed = false;
    for (Type *T : Aggregate->getElementTypes()) {
      ElementTypes.push_back(type(T));
      Changed |= ElementTypes.back() != T;
    }
    for (Value *E : Aggregate->getElements()) {
      Elements.push_back(value(E));
      Changed |= Elements.back() != E;
    }
    if (Changed)
      return AggregateConstant::create(Context, ElementTypes, Elements,
                                       Aggregate->getDelimiter(),
                                       Aggregate->getSourceRange());
  }
  return V;
}

MetaVariable *Substitution::variable(MetaVariable *V) const {
  if (!V)
    return nullptr;
  if (auto *Replacement = dyn_cast_or_null<MetaVariable>(Values.lookup(V)))
    return Replacement;
  return V;
}

Type *Substitution::type(Type *T) const {
  if (!T)
    return nullptr;
  switch (T->getTypeID()) {
  case Type::MetaIntegerTyID: {
    auto *MIT = cast<MetaIntegerType>(T);
    MetaVariable *Width = MIT->getBitWidthVariable();
    if (Type *Replacement = Types.lookup(Width))
      return Replacement;
    if (MetaVariable *Renamed = variable(Width); Renamed != Width)
      return MetaIntegerType::get(Context, Renamed, MIT->isByte());
    return T;
  }
  case Type::MetaTyID: {
    MetaVariable *Var = cast<MetaIRType>(T)->getVariable();
    if (Type *Replacement = Types.lookup(Var))
      return Replacement;
    if (MetaVariable *Renamed = variable(Var); Renamed != Var)
      return MetaIRType::get(Context, Renamed);
    return T;
  }
  case Type::PointerTyID: {
    auto *PT = cast<PointerType>(T);
    Type *Element = type(PT->getElementType());
    return Element == PT->getElementType()
               ? T
               : PointerType::get(Context, Element, PT->getAddressSpace());
  }
  case Type::ArrayTyID:
  case Type::FixedVectorTyID:
  case Type::ScalableVectorTyID: {
    auto *ST = cast<SequenceType>(T);
    Type *Element = type(ST->getElementType());
    uint64_t Count = ST->getCount();
    MetaVariable *CountVar = ST->getCountVariable();
    if (CountVar) {
      Value *Replacement = Values.lookup(CountVar);
      if (auto *Renamed = dyn_cast_or_null<MetaVariable>(Replacement)) {
        CountVar = Renamed;
      } else if (auto *Constant =
                     dyn_cast_or_null<IntegerConstant>(Replacement)) {
        Count = Constant->getValue().getZExtValue();
        CountVar = nullptr;
      }
    }
    if (Element == ST->getElementType() && Count == ST->getCount() &&
        CountVar == ST->getCountVariable())
      return T;
    if (auto *VT = dyn_cast<VectorType>(T))
      return VectorType::get(Context, VT->isScalable(), Element, Count,
                             CountVar);
    return ArrayType::get(Context, Element, Count, CountVar);
  }
  case Type::StructTyID: {
    auto *ST = cast<StructType>(T);
    SmallVector<Type *, 8> Elements;
    for (Type *E : ST->getElementTypes())
      Elements.push_back(type(E));
    if (ArrayRef<Type *>(Elements) == ST->getElementTypes())
      return T;
    return StructType::get(Context, Elements, ST->isPacked());
  }
  case Type::FunctionTyID: {
    auto *FT = cast<FunctionType>(T);
    Type *Return = type(FT->getReturnType());
    SmallVector<Type *, 8> Parameters;
    for (Type *P : FT->getParameterTypes())
      Parameters.push_back(type(P));
    if (Return == FT->getReturnType() &&
        ArrayRef<Type *>(Parameters) == FT->getParameterTypes())
      return T;
    return FunctionType::get(Context, Return, Parameters, FT->isVarArg());
  }
  default:
    return T;
  }
}

Expected<Constraint *> Substitution::constraint(Constraint *C) const {
  if (!C)
    return nullptr;
  Constraint *Result = nullptr;
  switch (C->getConstraintID()) {
  case Constraint::Integer:
  case Constraint::Boolean:
  case Constraint::String:
    return C;
  case Constraint::Array: {
    auto *AC = cast<ArrayConstraint>(C);
    SmallVector<Constraint *, 4> Elements;
    for (Constraint *Element : AC->getElements()) {
      Expected<Constraint *> New = constraint(Element);
      if (!New)
        return New.takeError();
      Elements.push_back(*New);
    }
    Result = ArrayConstraint::create(Context, AC->getSort(), Elements,
                                     AC->getSourceRange());
    break;
  }
  case Constraint::ArrayAccess: {
    auto *Access = cast<ArrayAccessConstraint>(C);
    Expected<Constraint *> Array = constraint(Access->getArray());
    if (!Array)
      return Array.takeError();
    Expected<Constraint *> Index = constraint(Access->getIndex());
    if (!Index)
      return Index.takeError();
    Result = ArrayAccessConstraint::create(Context, Access->getSort(), *Array,
                                           *Index, Access->getSourceRange());
    break;
  }
  case Constraint::Variable: {
    auto *VC = cast<VariableConstraint>(C);
    Value *Original = VC->getVariable();
    Value *Target = value(Original);
    if (auto *Var = dyn_cast<MetaVariable>(Target)) {
      Sort Type = Var != Original && Var->getSort() != Sort::Unknown
                      ? getRepresentation(Var->getSort())
                      : VC->getSort();
      Result =
          VariableConstraint::create(Context, Var, Type, VC->getSourceRange());
    } else if (isa<Instruction>(Target)) {
      Result = VariableConstraint::create(
          Context, Target,
          isa<Instruction>(Original) ? VC->getSort() : Sort::Value,
          VC->getSourceRange());
    } else if (auto *IC = dyn_cast<IntegerConstant>(Target)) {
      const APSInt &Number = IC->getValue();
      if (VC->getSort() == Sort::Boolean && Number.getBitWidth() == 1)
        return BooleanConstraint::create(Context, !Number.isZero(),
                                         VC->getSourceRange());
      return IntegerConstraint::create(Context, Number, VC->getSourceRange());
    } else {
      return makeError(C->getSourceRange(),
                       "'" + toString(*C) + "' is bound to '" +
                           toString(*Target) +
                           "', which a constraint cannot refer to");
    }
    break;
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call: {
    auto *OC = cast<OperatorConstraint>(C);
    SmallVector<Constraint *, 4> Arguments;
    for (Constraint *Argument : OC->getArguments()) {
      Expected<Constraint *> New = constraint(Argument);
      if (!New)
        return New.takeError();
      Arguments.push_back(*New);
    }
    Result = OC->isUserDefined()
                 ? OperatorConstraint::createUserDefined(
                       Context, OC->getConstraintID(), OC->getSort(),
                       OC->getOperator(), Arguments, OC->getSourceRange())
                 : OperatorConstraint::createBuiltin(
                       Context, OC->getConstraintID(), OC->getSort(),
                       OC->getOperatorID(), Arguments, OC->getSourceRange());
    break;
  }
  }
  Result->setContextInstruction(contextInstruction(C->getContextInstruction()));
  return Result;
}

SmallVector<MatcherOperand, 8>
Substitution::operands(const Instruction &I) const {
  SmallVector<MatcherOperand, 8> Result;
  auto Add = [&](const MatcherOperand &Op) {
    MatcherOperand New = Op;
    New.Ty = type(Op.Ty);
    New.Val = value(Op.Val);
    New.TypeArray = variable(Op.TypeArray);
    New.ValueArray = variable(Op.ValueArray);
    Result.push_back(New);
  };
  for (const MatcherOperand &Op : I.getUnkeyedOperands())
    Add(Op);
  for (const MatcherOperand &Op : I.getKeyedOperands())
    Add(Op);
  return Result;
}

namespace {

/// Phase 1: expands every composite matcher use into leaf patterns.
class Expander {
public:
  explicit Expander(MIRContext &Context) : Context(Context) {}

  /// Appends to Leaves the patterns Cur expands to. Cur itself is appended
  /// when it has no composite use.
  Error expand(const Pattern &Cur, SmallVectorImpl<const Pattern *> &Leaves);

private:
  MIRContext &Context;
  /// Numbers uses without a result name, to name their local copies.
  unsigned NextAnonymousUse = 0;

  Expected<Pattern *> inlineBranch(const Pattern &Cur, size_t UseIndex,
                                   const CompositeMatcher::Branch &Branch,
                                   ArrayRef<MatcherOperand> CallerOps);
  Expected<bool> bindParameters(const Instruction &Use,
                                const CompositeMatcher::Branch &Branch,
                                ArrayRef<MatcherOperand> CallerOps,
                                Substitution &Subst);

  MetaVariable *copyVariable(const MetaVariable &Original, StringRef UsePrefix);
  IntegerConstant *boolean(bool Value, SourceRange Range) {
    return IntegerConstant::create(Context, APSInt(APInt(1, Value), true),
                                   Range);
  }
};

} // namespace

Error Expander::expand(const Pattern &Cur,
                       SmallVectorImpl<const Pattern *> &Leaves) {
  ArrayRef<Instruction *> Instructions = Cur.getInstructions();
  auto It = find_if(Instructions,
                    [](const Instruction *I) { return I->isComposite(); });
  if (It == Instructions.end()) {
    Leaves.push_back(&Cur);
    return Error::success();
  }

  size_t UseIndex = It - Instructions.begin();
  const Instruction &Use = **It;
  ArrayRef<MatcherOperand> CallerOps = Use.getUnkeyedOperands();
  unsigned NumOrders = Use.hasMetaFlag(MetaFlag::MF_c) ? 2 : 1;

  for (const CompositeMatcher::Branch &Branch :
       Use.getCompositeMatcher()->getBranches()) {
    for (unsigned Order = 0; Order != NumOrders; ++Order) {
      SmallVector<MatcherOperand, 8> Ops(CallerOps.begin(), CallerOps.end());
      if (Order == 1)
        std::swap(Ops[0], Ops[1]);
      Expected<Pattern *> Variant = inlineBranch(Cur, UseIndex, Branch, Ops);
      if (!Variant)
        return Variant.takeError();
      // A branch the use cannot satisfy is dropped.
      if (!*Variant)
        continue;
      // The inlined branch may itself use composite matchers.
      if (Error E = expand(**Variant, Leaves))
        return E;
    }
  }
  return Error::success();
}

Expected<bool> Expander::bindParameters(const Instruction &Use,
                                        const CompositeMatcher::Branch &Branch,
                                        ArrayRef<MatcherOperand> CallerOps,
                                        Substitution &Subst) {
  const CompositeMatcher &CM = *Use.getCompositeMatcher();
  ArrayRef<ParameterDef> Params = CM.getParameters();
  assert(Branch.ParameterVars.size() == Params.size() &&
         "branch parameter variables do not match the declaration");

  auto BindType = [&](unsigned ParamIndex,
                      const MatcherOperand &Op) -> Expected<bool> {
    const ParameterDef &P = Params[ParamIndex];
    MetaVariable *Var = Branch.ParameterVars[ParamIndex];
    Type *CallerTy = Op.Ty;
    if (!CallerTy)
      return true;
    if (!Var) {
      // The declaration fixes this type. A use's meta type could only be
      // compared once matched, so the use must spell the type as well.
      if (isMetaType(CallerTy))
        return makeError(Op.Val && Op.Val->getSourceRange().Begin.isValid()
                             ? Op.Val->getSourceRange()
                             : Use.getSourceRange(),
                         "matcher '" + CM.getName() + "' requires type '" +
                             toString(*P.Ty) +
                             "' for a parameter, but this use "
                             "passes '" +
                             toString(*CallerTy) + "'");
      return P.Ty == CallerTy;
    }
    // A type parameter repeated for several operands must get one type.
    if (Type *Bound = Subst.Types.lookup(Var))
      return Bound == CallerTy || isMetaType(Bound) || isMetaType(CallerTy);
    Subst.Types[Var] = CallerTy;
    // The width of an 'i?bits' parameter is also a value, usable in the
    // branch's constraints.
    if (isa<MetaIntegerType>(P.Ty)) {
      unsigned Width = 0;
      if (auto *MIT = dyn_cast<MetaIntegerType>(CallerTy))
        Subst.Values[Var] = MIT->getBitWidthVariable();
      else if (auto *IT = dyn_cast<IntegerType>(CallerTy))
        Width = IT->getNumBits();
      else if (auto *BT = dyn_cast<ByteType>(CallerTy))
        Width = BT->getNumBits();
      if (Width)
        Subst.Values[Var] = IntegerConstant::create(
            Context, APSInt(APInt(64, Width), true),
            Op.Val ? Op.Val->getSourceRange() : P.Range);
    }
    return true;
  };
  auto BindValue = [&](unsigned ParamIndex, const MatcherOperand &Op) {
    if (MetaVariable *Var = Branch.ParameterVars[ParamIndex])
      if (Op.Val)
        Subst.Values[Var] = Op.Val;
  };

  // Each archetype lays its parameters out as (type, operand) pairs; see
  // MIRParser::parseMatchParameters.
  SmallVector<std::pair<unsigned, unsigned>, 8> TypePositions, ValuePositions;
  switch (CM.getSyntax()) {
  case Instruction::OperandSyntax::Nary:
    for (unsigned I = 0; I != CM.getArity(); ++I) {
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

  for (auto [ParamIndex, OpIndex] : TypePositions) {
    assert(ParamIndex < Params.size() && OpIndex < CallerOps.size() &&
           "use does not match the matcher's archetype");
    Expected<bool> Fits = BindType(ParamIndex, CallerOps[OpIndex]);
    if (!Fits)
      return Fits.takeError();
    if (!*Fits)
      return false;
  }
  for (auto [ParamIndex, OpIndex] : ValuePositions) {
    assert(ParamIndex < Params.size() && OpIndex < CallerOps.size() &&
           "use does not match the matcher's archetype");
    BindValue(ParamIndex, CallerOps[OpIndex]);
  }
  return true;
}

MetaVariable *Expander::copyVariable(const MetaVariable &Original,
                                     StringRef UsePrefix) {
  // Copies are named after the use, e.g. '?r$k' for '?k' in the use '%r'.
  // Hidden variables ('_'-prefixed) stay hidden.
  StringRef Name = Original.getName();
  std::string CopyName =
      ((Name.starts_with("_") ? "_" : "") + UsePrefix + "$" + Name).str();
  return MetaVariable::create(Context, Context.pImpl->Saver.save(CopyName),
                              Original.getInferredSort(),
                              Original.getSourceRange());
}

Expected<Pattern *>
Expander::inlineBranch(const Pattern &Cur, size_t UseIndex,
                       const CompositeMatcher::Branch &Branch,
                       ArrayRef<MatcherOperand> CallerOps) {
  const Instruction &Use = *Cur.getInstructions()[UseIndex];
  const CompositeMatcher &CM = *Use.getCompositeMatcher();
  const Instruction &Root = *Branch.Root;
  Substitution Subst(Context);

  Expected<bool> Fits = bindParameters(Use, Branch, CallerOps, Subst);
  if (!Fits)
    return Fits.takeError();
  if (!*Fits)
    return nullptr;

  std::string UsePrefix = Use.getResultName().empty()
                              ? ("#" + Twine(NextAnonymousUse++)).str()
                              : Use.getResultName().str();

  // Bind the matcher's supported flags. For each one, the use either omits
  // it (either value), requires it, negates it (it must be absent), or
  // captures it; a branch may also fix its value. FlagValue is what the root's
  // capture of the flag stands for: a boolean constant or a meta variable.
  SmallVector<std::pair<const MetaVariable *, bool>, 4> FixedFlags;
  DenseMap<unsigned, Value *> FlagValues;
  for (InstructionFlag::FlagID FlagID : CM.getSupportedFlags()) {
    auto HasID = [FlagID](const InstructionFlag &F) { return F.ID == FlagID; };
    const InstructionFlag *UseFlag = find_if(Use.getFlags(), HasID);
    // A flag forwarded from an enclosing use that omitted it is omitted too.
    if (UseFlag == Use.getFlags().end() || isWildcardCapture(UseFlag->Capture))
      UseFlag = nullptr;
    const auto *Fixed = find_if(Branch.FixedFlags, [FlagID](const auto &F) {
      return F.first == FlagID;
    });
    if (Fixed == Branch.FixedFlags.end())
      Fixed = nullptr;

    Value *FlagValue = nullptr;
    if (UseFlag && !UseFlag->Capture) {
      bool Required = !UseFlag->Negated;
      if (Fixed && Fixed->second != Required)
        return nullptr;
      FlagValue = boolean(Required, Use.getSourceRange());
    } else if (Fixed) {
      if (UseFlag)
        FixedFlags.push_back({UseFlag->Capture, Fixed->second});
      FlagValue = UseFlag ? static_cast<Value *>(UseFlag->Capture)
                          : boolean(Fixed->second, Use.getSourceRange());
    } else if (UseFlag) {
      FlagValue = UseFlag->Capture;
    } else {
      FlagValue = MetaVariable::create(
          Context,
          Context.pImpl->Saver.save((OmittedFlagPrefix + UsePrefix + "$" +
                                     InstructionFlag::getName(FlagID))
                                        .str()),
          Sort::Boolean, Use.getSourceRange());
    }
    FlagValues[FlagID] = FlagValue;
    for (const InstructionFlag &F : Root.getFlags())
      if (F.ID == FlagID && F.Capture)
        Subst.Values[F.Capture] = FlagValue;
  }

  auto *Variant = Pattern::create(Context);
  for (const auto &[Var, Val] : FixedFlags)
    Variant->addFixedFlag(Var, Val);

  // The root's capture is the use's capture, when the use names one.
  if (Root.getCapture() && Use.getCapture())
    Subst.Values[Root.getCapture()] = Use.getCapture();

  // Every other local of the branch gets a fresh copy for this use.
  SmallVector<MetaVariable *, 8> LocalCopies;
  for (MetaVariable *Local : Branch.LocalVariables) {
    if (Subst.Values.count(Local))
      continue;
    MetaVariable *Copy = copyVariable(*Local, UsePrefix);
    Subst.Values[Local] = Copy;
    // Block labels in a body are dropped (the body is placed in the use's
    // block), so their variables are never bound.
    if (Local->getSort() != Sort::BasicBlock)
      LocalCopies.push_back(Copy);
  }

  // Instructions before the use are shared by every variant.
  for (Instruction *I : Cur.getInstructions().take_front(UseIndex))
    Variant->addInstruction(I);

  // Inline the branch body.
  for (Instruction *BI : Branch.Instructions) {
    bool IsRoot = BI == &Root;
    StringRef ResultName =
        IsRoot ? Use.getResultName()
               : Context.pImpl->Saver.save(
                     (UsePrefix + "$" + BI->getResultName()).str());

    SmallVector<MetaFlag *, 4> MetaFlags(BI->getMetaFlags());
    MetaVariable *Capture = Subst.variable(BI->getCapture());
    SmallVector<InstructionFlag, 4> Flags;
    for (const InstructionFlag &F : BI->getFlags()) {
      if (!IsRoot || !CM.hasSupportedFlag(F.ID)) {
        Flags.push_back({F.ID, Subst.variable(F.Capture), F.Negated});
        continue;
      }
      // A supported flag on the root takes the use's flag: absent (false),
      // required (true), or a variable.
      Value *FlagValue = FlagValues.lookup(F.ID);
      if (auto *Var = dyn_cast<MetaVariable>(FlagValue))
        Flags.push_back({F.ID, Var});
      else
        Flags.push_back(
            {F.ID, nullptr,
             cast<IntegerConstant>(FlagValue)->getValue().isZero()});
    }
    if (IsRoot) {
      if (Use.getCapture())
        Capture = Use.getCapture();
      // The use's metaflags apply to the root, except ':c', which was
      // expanded above.
      for (MetaFlag *MF : Use.getMetaFlags())
        if (MF->getMetaFlagID() != MetaFlag::MF_c &&
            !is_contained(MetaFlags, MF))
          MetaFlags.push_back(MF);
    }

    Instruction *New = Instruction::createLike(
        Context, *BI, ResultName, Flags, MetaFlags, Subst.operands(*BI),
        Capture, BI->getSourceRange(), Use.getParentBlock(),
        BI->getSettings().inheritedFrom(Use.getSettings()));
    New->setExpandedFrom(&Use);

    if (IsRoot) {
      // ':o(N)' lets the use match the root or, alternatively, its Nth
      // operand.
      for (const MetaFlag *MF : Use.getMetaFlags()) {
        if (MF->getMetaFlagID() != MetaFlag::MF_o)
          continue;
        uint64_t Index = MF->getArguments().empty()
                             ? 0
                             : MF->getArguments().front().IntegerValue;
        assert(Index < CallerOps.size() && "':o' index checked by the parser");
        New->setOrSelfValue(Subst.value(CallerOps[Index].Val));
        break;
      }
    }
    Variant->addInstruction(New);
    Subst.Instructions[BI] = New;
  }
  Instruction *UseRoot = Subst.Instructions.lookup(&Root);
  Subst.Instructions[&Use] = UseRoot;

  // The metaflags on the use's operands apply to the values it passes, as
  // they would on a primitive instruction's; the use is gone, so they are
  // kept for desugaring, at the instruction it became.
  for (const MatcherOperand &Op : CallerOps)
    if (!Op.MetaFlags.empty() && Op.Val)
      Variant->addOperandFlags({Op.Val, Op.MetaFlags, UseRoot});

  // Instructions after the use are copied when they refer to it.
  for (Instruction *I : Cur.getInstructions().drop_front(UseIndex + 1)) {
    SmallVector<MatcherOperand, 8> Operands = Subst.operands(*I);
    Value *OrSelf = Subst.value(I->getOrSelfValue());
    bool Changed = OrSelf != I->getOrSelfValue();
    ArrayRef<MatcherOperand> Unkeyed = I->getUnkeyedOperands();
    SmallVector<MatcherOperand, 4> Keyed = I->getKeyedOperands();
    for (size_t Index = 0; Index != Operands.size(); ++Index) {
      const MatcherOperand &Old = Index < Unkeyed.size()
                                      ? Unkeyed[Index]
                                      : Keyed[Index - Unkeyed.size()];
      Changed |= Operands[Index].Val != Old.Val;
    }
    if (!Changed) {
      Variant->addInstruction(I);
      continue;
    }
    Instruction *New = Instruction::createLike(
        Context, *I, I->getResultName(), I->getFlags(), I->getMetaFlags(),
        Operands, I->getCapture(), I->getSourceRange(), I->getParentBlock(),
        I->getSettings());
    New->setOrSelfValue(OrSelf);
    Subst.Instructions[I] = New;
    Variant->addInstruction(New);
  }

  // The branch's constraints, then the use site's, which may refer to the
  // use (now the root) or to instructions after it.
  for (Constraint *C : Branch.Constraints) {
    Expected<Constraint *> New = Subst.constraint(C);
    if (!New)
      return New.takeError();
    Variant->addConstraint(*New);
  }
  for (Constraint *C : Cur.getConstraints()) {
    Expected<Constraint *> New = Subst.constraint(C);
    if (!New)
      return New.takeError();
    Variant->addConstraint(*New);
  }

  for (MetaVariable *M : Cur.getMetaVariables())
    Variant->addMetaVariable(M);
  for (MetaVariable *M : LocalCopies)
    Variant->addMetaVariable(M);
  for (const auto &[Var, Val] : Cur.getFixedFlags())
    Variant->addFixedFlag(Var, Val);
  // Those of uses inlined before, about values this one may have replaced.
  for (const Pattern::OperandFlags &F : Cur.getOperandFlags())
    Variant->addOperandFlags({Subst.value(F.Subject), F.Flags,
                              Subst.contextInstruction(F.ContextInstruction)});
  return Variant;
}

namespace {

/// Phase 2: desugars metaflags into constraints.
class Desugarer {
public:
  explicit Desugarer(MIRContext &Context) : Context(Context) {}

  Error desugar(Pattern &P);

private:
  MIRContext &Context;

  Expected<Constraint *> lower(const MetaFlag &MF, Value *Subject);
  Expected<Constraint *> lowerNot(const MetaFlag &MF, Value *Subject);
  Expected<Constraint *> lowerOr(const MetaFlag &MF, Value *Subject);
  Expected<Constraint *>
  lowerUserDefined(const MetaFlag &MF, const MetaFlagDef &Def, Value *Subject);
};

} // namespace

Error Desugarer::desugar(Pattern &P) {
  // Collect first: adding constraints must not disturb the iteration.
  SmallVector<Constraint *, 8> Lowered;
  auto LowerAll = [&](ArrayRef<MetaFlag *> Flags, Value *Subject,
                      const Instruction *CxtI) -> Error {
    for (const MetaFlag *MF : Flags) {
      Expected<Constraint *> C = lower(*MF, Subject);
      if (!C)
        return C.takeError();
      if (!*C)
        continue;
      // A value-tracking operator anywhere in the flag's body is evaluated at
      // the instruction the flag is written on.
      (*C)->setDefaultContextInstruction(CxtI);
      Lowered.push_back(*C);
    }
    return Error::success();
  };

  for (Instruction *I : P.getInstructions()) {
    Value *Subject = I->getCapture() ? static_cast<Value *>(I->getCapture())
                                     : static_cast<Value *>(I);
    if (Error E = LowerAll(I->getMetaFlags(), Subject, I))
      return E;
    for (const MatcherOperand &Op : I->getUnkeyedOperands())
      if (Error E = LowerAll(Op.MetaFlags, Op.Val, I))
        return E;
  }
  for (const Pattern::OperandFlags &F : P.getOperandFlags())
    if (Error E = LowerAll(F.Flags, F.Subject, F.ContextInstruction))
      return E;
  // Metaflags mostly say what a binding is (':constantInt', ':lowBitMask'),
  // so they are checked first: a constraint that could not be evaluated on
  // such a binding then is not what is reported to reject it.
  P.prependConstraints(Lowered);
  return Error::success();
}

/// Returns the constraint MF stands for on Subject, or null for a builtin
/// flag that is not a constraint (':c', ':o').
Expected<Constraint *> Desugarer::lower(const MetaFlag &MF, Value *Subject) {
  const MetaFlagDef *Def = Context.getMetaFlagDef(MF.getName());
  if (!Subject) {
    if (MF.getMetaFlagID() == MetaFlag::MF_c ||
        MF.getMetaFlagID() == MetaFlag::MF_o)
      return nullptr;
    return makeError(MF.getSourceRange(),
                     "metaflag ':" + MF.getName() +
                         "' has no value to use as its subject");
  }
  switch (MF.getMetaFlagID()) {
  case MetaFlag::MF_not:
    return lowerNot(MF, Subject);
  case MetaFlag::MF_or:
    return lowerOr(MF, Subject);
  case MetaFlag::MF_c:
  case MetaFlag::MF_o:
    return nullptr;
  case MetaFlag::UnknownMetaFlag:
    break;
  }
  if (!Def)
    return makeError(MF.getSourceRange(),
                     "unknown metaflag ':" + MF.getName() + "'");
  return lowerUserDefined(MF, *Def, Subject);
}

Expected<Constraint *> Desugarer::lowerNot(const MetaFlag &MF, Value *Subject) {
  if (MF.getArguments().size() != 1 || !MF.getArguments()[0].FlagValue)
    return makeError(MF.getSourceRange(),
                     "metaflag ':not' requires one nested flag");
  Expected<Constraint *> Inner =
      lower(*MF.getArguments()[0].FlagValue, Subject);
  if (!Inner)
    return Inner.takeError();
  if (!*Inner)
    return makeError(MF.getSourceRange(),
                     "metaflag ':not' contains a flag that cannot be lowered");
  return OperatorConstraint::createBuiltin(Context, Constraint::Unary,
                                           Sort::Boolean, Constraint::O_Not,
                                           {*Inner}, MF.getSourceRange());
}

Expected<Constraint *> Desugarer::lowerOr(const MetaFlag &MF, Value *Subject) {
  Constraint *Result = nullptr;
  for (const MetaFlag::Argument &Arg : MF.getArguments()) {
    if (!Arg.FlagValue)
      return makeError(MF.getSourceRange(),
                       "metaflag ':or' requires nested flags");
    Expected<Constraint *> Inner = lower(*Arg.FlagValue, Subject);
    if (!Inner)
      return Inner.takeError();
    if (!*Inner)
      return makeError(MF.getSourceRange(),
                       "metaflag ':or' contains a flag that cannot be lowered");
    Result = Result ? OperatorConstraint::createBuiltin(
                          Context, Constraint::Binary, Sort::Boolean,
                          Constraint::O_LogicalOr, {Result, *Inner},
                          MF.getSourceRange())
                    : *Inner;
  }
  if (!Result)
    return makeError(MF.getSourceRange(),
                     "metaflag ':or' requires at least one flag");
  return Result;
}

Expected<Constraint *> Desugarer::lowerUserDefined(const MetaFlag &MF,
                                                   const MetaFlagDef &Def,
                                                   Value *Subject) {
  ArrayRef<MetaFlag::Argument> Args = MF.getArguments();
  ArrayRef<MetaVariable *> Params = Def.getParameterVars();
  if (Args.size() != Def.getNumArguments())
    return makeError(MF.getSourceRange(),
                     "metaflag ':" + MF.getName() + "' expects " +
                         Twine(Def.getNumArguments()) + " arguments, got " +
                         Twine(Args.size()));
  if (!Def.getBody())
    return makeError(MF.getSourceRange(),
                     "metaflag ':" + MF.getName() + "' has an empty body");

  // The first parameter is the subject; the rest are the flag's arguments.
  Substitution Subst(Context);
  Subst.Values[Params.front()] = Subject;
  for (unsigned I = 0; I != Args.size(); ++I) {
    if (Args[I].K != MetaFlag::Argument::Integer)
      return makeError(MF.getSourceRange(), "metaflag ':" + MF.getName() +
                                                "' expects integer arguments");
    Subst.Values[Params[I + 1]] = IntegerConstant::create(
        Context,
        APSInt(APInt(64, Args[I].IntegerValue, /*isSigned=*/true),
               /*isUnsigned=*/false),
        MF.getSourceRange());
  }
  return Subst.constraint(Def.getBody());
}

namespace {

/// The meta variables a match binds, and the instructions it matches.
struct Bindings {
  SmallPtrSet<const MetaVariable *, 16> Variables;
  SmallVector<const Instruction *, 8> Instructions;

  void addType(const Type *T) {
    if (!T)
      return;
    if (auto *MIT = dyn_cast<MetaIntegerType>(T))
      Variables.insert(MIT->getBitWidthVariable());
    else if (auto *MT = dyn_cast<MetaIRType>(T))
      Variables.insert(MT->getVariable());
    else if (auto *PT = dyn_cast<PointerType>(T))
      addType(PT->getElementType());
    else if (auto *ST = dyn_cast<SequenceType>(T)) {
      addType(ST->getElementType());
      if (MetaVariable *Count = ST->getCountVariable())
        Variables.insert(Count);
    } else if (auto *ST = dyn_cast<StructType>(T)) {
      for (const Type *E : ST->getElementTypes())
        addType(E);
    } else if (auto *FT = dyn_cast<FunctionType>(T)) {
      addType(FT->getReturnType());
      for (const Type *Parameter : FT->getParameterTypes())
        addType(Parameter);
    }
  }

  void addValue(const Value *V) {
    if (auto *MV = dyn_cast_or_null<MetaVariable>(V))
      Variables.insert(MV);
    else if (auto *I = dyn_cast_or_null<Instruction>(V))
      Instructions.push_back(I);
    else if (auto *Aggregate = dyn_cast_or_null<AggregateConstant>(V)) {
      for (const Type *T : Aggregate->getElementTypes())
        addType(T);
      for (const Value *E : Aggregate->getElements())
        addValue(E);
    }
  }

  void addVariable(const MetaVariable *V) {
    if (V)
      Variables.insert(V);
  }

  void addOperand(const MatcherOperand &Op) {
    addType(Op.Ty);
    addValue(Op.Val);
    addVariable(Op.TypeArray);
    addVariable(Op.ValueArray);
  }

  /// What matching I binds; with OnlySelf, what it binds when ':o' lets it
  /// match its operand instead: itself, its capture and that operand.
  void addInstruction(const Instruction &I, bool OnlySelf) {
    addVariable(I.getCapture());
    if (OnlySelf) {
      if (const Value *Self = I.getOrSelfValue())
        return addValue(Self);
      unsigned Position = *I.getOrSelfOperandIndex();
      for (const MatcherOperand &Op : I.getUnkeyedOperands())
        if (Op.IsInstructionOperand && Position-- == 0)
          return addValue(Op.Val);
      return;
    }
    addVariable(I.getParentBlock());
    for (const InstructionFlag &Flag : I.getFlags())
      addVariable(Flag.Capture);
    for (const MatcherOperand &Op : I.getUnkeyedOperands())
      addOperand(Op);
    for (const MatcherOperand &Op : I.getKeyedOperands())
      addOperand(Op);
  }
};

} // namespace

/// Rejects a named meta variable of P that a match may leave unbound: one
/// that only the parts of an ':o' instruction other than its operand bind,
/// when the instruction matches that operand instead.
static Error checkOrSelfBindings(const Pattern &P) {
  Bindings Always;
  SmallPtrSet<const Instruction *, 16> Visited;
  // The variables each ':o' instruction binds when it matches itself.
  DenseMap<const MetaVariable *, const Instruction *> BoundBy;
  for (Instruction *Root : P.getRoots())
    Always.Instructions.push_back(Root);
  while (!Always.Instructions.empty()) {
    const Instruction *I = Always.Instructions.pop_back_val();
    if (!Visited.insert(I).second)
      continue;
    bool OrSelf = I->getOrSelfOperandIndex().has_value();
    if (OrSelf) {
      // Matching itself binds its parts and its operand instructions'.
      Bindings Itself;
      SmallPtrSet<const Instruction *, 8> Seen;
      Itself.Instructions.push_back(I);
      while (!Itself.Instructions.empty()) {
        const Instruction *J = Itself.Instructions.pop_back_val();
        if (Seen.insert(J).second)
          Itself.addInstruction(*J, /*OnlySelf=*/false);
      }
      for (const MetaVariable *V : Itself.Variables)
        BoundBy.try_emplace(V, I);
    }
    Always.addInstruction(*I, OrSelf);
  }
  for (const MetaVariable *V : P.getMetaVariables()) {
    StringRef Name = V->getName();
    if (Name.empty() || Name.starts_with("_") || Always.Variables.contains(V))
      continue;
    const Instruction *OrSelf = BoundBy.lookup(V);
    if (!OrSelf)
      continue;
    return makeError(
        V->getSourceRange().Begin.isValid() ? V->getSourceRange()
                                            : OrSelf->getSourceRange(),
        "meta variable '?" + Name +
            "' is not bound when ':o' "
            "lets '" +
            OrSelf->getOpcodeName() + "' match its operand; name it '?_" +
            Name + "' if it need not be bound");
  }
  return Error::success();
}

Expected<PatternVariants> PatternLowering::lower(const Pattern *P) {
  if (!P)
    return PatternVariants();

  SmallVector<const Pattern *, 2> Expanded;
  if (Error E = Expander(Context).expand(*P, Expanded))
    return E;

  SmallVector<Pattern *, 2> Leaves;
  Desugarer Desugar(Context);
  for (const Pattern *Leaf : Expanded) {
    // Leaves other than P were created by the expansion and may be extended
    // in place; P is copied so that lowering leaves it untouched.
    Pattern *Owned = Leaf == P ? P->copy() : const_cast<Pattern *>(Leaf);
    if (Error E = Desugar.desugar(*Owned))
      return E;
    if (Error E = checkOrSelfBindings(*Owned))
      return E;
    Leaves.push_back(Owned);
  }
  return PatternVariants(std::move(Leaves));
}

} // namespace metaphir
} // namespace llvm
