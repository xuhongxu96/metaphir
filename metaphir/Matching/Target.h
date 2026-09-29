#ifndef METAPHIR_MATCHING_TARGET_H
#define METAPHIR_MATCHING_TARGET_H

#include "metaphir/Matching/Features.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include <optional>

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

  /// The function's features, computed on first use.
  const FunctionFeatures &getFeatures() const;

private:
  const Function &F;
  SmallVector<const llvm::Instruction *, 16> Instructions;
  mutable std::optional<FunctionFeatures> Features;
};

} // namespace metaphir
} // namespace llvm

#endif
