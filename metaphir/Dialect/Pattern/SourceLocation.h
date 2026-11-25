//===- SourceLocation.h - Pattern source ranges as locations ----*- C++ -*-===//
//
// A pattern's operations are located at the source text they were parsed
// from. The location keeps the range itself, so diagnostics can be printed
// by the SourceMgr that holds the text, as the parser prints its own; it
// falls back to a file:line:col range wherever MLIR prints locations.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_SOURCELOCATION_H
#define METAPHIR_DIALECT_PATTERN_SOURCELOCATION_H

#include "mlir/IR/Location.h"
#include "llvm/Support/SMLoc.h"
#include <optional>

namespace llvm {
class SourceMgr;
namespace metaphir {

/// The location of Range, in a buffer of SM.
mlir::Location getLocation(mlir::MLIRContext *Context, const SourceMgr &SM,
                           SMRange Range);
inline mlir::Location getLocation(mlir::MLIRContext *Context,
                                  const SourceMgr &SM, SMLoc Loc) {
  return getLocation(Context, SM, SMRange(Loc, Loc));
}

/// The source range a location made by getLocation stands for: for a call
/// site (an inlined matcher body), that of the callee. Invalid if it has none.
SMRange getSourceRange(mlir::Location Loc);

/// For a location inlined from a matcher's body, the range of the outermost
/// use of the matcher; otherwise Loc's own range.
SMRange getOutermostSourceRange(mlir::Location Loc);

/// The line of Loc in the main file of SM (the pattern parsed first), if it
/// is there rather than in the standard library.
std::optional<unsigned> getMainFileLine(const SourceMgr &SM, SMLoc Loc);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_SOURCELOCATION_H
