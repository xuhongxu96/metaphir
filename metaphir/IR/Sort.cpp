#include "metaphir/IR/Sort.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <array>

namespace llvm {
namespace metaphir {

namespace {
constexpr unsigned NumSorts = 0
#define MIR_SORT(ID, Name, Representation) +1
#include "metaphir/IR/Sorts.def"
    ;

using SortMatrix = std::array<std::array<bool, NumSorts>, NumSorts>;

// The reflexive-transitive closure of the MIR_SUBSORT edges, with Unknown
// above every sort.
const SortMatrix &subsortMatrix() {
  static const SortMatrix Matrix = [] {
    SortMatrix M{};
    for (unsigned I = 0; I != NumSorts; ++I) {
      M[I][I] = true;
      M[I][unsigned(Sort::Unknown)] = true;
    }
#define MIR_SUBSORT(Sub, Super)                                                \
  M[unsigned(Sort::Sub)][unsigned(Sort::Super)] = true;
#include "metaphir/IR/Sorts.def"
    for (unsigned K = 0; K != NumSorts; ++K)
      for (unsigned I = 0; I != NumSorts; ++I)
        if (M[I][K])
          for (unsigned J = 0; J != NumSorts; ++J)
            if (M[K][J])
              M[I][J] = true;
    return M;
  }();
  return Matrix;
}
} // namespace

StringRef getSortName(Sort S) {
  switch (S) {
#define MIR_SORT(ID, Name, Representation)                                     \
  case Sort::ID:                                                               \
    return Name;
#include "metaphir/IR/Sorts.def"
  }
  llvm_unreachable("invalid sort");
}

raw_ostream &operator<<(raw_ostream &OS, Sort S) {
  return OS << getSortName(S);
}

bool isSubsort(Sort Sub, Sort Super) {
  return subsortMatrix()[unsigned(Sub)][unsigned(Super)];
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

Sort getRepresentation(Sort S) {
  switch (S) {
#define MIR_SORT(ID, Name, Representation)                                     \
  case Sort::ID:                                                               \
    return Sort::Representation;
#include "metaphir/IR/Sorts.def"
  }
  llvm_unreachable("invalid sort");
}

} // namespace metaphir
} // namespace llvm
