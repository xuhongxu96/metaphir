#include "metaphir/Matching/FeatureRequirement.h"
#include "metaphir/Matching/TypeCode.h"
#include "llvm/ADT/STLExtras.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

bool ShapeRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  Signature First;
  First.ID = ID;
  for (auto It = llvm::lower_bound(
           Features.Signatures, First,
           [](const Signature &L, const Signature &R) { return L.ID < R.ID; });
       It != Features.Signatures.end() && It->ID == ID; ++It)
    if ((It->Flags & Present) == Present && (It->Flags & Absent) == 0 &&
        (!Width || getIntegerElementWidth(It->Result) == Width))
      return true;
  return false;
}

/// Whether some slot of S has fact A.
static bool hasSiteFact(const FunctionFeatures &Features, const Site &S,
                        Atom A) {
  for (unsigned Slots = S.Slots; Slots; Slots &= Slots - 1)
    if (Features.hasFact(S.ID, llvm::countr_zero(Slots), A))
      return true;
  return false;
}

bool FeatureRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  if ((Instructions & ~Features.Instructions) != 0)
    return false;
  for (auto [User, Operand] : Edges)
    if (!Features.mayHaveEdge(User, Operand))
      return false;
  for (uint16_t Sibling : Siblings)
    if (!std::binary_search(Features.Siblings.begin(), Features.Siblings.end(),
                            Sibling))
      return false;
  if (!all_of(Globals, [&](uint64_t Hash) { return Features.hasGlobal(Hash); }))
    return false;
  if (!Features.Fine)
    return true;
  for (const ShapeRequirement &Shape : Shapes)
    if (!Shape.isSatisfiedBy(Features))
      return false;
  for (const auto &[S, A] : SiteFacts)
    if (!hasSiteFact(Features, S, A))
      return false;
  return true;
}

} // namespace metaphir
} // namespace llvm
