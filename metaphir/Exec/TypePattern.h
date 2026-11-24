//===- TypePattern.h - Type patterns of plans and index queries -*- C++ -*-===//
//
// The type patterns of mpir_plan.check_type and mpir_index.typing, matched
// against LLVM types.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_TYPEPATTERN_H
#define METAPHIR_EXEC_TYPEPATTERN_H

#include "metaphir/Dialect/Pattern/Bindings.h"
#include "metaphir/Matching/Binding.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include <vector>

namespace llvm {
class Type;
namespace metaphir {

/// The type patterns of a plan or an index query, numbered as they are added.
class TypePatterns {
public:
  /// Adds Pattern, returning its number.
  unsigned add(mpir::TypePatternAttr Pattern) {
    Patterns.push_back(Pattern);
    return Patterns.size() - 1;
  }

  /// Unifies a type variable (a slot) with a binding: binds it if it is
  /// unbound, and otherwise tells whether its binding is that one.
  using UnifyFn = function_ref<bool(unsigned Slot, const Binding &)>;

  /// Whether the pattern numbered Index matches Target, binding its
  /// variables.
  bool match(unsigned Index, const llvm::Type &Target, bool TreatIntAsVec,
             UnifyFn Unify) const;

private:
  std::vector<mpir::TypePatternAttr> Patterns;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_TYPEPATTERN_H
