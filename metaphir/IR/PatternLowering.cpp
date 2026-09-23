#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

namespace {

bool isWildcardCapture(const MetaVariable *Capture) {
  return Capture && (Capture->getName() == "_" ||
                     Capture->getName().starts_with("_flag$"));
}

using InliningContext = PatternLowering::InliningContext;
using DesugarContext = PatternLowering::DesugarContext;
using SubstitutionContext = PatternLowering::SubstitutionContext;

} // namespace

Expected<PatternVariants> PatternLowering::lower(Pattern *P) {
  if (!P)
    return PatternVariants();

  // Phase 1: Expand composite matchers into flattened leaf patterns.
  Expected<SmallVector<Pattern *, 2>> VariantsOrErr = expandComposites(P);
  if (!VariantsOrErr)
    return VariantsOrErr.takeError();

  // Phase 2: Desugar metaflags on each flattened leaf pattern variant.
  for (Pattern *Variant : *VariantsOrErr) {
    if (Error E = desugarMetaFlags(Variant))
      return E;
  }

  return PatternVariants(std::move(*VariantsOrErr));
}

Expected<SmallVector<Pattern *, 2>>
PatternLowering::expandComposites(Pattern *P) {
  SmallVector<Pattern *, 2> Leaves;
  if (Error E = expandPattern(P, Leaves))
    return E;
  return Leaves;
}

Error PatternLowering::expandPattern(Pattern *Cur,
                                     SmallVectorImpl<Pattern *> &Results) {
  ArrayRef<Instruction *> Insts = Cur->getInstructions();
  int CompIdx = -1;
  for (size_t I = 0; I < Insts.size(); ++I) {
    if (Insts[I]->isComposite()) {
      CompIdx = I;
      break;
    }
  }

  // If no composite instructions remain, this pattern is a leaf variant.
  if (CompIdx == -1) {
    Results.push_back(Cur);
    return Error::success();
  }

  Instruction *CompInst = Insts[CompIdx];
  CompositeMatcher *CM = CompInst->getCompositeMatcher();
  ArrayRef<MatcherOperand> OriginalCallerOps = CompInst->getUnkeyedOperands();
  bool IsCommutative =
      llvm::any_of(CompInst->getMetaFlags(), [](const MetaFlag *MF) {
        return MF->getMetaFlagID() == MetaFlag::MF_c;
      });

  for (const auto &Branch : CM->getBranches()) {
    unsigned NumOrders = IsCommutative ? 2 : 1;
    for (unsigned Order = 0; Order != NumOrders; ++Order) {
      SmallVector<MatcherOperand, 8> CallerOps(OriginalCallerOps.begin(),
                                               OriginalCallerOps.end());
      if (Order == 1)
        std::swap(CallerOps[0], CallerOps[1]);

      Expected<Pattern *> VariantOrErr =
          inlineBranch(Cur, CompIdx, CM, Branch, CallerOps);
      if (!VariantOrErr)
        return VariantOrErr.takeError();

      Pattern *Variant = *VariantOrErr;
      if (!Variant)
        continue; // Statically incompatible branch pruned

      // Recurse to expand any remaining composite instructions in Variant.
      if (Error E = expandPattern(Variant, Results))
        return E;
    }
  }

  return Error::success();
}

