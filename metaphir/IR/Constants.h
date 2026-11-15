#ifndef METAPHIR_IR_CONSTANTS_H
#define METAPHIR_IR_CONSTANTS_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

/// The keyword constants ('null', 'poison', ...) and comparison predicates,
/// from KeywordConstants.def.
namespace KeywordConstant {
enum KeywordID {
#define MIR_KEYWORD_CONSTANT(ID, Spelling) K_##ID,
#include "metaphir/IR/KeywordConstants.def"
};

StringRef getKeywordName(KeywordID ID);
} // namespace KeywordConstant

/// How an aggregate constant is delimited: an array ('[...]'), a struct
/// ('{...}') or a vector ('<...>').
namespace AggregateConstant {
enum Delimiter { Square, Brace, Angle };
} // namespace AggregateConstant

} // namespace metaphir
} // namespace llvm

#endif
