#include "metaphir/Matching/OpcodePredicates.h"
#include "metaphir/Matching/InstructionMatcher.h"
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

bool InstructionMatcher::matchInstructionTarget() {
  return matchesInstructionID(Matcher.getInstructionID(), *TargetInstruction);
}

} // namespace metaphir
} // namespace llvm
