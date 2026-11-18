//===- LoweringUtils.h - What the lowering passes share ---------*- C++ -*-===//
//
// The accessors and builders the passes of Lowering.h use alike. Each pass is
// in a file of its own.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_LOWERING_LOWERINGUTILS_H
#define METAPHIR_TRANSFORMS_LOWERING_LOWERINGUTILS_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "llvm/Support/raw_ostream.h"
#include <optional>
#include <string>

namespace llvm {
namespace metaphir {
namespace lowering {

using mlir::Attribute;
using mlir::Location;
using mlir::LogicalResult;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using mlir::ValueRange;
using namespace mpir;

inline SortType sortType(mlir::MLIRContext *Context, Sort S) {
  return SortType::get(Context, S);
}

/// What Print prints to a stream, as a string.
template <typename T> std::string toString(const T &Print) {
  std::string Result;
  raw_string_ostream OS(Result);
  Print(OS);
  return Result;
}

/// Accessors shared by mpir.inst and mpir.use.
struct MatcherUse {
  Operation *Op;

  explicit MatcherUse(Operation *Op) : Op(Op) {}
  InstOp inst() const { return dyn_cast<InstOp>(Op); }
  UseOp use() const { return dyn_cast<UseOp>(Op); }

#define FORWARD(Type, Name)                                                    \
  Type Name() const { return inst() ? inst().Name() : use().Name(); }
  FORWARD(std::optional<StringRef>, getResultName)
  FORWARD(std::optional<mlir::ArrayAttr>, getMetaflags)
  FORWARD(std::optional<mlir::ArrayAttr>, getOperandMetaflags)
  FORWARD(ArrayRef<instruction_flag::FlagID>, getFlags)
  FORWARD(ArrayRef<FlagMode>, getFlagModes)
  FORWARD(mlir::OperandRange, getFlagCaptures)
  FORWARD(ArrayRef<OperandKind>, getOperandKinds)
  FORWARD(std::optional<bool>, getTreatIntAsVec)
#undef FORWARD
  Value getCapture() const {
    return inst() ? Value(inst().getCapture()) : Value(use().getCapture());
  }
  Value getParentBlock() const {
    return inst() ? Value(inst().getParentBlock())
                  : Value(use().getParentBlock());
  }
  Value result() const { return Op->getResult(0); }
};

/// The pieces of an mpir.inst or mpir.use, for building another.
struct MatcherParts {
  std::string ResultName;
  bool HasResultName = false;
  SmallVector<instruction_flag::FlagID, 4> Flags;
  SmallVector<FlagMode, 4> Modes;
  SmallVector<Value, 2> FlagCaptures;
  SmallVector<MatcherOperandView, 8> Operands;
  SmallVector<Attribute, 4> MetaFlags;
  SmallVector<Attribute, 8> OperandMetaFlags;
  std::optional<bool> TreatIntAsVec;
  Value Capture;
  Value ParentBlock;

  static MatcherParts of(MatcherUse U);

  /// Builds an mpir.inst (with Opcode) or an mpir.use (with Matcher).
  Operation *build(OpBuilder &Builder, Location Loc, StringRef OpName,
                   mlir::NamedAttribute Key, bool SwappedPredicate = false);
};

} // namespace lowering
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_LOWERINGUTILS_H
