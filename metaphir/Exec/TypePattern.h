//===- TypePattern.h - Type patterns of plans and index queries -*- C++ -*-===//
//
// The type patterns mpir_plan.check_type and mpir_index.typing encode (see
// Pattern/Bindings.h), decoded into trees, and matched against LLVM types.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_TYPEPATTERN_H
#define METAPHIR_EXEC_TYPEPATTERN_H

#include "metaphir/Dialect/Pattern/Bindings.h"
#include "metaphir/Matching/Binding.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include <vector>

namespace llvm {
class Type;
namespace metaphir {

class TypePatterns {
public:
  struct Node {
    mpir::TypePatternKind Kind;
    int64_t A = 0, B = 0, C = 0;
    SmallVector<unsigned, 2> Children;
  };

  /// Decodes Pattern, returning the index of its root.
  unsigned add(mlir::ArrayAttr Pattern);

  /// Unifies a type variable (a slot) with a binding: binds it if it is
  /// unbound, and otherwise tells whether its binding is that one.
  using UnifyFn = function_ref<bool(unsigned Slot, const Binding &)>;

  /// Whether the pattern at Index matches Target, binding its variables.
  bool match(unsigned Index, const llvm::Type &Target, bool TreatIntAsVec,
             UnifyFn Unify) const;

private:
  std::vector<Node> Nodes;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_TYPEPATTERN_H
