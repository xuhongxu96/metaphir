//===- CheckBindingsTest.cpp - mpir-check-bindings
//-------------------------===//
//
// A named meta variable must be bound whichever alternative ':o' takes: it is
// an error if only the instruction binds it, as a match of its operand would
// leave the variable without a value.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/CheckBindings.h"
#include "TransformTest.h"
#include "metaphir/Transforms/Lowering/LowerAlternatives.h"

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
};

TEST_F(CheckBindingsTest, RejectsAVariableOnlyTheInstructionBinds) {
  EXPECT_TRUE(
      mlir::failed(check("%a = add:o i32 ?x, ?y\n%b = mul i32 %a, 3\n")));
  EXPECT_NE(Errors.find("meta variable '?y' is not bound when ':o' lets 'add' "
                        "match its operand; name it '?_y' if it need not be "
                        "bound"),
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

} // namespace
