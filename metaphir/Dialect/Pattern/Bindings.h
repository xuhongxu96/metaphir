//===- Bindings.h - How plans and index queries name bindings ---*- C++ -*-===//
//
// What mpir_plan matchers and mpir_index queries share of a lowered pattern:
// the slot that numbers each of its bindings, and the type patterns of its
// types.
//
// A plan refers to a binding only by its slot (mpir_plan.bind writes a slot
// and a check reads one), and an index query numbers its type variables by
// the same slots, so a variable is one number in both.
//
// A type pattern, of mpir_plan.check_type or mpir_index.typing, is an
// ArrayAttr whose first element is its TypePatternKind, then:
//
//   Primitive      Type::TypeID
//   Integer        width, byte (0 or 1)
//   MetaInteger    slot of the width, byte
//   Variable       slot
//   Pointer        address space (-1 for any), opaque (0 or 1)
//   Sequence       kind (0 array, 1 vector, 2 scalable vector), count,
//                  slot of the count (-1 if the count is fixed), element
//   Struct         packed, elements...
//   Function       variadic, return type, parameters...
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_BINDINGS_H
#define METAPHIR_DIALECT_PATTERN_BINDINGS_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/Builders.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
namespace metaphir {
namespace mpir {

enum class TypePatternKind : int64_t {
  Primitive = 0,
  Integer = 1,
  MetaInteger = 2,
  Variable = 3,
  Pointer = 4,
  Sequence = 5,
  Struct = 6,
  Function = 7,
};

/// The slots of a lowered pattern's bindings: one per meta variable,
/// instruction matcher and alternative, numbered in the order they are
/// written (a pre-order walk). A matcher that an alternative yields shares
/// the alternative's slot instead, because whichever alternative matches,
/// the instruction it matches is the alternative's match. With nested
/// alternatives, it shares the outermost one's slot.
struct SlotAssignment {
  /// The value each slot is for: a meta variable, or an instruction matcher
  /// or alternative.
  SmallVector<mlir::Value, 16> Values;
  /// The slot of each value that has one.
  DenseMap<mlir::Value, unsigned> Of;
};

SlotAssignment assignSlots(mpir::PatternOp Pattern);

/// The type pattern of the pattern type T (see above), numbering each
/// meta variable in it by its slot, and appending each to Variables if given.
mlir::ArrayAttr
encodeTypePattern(mlir::Builder &Builder, mlir::Value T,
                  const SlotAssignment &Slots,
                  SmallVectorImpl<mlir::Value> *Variables = nullptr);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_BINDINGS_H
