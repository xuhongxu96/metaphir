#ifndef METAPHIR_MATCHING_TARGET_H
#define METAPHIR_MATCHING_TARGET_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Function;
class Instruction;
namespace metaphir {

class Target {
public:
  explicit Target(const Function &Function);

  ArrayRef<const llvm::Instruction *> getInstructions() const {
    return Instructions;
  }

private:
  SmallVector<const llvm::Instruction *, 16> Instructions;
};

} // namespace metaphir
} // namespace llvm

#endif
