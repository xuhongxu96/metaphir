#include "metaphir/Matching/OpcodePredicates.h"
#include "metaphir/Matching/InstructionMatcher.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"

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

bool InstructionMatcher::matchInstructionTarget() {
  return matchesInstructionID(Matcher.getInstructionID(), *TargetInstruction);
}

} // namespace metaphir
} // namespace llvm
