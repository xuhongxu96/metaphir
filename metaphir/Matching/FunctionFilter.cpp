#include "metaphir/Matching/FunctionFilter.h"

namespace llvm {
namespace metaphir {

FunctionFilter::~FunctionFilter() = default;

bool FunctionFilter::mayMatch(const FunctionFeatures &Features) const {
  for (unsigned Index = 0; Index != size(); ++Index)
    if (mayMatchVariant(Index, Features))
      return true;
  return false;
}

} // namespace metaphir
} // namespace llvm
