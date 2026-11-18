//===- TransformTest.h - Running one pass over a parsed pattern -*- C++ -*-===//
//
// The fixture of the tests of the passes over the mpir dialects: parse a
// pattern, run a pass on the module, look at what is left.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TEST_TRANSFORMS_TRANSFORMTEST_H
#define METAPHIR_TEST_TRANSFORMS_TRANSFORMTEST_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Parser/PatternParser.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Pass/PassManager.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

#include <string>

namespace llvm {
namespace metaphir {
namespace test {

class TransformTest : public testing::Test {
protected:
  /// Parses Source, a pattern file, with the standard library.
  mlir::ModuleOp parse(StringRef Source) {
    SMDiagnostic Diag;
    Module = parsePatternBuffer(
        MemoryBuffer::getMemBufferCopy(Source, "pattern"), SM, Context, Diag);
    if (!Module) {
      std::string Message;
      raw_string_ostream OS(Message);
      Diag.print("test", OS);
      ADD_FAILURE() << Message;
      return nullptr;
    }
    return *Module;
  }

  /// Parses Source, textual MLIR of the mpir dialects, as a module that has
  /// none of the parser's checks.
  mlir::ModuleOp parseMLIR(StringRef Source) {
    loadPatternDialects(Context);
    Module = mlir::parseSourceString<mlir::ModuleOp>(Source, &Context);
    EXPECT_TRUE(Module);
    return *Module;
  }

  /// Runs Passes, in order, over the module. Their errors are in Errors.
  template <typename... PassTs>
  mlir::LogicalResult run(std::unique_ptr<PassTs>... Passes) {
    mlir::PassManager PM(&Context);
    (PM.addPass(std::move(Passes)), ...);
    mlir::ScopedDiagnosticHandler Handler(&Context, [&](mlir::Diagnostic &D) {
      Errors += D.str() + "\n";
      return mlir::success();
    });
    return PM.run(*Module);
  }

  /// The pattern of the module.
  mpir::PatternOp pattern() {
    for (mpir::PatternOp P : Module->getOps<mpir::PatternOp>())
      return P;
    ADD_FAILURE() << "no pattern";
    return nullptr;
  }

  /// How many operations of type OpT the pattern has, nested ones included.
  template <typename OpT> unsigned count() {
    unsigned N = 0;
    pattern().walk([&](OpT) { ++N; });
    return N;
  }

  /// The first operation of type OpT of the pattern, if any.
  template <typename OpT> OpT first() {
    OpT Found;
    pattern().walk([&](OpT Op) {
      Found = Op;
      return mlir::WalkResult::interrupt();
    });
    return Found;
  }

  SourceMgr SM;
  mlir::MLIRContext Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module;
  /// What the passes reported, a line per error.
  std::string Errors;
};

} // namespace test
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TEST_TRANSFORMS_TRANSFORMTEST_H
