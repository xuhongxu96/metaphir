#ifndef METAPHIR_EXEC_PRIMITIVE_TYPE_MATCH_H
#define METAPHIR_EXEC_PRIMITIVE_TYPE_MATCH_H

#include "metaphir/Exec/PrimitiveTypeMatch.inc"

namespace llvm {
namespace metaphir {
namespace primitive_type {

/// Whether Target is the primitive type ID.
inline bool matches(TypeID ID, const llvm::Type &Target) {
  return (Target.*TypeChecks[ID])();
}

} // namespace primitive_type
} // namespace metaphir
} // namespace llvm

#endif