bool PatternLowering::bindParameters(InliningContext &Ctx) {
  ArrayRef<ParameterDef> Params = Ctx.CM->getParameters();
  ArrayRef<MatcherOperand> CallerOps = Ctx.CallerOps;
  bool TypeMismatch = false;

  auto mapTypeParam = [&](const ParameterDef &P, Type *CallerTy) {
    if (!CallerTy)
      return;
    if (P.Name.empty()) {
      if (P.Ty != CallerTy)
        TypeMismatch = true;
      return;
    }
    Ctx.Types[P.Name] = CallerTy;
    if (auto *MIT = dyn_cast<MetaIntegerType>(CallerTy))
      if (MIT->getBitWidthVariable())
        Ctx.MetaValues[P.Name] = MIT->getBitWidthVariable();
  };

  auto mapValParam = [&](StringRef ParamName, Value *CallerVal) {
    if (CallerVal)
      Ctx.MetaValues[ParamName] = CallerVal;
  };

  switch (Ctx.CM->getSyntax()) {
  case Instruction::OperandSyntax::Unary:
    if (Params.size() >= 2 && CallerOps.size() >= 1) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
    }
    break;
  case Instruction::OperandSyntax::Binary:
    if (Params.size() >= 3 && CallerOps.size() >= 2) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapValParam(Params[2].Name, CallerOps[1].Val);
    }
    break;
  case Instruction::OperandSyntax::Cast:
    if (Params.size() >= 3 && CallerOps.size() >= 2) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapTypeParam(Params[2], CallerOps[1].Ty);
    }
    break;
  case Instruction::OperandSyntax::Ternary:
    if (Params.size() >= 6 && CallerOps.size() >= 3) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapTypeParam(Params[2], CallerOps[1].Ty);
      mapValParam(Params[3].Name, CallerOps[1].Val);
      mapTypeParam(Params[4], CallerOps[2].Ty);
      mapValParam(Params[5].Name, CallerOps[2].Val);
    }
    break;
  case Instruction::OperandSyntax::Custom:
    for (size_t I = 0; I < Params.size() && I < CallerOps.size(); ++I) {
      if (CallerOps[I].Val)
        mapValParam(Params[I].Name, CallerOps[I].Val);
      if (CallerOps[I].Ty)
        mapTypeParam(Params[I], CallerOps[I].Ty);
    }
    break;
  }
  return !TypeMismatch;
}

bool PatternLowering::bindFlags(InliningContext &Ctx) {
  for (InstructionFlag::FlagID FlagID : Ctx.CM->getSupportedFlags()) {
    StringRef FlagName = InstructionFlag::getName(FlagID);
    const InstructionFlag *CallerFlag = nullptr;
    for (const InstructionFlag &F : Ctx.CompInst->getFlags()) {
      if (F.ID == FlagID) {
        CallerFlag = &F;
        break;
      }
    }

    const auto *FixedIt =
        llvm::find_if(Ctx.Branch.FixedFlags,
                      [&](const auto &P) { return P.first == FlagID; });
    bool HasFixedVal = (FixedIt != Ctx.Branch.FixedFlags.end());

    if (HasFixedVal) {
      bool FixedVal = FixedIt->second;
      if (!CallerFlag) {
        if (FixedVal != false)
          return false;
      } else if (!CallerFlag->Capture) {
        if (FixedVal != true)
          return false;
      } else {
        if (!isWildcardCapture(CallerFlag->Capture)) {
          Ctx.Variant->addFixedFlag(CallerFlag->Capture, FixedVal);
          Ctx.MetaValues[FlagName] = CallerFlag->Capture;
        }
      }
      continue;
    }

    if (CallerFlag && CallerFlag->Capture) {
      if (isWildcardCapture(CallerFlag->Capture)) {
        std::string SyntheticName =
            (Twine("_flag$") + Ctx.CompInst->getResultName() + "$" + FlagName)
                .str();
        auto *FlagVar =
            MetaVariable::get(Context, SyntheticName, MetaType::Bool,
                              Ctx.CompInst->getSourceRange());
        Ctx.MetaValues[FlagName] = FlagVar;
      } else {
        Ctx.MetaValues[FlagName] = CallerFlag->Capture;
      }
    } else if (CallerFlag) {
      Ctx.MetaValues[FlagName] = nullptr;
    } else {
      Ctx.OmittedFlags.push_back(FlagID);
    }
  }
  return true;
}

Expected<Pattern *>
PatternLowering::inlineBranch(Pattern *Cur, size_t CompIdx,
                              CompositeMatcher *CM,
                              const CompositeMatcher::Branch &Branch,
                              ArrayRef<MatcherOperand> CallerOps) {
  auto *Variant = Pattern::get(Context);
  InliningContext Ctx(Cur, CompIdx, CM, Branch, CallerOps, Variant);

  if (!bindParameters(Ctx))
    return nullptr;

  if (!bindFlags(Ctx))
    return nullptr;

  // 1. Share preceding instructions (0..CompIdx - 1) across all branches by raw
  // pointer.
  for (size_t I = 0; I < CompIdx; ++I)
    Variant->addInstruction(Cur->getInstructions()[I]);

  // 2. Inline branch instructions.
  if (Error E = inlineBranchInstructions(Ctx))
    return E;

  // 3. Rewrite downstream instructions (CompIdx + 1..) with Copy-on-Write.
  rewriteDownstreamInstructions(Ctx);

  // 4. Transfer constraints from inlined branch and caller.
  transferConstraints(Ctx);

  // 5. Forward pattern metadata.
  for (MetaVariable *M : Cur->getMetaVariables())
    Variant->addMetaVariable(M);
  for (const auto &[Var, Val] : Cur->getFixedFlags())
    Variant->addFixedFlag(Var, Val);

  return Variant;
}

