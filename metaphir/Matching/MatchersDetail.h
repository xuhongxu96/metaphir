#ifndef METAPHIR_MATCHING_MATCHERS_DETAIL_H
#define METAPHIR_MATCHING_MATCHERS_DETAIL_H

#include "metaphir/Matching/Instantiation.h"
#include <optional>

namespace llvm {
namespace metaphir {

class Value;

namespace detail {

MatchResults success(Instantiation State);

bool bind(Instantiation &State, const Value &Matcher,
          Instantiation::Binding Target);

/// The integer a constant contributes: a scalar integer constant, or the
/// repeated element of a vector splat. Poison lanes are ignored, like LLVM's
/// m_APInt.
std::optional<APInt> getConstantInteger(const llvm::Value &V);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif
