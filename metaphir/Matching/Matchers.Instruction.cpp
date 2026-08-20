#include "metaphir/Matching/Matchers.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Values.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>

namespace llvm {
namespace metaphir {
namespace detail {

static bool hasMetaFlag(ArrayRef<MetaFlag *> Flags, MetaFlag::MetaFlagID ID) {
  return any_of(Flags, [ID](const MetaFlag *Flag) {
    return Flag->getMetaFlagID() == ID;
  });
}

static const MetaFlag &getNestedMetaFlag(const MetaFlag::Argument &Argument) {
  assert(Argument.K == MetaFlag::Argument::Flag && Argument.FlagValue &&
         "expected a nested meta flag argument");
  return *Argument.FlagValue;
}

static bool matchOperandMetaFlag(const MetaFlag &Flag,
                                 const llvm::Value &Target) {
  using namespace PatternMatch;

  switch (Flag.getMetaFlagID()) {
  case MetaFlag::MF_s:
    return Target.hasOneUse();
  case MetaFlag::MF_su:
    return Target.hasOneUser();
  case MetaFlag::MF_allones:
    return PatternMatch::match(&Target, m_AllOnes());
  case MetaFlag::MF_lowbitmask:
    return PatternMatch::match(&Target, m_LowBitMask());
  case MetaFlag::MF_forbidpoison:
    if (const auto *Constant = dyn_cast<llvm::Constant>(&Target))
      return !isa<PoisonValue>(Constant) && !Constant->containsPoisonElement();
    return false;
  case MetaFlag::MF_integralconstant:
    return PatternMatch::match(&Target, m_AnyIntegralConstant());
  case MetaFlag::MF_zerofp:
    return PatternMatch::match(&Target, m_AnyZeroFP());
  case MetaFlag::MF_poison:
    return PatternMatch::match(&Target, m_Poison());
  case MetaFlag::MF_apint: {
    const APInt *Value = nullptr;
    return PatternMatch::match(&Target, m_APInt(Value));
  }
  case MetaFlag::MF_constantint:
    return isa<llvm::ConstantInt>(Target);
  case MetaFlag::MF_poweroftwo:
    return PatternMatch::match(&Target, m_Power2());
  case MetaFlag::MF_or: {
    assert(!Flag.getArguments().empty() &&
           "':or' requires at least one argument");
    return any_of(Flag.getArguments(), [&](const MetaFlag::Argument &Argument) {
      return matchOperandMetaFlag(getNestedMetaFlag(Argument), Target);
    });
  }
  case MetaFlag::MF_not:
    assert(Flag.getArguments().size() == 1 &&
           "':not' requires exactly one argument");
    return !matchOperandMetaFlag(getNestedMetaFlag(Flag.getArguments().front()),
                                 Target);
  case MetaFlag::MF_c:
  case MetaFlag::MF_o:
    llvm_unreachable("instruction meta flag used on an operand");
  case MetaFlag::UnknownMetaFlag:
    llvm_unreachable("invalid meta flag ID");
  }
}

static bool matchUseFlags(ArrayRef<MetaFlag *> Flags,
                          const llvm::Value &Target) {
  for (const MetaFlag *Flag : Flags) {
    switch (Flag->getMetaFlagID()) {
    case MetaFlag::MF_s:
      if (!Target.hasOneUse())
        return false;
      break;
    case MetaFlag::MF_su:
      if (!Target.hasOneUser())
        return false;
      break;
    default:
      break;
    }
  }
  return true;
}

static bool hasSemanticFlag(InstructionFlag::FlagID ID,
                            const llvm::Instruction &Target) {
  switch (ID) {
  case InstructionFlag::F_nsw:
    return Target.hasNoSignedWrap();
  case InstructionFlag::F_nuw:
    if (const auto *GEP = dyn_cast<GEPOperator>(&Target))
      return GEP->hasNoUnsignedWrap();
    return Target.hasNoUnsignedWrap();
  case InstructionFlag::F_exact:
    assert(isa<PossiblyExactOperator>(Target) &&
           "exact flag used with an incompatible instruction");
    return cast<PossiblyExactOperator>(Target).isExact();
  case InstructionFlag::F_disjoint:
    assert(isa<PossiblyDisjointInst>(Target) &&
           "disjoint flag used with an incompatible instruction");
    return cast<PossiblyDisjointInst>(Target).isDisjoint();
  case InstructionFlag::F_inalloca:
    assert(isa<AllocaInst>(Target) &&
           "inalloca flag used with an incompatible instruction");
    return cast<AllocaInst>(Target).isUsedWithInAlloca();
  case InstructionFlag::F_volatile:
    if (const auto *Load = dyn_cast<LoadInst>(&Target))
      return Load->isVolatile();
    if (const auto *Store = dyn_cast<StoreInst>(&Target))
      return Store->isVolatile();
    llvm_unreachable("volatile flag used with an incompatible instruction");
  case InstructionFlag::F_inbounds:
    assert(isa<GetElementPtrInst>(Target) &&
           "inbounds flag used with an incompatible instruction");
    return cast<GetElementPtrInst>(Target).isInBounds();
  case InstructionFlag::F_nusw:
    assert(isa<GetElementPtrInst>(Target) &&
           "nusw flag used with an incompatible instruction");
    return cast<GetElementPtrInst>(Target).hasNoUnsignedSignedWrap();
  case InstructionFlag::F_nneg:
    return Target.hasNonNeg();
  case InstructionFlag::F_samesign:
    assert(isa<ICmpInst>(Target) &&
           "samesign flag used with an incompatible instruction");
    return cast<ICmpInst>(Target).hasSameSign();
  case InstructionFlag::F_fast:
  case InstructionFlag::F_nnan:
  case InstructionFlag::F_ninf:
  case InstructionFlag::F_nsz:
  case InstructionFlag::F_arcp:
  case InstructionFlag::F_contract:
  case InstructionFlag::F_afn:
  case InstructionFlag::F_reassoc: {
    FastMathFlags Flags = Target.getFastMathFlagsOrNone();
    switch (ID) {
    case InstructionFlag::F_fast:
      return Flags.isFast();
    case InstructionFlag::F_nnan:
      return Flags.noNaNs();
    case InstructionFlag::F_ninf:
      return Flags.noInfs();
    case InstructionFlag::F_nsz:
      return Flags.noSignedZeros();
    case InstructionFlag::F_arcp:
      return Flags.allowReciprocal();
    case InstructionFlag::F_contract:
      return Flags.allowContract();
    case InstructionFlag::F_afn:
      return Flags.approxFunc();
    case InstructionFlag::F_reassoc:
      return Flags.allowReassoc();
    default:
      llvm_unreachable("not a fast-math flag");
    }
  }
  case InstructionFlag::NumFlagIDs:
    llvm_unreachable("invalid instruction flag ID");
  }
  llvm_unreachable("invalid instruction flag ID");
}

static bool matchSemanticFlags(const Instruction &Matcher,
                               const llvm::Instruction &Target,
                               Instantiation &State) {
  for (const InstructionFlag &Flag : Matcher.getFlags()) {
    bool Present = hasSemanticFlag(Flag.ID, Target);
    if (Flag.Capture) {
      if (!bind(State, *Flag.Capture, Present))
        return false;
    } else if (!Present) {
      return false;
    }
  }
  return true;
}

template <unsigned Opcode>
static bool matchOpcode(const llvm::Instruction &Target) {
  return Target.getOpcode() == Opcode;
}

static bool matchShr(const llvm::Instruction &Target) {
  return Target.getOpcode() == llvm::Instruction::LShr ||
         Target.getOpcode() == llvm::Instruction::AShr;
}

static bool matchZExtOrSExt(const llvm::Instruction &Target) {
  return Target.getOpcode() == llvm::Instruction::ZExt ||
         Target.getOpcode() == llvm::Instruction::SExt;
}

static bool matchBitwiseLogic(const llvm::Instruction &Target) {
  return llvm::Instruction::isBitwiseLogicOp(Target.getOpcode());
}

static bool matchBranch(const llvm::Instruction &Target) {
  return isa<CondBrInst, UncondBrInst>(Target);
}

static bool matchInstructionTarget(Instruction::InstructionID ID,
                                   const llvm::Instruction &Target) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_TARGET(Name, TargetMatcher)                    \
  case Instruction::I_##Name:                                                  \
    return TargetMatcher(Target);
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction matcher ID");
}

static bool matchPredicate(const Instruction &Matcher,
                           const llvm::Instruction &Target,
                           Instantiation &State) {
  const MatcherOperand *Predicate =
      Matcher.getKeyedOperand(MatcherOperand::Predicate);
  if (!Predicate)
    return true;

  assert(isa<CmpInst>(Target) &&
         "predicate used with an incompatible instruction matcher");
  assert(Predicate->Val && "predicate operand has no value");

  const auto &Compare = cast<CmpInst>(Target);
  if (const auto *Variable = dyn_cast<MetaVariable>(Predicate->Val))
    return bind(State, *Variable, Compare.getPredicate());

  const auto *Keyword = dyn_cast<KeywordConstant>(Predicate->Val);
  assert(Keyword && "predicate is neither a variable nor a keyword");

  return KeywordConstant::getKeywordName(Keyword->getKeywordID()) ==
         CmpInst::getPredicateName(Compare.getPredicate());
}

static bool matchIntegerKeyedOperand(const MatcherOperand &Matcher,
                                     const APSInt &Target,
                                     Instantiation &State) {
  assert(Matcher.Val && "keyed integer operand has no value");
  if (const auto *Variable = dyn_cast<MetaVariable>(Matcher.Val))
    return bind(State, *Variable, static_cast<const APInt &>(Target));
  const auto *Constant = dyn_cast<IntegerConstant>(Matcher.Val);
  assert(Constant && "keyed integer operand is not an integer matcher");
  return APSInt::isSameValue(Constant->getValue(), Target);
}

static std::optional<APSInt>
getKeyedIntegerTarget(MatcherOperand::KeyedOperandKind Kind,
                      const llvm::Instruction &Target) {
  switch (Kind) {
  case MatcherOperand::Alignment:
    if (const auto *Alloca = dyn_cast<AllocaInst>(&Target))
      return APSInt::getUnsigned(Alloca->getAlign().value());
    if (const auto *Load = dyn_cast<LoadInst>(&Target))
      return APSInt::getUnsigned(Load->getAlign().value());
    if (const auto *Store = dyn_cast<StoreInst>(&Target))
      return APSInt::getUnsigned(Store->getAlign().value());
    llvm_unreachable("alignment used with an incompatible instruction");
  case MatcherOperand::AddressSpace:
    assert(isa<AllocaInst>(Target) &&
           "address space used with an incompatible instruction");
    return APSInt::getUnsigned(cast<AllocaInst>(Target).getAddressSpace());
  case MatcherOperand::InRangeLower:
  case MatcherOperand::InRangeUpper: {
    assert(isa<GetElementPtrInst>(Target) &&
           "inrange bound used with an incompatible instruction");
    std::optional<ConstantRange> Range = cast<GEPOperator>(Target).getInRange();
    if (!Range)
      return std::nullopt;
    const APInt &Bound = Kind == MatcherOperand::InRangeLower
                             ? Range->getLower()
                             : Range->getUpper();
    return APSInt(Bound, false);
  }
  case MatcherOperand::NotKeyed:
  case MatcherOperand::Predicate:
  case MatcherOperand::NumKeyedOperandKinds:
    llvm_unreachable("keyed operand does not contain an integer");
  }
  llvm_unreachable("invalid keyed operand kind");
}

static bool matchKeyedOperands(const Instruction &Matcher,
                               const llvm::Instruction &Target,
                               Instantiation &State) {
  if (!matchPredicate(Matcher, Target, State))
    return false;

  for (unsigned Kind = MatcherOperand::Alignment;
       Kind != MatcherOperand::NumKeyedOperandKinds; ++Kind) {
    const auto Key = static_cast<MatcherOperand::KeyedOperandKind>(Kind);
    const MatcherOperand *Operand = Matcher.getKeyedOperand(Key);
    if (!Operand)
      continue;
    std::optional<APSInt> TargetValue = getKeyedIntegerTarget(Key, Target);
    if (!TargetValue ||
        !matchIntegerKeyedOperand(*Operand, *TargetValue, State))
      return false;
  }
  return true;
}

static MatchResults matchValueOperand(const MatcherOperand &Matcher,
                                      const llvm::Value &Target,
                                      Instantiation State,
                                      const MatchDriver &Driver) {
  assert(Matcher.IsInstructionOperand && "expected a value operand");
  if (Matcher.IsArray)
    return {};
  assert(Matcher.Val && "matcher operand has no value");
  if (Matcher.Ty && !matchType(*Matcher.Ty, *Target.getType(), State))
    return {};
  if (!all_of(Matcher.MetaFlags, [&](const MetaFlag *Flag) {
        assert(Flag && "null operand meta flag");
        return matchOperandMetaFlag(*Flag, Target);
      }))
    return {};
  return Driver.match(*Matcher.Val, Target, std::move(State));
}

static MatchResults matchOperandOrder(ArrayRef<MatcherOperand> PatternOperands,
                                      ArrayRef<const llvm::Value *> Targets,
                                      ArrayRef<unsigned> Order,
                                      Instantiation State,
                                      const MatchDriver &Driver) {
  assert(Targets.size() == Order.size() &&
         "target operand order has inconsistent sizes");
  MatchResults States = success(std::move(State));
  for (unsigned Index = 0; Index != PatternOperands.size(); ++Index) {
    const MatcherOperand &Operand = PatternOperands[Index];
    if (Operand.IsArray) {
      assert(Index + 1 == PatternOperands.size() &&
             "array capture must be the final operand");
      assert(Operand.ValueArray && "array operand has no value-array capture");

      Instantiation::ValueArray Values;
      Instantiation::TypeArray Types;
      for (unsigned TargetIndex = Index; TargetIndex != Targets.size();
           ++TargetIndex) {
        assert(Order[TargetIndex] < Targets.size() &&
               "operand index is out of range");
        const llvm::Value *Target = Targets[Order[TargetIndex]];
        Values.push_back(Target);
        if (Operand.TypeArray)
          Types.push_back(Target->getType());
      }

      MatchResults Bound;
      for (Instantiation &Candidate : States) {
        if (!bind(Candidate, *Operand.ValueArray, Values))
          continue;
        if (Operand.TypeArray && !bind(Candidate, *Operand.TypeArray, Types))
          continue;
        Bound.push_back(std::move(Candidate));
      }
      return Bound;
    }

    MatchResults Next;
    for (Instantiation &Candidate : States) {
      assert(Order[Index] < Targets.size() && "operand index is out of range");
      MatchResults Matches = matchValueOperand(Operand, *Targets[Order[Index]],
                                               std::move(Candidate), Driver);
      Next.append(std::make_move_iterator(Matches.begin()),
                  std::make_move_iterator(Matches.end()));
    }
    States = std::move(Next);
    if (States.empty())
      break;
  }
  return States;
}

static SmallVector<const llvm::Value *, 4>
getTargetOperands(const llvm::Instruction &Target) {
  SmallVector<const llvm::Value *, 4> Operands;
  switch (Target.getOpcode()) {
  case llvm::Instruction::CondBr: {
    const auto &Branch = cast<CondBrInst>(Target);
    Operands.push_back(Branch.getCondition());
    Operands.push_back(Branch.getSuccessor(0));
    Operands.push_back(Branch.getSuccessor(1));
    return Operands;
  }
  case llvm::Instruction::UncondBr:
    Operands.push_back(cast<UncondBrInst>(Target).getSuccessor(0));
    return Operands;
  case llvm::Instruction::Call: {
    const auto &Call = cast<CallBase>(Target);
    Operands.push_back(Call.getCalledOperand());
    for (const llvm::Use &Argument : Call.args())
      Operands.push_back(Argument.get());
    return Operands;
  }
  case llvm::Instruction::PHI: {
    const auto &Phi = cast<PHINode>(Target);
    for (unsigned Index = 0; Index != Phi.getNumIncomingValues(); ++Index) {
      Operands.push_back(Phi.getIncomingValue(Index));
      Operands.push_back(Phi.getIncomingBlock(Index));
    }
    return Operands;
  }
  case llvm::Instruction::ExtractValue:
  case llvm::Instruction::InsertValue: {
    for (const llvm::Use &Operand : Target.operands())
      Operands.push_back(Operand.get());
    llvm::Type *IndexType = llvm::Type::getInt64Ty(Target.getContext());
    ArrayRef<unsigned> Indices =
        Target.getOpcode() == llvm::Instruction::ExtractValue
            ? cast<ExtractValueInst>(Target).getIndices()
            : cast<InsertValueInst>(Target).getIndices();
    for (unsigned Index : Indices)
      Operands.push_back(ConstantInt::get(IndexType, Index));
    return Operands;
  }
  default:
    for (const llvm::Use &Operand : Target.operands())
      Operands.push_back(Operand.get());
    return Operands;
  }
}

static std::optional<unsigned> getOrSelfOperand(const Instruction &Matcher) {
  for (const MetaFlag *Flag : Matcher.getMetaFlags()) {
    assert(Flag && "null instruction meta flag");
    if (Flag->getMetaFlagID() != MetaFlag::MF_o)
      continue;
    if (Flag->getArguments().empty())
      return 0;
    assert(Flag->getArguments().size() == 1 &&
           Flag->getArguments().front().K == MetaFlag::Argument::Integer &&
           Flag->getArguments().front().IntegerValue >= 0 &&
           "':o' requires one non-negative integer argument");
    return static_cast<unsigned>(Flag->getArguments().front().IntegerValue);
  }
  return std::nullopt;
}

static const llvm::Type &
getTypeOnlyOperandTarget(const Instruction &Matcher,
                         const llvm::Instruction &Target) {
  if (Matcher.getInstructionID() == Instruction::I_alloca)
    return *cast<AllocaInst>(Target).getAllocatedType();
  if (Matcher.getInstructionID() == Instruction::I_getelementptr)
    return *cast<GetElementPtrInst>(Target).getSourceElementType();
  return *Target.getType();
}

static bool matchTypeOnlyOperands(const Instruction &Matcher,
                                  const llvm::Instruction &Target,
                                  Instantiation &State) {
  const llvm::Type &TargetType = getTypeOnlyOperandTarget(Matcher, Target);

  for (const MatcherOperand &Operand : Matcher.getUnkeyedOperands()) {
    if (Operand.IsInstructionOperand)
      continue;
    assert(!Operand.Val && !Operand.IsArray &&
           "type-only operand contains a value");
    if (!Operand.Ty)
      continue;
    if (!matchType(*Operand.Ty, TargetType, State))
      return false;
  }
  return true;
}

static MatchResults matchOrSelf(const Instruction &Matcher,
                                ArrayRef<MatcherOperand> PatternOperands,
                                unsigned OperandIndex,
                                const llvm::Value &Target, Instantiation State,
                                const MatchDriver &Driver) {
  if (OperandIndex >= PatternOperands.size() ||
      PatternOperands[OperandIndex].IsArray)
    return {};
  assert(PatternOperands[OperandIndex].Val &&
         "':o' operand has no matcher value");

  MatchResults Results = Driver.match(*PatternOperands[OperandIndex].Val,
                                      Target, std::move(State));
  MatchResults BoundResults;
  for (Instantiation &Candidate : Results) {
    if (!bind(Candidate, Matcher, &Target))
      continue;
    if (Matcher.getCapture() &&
        (!isa<llvm::Instruction>(Target) ||
         !bind(Candidate, *Matcher.getCapture(), &Target)))
      continue;
    BoundResults.push_back(std::move(Candidate));
  }
  return BoundResults;
}

MatchResults matchInstruction(const Instruction &Matcher,
                              const llvm::Value &Target, Instantiation State,
                              const MatchDriver &Driver) {
  if (!matchUseFlags(Matcher.getMetaFlags(), Target))
    return {};

  SmallVector<MatcherOperand, 4> PatternOperands;
  for (const MatcherOperand &Operand : Matcher.getUnkeyedOperands())
    if (Operand.IsInstructionOperand) {
      assert((Operand.Val || Operand.IsArray) &&
             "value operand has neither a value nor an array capture");
      PatternOperands.push_back(Operand);
    }

  MatchResults Results;
  if (std::optional<unsigned> OperandIndex = getOrSelfOperand(Matcher))
    Results = matchOrSelf(Matcher, PatternOperands, *OperandIndex, Target,
                          State, Driver);

  const auto *TargetInstruction = dyn_cast<llvm::Instruction>(&Target);
  if (!TargetInstruction ||
      !matchInstructionTarget(Matcher.getInstructionID(), *TargetInstruction))
    return Results;

  if (!bind(State, Matcher, TargetInstruction) ||
      (Matcher.getParentBlock() != nullptr &&
       !bind(State, *Matcher.getParentBlock(),
             TargetInstruction->getParent())) ||
      !matchTypeOnlyOperands(Matcher, *TargetInstruction, State) ||
      !matchSemanticFlags(Matcher, *TargetInstruction, State) ||
      !matchKeyedOperands(Matcher, *TargetInstruction, State))
    return Results;

  if (Matcher.getCapture() &&
      !bind(State, *Matcher.getCapture(), TargetInstruction))
    return Results;

  SmallVector<const llvm::Value *, 4> Targets =
      getTargetOperands(*TargetInstruction);
  unsigned ArrayCount = count_if(
      PatternOperands, [](const MatcherOperand &Op) { return Op.IsArray; });
  assert(ArrayCount <= 1 && "instruction has multiple array captures");
  if ((!ArrayCount && PatternOperands.size() != Targets.size()) ||
      (ArrayCount && (!PatternOperands.back().IsArray ||
                      PatternOperands.size() - 1 > Targets.size())))
    return Results;

  SmallVector<unsigned, 4> NaturalOrder;
  for (unsigned Index = 0; Index != Targets.size(); ++Index)
    NaturalOrder.push_back(Index);
  MatchResults Natural =
      matchOperandOrder(PatternOperands, Targets, NaturalOrder, State, Driver);
  Results.append(std::make_move_iterator(Natural.begin()),
                 std::make_move_iterator(Natural.end()));

  if (hasMetaFlag(Matcher.getMetaFlags(), MetaFlag::MF_c)) {
    SmallVector<unsigned, 4> SwappedIndices = NaturalOrder;
    if (Matcher.getInstructionID() == Instruction::I_call &&
        SwappedIndices.size() == 3)
      std::swap(SwappedIndices[1], SwappedIndices[2]);
    else if (SwappedIndices.size() == 2)
      std::swap(SwappedIndices[0], SwappedIndices[1]);
    else
      report_fatal_error(
          Twine("commutative matcher '") + Matcher.getOpcodeName() +
          "' has unsupported operand count " + Twine(SwappedIndices.size()));
    MatchResults Swapped = matchOperandOrder(
        PatternOperands, Targets, SwappedIndices, std::move(State), Driver);
    Results.append(std::make_move_iterator(Swapped.begin()),
                   std::make_move_iterator(Swapped.end()));
  }
  return Results;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
