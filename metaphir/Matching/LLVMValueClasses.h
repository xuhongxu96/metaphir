#ifndef METAPHIR_MATCHING_LLVM_VALUE_CLASSES_H
#define METAPHIR_MATCHING_LLVM_VALUE_CLASSES_H

#include "metaphir/Matching/LLVMValueClasses.inc"
#include "llvm/IR/Value.h"
#include <optional>

namespace llvm {
namespace metaphir {

// The LLVM value classes `isa` can test, generated from
// LLVMValueClasses.td (LLVMValueClasses.inc); this reads them. The class's
// index is its persisted ordinal.

/// The name of the ClassIndex-th class.
inline StringLiteral getValueClassName(unsigned ClassIndex) {
  return ValueClasses[ClassIndex].Name;
}

/// Whether the index records the class: not those nearly every value at a
/// site is of.
inline bool isRecordedValueClass(unsigned ClassIndex) {
  return ValueClasses[ClassIndex].Recorded;
}

/// The index of the class named Name, if there is one.
inline std::optional<unsigned> findValueClass(StringRef Name) {
  for (unsigned I = 0; I != NumValueClasses; ++I)
    if (ValueClasses[I].Name == Name)
      return I;
  return std::nullopt;
}

/// Whether V is of the ClassIndex-th class.
inline bool isValueClass(const llvm::Value &V, unsigned ClassIndex) {
  return ValueClasses[ClassIndex].Is(V);
}

} // namespace metaphir
} // namespace llvm

#endif
