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

} // namespace

Expected<Constraint *>
PatternLowering::buildMetaFlagConstraint(const MetaFlag *MF,
                                         Value *OperandVal) {
  if (!OperandVal) {
    if (!Context.getMetaFlagDef(MF->getName()))
      return static_cast<Constraint *>(nullptr);
    return createStringError((Twine("meta flag ':") + MF->getName() +
                              "' has no value to use as its subject")
                                 .str());
  }
  // The operand need not be a meta variable: expanding a composite matcher can
  // substitute a branch parameter with a literal, and substituteConstraint
  // turns that into a constant operand of the flag's constraint.

  if (MF->getMetaFlagID() == MetaFlag::MF_not) {
    if (MF->getArguments().empty() || !MF->getArguments()[0].FlagValue)
      return createStringError("meta flag ':not' requires one nested flag");
    Expected<Constraint *> InnerOrErr =
        buildMetaFlagConstraint(MF->getArguments()[0].FlagValue, OperandVal);
    if (!InnerOrErr)
      return InnerOrErr.takeError();
    Constraint *Inner = *InnerOrErr;
    if (!Inner)
      return createStringError(
          "meta flag ':not' contains a flag that cannot be lowered");
    return OperatorConstraint::get(Context, Constraint::Unary,
                                   Constraint::BooleanResult, "!", {Inner},
                                   MF->getSourceRange());
  }

  if (MF->getMetaFlagID() == MetaFlag::MF_or) {
    SmallVector<Constraint *, 4> Inner;
    for (const auto &Arg : MF->getArguments()) {
      if (!Arg.FlagValue)
        return createStringError("meta flag ':or' requires nested flags");
      Expected<Constraint *> COrErr =
          buildMetaFlagConstraint(Arg.FlagValue, OperandVal);
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
      Cur = OperatorConstraint::get(Context, Constraint::Binary,
                                    Constraint::BooleanResult, "||",
                                    {Cur, Inner[I]}, MF->getSourceRange());
    }
    return Cur;
  }

  if (MetaFlagDef *Def = Context.getMetaFlagDef(MF->getName())) {
    ArrayRef<StringRef> Params = Def->getParameters();
    ArrayRef<MetaFlag::Argument> Args = MF->getArguments();
    if (Args.size() != Def->getNumArguments())
      return createStringError((Twine("meta flag ':") + MF->getName() +
                                "' expects " + Twine(Def->getNumArguments()) +
                                " argument(s), got " + Twine(Args.size()))
                                   .str());
    if (!Def->getBody())
      return createStringError(
          (Twine("meta flag ':") + MF->getName() + "' has an empty body")
              .str());
    MetaValueMap MetaValues;
    StringMap<Type *> TyMap;
    // The first parameter is the subject the flag is written on; the rest take
    // the flag's arguments in order.
    MetaValues[Params.front()] = OperandVal;
    for (unsigned I = 0; I != Args.size(); ++I) {
      if (Args[I].K != MetaFlag::Argument::Integer)
        return createStringError((Twine("meta flag ':") + MF->getName() +
                                  "' expects integer arguments")
                                     .str());
      MetaValues[Params[I + 1]] = IntegerConstant::get(
          Context, APSInt(APInt(64, Args[I].IntegerValue, true), false),
          MF->getSourceRange());
    }
    return substituteConstraint(Def->getBody(), MetaValues, TyMap);
  }

  // Built-in matcher flags are handled by the matcher itself.
  return static_cast<Constraint *>(nullptr);
}

Error PatternLowering::lowerMetaFlags(
    Pattern *TargetPattern, ArrayRef<const MetaFlag *> Flags, Value *Subject,
    SmallVectorImpl<MetaFlag *> &RemainingFlags) {
  for (const MetaFlag *MF : Flags) {
    Expected<Constraint *> COrErr = buildMetaFlagConstraint(MF, Subject);
    if (!COrErr)
      return COrErr.takeError();
    if (Constraint *C = *COrErr)
      TargetPattern->addConstraint(C);
    else
      RemainingFlags.push_back(const_cast<MetaFlag *>(MF));
  }
  return Error::success();
}

