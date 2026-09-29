#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/Parser/MIRParser.h"
#include "test/TestUtils.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// A library that fails to parse reports why, against the library's name, and
// is not recorded as loaded (so it is not silently skipped later).
TEST(LibraryTest, FailedLibraryReportsDiagnosticAndStaysUnloaded) {
  MIRContext Context;
  SMDiagnostic Diag;
  EXPECT_TRUE(
      MIRParser::loadLibrary(Context, "broken", "%x = bogus i32 ?a\n", Diag));
  EXPECT_EQ(Diag.getFilename(), "broken");
  EXPECT_EQ(Diag.getLineNo(), 1);
  EXPECT_EQ(Diag.getMessage(), "expected instruction matcher");
  EXPECT_FALSE(Context.isLibraryLoaded("broken"));
}

// Loading is idempotent and makes the library's definitions available.
TEST(LibraryTest, LoadedLibraryRegistersDefinitionsOnce) {
  MIRContext Context;
  SMDiagnostic Diag;
  StringRef Source = "constraint isSeven(?v) {\n  ?v == 7\n}\n";
  ASSERT_FALSE(MIRParser::loadLibrary(Context, "lib", Source, Diag))
      << Diag.getMessage().str();
  EXPECT_TRUE(Context.isLibraryLoaded("lib"));
  EXPECT_NE(Context.getConstraintDef("isSeven"), nullptr);
  EXPECT_FALSE(MIRParser::loadLibrary(Context, "lib", Source, Diag));
}

// Source ranges of library definitions stay resolvable after loading: the
// buffers are kept alive by the context.
TEST(LibraryTest, LibraryDefinitionsKeepValidSourceRanges) {
  MIRContext Context;
  SMDiagnostic Diag;
  // The library text is a temporary; the context must keep its own copy.
  std::string Source = "constraint isSeven(?v) {\n  ?v == 7\n}\n";
  ASSERT_FALSE(MIRParser::loadLibrary(Context, "lib", Source, Diag));
  Source.assign(Source.size(), 'X');

  const ConstraintDef *Def = Context.getConstraintDef("isSeven");
  ASSERT_NE(Def, nullptr);
  const SourceMgr &SM = Context.getLibrarySourceMgr();
  SMLoc Loc = Def->getBody()->getSourceRange().Begin;
  ASSERT_NE(SM.FindBufferContainingLoc(Loc), 0u);
  EXPECT_EQ(SM.getLineAndColumn(Loc).first, 2u);
  EXPECT_EQ(StringRef(Loc.getPointer(), 2), "==");
}

// Parsing a pattern with a broken standard library is not possible to set up
// from outside, but a user pattern parse still reports its own errors after
// the standard library loaded successfully.
TEST(LibraryTest, PatternParseLoadsStandardLibrary) {
  MIRContext Context;
  SourceMgr SM;
  ASSERT_NE(test::parsePattern("add i32 ?x:zero, ?y\n", SM, Context), nullptr);
  EXPECT_TRUE(Context.isLibraryLoaded(MIRParser::StdLibName));
}

} // namespace
