#ifndef METAPHIR_IR_SORT_H
#define METAPHIR_IR_SORT_H

#include "metaphir/IR/Sort.inc"
#include <optional>

namespace llvm {

class raw_ostream;

namespace metaphir {

raw_ostream &operator<<(raw_ostream &OS, Sort S);

/// The name printed for a sort.
inline StringRef getSortName(Sort S) { return SortInfos[unsigned(S)].Name; }

/// A sort's keyword in the mpir dialect.
inline StringRef getSortKeyword(Sort S) {
  return SortInfos[unsigned(S)].Keyword;
}

/// The sort of the runtime value that represents S in a constraint.
inline Sort getRepresentation(Sort S) {
  return SortInfos[unsigned(S)].Representation;
}

/// The sort whose keyword is Keyword, if any.
inline std::optional<Sort> getSortFromKeyword(StringRef Keyword) {
  for (unsigned I = 0; I != NumSorts; ++I)
    if (SortInfos[I].Keyword == Keyword)
      return Sort(I);
  return std::nullopt;
}

/// Whether Sub lies below Super in the sort order. Unknown is the top.
inline bool isSubsort(Sort Sub, Sort Super) {
  return SubsortRows[unsigned(Sub)] >> unsigned(Super) & 1;
}

/// The greatest lower bound of A and B, or none when they have no common
/// subsort.
std::optional<Sort> meetSorts(Sort A, Sort B);
/// The sort a meta variable denotes once inference is done: an Operand-only
/// meta variable denotes a Value.
inline Sort resolveSort(Sort S) { return S == Sort::Operand ? Sort::Value : S; }

} // namespace metaphir
} // namespace llvm
#endif
