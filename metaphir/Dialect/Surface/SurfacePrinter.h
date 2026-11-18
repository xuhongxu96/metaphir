//===- SurfacePrinter.h - Print patterns as they are written ----*- C++ -*-===//
//
// Prints the mpir and mpir_expr dialects in the pattern language: instruction
// matchers as written, and constraints as prefix expressions,
// '(&& (== ?x 1) (isZero ?y))', as diagnostics and metaphir-parse show them.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_SURFACE_SURFACEPRINTER_H
#define METAPHIR_DIALECT_SURFACE_SURFACEPRINTER_H

#include "mlir/IR/Value.h"

namespace llvm {
class raw_ostream;
namespace metaphir {
namespace mpir {
class PatternOp;
} // namespace mpir

/// Prints Pattern as metaphir-parse does: a header, its instructions (with
/// block labels), its constraints and its meta variables with their sorts.
/// A null Pattern prints as one without anything.
void printSurfacePattern(raw_ostream &OS, mpir::PatternOp Pattern);

/// Prints an mpir.inst or mpir.use as written.
void printSurfaceInstruction(raw_ostream &OS, mlir::Operation *Instruction);

/// Prints a constraint expression in prefix form.
void printSurfaceExpression(raw_ostream &OS, mlir::Value Expression);

/// Prints a pattern value: '?x', '%a', '@g', a constant or a type pattern.
void printSurfaceValue(raw_ostream &OS, mlir::Value V);

/// The name of a meta variable: an mpir.var, or a parameter of a definition
/// or match branch. Empty for anything else.
StringRef getMetaVariableName(mlir::Value V);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_SURFACE_SURFACEPRINTER_H