Value *PatternLowering::substituteValue(Value *V,
                                        const MetaValueMap &MetaValues,
                                        const InstrValueMap &InstrValues) {
  if (!V)
    return nullptr;
  if (auto *I = dyn_cast<Instruction>(V)) {
    auto It = InstrValues.find(I);
    if (It != InstrValues.end())
      return It->second;
    return V;
  }
  if (auto *MV = dyn_cast<MetaVariable>(V)) {
    auto It = MetaValues.find(MV->getName());
    if (It != MetaValues.end())
      return It->second;
  }
  return V;
}

Type *PatternLowering::substituteType(Type *Ty,
                                      const StringMap<Type *> &TypeMap) {
  if (!Ty)
    return nullptr;
  if (auto *MIT = dyn_cast<MetaIntegerType>(Ty)) {
    if (MIT->getBitWidthVariable()) {
      auto It = TypeMap.find(MIT->getBitWidthVariable()->getName());
      if (It != TypeMap.end())
        return It->second;
    }
  }
  if (auto *MRT = dyn_cast<MetaIRType>(Ty)) {
    if (MRT->getVariable()) {
      auto It = TypeMap.find(MRT->getVariable()->getName());
      if (It != TypeMap.end())
        return It->second;
    }
  }
  return Ty;
}

