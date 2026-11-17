#ifndef METAPHIR_EXEC_KEYWORD_CONSTANT_MATCH_H
#define METAPHIR_EXEC_KEYWORD_CONSTANT_MATCH_H

#include "metaphir/Exec/KeywordConstantMatch.inc"
#include "metaphir/IR/Constants.h"
#include <iterator>

namespace llvm {
namespace metaphir {
namespace keyword_constant {

/// Whether V is the constant ID names; false for a predicate.
inline bool matches(KeywordID ID, const llvm::Value &V) {
  return ID < std::size(ConstantChecks) && ConstantChecks[ID](V);
}

} // namespace keyword_constant
} // namespace metaphir
} // namespace llvm

#endif
