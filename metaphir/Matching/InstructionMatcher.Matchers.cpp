#include "metaphir/Matching/InstructionMatcher.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"

namespace llvm {
namespace metaphir {

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

bool InstructionMatcher::matchInstructionTarget() {
  switch (Matcher.getInstructionID()) {
#define MIR_INSTRUCTION_MATCHER_TARGET(Name, TargetMatcher)                    \
  case Instruction::I_##Name:                                                  \
    return TargetMatcher(*TargetInstruction);
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction matcher ID");
}

} // namespace metaphir
} // namespace llvm