Constraint *
PatternLowering::substituteConstraint(Constraint *C,
                                      const MetaValueMap &MetaValues,
                                      const StringMap<Type *> &TypeMap) {
  if (!C)
    return nullptr;

  switch (C->getConstraintID()) {
  case Constraint::Integer:
  case Constraint::Boolean:
  case Constraint::String:
    return C;
  case Constraint::Variable: {
    auto *VC = cast<VariableConstraint>(C);
    auto It = MetaValues.find(VC->getVariable()->getName());
    if (It != MetaValues.end()) {
      if (auto *TargetVar = dyn_cast<MetaVariable>(It->second)) {
        Constraint::ResultType ResTy =
            TargetVar->getType() != MetaType::Unknown
                ? Constraint::getResultType(TargetVar->getType())
                : VC->getResultType();
        return VariableConstraint::get(Context, TargetVar, ResTy,
                                       VC->getSourceRange());
      }
      if (auto *IC = dyn_cast<IntegerConstant>(It->second))
        return IntegerConstraint::get(Context, IC->getValue().getExtValue(),
                                      VC->getSourceRange());
    }
    return C;
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call: {
    auto *OC = cast<OperatorConstraint>(C);
    SmallVector<Constraint *, 4> NewArgs;
    for (Constraint *Arg : OC->getArguments())
      NewArgs.push_back(substituteConstraint(Arg, MetaValues, TypeMap));
    auto *New = OperatorConstraint::get(Context, OC->getConstraintID(),
                                        OC->getResultType(), OC->getOperator(),
                                        NewArgs, OC->getSourceRange());
    // OperatorConstraint::get does not carry the context instruction over, and
    // a copy inlined from a 'match' body has to point at the inlined
    // instruction rather than the one in the definition.
    New->setContextInstruction(
        remapContextInstruction(OC->getContextInstruction()));
    return New;
  }
  default:
    return C;
  }
}

const Instruction *
PatternLowering::remapContextInstruction(const Instruction *Context) const {
  if (!Context)
    return nullptr;
  auto It = InlinedInstructions.find(Context);
  return It == InlinedInstructions.end() ? Context : It->second;
}

Error PatternLowering::inlineBranch(SmallVectorImpl<Instruction *> &BranchInsts,
                                    Instruction *&RootInst,
                                    Pattern *TargetPattern,
                                    Instruction *CompInst, CompositeMatcher *CM,
                                    const CompositeMatcher::Branch &Branch,
                                    ArrayRef<MatcherOperand> CallerOps) {
  RootInst = nullptr;
  InlinedInstructions.clear();
  MetaValueMap MetaValues;
  StringMap<Type *> TypeMap;

  ArrayRef<ParameterDef> Params = CM->getParameters();

  // Set when a parameter fixes a concrete type that the caller does not use, in
  // which case this branch does not apply.
  bool TypeMismatch = false;
  SmallVector<InstructionFlag::FlagID, 4> OmittedFlags;
  auto mapTypeParam = [&](const ParameterDef &P, Type *CallerTy) {
    if (!CallerTy)
      return;
    if (P.Name.empty()) {
      // The declaration fixed the type instead of binding a name for it. Types
      // are uniqued, so identity is the right comparison.
      if (P.Ty != CallerTy)
        TypeMismatch = true;
      return;
    }
    StringRef ParamName = P.Name;
    TypeMap[ParamName] = CallerTy;
    if (auto *MIT = dyn_cast<MetaIntegerType>(CallerTy)) {
      if (MIT->getBitWidthVariable())
        MetaValues[ParamName] = MIT->getBitWidthVariable();
    }
  };

  auto mapValParam = [&](StringRef ParamName, Value *CallerVal) {
    if (CallerVal)
      MetaValues[ParamName] = CallerVal;
  };

  switch (CM->getSyntax()) {
  case Instruction::OperandSyntax::Cast:
    if (Params.size() >= 3 && CallerOps.size() >= 2) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapTypeParam(Params[2], CallerOps[1].Ty);
    }
    break;
  case Instruction::OperandSyntax::Binary:
    if (Params.size() >= 3 && CallerOps.size() >= 2) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapValParam(Params[2].Name, CallerOps[1].Val);
    }
    break;
  case Instruction::OperandSyntax::Ternary:
    // Three independently typed operands.
    if (Params.size() >= 6 && CallerOps.size() >= 3) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
      mapTypeParam(Params[2], CallerOps[1].Ty);
      mapValParam(Params[3].Name, CallerOps[1].Val);
      mapTypeParam(Params[4], CallerOps[2].Ty);
      mapValParam(Params[5].Name, CallerOps[2].Val);
    }
    break;
  case Instruction::OperandSyntax::Unary:
    if (Params.size() >= 2 && CallerOps.size() >= 1) {
      mapTypeParam(Params[0], CallerOps[0].Ty);
      mapValParam(Params[1].Name, CallerOps[0].Val);
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
  if (TypeMismatch)
    return Error::success();

  // Bind flag parameters hygienically.
  //
  // For each supported flag of the composite matcher:
  // - If the branch specifies a fixed value for this flag (e.g. `or [nsw,
  // nuw]`):
  //   - Caller omitted the flag (asserts absent/false): if FixedVal is true,
  //     statically incompatible; prune this branch immediately.
  //   - Caller asserted the flag present without capture (e.g. `addlike nsw`):
  //     if FixedVal is false, statically incompatible; prune this branch.
  //   - Caller captured the flag (e.g. `addlike nsw:?x`): bind the caller's
  //     capture variable to FixedVal via TargetPattern's FixedFlags.
  //   - Caller used wildcard capture (e.g. `addlike nsw:?_`): matches without
  //     binding.
  // - If the branch does NOT specify a fixed value for this flag:
  //   - Delegate to the branch's instructions (e.g. `add nsw:?nsw nuw:?nuw`):
  //     - Named capture: map flag name to caller's capture variable.
  //     - Wildcard capture: create a synthetic internal variable.
  //     - Present without capture: require the flag to be present.
  //     - Omitted: remove the flag so the matcher requires it to be absent.
  for (InstructionFlag::FlagID FlagID : CM->getSupportedFlags()) {
    StringRef FlagName = InstructionFlag::getName(FlagID);
    const InstructionFlag *CallerFlag = nullptr;
    for (const InstructionFlag &F : CompInst->getFlags()) {
      if (F.ID == FlagID) {
        CallerFlag = &F;
        break;
      }
    }

    const auto *FixedIt = llvm::find_if(
        Branch.FixedFlags, [&](const auto &P) { return P.first == FlagID; });
    bool HasFixedVal = (FixedIt != Branch.FixedFlags.end());

    if (HasFixedVal) {
      bool FixedVal = FixedIt->second;
      if (!CallerFlag) {
        // Flag omitted by caller: asserts absent (false).
        if (FixedVal != false)
          return Error::success(); // Branch requires true, caller requires
                                   // false.
      } else if (!CallerFlag->Capture) {
        // Flag present without capture: asserts present (true).
        if (FixedVal != true)
          return Error::success(); // Branch requires false, caller requires
                                   // true.
      } else {
        // Flag present with capture (e.g. `nsw:?x` or `nsw:?_`).
        if (!isWildcardCapture(CallerFlag->Capture)) {
          TargetPattern->addFixedFlag(CallerFlag->Capture, FixedVal);
          MetaValues[FlagName] = CallerFlag->Capture;
        }
      }
      continue;
    }

    if (CallerFlag && CallerFlag->Capture) {
      // Named capture (may be ?_ wildcard or a real variable)
      if (isWildcardCapture(CallerFlag->Capture)) {
        // Wildcard: capture the flag value but don't expose any variable.
        // Create a synthetic internal variable so the flag is captured but
        // not constrained.
        std::string SyntheticName =
            (Twine("_flag$") + CompInst->getResultName() + "$" + FlagName)
                .str();
        auto *FlagVar = MetaVariable::get(
            Context, SyntheticName, MetaType::Bool, CompInst->getSourceRange());
        MetaValues[FlagName] = FlagVar;
      } else {
        // Named: map the branch parameter to the caller's capture variable.
        MetaValues[FlagName] = CallerFlag->Capture;
      }
    } else if (CallerFlag) {
      // Flag present without capture (e.g. `addlike nsw`): assert present.
      // Mapping to nullptr causes the branch instruction's flag to have nullptr
      // capture, which InstructionMatcher natively asserts as present.
      MetaValues[FlagName] = nullptr;
    } else {
      // Flag omitted (e.g. plain `addlike`): assert absent.
      OmittedFlags.push_back(FlagID);
    }
  }

  // Determine root instruction: '%ret' if present, otherwise the last
  // instruction.
  const Instruction *RootBI = nullptr;
  for (Instruction *BI : Branch.Instructions) {
    if (BI->getResultName() == "ret") {
      RootBI = BI;
      break;
    }
  }
  if (!RootBI && !Branch.Instructions.empty())
    RootBI = Branch.Instructions.back();

  // Inline instructions
  for (Instruction *BI : Branch.Instructions) {
    StringRef ResultName = BI->getResultName();
    bool IsRoot = (BI == RootBI);
    if (IsRoot)
      ResultName = CompInst->getResultName();
    else
      ResultName = Context.pImpl->Saver.save(
          (Twine(CompInst->getResultName()) + "$" + ResultName).str());

    SmallVector<MatcherOperand, 8> NewOps;
    for (const MatcherOperand &Op : BI->getUnkeyedOperands()) {
      MatcherOperand NewOp = Op;
      NewOp.Ty = substituteType(Op.Ty, TypeMap);
      NewOp.Val = substituteValue(Op.Val, MetaValues, InlinedInstructions);
      // Desugar this operand's metaflags now, against the substituted value.
      // The operand is lowered here rather than after expansion because at
      // this point it belongs to exactly one pattern: expansion later hands
      // instructions to several variants by pointer, and clearing the flags
      // then would leave every variant but the first without the constraint.
      SmallVector<MetaFlag *, 4> RemainingFlags;
      if (Error E = lowerMetaFlags(TargetPattern, Op.MetaFlags, NewOp.Val,
                                   RemainingFlags))
        return E;
      NewOp.setMetaFlags(Context, RemainingFlags);
      NewOps.push_back(NewOp);
    }

    MetaVariable *Capture = BI->getCapture();
    SmallVector<MetaFlag *, 4> MetaFlags(BI->getMetaFlags().begin(),
                                         BI->getMetaFlags().end());
    if (IsRoot) {
      if (CompInst->getCapture())
        Capture = CompInst->getCapture();
      for (const MetaFlag *MF : CompInst->getMetaFlags())
        if (MF->getMetaFlagID() == MetaFlag::MF_o)
          MetaFlags.push_back(const_cast<MetaFlag *>(MF));
    }

    // Instruction meta flags in a composite body cannot be lowered by the
    // initial pattern pass: the body instructions are not part of the caller
    // pattern yet. Lower them after selecting the final capture for this
    // inlined instruction, leaving matcher-owned flags in place.
    if (!Capture && any_of(MetaFlags, [&](const MetaFlag *MF) {
          return Context.getMetaFlagDef(MF->getName()) != nullptr;
        }))
      Capture = MetaVariable::get(Context, "_", MetaType::Instruction,
                                  BI->getSourceRange());
    SmallVector<MetaFlag *, 4> RemainingMetaFlags;
    if (Error E = lowerMetaFlags(TargetPattern, MetaFlags, Capture,
                                 RemainingMetaFlags))
      return E;
    MetaFlags = std::move(RemainingMetaFlags);

    SmallVector<InstructionFlag, 4> NewFlags;
    for (const InstructionFlag &BF : BI->getFlags()) {
      if (llvm::is_contained(OmittedFlags, BF.ID))
        continue;
      if (IsRoot && CM->hasSupportedFlag(BF.ID)) {
        StringRef FlagName = InstructionFlag::getName(BF.ID);
        MetaVariable *Cap = nullptr;
        if (auto *V = MetaValues.lookup(FlagName))
          Cap = dyn_cast<MetaVariable>(V);
        NewFlags.push_back(InstructionFlag{BF.ID, Cap});
      } else {
        NewFlags.push_back(BF);
      }
    }

    Instruction *NewInst = Instruction::get(
        Context, BI->getInstructionID(), ResultName, NewFlags, MetaFlags,
        NewOps, Capture, BI->getSourceRange(), CompInst->getParentBlock(),
        // The inlined instruction sits at the use site, so it takes the use
        // site's settings except where the body wrote its own.
        BI->getSettings().inheritedFrom(CompInst->getSettings()));
    if (IsRoot) {
      for (const MetaFlag *MF : CompInst->getMetaFlags()) {
        if (MF->getMetaFlagID() != MetaFlag::MF_o)
          continue;
        unsigned Index = 0;
        if (!MF->getArguments().empty())
          Index = MF->getArguments().front().IntegerValue;
        NewInst->setOrSelfValue(CallerOps[Index].Val);
        break;
      }
    }
    BranchInsts.push_back(NewInst);
    InlinedInstructions[BI] = NewInst;
    if (IsRoot)
      RootInst = NewInst;
  }

  // Inline constraints
  for (Constraint *C : Branch.Constraints) {
    Constraint *Subst = substituteConstraint(C, MetaValues, TypeMap);
    if (Subst)
      TargetPattern->addConstraint(Subst);
  }

  return Error::success();
}

