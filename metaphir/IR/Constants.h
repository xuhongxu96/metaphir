#ifndef METAPHIR_IR_CONSTANTS_H
#define METAPHIR_IR_CONSTANTS_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

/// The keyword constants ('null', 'poison', ...) and comparison predicates,
/// from KeywordConstants.def.
struct KeywordConstant {
  enum KeywordID {
#define MIR_KEYWORD_CONSTANT(ID, Spelling) K_##ID,
#include "metaphir/IR/KeywordConstants.def"
  };

  static StringRef getKeywordName(KeywordID ID);

  KeywordConstant() = delete;
};

/// How an aggregate constant is delimited: an array ('[...]'), a struct
/// ('{...}') or a vector ('<...>').
struct AggregateConstant {
  enum Delimiter { Square, Brace, Angle };

  AggregateConstant() = delete;
};

} // namespace metaphir
} // namespace llvm

#endif
