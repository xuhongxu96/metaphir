//===- TestUtils.h - Shared helpers for MetaphIR unit tests -----*- C++ -*-===//
//
// Parsing LLVM IR for tests.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TEST_TESTUTILS_H
#define METAPHIR_TEST_TESTUTILS_H

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

#include <memory>

namespace llvm {
namespace metaphir {
namespace test {

/// Parses textual LLVM IR, returning null (and printing the diagnostic) on
/// failure.
inline std::unique_ptr<Module> parseLLVMModule(StringRef IR,
                                               LLVMContext &Context) {
  SMDiagnostic Diag;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Diag, Context);
  if (!M)
    Diag.print("test", errs());
  return M;
}

} // namespace test
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TEST_TESTUTILS_H
