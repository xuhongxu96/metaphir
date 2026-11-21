//===- LowerAlternativesTest.cpp - mpir-lower-alternatives
//-----------------===//
//
// ':c' and ':o' on a built-in instruction matcher become an mpir.alt: ':c'
// the instruction with its operands in either order, ':o' its operand or the
// instruction.
//
//===----------------------------------------------------------------------===//

#include "TransformTest.h"
#include "metaphir/Transforms/Lowering/Passes.h"

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
  // One instruction in each region, its operands in either order, and no
  // metaflag left on them.
  ASSERT_EQ(count<mpir::InstOp>(), 2u);
  pattern().walk([](mpir::InstOp Inst) { EXPECT_FALSE(Inst.getMetaflags()); });
  auto Operands = [&](unsigned Region) {
    auto Inst =
        (*Alt->getRegion(Region).front().getOps<mpir::YieldOp>().begin())
            .getValue()
            .getDefiningOp<mpir::InstOp>();
    SmallVector<mlir::Value, 2> Values;
    for (const mpir::MatcherOperandView &Op : mpir::getMatcherOperands(Inst))
      Values.push_back(Op.Val);
    return Values;
  };
  SmallVector<mlir::Value, 2> First = Operands(0), Second = Operands(1);
  ASSERT_EQ(First.size(), 2u);
  ASSERT_EQ(Second.size(), 2u);
  EXPECT_EQ(First[0], Second[1]);
  EXPECT_EQ(First[1], Second[0]);
}

TEST_F(LowerAlternativesTest, OrSelfIsTheOperandOrTheInstruction) {
  ASSERT_TRUE(parse("%r = add:o i32 ?x, 1\n"));
  ASSERT_TRUE(mlir::succeeded(run(createLowerAlternativesPass()))) << Errors;
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  mpir::AltOp Alt = first<mpir::AltOp>();
  EXPECT_EQ(Alt->getNumRegions(), 2u);
  // The instruction is in one of the regions only; the other yields its
  // operand.
  EXPECT_EQ(count<mpir::InstOp>(), 1u);
  auto Yielded = [&](unsigned Region) {
    return (*Alt->getRegion(Region).front().getOps<mpir::YieldOp>().begin())
        .getValue();
  };
  EXPECT_FALSE(Yielded(0).getDefiningOp<mpir::InstOp>());
  EXPECT_TRUE(Yielded(1).getDefiningOp<mpir::InstOp>());
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
