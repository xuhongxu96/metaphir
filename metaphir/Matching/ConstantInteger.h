#ifndef METAPHIR_MATCHING_CONSTANTINTEGER_H
#define METAPHIR_MATCHING_CONSTANTINTEGER_H

#include "llvm/ADT/APInt.h"
#include <optional>

namespace llvm {
class Value;
namespace metaphir {

/// The integer an LLVM constant contributes: a scalar integer constant, or
/// the repeated element of a vector splat. Poison lanes are ignored, like
/// LLVM's m_APInt.
std::optional<APInt> getConstantInteger(const llvm::Value &V);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTANTINTEGER_H