Error PatternLowering::inlineBranchInstructions(InliningContext &Ctx) {
  const Instruction *RootBI = nullptr;
  for (Instruction *BI : Ctx.Branch.Instructions) {
    if (BI->getResultName() == "ret") {
      RootBI = BI;
      break;
    }
  }
  if (!RootBI && !Ctx.Branch.Instructions.empty())
    RootBI = Ctx.Branch.Instructions.back();

  Instruction *RootInst = nullptr;
  SubstitutionContext SubstCtx = Ctx.getSubstCtx();

  for (Instruction *BI : Ctx.Branch.Instructions) {
    bool IsRoot = (BI == RootBI);
    StringRef ResultName =
        IsRoot
            ? Ctx.CompInst->getResultName()
            : Context.pImpl->Saver.save((Twine(Ctx.CompInst->getResultName()) +
                                         "$" + BI->getResultName())
                                            .str());

    SmallVector<MatcherOperand, 8> NewOps;
    for (const MatcherOperand &Op : BI->getUnkeyedOperands()) {
      MatcherOperand NewOp = Op;
      NewOp.Ty = substituteType(Op.Ty, SubstCtx);
      NewOp.Val = substituteValue(Op.Val, SubstCtx);
      NewOp.MetaFlags = Context.pImpl->copyArray<MetaFlag *>(Op.MetaFlags);
      NewOps.push_back(NewOp);
    }

    MetaVariable *Capture = BI->getCapture();
    SmallVector<MetaFlag *, 4> MetaFlags(BI->getMetaFlags().begin(),
                                         BI->getMetaFlags().end());
    if (IsRoot) {
      if (Ctx.CompInst->getCapture())
        Capture = Ctx.CompInst->getCapture();
      for (const MetaFlag *MF : Ctx.CompInst->getMetaFlags())
        if (MF->getMetaFlagID() == MetaFlag::MF_o)
          MetaFlags.push_back(const_cast<MetaFlag *>(MF));
    }

    SmallVector<InstructionFlag, 4> NewFlags;
    for (const InstructionFlag &BF : BI->getFlags()) {
      if (llvm::is_contained(Ctx.OmittedFlags, BF.ID))
        continue;
      if (IsRoot && Ctx.CM->hasSupportedFlag(BF.ID)) {
        StringRef FlagName = InstructionFlag::getName(BF.ID);
        MetaVariable *Cap = nullptr;
        if (auto *V = Ctx.MetaValues.lookup(FlagName))
          Cap = dyn_cast<MetaVariable>(V);
        NewFlags.push_back(InstructionFlag{BF.ID, Cap});
      } else {
        NewFlags.push_back(BF);
      }
    }

    Instruction *NewInst = Instruction::get(
        Context, BI->getInstructionID(), ResultName, NewFlags, MetaFlags,
        NewOps, Capture, BI->getSourceRange(), Ctx.CompInst->getParentBlock(),
        BI->getSettings().inheritedFrom(Ctx.CompInst->getSettings()));

    if (IsRoot) {
      for (const MetaFlag *MF : Ctx.CompInst->getMetaFlags()) {
        if (MF->getMetaFlagID() == MetaFlag::MF_o) {
          unsigned Index = 0;
          if (!MF->getArguments().empty())
            Index = MF->getArguments().front().IntegerValue;
          NewInst->setOrSelfValue(
              substituteValue(Ctx.CallerOps[Index].Val, SubstCtx));
          break;
        }
      }
      RootInst = NewInst;
    }

    Ctx.Variant->addInstruction(NewInst);
    Ctx.InlinedInstructions[BI] = NewInst;
  }

  if (RootInst)
    Ctx.InlinedInstructions[Ctx.CompInst] = RootInst;

  return Error::success();
}

