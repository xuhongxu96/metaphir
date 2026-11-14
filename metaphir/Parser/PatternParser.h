//===- PatternParser.h - Parse patterns into the mpir dialect ---*- C++ -*-===//
//
// Parses MetaphIR source into a module of the mpir dialect, the surface form:
// the standard library's definitions and the file's ('match' as mpir.matcher,
// 'constraint' as mpir.constraint_def, 'metaflag' as mpir.metaflag_def), and,
// if the file has instructions, its pattern as an mpir.pattern.
//
// The language, and every diagnostic, is that of MIRParser.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_PARSER_PATTERNPARSER_H
#define METAPHIR_PARSER_PATTERNPARSER_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include <memory>

namespace mlir {
class MLIRContext;
} // namespace mlir

namespace llvm {
namespace metaphir {

/// Loads the dialects patterns are made of into Context.
void loadPatternDialects(mlir::MLIRContext &Context);

/// Parses Buffer, added to SM (which must outlive the module: locations
/// point into its buffers), into a module in Context. The standard library is
/// added to SM after it, so Buffer is SM's main file. Returns null on error,
/// with the diagnostic in Diag.
mlir::OwningOpRef<mlir::ModuleOp>
parsePatternBuffer(std::unique_ptr<MemoryBuffer> Buffer, SourceMgr &SM,
                   mlir::MLIRContext &Context, SMDiagnostic &Diag);

/// Parses the file Filename as parsePatternBuffer parses a buffer.
mlir::OwningOpRef<mlir::ModuleOp> parsePatternFile(StringRef Filename,
                                                   SourceMgr &SM,
                                                   mlir::MLIRContext &Context,
                                                   SMDiagnostic &Diag);

/// Parses Source as a library named Name into Module, after the definitions
/// it has (the standard library's among them). Returns true on error, with
/// the diagnostic in Diag.
bool parsePatternLibrary(mlir::ModuleOp Module, StringRef Name,
                         StringRef Source, SourceMgr &SM, SMDiagnostic &Diag);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_PARSER_PATTERNPARSER_H
