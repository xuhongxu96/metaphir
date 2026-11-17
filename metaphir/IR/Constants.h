#ifndef METAPHIR_IR_CONSTANTS_H
#define METAPHIR_IR_CONSTANTS_H

#include "metaphir/IR/Constants.inc"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

/// The keyword constants ('null', 'poison', ...) and comparison predicates,
/// generated from KeywordConstants.td (Constants.inc); this reads it.
namespace keyword_constant {

/// The spellings of every keyword constant, in the order of KeywordID.
inline ArrayRef<StringRef> getKeywordNames() { return Spellings; }

inline StringRef getKeywordName(KeywordID ID) { return Spellings[ID]; }

} // namespace keyword_constant

namespace aggregate_constant {

/// How the mpir dialect spells each kind, in the order of Delimiter.
inline ArrayRef<StringRef> getNames() { return Names; }

} // namespace aggregate_constant

} // namespace metaphir
} // namespace llvm

#endif
