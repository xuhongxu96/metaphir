#include "metaphir/Matching/Target.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"

namespace llvm {
namespace metaphir {

Target::Target(const Function &Function) {
  for (const BasicBlock &Block : Function)
    for (const llvm::Instruction &Instruction : Block)
      Instructions.push_back(&Instruction);
}

} // namespace metaphir
} // namespace llvm
