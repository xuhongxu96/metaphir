#ifndef METAPHIR_PARSER_KEYWORD_RANGE_H
#define METAPHIR_PARSER_KEYWORD_RANGE_H

#include "metaphir/Parser/MIRToken.h"
#include <optional>

namespace llvm {
namespace metaphir {
namespace tok {

/// The keyword tokens of one table: consecutive token kinds, in the order of
/// the table's IDs.
struct KeywordRange {
  Kind First;
  Kind Last;
};

/// The ID of the keyword K in the table whose keywords are Range, if it is
/// one. Offset is the number of IDs before the table's first.
template <class ID>
constexpr std::optional<ID> getKeywordID(Kind K, KeywordRange Range,
                                         unsigned Offset = 0) {
  if (K < Range.First || K > Range.Last)
    return std::nullopt;
  return ID(K - Range.First + Offset);
}

} // namespace tok
} // namespace metaphir
} // namespace llvm

#endif
