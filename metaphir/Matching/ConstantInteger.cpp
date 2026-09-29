#include "metaphir/Matching/ConstantInteger.h"
#include "llvm/IR/Constants.h"

namespace llvm {
namespace metaphir {

std::optional<APInt> getConstantInteger(const llvm::Value &V) {
  if (const auto *Integer = dyn_cast<ConstantInt>(&V))
    return Integer->getValue();
  if (const auto *Constant = dyn_cast<llvm::Constant>(&V))
    if (Constant->getType()->isVectorTy())
      if (const auto *Splat = dyn_cast_or_null<ConstantInt>(
              Constant->getSplatValue(/*AllowPoison=*/true)))
        return Splat->getValue();
  return std::nullopt;
}

} // namespace metaphir
} // namespace llvm
