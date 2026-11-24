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
// A type pattern, of mpir_plan.check_type or mpir_index.typing, is a
// TypePatternAttr (PatternBase.td) whose variables are numbered by their
// slots.
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

/// The type pattern of the pattern type T, numbering each meta variable in it
/// by its slot, and appending each to Variables if given.
TypePatternAttr
encodeTypePattern(mlir::Value T, const SlotAssignment &Slots,
                  SmallVectorImpl<mlir::Value> *Variables = nullptr);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_BINDINGS_H
