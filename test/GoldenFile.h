//===- GoldenFile.h - Compare a dump with a checked-in file --------------===//
//
// Tests that pin a generated table's order and contents dump it as text and
// compare it with a golden file. Setting METAPHIR_UPDATE_GOLDEN rewrites the
// golden file from the dump instead.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TEST_GOLDEN_FILE_H
#define METAPHIR_TEST_GOLDEN_FILE_H

#include "llvm/ADT/SmallString.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"
#include <cstdlib>
#include <system_error>

#ifndef METAPHIR_SOURCE_DIR
#error "METAPHIR_SOURCE_DIR must name the repository root"
#endif

namespace llvm {
namespace metaphir {
namespace test {

/// Expects Actual to equal the file at Relative, a path under the repository.
inline void expectMatchesGolden(StringRef Relative, StringRef Actual) {
  SmallString<128> Path(METAPHIR_SOURCE_DIR);
  sys::path::append(Path, Relative);
  if (std::getenv("METAPHIR_UPDATE_GOLDEN")) {
    std::error_code EC;
    raw_fd_ostream OS(Path, EC);
    ASSERT_FALSE(EC) << "cannot write " << Path.str();
    OS << Actual;
    return;
  }
  auto Buffer = MemoryBuffer::getFile(Path);
  ASSERT_TRUE(bool(Buffer)) << "cannot read " << Path.str();
  EXPECT_EQ((*Buffer)->getBuffer().str(), Actual.str())
      << Path.str() << " differs; rerun with METAPHIR_UPDATE_GOLDEN=1 if the "
      << "change is intended";
}

} // namespace test
} // namespace metaphir
} // namespace llvm

#endif
