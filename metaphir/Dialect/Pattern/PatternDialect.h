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

/// How many operand_values an operand of Kind takes.
unsigned getNumOperandValues(OperandKind Kind);
/// Whether an operand of Kind is one of the instruction's value operands.
bool isValueOperand(OperandKind Kind);
/// Whether an operand of Kind is an array of the remaining operands
/// ('...?values', or '...?types ?values').
bool isArrayOperand(OperandKind Kind);
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

#include "metaphir/Dialect/Pattern/PatternOpInterfaces.h.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Pattern/PatternOps.h.inc"

namespace llvm {
namespace metaphir {
namespace mpir {

/// The sort of a pattern value.
inline Sort sortOf(mlir::Value V) {
  return cast<SortType>(V.getType()).getSort();
}

/// One matcher operand of an mpir.inst or mpir.use, with its values.
struct MatcherOperandView {
  OperandKind Kind;
  /// The type pattern, if the operand has one.
  mlir::Value Type;
  /// The value (or value array, or keyed value), if any.
  mlir::Value Val;
};

/// The operations of other dialects that stand for a pattern value (a plan's
/// slot, an index's node) are named by discardable attributes: the result
/// name of an instruction, or the name of a meta variable. These are the
/// attributes' names, which the pattern dialect's own operations have too.
inline constexpr StringLiteral ResultNameAttrName = "result_name";
inline constexpr StringLiteral VarNameAttrName = "var_name";

/// The matcher operands of Op, an mpir.inst or mpir.use.
SmallVector<MatcherOperandView, 4> getMatcherOperands(MatcherOpInterface Op);

/// The pieces of an mpir.inst or mpir.use, for building another.
struct MatcherParts {
  /// The name the result is written with, or null.
  mlir::StringAttr ResultName;
  SmallVector<instruction_flag::FlagID, 4> Flags;
  SmallVector<FlagMode, 4> Modes;
  SmallVector<mlir::Value, 2> FlagCaptures;
  SmallVector<MatcherOperandView, 8> Operands;
  /// The metaflags written on the instruction, and on each operand (an array
  /// per operand).
  SmallVector<mlir::Attribute, 4> MetaFlags;
  SmallVector<mlir::Attribute, 8> OperandMetaFlags;
  std::optional<bool> TreatIntAsVec;
  mlir::Value Capture;
  mlir::Value ParentBlock;

  /// The parts of Matcher.
  static MatcherParts of(MatcherOpInterface Matcher);

  /// Builds an mpir.inst of Opcode, or an mpir.use of Matcher, with these
  /// parts.
  InstOp buildInst(mlir::OpBuilder &Builder, mlir::Location Loc,
                   OpcodeAttr Opcode) const;
  UseOp buildUse(mlir::OpBuilder &Builder, mlir::Location Loc,
                 mlir::FlatSymbolRefAttr Matcher) const;
};

/// The instruction matchers and alternatives of Block (of a lowered pattern,
/// or of an alternative) that no other matcher uses as an operand: those a
/// match of the block starts from.
SmallVector<mlir::Operation *, 4> getPatternRoots(mlir::Block &Block);

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_PATTERNDIALECT_H
