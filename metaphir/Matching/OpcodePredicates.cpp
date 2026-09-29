#include "metaphir/Matching/OpcodePredicates.h"
#include "metaphir/Matching/InstructionMatcher.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace llvm {
namespace metaphir {

template <unsigned Opcode>
static bool matchOpcode(const llvm::Instruction &Target) {
  return Target.getOpcode() == Opcode;
}

static bool matchBranch(const llvm::Instruction &Target) {
  return isa<CondBrInst, UncondBrInst>(Target);
}

bool matchesInstructionID(Instruction::InstructionID ID,
                          const llvm::Instruction &Target) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_TARGET(Name, TargetMatcher)                    \
  case Instruction::I_##Name:                                                  \
    return TargetMatcher(Target);
#include "metaphir/IR/InstructionMatchers.def"
  case Instruction::NumInstructionIDs:
    break;
  }
  llvm_unreachable("invalid instruction matcher ID");
}

bool hasSemanticFlag(InstructionFlag::FlagID ID,
                     const llvm::Instruction &Target) {
  switch (ID) {
  case InstructionFlag::F_nsw:
    return Target.hasNoSignedWrap();
  case InstructionFlag::F_nuw:
    if (const auto *GEP = dyn_cast<GEPOperator>(&Target))
      return GEP->hasNoUnsignedWrap();
    return Target.hasNoUnsignedWrap();
  // A flag the instruction cannot carry is absent. (The supported flags of
  // each matcher are declared in InstructionMatchers.def.)
  case InstructionFlag::F_exact:
    if (const auto *Exact = dyn_cast<PossiblyExactOperator>(&Target))
      return Exact->isExact();
    return false;
  case InstructionFlag::F_disjoint:
    if (const auto *Disjoint = dyn_cast<PossiblyDisjointInst>(&Target))
      return Disjoint->isDisjoint();
    return false;
  case InstructionFlag::F_inalloca:
    if (const auto *Alloca = dyn_cast<AllocaInst>(&Target))
      return Alloca->isUsedWithInAlloca();
    return false;
  case InstructionFlag::F_volatile:
    if (const auto *Load = dyn_cast<LoadInst>(&Target))
      return Load->isVolatile();
    if (const auto *Store = dyn_cast<StoreInst>(&Target))
      return Store->isVolatile();
    return false;
  case InstructionFlag::F_inbounds:
    if (const auto *GEP = dyn_cast<GetElementPtrInst>(&Target))
      return GEP->isInBounds();
    return false;
  case InstructionFlag::F_nusw:
    if (const auto *GEP = dyn_cast<GetElementPtrInst>(&Target))
      return GEP->hasNoUnsignedSignedWrap();
    return false;
  case InstructionFlag::F_nneg:
    return Target.hasNonNeg();
  case InstructionFlag::F_samesign:
    if (const auto *Compare = dyn_cast<ICmpInst>(&Target))
      return Compare->hasSameSign();
    return false;
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

void collectMatcherOperands(const llvm::Instruction &Target,
                            SmallVectorImpl<const llvm::Value *> &Operands) {
  Operands.clear();
  switch (Target.getOpcode()) {
  case llvm::Instruction::CondBr: {
    const auto &Branch = cast<CondBrInst>(Target);
    Operands.push_back(Branch.getCondition());
    Operands.push_back(Branch.getSuccessor(0));
    Operands.push_back(Branch.getSuccessor(1));
    return;
  }
  case llvm::Instruction::UncondBr:
    Operands.push_back(cast<UncondBrInst>(Target).getSuccessor(0));
    return;
  case llvm::Instruction::Call: {
    const auto &Call = cast<CallBase>(Target);
    Operands.push_back(Call.getCalledOperand());
    for (const llvm::Use &Argument : Call.args())
      Operands.push_back(Argument.get());
    return;
  }
  case llvm::Instruction::PHI: {
    const auto &Phi = cast<PHINode>(Target);
    for (unsigned Index = 0; Index != Phi.getNumIncomingValues(); ++Index) {
      Operands.push_back(Phi.getIncomingValue(Index));
      Operands.push_back(Phi.getIncomingBlock(Index));
    }
    return;
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
    return;
  }
  default:
    for (const llvm::Use &Operand : Target.operands())
      Operands.push_back(Operand.get());
    return;
  }
}

bool InstructionMatcher::matchInstructionTarget() {
  return matchesInstructionID(Matcher.getInstructionID(), *TargetInstruction);
}

} // namespace metaphir
} // namespace llvm
