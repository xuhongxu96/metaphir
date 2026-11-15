#ifndef METAPHIR_IR_CONSTANTS_H
#define METAPHIR_IR_CONSTANTS_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

/// The keyword constants ('null', 'poison', ...) and comparison predicates,
/// from KeywordConstants.def.
namespace keyword_constant {
enum KeywordID {
#define MIR_KEYWORD_CONSTANT(ID, Spelling) K_##ID,
#include "metaphir/IR/KeywordConstants.def"
};

StringRef getKeywordName(KeywordID ID);
} // namespace keyword_constant

/// How an aggregate constant is delimited: an array ('[...]'), a struct
/// ('{...}') or a vector ('<...>').
namespace aggregate_constant {
enum Delimiter { Square, Brace, Angle };
} // namespace aggregate_constant

} // namespace metaphir
} // namespace llvm

#endif
