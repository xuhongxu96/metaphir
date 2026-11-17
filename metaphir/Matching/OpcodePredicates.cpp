#include "metaphir/Matching/OpcodePredicates.h"
#include "metaphir/Matching/OpcodeMatchers.inc"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace llvm {
namespace metaphir {

bool matchesInstructionID(instruction::InstructionID ID,
                          const llvm::Instruction &Target) {
  const instruction::InstructionTarget &T = instruction::Targets[ID];
  return T.Check ? T.Check(Target) : Target.getOpcode() == T.Opcode;
}

bool hasSemanticFlag(instruction_flag::FlagID ID,
                     const llvm::Instruction &Target) {
  switch (ID) {
  case instruction_flag::F_nsw:
    return Target.hasNoSignedWrap();
  case instruction_flag::F_nuw:
    if (const auto *GEP = dyn_cast<GEPOperator>(&Target))
      return GEP->hasNoUnsignedWrap();
    return Target.hasNoUnsignedWrap();
  // A flag the instruction cannot carry is absent. (The supported flags of
  // each matcher are declared in InstructionMatchers.td.)
  case instruction_flag::F_exact:
    if (const auto *Exact = dyn_cast<PossiblyExactOperator>(&Target))
      return Exact->isExact();
    return false;
  case instruction_flag::F_disjoint:
    if (const auto *Disjoint = dyn_cast<PossiblyDisjointInst>(&Target))
      return Disjoint->isDisjoint();
    return false;
  case instruction_flag::F_inalloca:
    if (const auto *Alloca = dyn_cast<AllocaInst>(&Target))
      return Alloca->isUsedWithInAlloca();
    return false;
  case instruction_flag::F_volatile:
    if (const auto *Load = dyn_cast<LoadInst>(&Target))
      return Load->isVolatile();
    if (const auto *Store = dyn_cast<StoreInst>(&Target))
      return Store->isVolatile();
    return false;
  case instruction_flag::F_inbounds:
    if (const auto *GEP = dyn_cast<GetElementPtrInst>(&Target))
      return GEP->isInBounds();
    return false;
  case instruction_flag::F_nusw:
    if (const auto *GEP = dyn_cast<GetElementPtrInst>(&Target))
      return GEP->hasNoUnsignedSignedWrap();
    return false;
  case instruction_flag::F_nneg:
    return Target.hasNonNeg();
  case instruction_flag::F_samesign:
    if (const auto *Compare = dyn_cast<ICmpInst>(&Target))
      return Compare->hasSameSign();
    return false;
  case instruction_flag::F_fast:
  case instruction_flag::F_nnan:
  case instruction_flag::F_ninf:
  case instruction_flag::F_nsz:
  case instruction_flag::F_arcp:
  case instruction_flag::F_contract:
  case instruction_flag::F_afn:
  case instruction_flag::F_reassoc: {
    FastMathFlags Flags = Target.getFastMathFlagsOrNone();
    switch (ID) {
    case instruction_flag::F_fast:
      return Flags.isFast();
    case instruction_flag::F_nnan:
      return Flags.noNaNs();
    case instruction_flag::F_ninf:
      return Flags.noInfs();
    case instruction_flag::F_nsz:
      return Flags.noSignedZeros();
    case instruction_flag::F_arcp:
      return Flags.allowReciprocal();
    case instruction_flag::F_contract:
      return Flags.allowContract();
    case instruction_flag::F_afn:
      return Flags.approxFunc();
    case instruction_flag::F_reassoc:
      return Flags.allowReassoc();
    default:
      llvm_unreachable("not a fast-math flag");
    }
  }
  case instruction_flag::NumFlagIDs:
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
  case llvm::Instruction::ShuffleVector: {
    // The mask is not an operand; it is matched as the constant vector of
    // i32 the IR prints (poison for an undefined element).
    const auto &Shuffle = cast<ShuffleVectorInst>(Target);
    Operands.push_back(Shuffle.getOperand(0));
    Operands.push_back(Shuffle.getOperand(1));
    Operands.push_back(Shuffle.getShuffleMaskForBitcode());
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

} // namespace metaphir
} // namespace llvm
