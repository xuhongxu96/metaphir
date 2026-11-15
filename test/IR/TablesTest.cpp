//===- TablesTest.cpp - The language's vocabulary ------------------------===//
//
// What the .def tables generate: instruction matchers' properties, keyword
// names, and the schemas of metaflags and constraint operators.
//
//===----------------------------------------------------------------------===//

#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(TablesTest, GeneratedInstructionProperties) {
  EXPECT_EQ(Instruction::getOpcodeName(Instruction::I_add), "add");
  EXPECT_TRUE(Instruction::isCommutative(Instruction::I_add));
  EXPECT_FALSE(Instruction::isCommutative(Instruction::I_sub));
  EXPECT_NE(Instruction::getSupportedFlags(Instruction::I_add) &
                Instruction::mask(InstructionFlag::F_nsw),
            0u);
  EXPECT_EQ(Instruction::getSupportedFlags(Instruction::I_add) &
                Instruction::mask(InstructionFlag::F_exact),
            0u);
  EXPECT_EQ(InstructionFlag::getName(InstructionFlag::F_nsw), "nsw");
}

TEST(TablesTest, UsesEnumeratedKeywordConstants) {
  EXPECT_EQ(KeywordConstant::getKeywordName(KeywordConstant::K_Poison),
            "poison");
}

TEST(TablesTest, GeneratedExtensibilitySchemas) {
  auto Or = MetaFlag::getSchema(MetaFlag::MF_or);
  ASSERT_TRUE(Or);
  EXPECT_EQ(Or->Arguments, MetaFlag::FlagArgument);
  EXPECT_EQ(Or->AllowedPlacement, MetaFlag::OperandPlacement);
  EXPECT_FALSE(MetaFlag::getSchema(MetaFlag::UnknownMetaFlag));
  EXPECT_EQ(MetaFlag::getMetaFlagID("c"), MetaFlag::MF_c);
  EXPECT_EQ(MetaFlag::getMetaFlagID("future_flag"), MetaFlag::UnknownMetaFlag);

  auto ULT = Constraint::getOperatorSchema(Constraint::O_ULT);
  ASSERT_TRUE(ULT);
  EXPECT_EQ(ULT->Result, Sort::Boolean);
  EXPECT_EQ(ULT->MinArity, 2u);
  EXPECT_EQ(ULT->MaxArity, 2u);
  EXPECT_FALSE(Constraint::getOperatorSchema(Constraint::UnknownOperator));
  EXPECT_EQ(Constraint::getOperatorID("ult", Constraint::Call),
            Constraint::O_ULT);
  EXPECT_EQ(Constraint::getOperatorID("-", Constraint::Unary),
            Constraint::O_Negate);
  EXPECT_EQ(Constraint::getOperatorID("-", Constraint::Binary),
            Constraint::O_Subtract);
  EXPECT_EQ(Constraint::getOperatorID("future_predicate", Constraint::Call),
            Constraint::UnknownOperator);
}

} // namespace
