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
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "metaphir/Dialect/Pattern/NamedEnum.h"
#include "metaphir/Dialect/Pattern/PatternEnums.h.inc"

namespace llvm {
namespace metaphir {
namespace mpir {

/// Sets the flags, flag modes and operand kinds of the mpir.inst or mpir.use
/// that State builds. They are properties rather than attributes, so State's
/// attributes cannot carry them.
void setMatcherProperties(mlir::Builder &Builder, mlir::OperationState &State,
                          ArrayRef<instruction_flag::FlagID> Flags,
                          ArrayRef<FlagMode> Modes,
                          ArrayRef<OperandKind> Kinds);

/// How many operand_values an operand of Kind takes.
unsigned getNumOperandValues(OperandKind Kind);
/// Whether an operand of Kind is one of the instruction's value operands.
bool isValueOperand(OperandKind Kind);
/// Whether an operand of Kind is a keyed operand (a predicate, an alignment,
/// an address space, an inrange bound): written as 'key value', at most once.
bool isKeyedOperand(OperandKind Kind);

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

/// The instruction matchers and alternatives of Block (of a lowered pattern,
/// or of an alternative) that no other matcher uses as an operand: those a
/// match of the block starts from.
SmallVector<mlir::Operation *, 4> getPatternRoots(mlir::Block &Block);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_PATTERNDIALECT_H
