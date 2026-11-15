#include "metaphir/Exec/CompiledPattern.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

std::string compileErrors(StringRef Source, bool &Compiled) {
  std::string Errors;
  raw_string_ostream OS(Errors);
  auto Pattern = CompiledPattern::compile(
      MemoryBuffer::getMemBufferCopy(Source, "pattern"), OS, "prog");
  Compiled = Pattern != nullptr;
  OS.flush();
  return Errors;
}

TEST(CompiledPatternTest, RejectsBindingsThatOrSelfLeavesUnbound) {
  bool Compiled = true;
  std::string Errors =
      compileErrors("%z = zext:o i?n ?x to i32\n%r = add i32 %z, 1\n", Compiled);
  EXPECT_FALSE(Compiled);
  EXPECT_NE(Errors.find("prog: pattern:1:"), std::string::npos) << Errors;
}

TEST(CompiledPatternTest, CompilesGoodPatterns) {
  bool Compiled = false;
  std::string Errors = compileErrors("%r = add i32 ?x, 1\n", Compiled);
  EXPECT_TRUE(Compiled) << Errors;
  EXPECT_EQ(Errors, "");
}

TEST(CompiledPatternTest, ReportsFilesThatCannotBeRead) {
  std::string Errors;
  raw_string_ostream OS(Errors);
  EXPECT_EQ(CompiledPattern::compileFile("/nonexistent/pattern.mpir", OS, "prog"),
            nullptr);
  OS.flush();
  EXPECT_NE(Errors.find("cannot read file"), std::string::npos) << Errors;
}

} // namespace