void PatternLowering::rewriteDownstreamInstructions(InliningContext &Ctx) {
  for (size_t I = Ctx.CompIdx + 1; I < Ctx.Cur->getInstructions().size(); ++I) {
    Instruction *Orig = Ctx.Cur->getInstructions()[I];
    bool NeedsNewNode = false;
    for (const MatcherOperand &Op : Orig->getUnkeyedOperands()) {
      if (Op.Val &&
          Ctx.InlinedInstructions.count(dyn_cast<Instruction>(Op.Val))) {
        NeedsNewNode = true;
        break;
      }
    }
    if (!NeedsNewNode) {
      Ctx.Variant->addInstruction(Orig);
      continue;
    }

    SmallVector<MatcherOperand, 8> NewOperands;
    NewOperands.reserve(Orig->getUnkeyedOperands().size());
    for (const MatcherOperand &Op : Orig->getUnkeyedOperands()) {
      MatcherOperand NewOp = Op;
      if (NewOp.Val) {
        if (auto *OldI = dyn_cast<Instruction>(NewOp.Val)) {
          if (auto *NewTarget = Ctx.InlinedInstructions.lookup(OldI))
            NewOp.Val = NewTarget;
        }
      }
      NewOperands.push_back(NewOp);
    }
    Instruction *NewI = Instruction::withOperands(Context, Orig, NewOperands);
    Ctx.InlinedInstructions[Orig] = NewI;
    Ctx.Variant->addInstruction(NewI);
  }
}

void PatternLowering::transferConstraints(InliningContext &Ctx) {
  // 1. Inlined branch constraints.
  SubstitutionContext BranchSubstCtx = Ctx.getSubstCtx();
  for (Constraint *C : Ctx.Branch.Constraints) {
    if (Constraint *Subst = substituteConstraint(C, BranchSubstCtx))
      Ctx.Variant->addConstraint(Subst);
  }

  // 2. Caller constraints (remapping context instruction to inlined copies).
  MetaValueMap EmptyValues;
  TypeMap EmptyTypes;
  SubstitutionContext CallerSubstCtx(EmptyValues, EmptyTypes,
                                     Ctx.InlinedInstructions);
  for (Constraint *C : Ctx.Cur->getConstraints()) {
    if (Constraint *Copy = substituteConstraint(C, CallerSubstCtx))
      Ctx.Variant->addConstraint(Copy);
  }
}

Error PatternLowering::desugarMetaFlags(Pattern *P) {
  for (Instruction *I : P->getInstructions()) {
    DesugarContext Ctx(P, I);
    Value *Subject = I->getCapture() ? static_cast<Value *>(I->getCapture())
                                     : static_cast<Value *>(I);
    if (Error E = lowerMetaFlags(I->getMetaFlags(), Subject, Ctx))
      return E;

    for (const MatcherOperand &Op : I->getUnkeyedOperands()) {
      if (Error E = lowerMetaFlags(Op.MetaFlags, Op.Val, Ctx))
        return E;
    }
  }
  return Error::success();
}

Error PatternLowering::lowerMetaFlags(ArrayRef<const MetaFlag *> Flags,
                                      Value *Subject,
                                      const DesugarContext &Ctx) {
  for (const MetaFlag *MF : Flags) {
    Expected<Constraint *> COrErr = buildMetaFlagConstraint(MF, Subject, Ctx);
    if (!COrErr)
      return COrErr.takeError();
    if (Constraint *C = *COrErr) {
      if (Ctx.CxtI && !C->getContextInstruction())
        C->setContextInstruction(Ctx.CxtI);
      Ctx.TargetPattern->addConstraint(C);
    }
  }
  return Error::success();
}

Expected<Constraint *>
PatternLowering::buildMetaFlagConstraint(const MetaFlag *MF, Value *OperandVal,
                                         const DesugarContext &Ctx) {
  if (!OperandVal) {
    if (!Context.getMetaFlagDef(MF->getName()))
      return static_cast<Constraint *>(nullptr);
    return createStringError((Twine("meta flag ':") + MF->getName() +
                              "' has no value to use as its subject")
                                 .str());
  }

  if (MF->getMetaFlagID() == MetaFlag::MF_not ||
      MF->getMetaFlagID() == MetaFlag::MF_or)
    return lowerBuiltinLogicalFlag(MF, OperandVal, Ctx);

  if (Context.getMetaFlagDef(MF->getName()))
    return lowerUserDefinedFlag(MF, OperandVal, Ctx);

  return static_cast<Constraint *>(nullptr);
}