Expected<PatternVariants> PatternLowering::lower(Pattern *P) {
  if (!P)
    return PatternVariants();
  // Metaflags written in the pattern are desugared while P is still the only
  // pattern; those inlined from a 'match' body are desugared by inlineBranch as
  // it builds each branch. Both happen before an instruction can be shared by
  // more than one expansion variant.
  if (Error E = desugarMetaFlags(P))
    return E;
  Expected<SmallVector<Pattern *, 2>> Variants = expandCompositeMatchers(P);
  if (!Variants)
    return Variants.takeError();
  return PatternVariants(std::move(*Variants));
}

Error PatternLowering::desugarMetaFlags(Pattern *P) {
  for (Instruction *I : P->getInstructions()) {
    // An instruction-placement flag takes the instruction as its subject, which
    // a constraint can only name through the instruction's capture. Built-in
    // flags such as ':c' and ':o' have no definition and stay for the matcher.
    // An instruction-placement flag takes the instruction as its subject, which
    // a constraint names through the instruction's capture. When the pattern
    // did not name one, synthesize it: the matcher binds a capture whatever its
    // name, and Instantiation leaves '_'-prefixed names out of the reported
    // bindings, so it stays invisible.
    if (!I->getCapture() && any_of(I->getMetaFlags(), [&](const MetaFlag *MF) {
          return Context.getMetaFlagDef(MF->getName()) != nullptr;
        }))
      I->setCapture(MetaVariable::get(Context, "_", MetaType::Instruction,
                                      I->getSourceRange()));

    SmallVector<MetaFlag *, 4> RemainingFlags;
    if (Error E = lowerMetaFlags(P, I->getMetaFlags(), I->getCapture(),
                                 RemainingFlags))
      return E;
    I->setMetaFlags(Context, RemainingFlags);

    ArrayRef<MatcherOperand> Ops = I->getUnkeyedOperands();
    for (unsigned OpIdx = 0; OpIdx != Ops.size(); ++OpIdx) {
      RemainingFlags.clear();
      const MatcherOperand &Op = Ops[OpIdx];
      if (Error E = lowerMetaFlags(P, Op.MetaFlags, Op.Val, RemainingFlags))
        return E;
      I->setOperandMetaFlags(OpIdx, Context, RemainingFlags);
    }
  }
  return Error::success();
}

