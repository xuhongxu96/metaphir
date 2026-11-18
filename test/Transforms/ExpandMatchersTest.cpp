//===- ExpandMatchersTest.cpp - mpir-expand-matchers ----------------------===//
//
// A use of a 'match' matcher becomes an mpir.alt with a region per branch the
// use can match, the branch's body inlined.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/ExpandMatchers.h"
#include "TransformTest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class ExpandMatchersTest : public test::TransformTest {};

TEST_F(ExpandMatchersTest, EachBranchIsARegion) {
  ASSERT_TRUE(parse(R"(match pair [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
} or {
	%ret = mul ?ty ?x, ?y
}

%r = pair i32 ?a, ?b
)"));
  EXPECT_EQ(count<mpir::UseOp>(), 1u);
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::UseOp>(), 0u);
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  EXPECT_EQ(first<mpir::AltOp>()->getNumRegions(), 2u);
  EXPECT_EQ(count<mpir::InstOp>(), 2u);
}

// A use of a commutative matcher with ':c' matches its operands in either
// order: a region for each.
TEST_F(ExpandMatchersTest, CommutativeUseTriesBothOperandOrders) {
  ASSERT_TRUE(parse(R"(match:c plus [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = plus:c i32 ?a, ?b
)"));
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::UseOp>(), 0u);
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  EXPECT_EQ(first<mpir::AltOp>()->getNumRegions(), 2u);
}

// Without ':c' the use matches the operands in the order written.
TEST_F(ExpandMatchersTest, UseWithoutColonCKeepsTheOperandOrder) {
  ASSERT_TRUE(parse(R"(match:c plus [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = plus i32 ?a, ?b
)"));
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::UseOp>(), 0u);
  ASSERT_EQ(count<mpir::AltOp>(), 1u);
  EXPECT_EQ(first<mpir::AltOp>()->getNumRegions(), 1u);
}

TEST_F(ExpandMatchersTest, NestedUsesAreExpandedToo) {
  ASSERT_TRUE(parse(R"(match inner [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
} or {
	%ret = sub ?ty ?x, ?y
}

match outer [] Binary (?ty ?x, ?y) {
	%ret = inner ?ty ?x, ?y
} or {
	%ret = mul ?ty ?x, ?y
}

%r = outer i32 ?a, ?b
)"));
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::UseOp>(), 0u);
  EXPECT_GE(count<mpir::AltOp>(), 2u);
}

TEST_F(ExpandMatchersTest, StandardLibraryMatchers) {
  ASSERT_TRUE(parse("%r = addLike i32 ?a, ?b\n"));
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::UseOp>(), 0u);
  EXPECT_GE(count<mpir::AltOp>(), 1u);
}

TEST_F(ExpandMatchersTest, ABuiltInInstructionIsLeftAlone) {
  ASSERT_TRUE(parse("%r = add i32 ?a, ?b\n"));
  ASSERT_TRUE(mlir::succeeded(run(createExpandMatchersPass()))) << Errors;
  EXPECT_EQ(count<mpir::AltOp>(), 0u);
  EXPECT_EQ(count<mpir::InstOp>(), 1u);
}

TEST_F(ExpandMatchersTest, RejectsATypeTheMatcherFixes) {
  // The matcher takes i1 where the use passes a type only a match decides.
  ASSERT_TRUE(parse(R"(match pick [] Nary (i1 ?c, ?ty ?t) {
  %ret = select i1 ?c, ?ty ?t, ?ty ?t
}

%r = pick ?any ?cond, i32 ?x
)"));
  EXPECT_TRUE(mlir::failed(run(createExpandMatchersPass())));
  EXPECT_NE(Errors.find("matcher 'pick' requires type 'i1' for a parameter, "
                        "but this use passes '?any'"),
            std::string::npos)
      << Errors;
}

} // namespace
