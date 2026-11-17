#include "metaphir/IR/Sort.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

raw_ostream &operator<<(raw_ostream &OS, Sort S) {
  return OS << getSortName(S);
}

std::optional<Sort> meetSorts(Sort A, Sort B) {
  // The lower bounds of A and B; the meet is the one above all the others.
  std::optional<Sort> Meet;
  for (unsigned I = 0; I != NumSorts; ++I) {
    Sort C = Sort(I);
    if (!isSubsort(C, A) || !isSubsort(C, B))
      continue;
    if (!Meet || isSubsort(*Meet, C))
      Meet = C;
  }
  if (!Meet)
    return std::nullopt;
  for (unsigned I = 0; I != NumSorts; ++I) {
    Sort C = Sort(I);
    if (isSubsort(C, A) && isSubsort(C, B) && !isSubsort(C, *Meet))
      return std::nullopt;
  }
  return Meet;
}

} // namespace metaphir
} // namespace llvm