Expected<SmallVector<Pattern *, 2>>
PatternLowering::expandCompositeMatchers(Pattern *P) {
  SmallVector<Pattern *, 2> Worklist = {P};

  while (true) {
    bool FoundComposite = false;
    SmallVector<Pattern *, 2> NextWorklist;

    for (Pattern *Cur : Worklist) {
      ArrayRef<Instruction *> Insts = Cur->getInstructions();
      int CompIdx = -1;
      for (size_t I = 0; I < Insts.size(); ++I) {
        if (Insts[I]->isComposite()) {
          CompIdx = I;
          break;
        }
      }

      if (CompIdx == -1) {
        NextWorklist.push_back(Cur);
        continue;
      }

      FoundComposite = true;
      Instruction *CompInst = Insts[CompIdx];
      CompositeMatcher *CM = CompInst->getCompositeMatcher();
      ArrayRef<MatcherOperand> OriginalCallerOps =
          CompInst->getUnkeyedOperands();
      bool IsCommutative =
          any_of(CompInst->getMetaFlags(), [](const MetaFlag *MF) {
            return MF->getMetaFlagID() == MetaFlag::MF_c;
          });

      for (const auto &Branch : CM->getBranches()) {
        unsigned NumOperandOrders = IsCommutative ? 2 : 1;
        for (unsigned OperandOrder = 0; OperandOrder != NumOperandOrders;
             ++OperandOrder) {
          SmallVector<MatcherOperand, 8> CallerOps(OriginalCallerOps.begin(),
                                                   OriginalCallerOps.end());
          if (OperandOrder == 1)
            std::swap(CallerOps[0], CallerOps[1]);
          Pattern *Variant = Pattern::get(Context);
          SmallVector<Instruction *, 4> BranchInsts;
          Instruction *RootInst = nullptr;
          if (Error E = inlineBranch(BranchInsts, RootInst, Variant, CompInst,
                                     CM, Branch, CallerOps))
            return E;

          // If inlineBranch rejected the branch (e.g. flag conflict), skip it.
          if (BranchInsts.empty())
            continue;

          assert(RootInst &&
                 "RootInst should not be null for non-empty BranchInsts");

          auto replaceCompInst = [&](Instruction *I) -> Instruction * {
            bool NeedsClone = false;
            for (const MatcherOperand &Op : I->getUnkeyedOperands()) {
              if (Op.Val == CompInst) {
                NeedsClone = true;
                break;
              }
            }
            if (!NeedsClone)
              return I;
            SmallVector<MatcherOperand, 8> NewOps;
            for (const MatcherOperand &Op : I->getUnkeyedOperands()) {
              MatcherOperand NewOp = Op;
              if (NewOp.Val == CompInst)
                NewOp.Val = RootInst;
              NewOps.push_back(NewOp);
            }
            for (const MatcherOperand &Op : I->getKeyedOperands())
              NewOps.push_back(Op);
            return Instruction::get(
                Context, I->getInstructionID(), I->getResultName(),
                I->getFlags(), I->getMetaFlags(), NewOps, I->getCapture(),
                I->getSourceRange(), I->getParentBlock(), I->getSettings());
          };

          for (int I = 0; I < CompIdx; ++I)
            Variant->addInstruction(Insts[I]);

          for (Instruction *BI : BranchInsts)
            Variant->addInstruction(BI);

          for (size_t I = CompIdx + 1; I < Insts.size(); ++I)
            Variant->addInstruction(replaceCompInst(Insts[I]));

          // A constraint written outside the matcher may be anchored on the
          // composite instruction, which this variant replaced with its root.
          // Each variant therefore takes its own copy, with the context
          // rewritten to that root.
          InlinedInstructions[CompInst] = RootInst;
          MetaValueMap NoValues;
          StringMap<Type *> NoTypes;
          for (Constraint *C : Cur->getConstraints())
            if (Constraint *Copy = substituteConstraint(C, NoValues, NoTypes))
              Variant->addConstraint(Copy);
          for (MetaVariable *M : Cur->getMetaVariables())
            Variant->addMetaVariable(M);
          for (const auto &[Var, Val] : Cur->getFixedFlags())
            Variant->addFixedFlag(Var, Val);

          NextWorklist.push_back(Variant);
        }
      }
    }

    Worklist = std::move(NextWorklist);
    if (!FoundComposite)
      break;
  }

  return Worklist;
}

} // namespace metaphir
} // namespace llvm
