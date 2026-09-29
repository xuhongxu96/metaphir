#include "metaphir/Matching/Target.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"

namespace llvm {
namespace metaphir {

Target::Target(const Function &Function, const FunctionFeatures *Known)
    : F(Function), Known(Known) {
  for (const BasicBlock &Block : Function)
    for (const llvm::Instruction &Instruction : Block)
      Instructions.push_back(&Instruction);
}

const FunctionFeatures &Target::getFeatures() const {
  if (Known)
    return *Known;
  if (!Features)
    Features = FunctionFeatures::compute(F);
  return *Features;
}

} // namespace metaphir
} // namespace llvm
