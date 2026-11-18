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

} // namespace lowering
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_LOWERING_LOWERINGUTILS_H
