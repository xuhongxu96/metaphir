//===- CheckBindingsTest.cpp - mpir-check-bindings
//-------------------------===//
//
// A named meta variable must be bound whichever alternatives match: it is an
// error if only the instruction of ':o' binds it, as a match of its operand
// would leave the variable without a value, or only some branches of a
// matcher a use matches by.
//
//===----------------------------------------------------------------------===//

#include "TransformTest.h"
#include "metaphir/Transforms/Lowering/Passes.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class CheckBindingsTest : public test::TransformTest {
protected:
  /// Lowers the ':o' of Source and checks its bindings.
  mlir::LogicalResult check(StringRef Source) {
    if (!parse(Source))
      return mlir::failure();
    return run(createLowerAlternativesPass(), createCheckBindingsPass());
  }
  /// Expands the matcher uses of Source as well, and checks its bindings.
  mlir::LogicalResult checkExpanded(StringRef Source) {
    if (!parse(Source))
      return mlir::failure();
    return run(createDesugarMetaFlagsPass(), createExpandMatchersPass(),
               createLowerAlternativesPass(), createCheckBindingsPass());
  }
};

TEST_F(CheckBindingsTest, RejectsAFlagCaptureABranchLeavesUnbound) {
  // The second branch has no instruction to capture 'nsw' from.
  EXPECT_TRUE(
      mlir::failed(checkExpanded(R"(match addish [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?f ?ty ?x, ?y
} or {
  %ret = or ?ty ?x, ?y
}
%r = addish nsw:?c i32 ?a, ?b
)")));
  EXPECT_NE(Errors.find("meta variable '?c' is not bound by every "
                        "alternative; name it '?_c' if it need not be bound"),
            std::string::npos)
      << Errors;
}

TEST_F(CheckBindingsTest, AcceptsAFlagCaptureABranchFixes) {
  EXPECT_TRUE(
      mlir::succeeded(checkExpanded(R"(match addish [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?f ?ty ?x, ?y
} or [nsw = false] {
  %ret = or ?ty ?x, ?y
}
%r = addish nsw:?c i32 ?a, ?b
)"))) << Errors;
}

TEST_F(CheckBindingsTest, AcceptsAVariableOfOneBranch) {
  // '?k' is the second branch's own: nothing outside it reads it.
  EXPECT_TRUE(
      mlir::succeeded(checkExpanded(R"(match addish [] Binary (?ty ?x, ?y) {
  %ret = add ?ty ?x, ?y
} or {
  %t = xor ?ty ?x, ?k
  %ret = or ?ty %t, ?y
}
%r = addish i32 ?a, ?b
)"))) << Errors;
}

TEST_F(CheckBindingsTest, AcceptsACaptureEveryBranchBinds) {
  EXPECT_TRUE(
      mlir::succeeded(checkExpanded(R"(match addish [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?f ?ty ?x, ?y
} or {
  %ret = sub nsw:?g ?ty ?x, ?y
}
%r = addish nsw:?c i32 ?a, ?b
)"))) << Errors;
}

TEST_F(CheckBindingsTest, RejectsAVariableOnlyTheInstructionBinds) {
  EXPECT_TRUE(
      mlir::failed(check("%a = add:o i32 ?x, ?y\n%b = mul i32 %a, 3\n")));
  EXPECT_NE(Errors.find("meta variable '?y' is not bound by every "
                        "alternative; name it '?_y' if it need not be bound"),
            std::string::npos)
      << Errors;
}

TEST_F(CheckBindingsTest, AcceptsAVariableNamedWithAnUnderscore) {
  EXPECT_TRUE(
      mlir::succeeded(check("%a = add:o i32 ?x, ?_y\n%b = mul i32 %a, 3\n")))
      << Errors;
}

TEST_F(CheckBindingsTest, AcceptsAVariableBoundElsewhere) {
  // '?y' is bound by the multiplication, whichever way '%a' matches.
  EXPECT_TRUE(
      mlir::succeeded(check("%a = add:o i32 ?x, ?y\n%b = mul i32 %a, ?y\n")))
      << Errors;
}

TEST_F(CheckBindingsTest, AcceptsAPatternWithoutAlternatives) {
  EXPECT_TRUE(mlir::succeeded(check("%a = add i32 ?x, ?y\n")));
  EXPECT_TRUE(Errors.empty()) << Errors;
}

TEST_F(CheckBindingsTest, DoesNotChangeThePattern) {
  ASSERT_TRUE(parse("%a = add:o i32 ?x, ?_y\n%b = mul i32 %a, 3\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass())));
  unsigned Alts = count<mpir::AltOp>(), Insts = count<mpir::InstOp>();
  ASSERT_TRUE(mlir::succeeded(run(createCheckBindingsPass()))) << Errors;
  EXPECT_EQ(count<mpir::AltOp>(), Alts);
  EXPECT_EQ(count<mpir::InstOp>(), Insts);
}

TEST_F(CheckBindingsTest, ChecksNestedAlternativesOnce) {
  // Each ':c' is an alt whose alternatives both reach the one before it: an
  // alt walked once per alternative around it would be walked 2^40 times.
  std::string Source = "%v0 = add:c i32 ?x, ?y0\n";
  for (unsigned I = 1; I != 40; ++I)
    Source += "%v" + std::to_string(I) + " = add:c i32 %v" +
              std::to_string(I - 1) + ", ?y" + std::to_string(I) + "\n";
  EXPECT_TRUE(mlir::succeeded(check(Source))) << Errors;
}

} // namespace
