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
  /// Known, when given, are the function's features; they must outlive the
  /// target.
  explicit Target(const Function &Function,
                  const FunctionFeatures *Known = nullptr);

  ArrayRef<const llvm::Instruction *> getInstructions() const {
    return Instructions;
  }

  /// The function's features, computed on first use unless known.
  const FunctionFeatures &getFeatures() const;

private:
  const Function &F;
  const FunctionFeatures *Known;
  SmallVector<const llvm::Instruction *, 16> Instructions;
  mutable std::optional<FunctionFeatures> Features;
};

} // namespace metaphir
} // namespace llvm

#endif