Expected<Constraint *>
PatternLowering::lowerBuiltinLogicalFlag(const MetaFlag *MF, Value *Subject,
                                         const DesugarContext &Ctx) {
  if (MF->getMetaFlagID() == MetaFlag::MF_not) {
    if (MF->getArguments().empty() || !MF->getArguments()[0].FlagValue)
      return createStringError("meta flag ':not' requires one nested flag");
    Expected<Constraint *> InnerOrErr =
        buildMetaFlagConstraint(MF->getArguments()[0].FlagValue, Subject, Ctx);
    if (!InnerOrErr)
      return InnerOrErr.takeError();
    Constraint *Inner = *InnerOrErr;
    if (!Inner)
      return createStringError(
          "meta flag ':not' contains a flag that cannot be lowered");
    return OperatorConstraint::getBuiltin(
        Context, Constraint::Unary, Constraint::BooleanResult,
        Constraint::O_Not, {Inner}, MF->getSourceRange());
  }

  if (MF->getMetaFlagID() == MetaFlag::MF_or) {
    SmallVector<Constraint *, 4> Inner;
    for (const auto &Arg : MF->getArguments()) {
      if (!Arg.FlagValue)
        return createStringError("meta flag ':or' requires nested flags");
      Expected<Constraint *> COrErr =
          buildMetaFlagConstraint(Arg.FlagValue, Subject, Ctx);
      if (!COrErr)
        return COrErr.takeError();
      if (Constraint *C = *COrErr)
        Inner.push_back(C);
      else
        return createStringError(
            "meta flag ':or' contains a flag that cannot be lowered");
    }
    if (Inner.empty())
      return createStringError("meta flag ':or' requires at least one flag");
    Constraint *Cur = Inner[0];
    for (size_t I = 1; I < Inner.size(); ++I) {
      Cur = OperatorConstraint::getBuiltin(
          Context, Constraint::Binary, Constraint::BooleanResult,
          Constraint::O_LogicalOr, {Cur, Inner[I]}, MF->getSourceRange());
    }
    return Cur;
  }

  return static_cast<Constraint *>(nullptr);
}

Expected<Constraint *>
PatternLowering::lowerUserDefinedFlag(const MetaFlag *MF, Value *Subject,
                                      const DesugarContext &Ctx) {
  (void)Ctx;
  MetaFlagDef *Def = Context.getMetaFlagDef(MF->getName());
  assert(Def && "expected valid meta flag definition");

  ArrayRef<StringRef> Params = Def->getParameters();
  ArrayRef<MetaFlag::Argument> Args = MF->getArguments();
  if (Args.size() != Def->getNumArguments())
    return createStringError((Twine("meta flag ':") + MF->getName() +
                              "' expects " + Twine(Def->getNumArguments()) +
                              " argument(s), got " + Twine(Args.size()))
                                 .str());
  if (!Def->getBody())
    return createStringError(
        (Twine("meta flag ':") + MF->getName() + "' has an empty body").str());

  MetaValueMap MetaValues;
  TypeMap TyMap;
  InstrValueMap EmptyInstrMap;
  MetaValues[Params.front()] = Subject;
  for (unsigned I = 0; I != Args.size(); ++I) {
    if (Args[I].K != MetaFlag::Argument::Integer)
      return createStringError((Twine("meta flag ':") + MF->getName() +
                                "' expects integer arguments")
                                   .str());
    MetaValues[Params[I + 1]] = IntegerConstant::get(
        Context, APSInt(APInt(64, Args[I].IntegerValue, true), false),
        MF->getSourceRange());
  }

  SubstitutionContext SubstCtx(MetaValues, TyMap, EmptyInstrMap);
  return substituteConstraint(Def->getBody(), SubstCtx);
}

