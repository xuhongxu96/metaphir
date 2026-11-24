//===- TablesTest.cpp - The language's vocabulary ------------------------===//
//
// What the .td tables generate: instruction matchers' properties, keyword
// names, and the schemas of metaflags and constraint operators.
//
//===----------------------------------------------------------------------===//

#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/PatternSettings.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(TablesTest, GeneratedInstructionProperties) {
  EXPECT_EQ(instruction::getOpcodeName(instruction::I_add), "add");
  EXPECT_TRUE(instruction::isCommutative(instruction::I_add));
  EXPECT_FALSE(instruction::isCommutative(instruction::I_sub));
  EXPECT_NE(instruction::getSupportedFlags(instruction::I_add) &
                instruction::mask(instruction_flag::F_nsw),
            0u);
  EXPECT_EQ(instruction::getSupportedFlags(instruction::I_add) &
                instruction::mask(instruction_flag::F_exact),
            0u);
  EXPECT_EQ(instruction_flag::getName(instruction_flag::F_nsw), "nsw");
}

TEST(TablesTest, UsesEnumeratedKeywordConstants) {
  EXPECT_EQ(keyword_constant::getKeywordName(keyword_constant::K_Poison),
            "poison");
}

TEST(TablesTest, GeneratedExtensibilitySchemas) {
  auto Or = metaflag::getSchema(metaflag::MF_or);
  ASSERT_TRUE(Or);
  EXPECT_EQ(Or->Arguments, metaflag::FlagArgument);
  EXPECT_EQ(Or->AllowedPlacement, metaflag::OperandPlacement);
  EXPECT_FALSE(Or->Structural);
  EXPECT_TRUE(Or->Nestable);
  auto Not = metaflag::getSchema(metaflag::MF_not);
  ASSERT_TRUE(Not);
  EXPECT_FALSE(Not->Structural);
  EXPECT_TRUE(Not->Nestable);
  // ':c' and ':o' change how an instruction is matched, so they cannot be
  // nested inside another metaflag.
  auto Commutative = metaflag::getSchema(metaflag::MF_c);
  ASSERT_TRUE(Commutative);
  EXPECT_TRUE(Commutative->Structural);
  EXPECT_FALSE(Commutative->Nestable);
  auto OperandIndex = metaflag::getSchema(metaflag::MF_o);
  ASSERT_TRUE(OperandIndex);
  EXPECT_TRUE(OperandIndex->Structural);
  EXPECT_FALSE(OperandIndex->Nestable);
  EXPECT_FALSE(metaflag::getSchema(metaflag::UnknownMetaFlag));
  EXPECT_EQ(metaflag::getMetaFlagID("c"), metaflag::MF_c);
  EXPECT_EQ(metaflag::getMetaFlagID("future_flag"), metaflag::UnknownMetaFlag);

  auto ULT = constraint::getOperatorSchema(constraint::O_ULT);
  ASSERT_TRUE(ULT);
  EXPECT_EQ(ULT->Result, Sort::Boolean);
  EXPECT_EQ(ULT->MinArity, 2u);
  EXPECT_EQ(ULT->MaxArity, 2u);
  EXPECT_FALSE(constraint::getOperatorSchema(constraint::UnknownOperator));
  EXPECT_EQ(constraint::getOperatorID("ult", constraint::Call),
            constraint::O_ULT);
  EXPECT_EQ(constraint::getOperatorID("-", constraint::Unary),
            constraint::O_Negate);
  EXPECT_EQ(constraint::getOperatorID("-", constraint::Binary),
            constraint::O_Subtract);
  EXPECT_EQ(constraint::getOperatorID("future_predicate", constraint::Call),
            constraint::UnknownOperator);
}

TEST(TablesTest, PatternSettingsStartAtTheirDefaults) {
  // Each setting declares its default in PatternSettings.td, and a fresh
  // PatternSettings starts from them, with none written.
  PatternSettings Settings;
  EXPECT_EQ(
      Settings.has(pattern_setting::treatIntAsVec),
      bool(pattern_setting::DefaultMask & pattern_setting::treatIntAsVec));
  EXPECT_FALSE(Settings.isSpecified(pattern_setting::treatIntAsVec));
  // treatIntAsVec is off unless a pattern turns it on.
  EXPECT_EQ(pattern_setting::DefaultMask, 0u);
}

} // namespace
