//===- PatternDialect.h - The mpir dialect ----------------------*- C++ -*-===//
//
// Patterns as MLIR (see PatternOps.td).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_PATTERNDIALECT_H
#define METAPHIR_DIALECT_PATTERN_PATTERNDIALECT_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Sort.h"
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

namespace llvm {
namespace metaphir {
namespace mpir {

/// How a semantic flag is written on an instruction matcher: 'nsw' requires
/// it, '!nsw' requires its absence, 'nsw:?v' binds ?v to whether it is there.
enum class FlagMode : int32_t { Required = 0, Negated = 1, Captured = 2 };

/// The kinds of matcher operand, and how many of an instruction's
/// operand_values each takes.
enum class OperandKind : int32_t {
  /// 'i32 ?x': a type pattern and a value.
  TypedValue = 0,
  /// A value whose type is not written: a phi's block, a callee, an index.
  Value = 1,
  /// A bare type that is not an operand: a cast's destination, a load's
  /// result type, 'ret void'.
  TypeOnly = 2,
  /// '...?values': the remaining operands.
  ValueArray = 3,
  /// '...?types ?values': the remaining operands and their types.
  TypedValueArray = 4,
  /// Keyed operands, each one value.
  Predicate = 5,
  Alignment = 6,
  AddressSpace = 7,
  InRangeLower = 8,
  InRangeUpper = 9,
};

/// How many operand_values an operand of Kind takes.
unsigned getNumOperandValues(OperandKind Kind);
/// Whether an operand of Kind is one of the instruction's value operands.
bool isValueOperand(OperandKind Kind);
StringRef stringifyOperandKind(OperandKind Kind);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#include "metaphir/Dialect/Pattern/PatternOpsDialect.h.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsTypes.h.inc"

#define GET_ATTRDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsAttrDefs.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Pattern/PatternOps.h.inc"

namespace llvm {
namespace metaphir {
namespace mpir {

/// The type of pattern values of sort S.
inline SortType getSortType(mlir::MLIRContext *Context, Sort S) {
  return SortType::get(Context, S);
}

/// One matcher operand of an mpir.inst or mpir.use, with its values.
struct MatcherOperandView {
  OperandKind Kind;
  /// The type pattern, if the operand has one.
  mlir::Value Type;
  /// The value (or value array, or keyed value), if any.
  mlir::Value Val;
};

/// The matcher operands of Op, an mpir.inst or mpir.use.
SmallVector<MatcherOperandView, 4> getMatcherOperands(mlir::Operation *Op);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_PATTERNDIALECT_H