Value *PatternLowering::substituteValue(Value *V,
                                        const SubstitutionContext &Ctx) {
  if (!V)
    return nullptr;
  if (const auto *MV = dyn_cast<MetaVariable>(V)) {
    auto It = Ctx.MetaValues.find(MV->getName());
    if (It != Ctx.MetaValues.end())
      V = It->second;
  }
  if (const auto *I = dyn_cast_or_null<Instruction>(V)) {
    auto It = Ctx.InstrValues.find(I);
    if (It != Ctx.InstrValues.end())
      return It->second;
  }
  return V;
}

Type *PatternLowering::substituteType(Type *Ty,
                                      const SubstitutionContext &Ctx) {
  if (!Ty)
    return nullptr;
  if (auto *MIT = dyn_cast<MetaIntegerType>(Ty)) {
    if (MIT->getBitWidthVariable()) {
      auto It = Ctx.Types.find(MIT->getBitWidthVariable()->getName());
      if (It != Ctx.Types.end())
        return It->second;
    }
  }
  if (auto *MRT = dyn_cast<MetaIRType>(Ty)) {
    if (MRT->getVariable()) {
      auto It = Ctx.Types.find(MRT->getVariable()->getName());
      if (It != Ctx.Types.end())
        return It->second;
    }
  }
  return Ty;
}

Constraint *
PatternLowering::substituteConstraint(Constraint *C,
                                      const SubstitutionContext &Ctx) {
  if (!C)
    return nullptr;

  switch (C->getConstraintID()) {
  case Constraint::Integer:
  case Constraint::Boolean:
  case Constraint::String:
    return C;
  case Constraint::Variable: {
    auto *VC = cast<VariableConstraint>(C);
    if (auto *Inst = dyn_cast<Instruction>(VC->getVariable())) {
      if (auto *NewInst = Ctx.InstrValues.lookup(Inst))
        return VariableConstraint::get(Context, NewInst, VC->getResultType(),
                                       VC->getSourceRange());
      return C;
    }
    if (auto *MV = dyn_cast<MetaVariable>(VC->getVariable())) {
      auto It = Ctx.MetaValues.find(MV->getName());
      if (It != Ctx.MetaValues.end()) {
        if (auto *TargetVar = dyn_cast<MetaVariable>(It->second)) {
          Constraint::ResultType ResTy =
              TargetVar->getType() != MetaType::Unknown
                  ? Constraint::getResultType(TargetVar->getType())
                  : VC->getResultType();
          return VariableConstraint::get(Context, TargetVar, ResTy,
                                         VC->getSourceRange());
        }
        if (auto *TargetInst = dyn_cast<Instruction>(It->second)) {
          if (auto *NewI = Ctx.InstrValues.lookup(TargetInst))
            TargetInst = NewI;
          return VariableConstraint::get(Context, TargetInst,
                                         Constraint::ValueResult,
                                         VC->getSourceRange());
        }
        if (auto *IC = dyn_cast<IntegerConstant>(It->second))
          return IntegerConstraint::get(Context, IC->getValue().getExtValue(),
                                        VC->getSourceRange());
      }
    }
    return C;
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call: {
    auto *OC = cast<OperatorConstraint>(C);
    SmallVector<Constraint *, 4> NewArgs;
    for (Constraint *Arg : OC->getArguments())
      NewArgs.push_back(substituteConstraint(Arg, Ctx));
    OperatorConstraint *New = nullptr;
    if (OC->isUserDefined())
      New = OperatorConstraint::getUserDefined(
          Context, OC->getConstraintID(), OC->getResultType(),
          OC->getOperator(), NewArgs, OC->getSourceRange());
    else
      New = OperatorConstraint::getBuiltin(
          Context, OC->getConstraintID(), OC->getResultType(),
          OC->getOperatorID(), NewArgs, OC->getSourceRange());
    New->setContextInstruction(
        remapContextInstruction(OC->getContextInstruction(), Ctx));
    return New;
  }
  default:
    return C;
  }
}

const Instruction *
PatternLowering::remapContextInstruction(const Instruction *CxtI,
                                         const SubstitutionContext &Ctx) const {
  if (!CxtI)
    return nullptr;
  auto It = Ctx.InstrValues.find(CxtI);
  return It == Ctx.InstrValues.end() ? CxtI : It->second;
}

} // namespace metaphir
} // namespace llvm
