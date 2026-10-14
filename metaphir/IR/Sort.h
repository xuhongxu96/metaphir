#ifndef METAPHIR_IR_SORT_H
#define METAPHIR_IR_SORT_H

#include "llvm/ADT/StringRef.h"
#include <optional>

namespace llvm {

class raw_ostream;

namespace metaphir {

/// The sort of a meta variable or a constraint expression (see Sorts.def).
enum class Sort {
#define MIR_SORT(ID, Name, Representation) ID,
#include "metaphir/IR/Sorts.def"
};

StringRef getSortName(Sort S);
raw_ostream &operator<<(raw_ostream &OS, Sort S);

/// Whether Sub lies below Super in the sort order. Unknown is the top.
bool isSubsort(Sort Sub, Sort Super);
/// The greatest lower bound of A and B, or none when they have no common
/// subsort.
std::optional<Sort> meetSorts(Sort A, Sort B);
/// The sort of the runtime value that represents S in a constraint.
Sort getRepresentation(Sort S);
/// The sort a meta variable denotes once inference is done: an Operand-only
/// meta variable denotes a Value.
inline Sort resolveSort(Sort S) { return S == Sort::Operand ? Sort::Value : S; }

} // namespace metaphir
} // namespace llvm
#endif
