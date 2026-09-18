#include "metaphir/Matching/InstructionMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Values.h"
#include "metaphir/Matching/MatchersDetail.h"
#include "metaphir/Matching/SubtreeMatcher.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>

namespace llvm {
namespace metaphir {

using detail::bind;
using detail::success;

namespace {

bool hasSemanticFlag(InstructionFlag::FlagID ID,
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

} // namespace

std::optional<APSInt> InstructionMatcher::getKeyedIntegerTarget(
    MatcherOperand::KeyedOperandKind Kind) {
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

SmallVector<const llvm::Value *, 4> InstructionMatcher::getTargetOperands() {
  SmallVector<const llvm::Value *, 4> Operands;
  switch (TargetInstruction->getOpcode()) {
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
    for (const llvm::Use &Operand : TargetInstruction->operands())
      Operands.push_back(Operand.get());
    llvm::Type *IndexType = llvm::Type::getInt64Ty(Target.getContext());
    ArrayRef<unsigned> Indices =
        TargetInstruction->getOpcode() == llvm::Instruction::ExtractValue
            ? cast<ExtractValueInst>(Target).getIndices()
            : cast<InsertValueInst>(Target).getIndices();
    for (unsigned Index : Indices)
      Operands.push_back(ConstantInt::get(IndexType, Index));
    return Operands;
  }
  default:
    for (const llvm::Use &Operand : TargetInstruction->operands())
      Operands.push_back(Operand.get());
    return Operands;
  }
}

std::optional<unsigned> InstructionMatcher::getOrSelfOperand() {
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

const llvm::Type &InstructionMatcher::getTypeOnlyOperandTarget() {
  if (Matcher.getInstructionID() == Instruction::I_alloca)
    return *cast<AllocaInst>(Target).getAllocatedType();
  if (Matcher.getInstructionID() == Instruction::I_getelementptr)
    return *cast<GetElementPtrInst>(Target).getSourceElementType();
  return *Target.getType();
}

bool InstructionMatcher::matchIntegerKeyedOperand(const MatcherOperand &Matcher,
                                                  const APSInt &Target) {
  assert(Matcher.Val && "keyed integer operand has no value");
  if (const auto *Variable = dyn_cast<MetaVariable>(Matcher.Val))
    return bind(State, *Variable, static_cast<const APInt &>(Target));
  const auto *Constant = dyn_cast<IntegerConstant>(Matcher.Val);
  assert(Constant && "keyed integer operand is not an integer matcher");
  return APSInt::isSameValue(Constant->getValue(), Target);
}

bool InstructionMatcher::matchPredicate() {
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

bool InstructionMatcher::matchKeyedOperands() {
  if (!matchPredicate())
    return false;

  for (unsigned Kind = MatcherOperand::Alignment;
       Kind != MatcherOperand::NumKeyedOperandKinds; ++Kind) {
    const auto Key = static_cast<MatcherOperand::KeyedOperandKind>(Kind);
    const MatcherOperand *Operand = Matcher.getKeyedOperand(Key);
    if (!Operand)
      continue;
    std::optional<APSInt> TargetValue = getKeyedIntegerTarget(Key);
    if (!TargetValue || !matchIntegerKeyedOperand(*Operand, *TargetValue))
      return false;
  }
  return true;
}

bool InstructionMatcher::matchSemanticFlags() {
  Instruction::FlagMask Supported =
      Instruction::getSupportedFlags(Matcher.getInstructionID());
  for (unsigned ID = 0; ID != InstructionFlag::NumFlagIDs; ++ID) {
    auto FlagID = static_cast<InstructionFlag::FlagID>(ID);
    if (!(Supported & Instruction::mask(FlagID)))
      continue;

    const InstructionFlag *Flag = nullptr;
    for (const InstructionFlag &Candidate : Matcher.getFlags()) {
      if (Candidate.ID == FlagID) {
        Flag = &Candidate;
        break;
      }
    }

    bool Present = hasSemanticFlag(FlagID, *TargetInstruction);
    if (!Flag) {
      // An omitted supported flag is an assertion that the target does not
      // have it. Captures remain the way to explicitly accept either value.
      if (Present)
        return false;
    } else if (Flag->Capture) {
      if (!bind(State, *Flag->Capture, Present))
        return false;
    } else if (!Present) {
      return false;
    }
  }
  return true;
}

MatchResults
InstructionMatcher::matchValueOperand(const MatcherOperand &Matcher,
                                      const llvm::Value &Target,
                                      Instantiation State) {
  assert(Matcher.IsInstructionOperand && "expected a value operand");
  if (Matcher.IsArray)
    return {};
  assert(Matcher.Val && "matcher operand has no value");
  if (Matcher.Ty && !TypeMatcher(*Matcher.Ty, *Target.getType(), State,
                                 Settings.has(PatternSettings::treatIntAsVec))
                         .match())
    return {};

  assert(Matcher.MetaFlags.empty() &&
         "operand meta flag reached matching without being lowered");

  // Under treatIntAsVec, a scalar integer constant also matches a vector splat
  // constant whose element equals it (e.g. 0 matches zeroinitializer).
  if (Settings.has(PatternSettings::treatIntAsVec)) {
    if (const auto *IC = dyn_cast<IntegerConstant>(Matcher.Val)) {
      if (const auto *CV = dyn_cast<llvm::Constant>(&Target))
        if (CV->getType()->isVectorTy())
          if (const auto *Splat = CV->getSplatValue())
            if (const auto *CI = dyn_cast<ConstantInt>(Splat)) {
              APSInt TargetValue(CI->getValue(), IC->getValue().isUnsigned());
              if (APSInt::isSameValue(IC->getValue(), TargetValue))
                return success(std::move(State));
            }
    }
  }
  return SubtreeMatcher(*Matcher.Val, Target, std::move(State)).match();
}

MatchResults InstructionMatcher::matchOperandOrder(ArrayRef<unsigned> Order,
                                                   Instantiation State) {
  assert(TargetOperands.size() == Order.size() &&
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
      for (unsigned TargetIndex = Index; TargetIndex != TargetOperands.size();
           ++TargetIndex) {
        assert(Order[TargetIndex] < TargetOperands.size() &&
               "operand index is out of range");
        const llvm::Value *Target = TargetOperands[Order[TargetIndex]];
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
      assert(Order[Index] < TargetOperands.size() &&
             "operand index is out of range");
      MatchResults Matches = matchValueOperand(
          Operand, *TargetOperands[Order[Index]], std::move(Candidate));
      Next.append(std::make_move_iterator(Matches.begin()),
                  std::make_move_iterator(Matches.end()));
    }
    States = std::move(Next);
    if (States.empty())
      break;
  }
  return States;
}

bool InstructionMatcher::matchTypeOnlyOperands() {
  const llvm::Type &TargetType = getTypeOnlyOperandTarget();

  for (const MatcherOperand &Operand : Matcher.getUnkeyedOperands()) {
    if (Operand.IsInstructionOperand)
      continue;
    assert(!Operand.Val && !Operand.IsArray &&
           "type-only operand contains a value");
    if (!Operand.Ty)
      continue;
    if (!TypeMatcher(*Operand.Ty, TargetType, State,
                     Settings.has(PatternSettings::treatIntAsVec))
             .match())
      return false;
  }
  return true;
}

MatchResults InstructionMatcher::matchOrSelf(unsigned OperandIndex) {
  if (OperandIndex >= PatternOperands.size() ||
      PatternOperands[OperandIndex].IsArray)
    return {};
  const Value *OrSelfValue = Matcher.getOrSelfValue();
  if (!OrSelfValue) {
    assert(PatternOperands[OperandIndex].Val &&
           "':o' operand has no matcher value");
    OrSelfValue = PatternOperands[OperandIndex].Val;
  }

  MatchResults Results =
      SubtreeMatcher(*OrSelfValue, Target, State).match();
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

MatchResults InstructionMatcher::match() {
  PatternOperands.clear();
  TargetInstruction = nullptr;
  TargetOperands.clear();

  for (const MatcherOperand &Operand : Matcher.getUnkeyedOperands())
    if (Operand.IsInstructionOperand) {
      assert((Operand.Val || Operand.IsArray) &&
             "value operand has neither a value nor an array capture");
      PatternOperands.push_back(Operand);
    }

  MatchResults Results;
  if (std::optional<unsigned> OperandIndex = getOrSelfOperand())
    Results = matchOrSelf(*OperandIndex);

  TargetInstruction = dyn_cast<llvm::Instruction>(&Target);
  if (!TargetInstruction || !matchInstructionTarget())
    return Results;

  if (!bind(State, Matcher, TargetInstruction) ||
      (Matcher.getParentBlock() != nullptr &&
       !bind(State, *Matcher.getParentBlock(),
             TargetInstruction->getParent())) ||
      !matchTypeOnlyOperands() || !matchSemanticFlags() ||
      !matchKeyedOperands())
    return Results;

  if (Matcher.getCapture() &&
      !bind(State, *Matcher.getCapture(), TargetInstruction))
    return Results;

  TargetOperands = getTargetOperands();

  unsigned ArrayCount = count_if(
      PatternOperands, [](const MatcherOperand &Op) { return Op.IsArray; });
  assert(ArrayCount <= 1 && "instruction has multiple array captures");
  if ((!ArrayCount && PatternOperands.size() != TargetOperands.size()) ||
      (ArrayCount && (!PatternOperands.back().IsArray ||
                      PatternOperands.size() - 1 > TargetOperands.size())))
    return Results;

  SmallVector<unsigned, 4> NaturalOrder;
  for (unsigned Index = 0; Index != TargetOperands.size(); ++Index)
    NaturalOrder.push_back(Index);

  bool HasCommutativeFlag = Matcher.hasMetaFlag(MetaFlag::MF_c);

  MatchResults Natural =
      HasCommutativeFlag ? matchOperandOrder(NaturalOrder, State)
                         : matchOperandOrder(NaturalOrder, std::move(State));
  Results.append(std::make_move_iterator(Natural.begin()),
                 std::make_move_iterator(Natural.end()));

  if (HasCommutativeFlag) {
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

    MatchResults Swapped = matchOperandOrder(SwappedIndices, std::move(State));
    Results.append(std::make_move_iterator(Swapped.begin()),
                   std::make_move_iterator(Swapped.end()));
  }
  return Results;
}

} // namespace metaphir
} // namespace llvm
