#ifndef METAPHIR_IR_TYPE_H
#define METAPHIR_IR_TYPE_H

#include "metaphir/IR/Types.inc"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

/// The primitive types a pattern can name ('half', 'float', 'void',
/// 'label', ...). The others (integers, pointers, aggregates, vectors,
/// functions and meta types) are ops of the mpir dialect. Their data is
/// generated from Types.td (Types.inc); this reads it.
namespace primitive_type {

/// The spellings of every type, in the order of TypeID.
inline ArrayRef<StringRef> getNames() { return Spellings; }

/// How a pattern spells the type.
inline StringRef getName(TypeID ID) { return Spellings[ID]; }

} // namespace primitive_type
} // namespace metaphir
} // namespace llvm

#endif
