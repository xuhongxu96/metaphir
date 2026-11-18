//===- LowerAlternativesTest.cpp - mpir-lower-alternatives
//-----------------===//
//
// ':c' and ':o' on a built-in instruction matcher become an mpir.alt: ':c'
// the instruction with its operands in either order, ':o' its operand or the
// instruction.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/LowerAlternatives.h"
#include "TransformTest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class LowerAlternativesTest : public test::TransformTest {};

TEST_F(LowerAlternativesTest, CommutativeIsBothOperandOrders) {
  ASSERT_TRUE(parse("%r = add:c i32 ?x, 1\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  mpir::AltOp Alt = first<mpir::AltOp>();
  EXPECT_EQ(Alt->getNumRegions(), 2u);
  EXPECT_TRUE(Alt->hasAttr("commuted"));
  EXPECT_FALSE(Alt->hasAttr("or_self_of"));
  // One instruction in each region, and no metaflag left on them.
  ASSERT_EQ(count<mpir::InstOp>(), 2u);
  pattern().walk([](mpir::InstOp Inst) { EXPECT_FALSE(Inst.getMetaflags()); });
}

TEST_F(LowerAlternativesTest, OrSelfIsTheOperandOrTheInstruction) {
  ASSERT_TRUE(parse("%r = add:o i32 ?x, 1\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  mpir::AltOp Alt = first<mpir::AltOp>();
  EXPECT_EQ(Alt->getNumRegions(), 2u);
  auto OrSelfOf = Alt->getAttrOfType<mlir::StringAttr>("or_self_of");
  ASSERT_TRUE(OrSelfOf);
  EXPECT_EQ(OrSelfOf.getValue(), "add");
  EXPECT_TRUE(Alt->hasAttr("or_self_region"));
  // The instruction is in one of the regions only.
  EXPECT_EQ(count<mpir::InstOp>(), 1u);
}

TEST_F(LowerAlternativesTest, BothAlternativesNest) {
  ASSERT_TRUE(parse("%r = add:c:o i32 ?x, ?_y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  EXPECT_GE(count<mpir::AltOp>(), 2u);
  pattern().walk([](mpir::InstOp Inst) { EXPECT_FALSE(Inst.getMetaflags()); });
}

TEST_F(LowerAlternativesTest, WithoutAlternativesThePatternIsAsParsed) {
  ASSERT_TRUE(parse("%r = add i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  EXPECT_EQ(count<mpir::AltOp>(), 0u);
  EXPECT_EQ(count<mpir::InstOp>(), 1u);
}

TEST_F(LowerAlternativesTest, OtherMetaFlagsStay) {
  ASSERT_TRUE(parse("%r = add:s i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  EXPECT_EQ(count<mpir::AltOp>(), 0u);
  EXPECT_TRUE(first<mpir::InstOp>().getMetaflags());
}

} // namespace
