//===- TypePattern.h - Type patterns of plans and index queries -*- C++ -*-===//
//
// The type patterns of mpir_plan.check_type and mpir_index.typing, matched
// against LLVM types.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_TYPEPATTERN_H
#define METAPHIR_EXEC_TYPEPATTERN_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Matching/Binding.h"
#include "llvm/ADT/STLFunctionalExtras.h"

namespace llvm {
class Type;
namespace metaphir {

/// Unifies a type variable (a slot) with a binding: binds it if it is
/// unbound, and otherwise tells whether its binding is that one.
using UnifyFn = function_ref<bool(unsigned Slot, const Binding &)>;

/// Whether Pattern matches Target, binding its variables with Unify.
bool matchTypePattern(mpir::TypePatternAttr Pattern, const llvm::Type &Target,
                      bool TreatIntAsVec, UnifyFn Unify);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_TYPEPATTERN_H
