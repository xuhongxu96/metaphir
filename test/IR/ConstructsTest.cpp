#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Pattern.h"
#include "gtest/gtest.h"
#include <type_traits>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// Patterns are owned by their context; copying one would bypass that.
static_assert(!std::is_copy_constructible_v<Pattern>,
              "Pattern must not be copyable");

TEST(MetaphIRConstructs, UsesOneTypeHierarchy) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Bits =
      MetaVariable::create(Context, "bits", MetaType::Nat, Range);
  Value *BitsValue = Bits;
  EXPECT_EQ(BitsValue->getValueID(), Value::MetaVariableVal);
  EXPECT_EQ(cast<MetaVariable>(BitsValue), Bits);
  Type *MetaInteger = MetaIntegerType::get(Context, Bits, false);
  EXPECT_TRUE(isa<MetaIntegerType>(MetaInteger));
  EXPECT_EQ(cast<MetaIntegerType>(MetaInteger)->getBitWidthVariable(), Bits);

  Type *I32 = IntegerType::get(Context, 32);
  Type *Vector = VectorType::get(Context, false, I32, 4);
  EXPECT_TRUE(isa<VectorType>(Vector));
  EXPECT_EQ(cast<VectorType>(Vector)->getElementType(), I32);
}

TEST(MetaphIRConstructs, UniquesTypesByStructure) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Ty = MetaVariable::create(Context, "ty", MetaType::Type, Range);
  MetaVariable *Bits =
      MetaVariable::create(Context, "bits", MetaType::Nat, Range);
  MetaVariable *Count =
      MetaVariable::create(Context, "count", MetaType::Nat, Range);

  Type *I8 = IntegerType::get(Context, 8);
  Type *I32 = IntegerType::get(Context, 32);
  EXPECT_EQ(I32, IntegerType::get(Context, 32));
  EXPECT_EQ(ByteType::get(Context, 8), ByteType::get(Context, 8));
  EXPECT_EQ(MetaIRType::get(Context, Ty), MetaIRType::get(Context, Ty));
  EXPECT_EQ(MetaIntegerType::get(Context, Bits, false),
            MetaIntegerType::get(Context, Bits, false));
  EXPECT_NE(MetaIntegerType::get(Context, Bits, false),
            MetaIntegerType::get(Context, Bits, true));
  EXPECT_EQ(PointerType::get(Context, I32), PointerType::get(Context, I32));
  EXPECT_EQ(ArrayType::get(Context, I32, 4, Count),
            ArrayType::get(Context, I32, 4, Count));
  EXPECT_EQ(VectorType::get(Context, false, I32, 4, Count),
            VectorType::get(Context, false, I32, 4, Count));
  EXPECT_NE(VectorType::get(Context, false, I32, 4, Count),
            VectorType::get(Context, true, I32, 4, Count));

  Type *Elements[] = {I8, I32};
  EXPECT_EQ(StructType::get(Context, Elements, false),
            StructType::get(Context, Elements, false));
  EXPECT_NE(StructType::get(Context, Elements, false),
            StructType::get(Context, Elements, true));
  EXPECT_EQ(FunctionType::get(Context, I32, Elements, false),
            FunctionType::get(Context, I32, Elements, false));
  EXPECT_NE(FunctionType::get(Context, I32, Elements, false),
            FunctionType::get(Context, I32, Elements, true));
}

TEST(MetaphIRConstructs, GeneratedInstructionProperties) {
  EXPECT_TRUE(Instruction::isCommutative(Instruction::I_add));
  EXPECT_FALSE(Instruction::isCommutative(Instruction::I_sub));
  EXPECT_NE(Instruction::getSupportedFlags(Instruction::I_add) &
                Instruction::mask(InstructionFlag::F_nsw),
            0u);
  EXPECT_EQ(Instruction::getSupportedFlags(Instruction::I_add) &
                Instruction::mask(InstructionFlag::F_exact),
            0u);
}

TEST(MetaphIRConstructs, UsesEnumeratedKeywordConstants) {
  EXPECT_EQ(KeywordConstant::getKeywordName(KeywordConstant::K_Poison),
            "poison");
}

TEST(MetaphIRConstructs, SeparatesKeyedOperands) {
  MIRContext Context;
  SourceRange Range;
  Type *I32 = IntegerType::get(Context, 32);
  Value *LHS =
      KeywordConstant::create(Context, KeywordConstant::K_Poison, Range);
  Value *RHS =
      KeywordConstant::create(Context, KeywordConstant::K_Undef, Range);
  Value *Predicate =
      KeywordConstant::create(Context, KeywordConstant::K_EQ, Range);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MatcherOperand Operands[] = {
      {I32, LHS, false, true, nullptr, nullptr, MatcherOperand::NotKeyed, {}},
      {I32, RHS, false, true, nullptr, nullptr, MatcherOperand::NotKeyed, {}},
      {nullptr,
       Predicate,
       false,
       false,
       nullptr,
       nullptr,
       MatcherOperand::Predicate,
       {}},
  };

  Instruction *Matcher =
      Instruction::create(Context, Instruction::I_icmp, "", {}, {}, Operands,
                          nullptr, Range, Block);
  Value *MatcherValue = Matcher;
  EXPECT_EQ(MatcherValue->getValueID(), Value::InstructionVal);
  EXPECT_EQ(cast<Instruction>(MatcherValue), Matcher);
  ASSERT_EQ(Matcher->getUnkeyedOperands().size(), 2u);
  EXPECT_EQ(Matcher->getUnkeyedOperands()[0].Val, LHS);
  EXPECT_EQ(Matcher->getUnkeyedOperands()[1].Val, RHS);
  ASSERT_NE(Matcher->getKeyedOperand(MatcherOperand::Predicate), nullptr);
  EXPECT_EQ(Matcher->getKeyedOperand(MatcherOperand::Predicate)->Val,
            Predicate);
  EXPECT_EQ(Matcher->getKeyedOperand(MatcherOperand::Alignment), nullptr);
}

TEST(MetaphIRConstructs, GeneratedExtensibilitySchemas) {
  auto Or = MetaFlag::getSchema(MetaFlag::MF_or);
  ASSERT_TRUE(Or);
  EXPECT_EQ(Or->Arguments, MetaFlag::FlagArgument);
  EXPECT_EQ(Or->AllowedPlacement, MetaFlag::OperandPlacement);
  EXPECT_FALSE(MetaFlag::getSchema(MetaFlag::UnknownMetaFlag));
  EXPECT_EQ(MetaFlag::getMetaFlagID("c"), MetaFlag::MF_c);
  EXPECT_EQ(MetaFlag::getMetaFlagID("future_flag"), MetaFlag::UnknownMetaFlag);

  auto ULT = Constraint::getOperatorSchema(Constraint::O_ULT);
  ASSERT_TRUE(ULT);
  EXPECT_EQ(ULT->Result, Constraint::BooleanResult);
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

TEST(MetaphIRConstructs, OperatorConstraintUniquesUserOperatorNames) {
  MIRContext Context;
  SourceRange Range;
  OperatorConstraint *Op1 = OperatorConstraint::createUserDefined(
      Context, Constraint::Call, Constraint::BooleanResult,
      "myCustomConstraint", {}, Range);
  OperatorConstraint *Op2 = OperatorConstraint::createUserDefined(
      Context, Constraint::Call, Constraint::BooleanResult,
      "myCustomConstraint", {}, Range);

  EXPECT_TRUE(Op1->isUserDefined());
  EXPECT_TRUE(Op2->isUserDefined());
  EXPECT_EQ(Op1->getOperatorID(), Constraint::UnknownOperator);
  EXPECT_EQ(Op2->getOperatorID(), Constraint::UnknownOperator);
  EXPECT_EQ(Op1->getOperator(), "myCustomConstraint");
  EXPECT_EQ(Op2->getOperator(), "myCustomConstraint");
  EXPECT_EQ(Op1->getOperator().data(), Op2->getOperator().data());

  // Built-in operator overload:
  OperatorConstraint *Builtin = OperatorConstraint::createBuiltin(
      Context, Constraint::Binary, Constraint::BooleanResult,
      Constraint::O_Equal, {}, Range);
  EXPECT_FALSE(Builtin->isUserDefined());
  EXPECT_EQ(Builtin->getOperatorID(), Constraint::O_Equal);
  EXPECT_EQ(Builtin->getOperator(), "==");
}

TEST(MetaphIRConstructs, MetaFlagBuiltinAndCustomVariants) {
  MIRContext Context;
  SourceRange Range;

  // Built-in MetaFlag:
  MetaFlag *Builtin =
      MetaFlag::createBuiltin(Context, MetaFlag::MF_c, {}, Range);
  EXPECT_FALSE(Builtin->isUserDefined());
  EXPECT_EQ(Builtin->getMetaFlagID(), MetaFlag::MF_c);
  EXPECT_EQ(Builtin->getName(), "c");

  // Custom / User-defined MetaFlags:
  MetaFlag *Custom1 =
      MetaFlag::createUserDefined(Context, "userFlag", {}, Range);
  MetaFlag *Custom2 =
      MetaFlag::createUserDefined(Context, "userFlag", {}, Range);
  EXPECT_TRUE(Custom1->isUserDefined());
  EXPECT_TRUE(Custom2->isUserDefined());
  EXPECT_EQ(Custom1->getMetaFlagID(), MetaFlag::UnknownMetaFlag);
  EXPECT_EQ(Custom2->getMetaFlagID(), MetaFlag::UnknownMetaFlag);
  EXPECT_EQ(Custom1->getName(), "userFlag");
  EXPECT_EQ(Custom2->getName(), "userFlag");
  // Verified to be uniqued by Saver
  EXPECT_EQ(Custom1->getName().data(), Custom2->getName().data());
}

TEST(MetaphIRConstructs, InstructionCustomOpcodeAndKeyedOperands) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);

  // Instruction without keyed operands has 0 keyed operand allocations:
  Instruction *Inst = Instruction::create(Context, Instruction::I_add, "res",
                                          {}, {}, {}, nullptr, Range, Block);
  EXPECT_EQ(Inst->getOpcodeName(), "add");
  EXPECT_EQ(Inst->getCustomOpcodeName(), "");
  EXPECT_TRUE(Inst->getKeyedOperands().empty());
  EXPECT_EQ(Inst->getKeyedOperand(MatcherOperand::Predicate), nullptr);

  // Composite instruction gets opcode name from CompositeMatcher:
  auto *CM =
      CompositeMatcher::create(Context, "myCompositeOp", false, {},
                               Instruction::OperandSyntax::Binary, 2, {}, {});
  Instruction *CompInst = Instruction::createComposite(
      Context, "cres", CM, {}, {}, {}, nullptr, Range, Block);
  EXPECT_TRUE(CompInst->isComposite());
  EXPECT_EQ(CompInst->getOpcodeName(), "myCompositeOp");
  EXPECT_EQ(CompInst->getCustomOpcodeName(), "myCompositeOp");
  EXPECT_EQ(CompInst->getCompositeMatcher(), CM);
}

// Type::get only makes primitive types; derived types have their own factory.
TEST(MetaphIRConstructs, TypeGetRejectsDerivedTypeIDs) {
  MIRContext Context;
  EXPECT_NE(Type::get(Context, Type::DoubleTyID), nullptr);
  EXPECT_DEBUG_DEATH(Type::get(Context, Type::IntegerTyID),
                     "not a primitive type");
}

// A use of a composite matcher has no built-in instruction ID.
TEST(MetaphIRConstructs, CompositeUseHasNoInstructionID) {
  MIRContext Context;
  CompositeMatcher *Matcher =
      CompositeMatcher::create(Context, "m", /*IsCommutative=*/false, {},
                               Instruction::OperandSyntax::Binary, 2, {}, {});
  Instruction *Use = Instruction::createComposite(Context, "r", Matcher, {}, {},
                                                  {}, nullptr, {}, nullptr);
  EXPECT_EQ(Use->getOpcodeName(), "m");
  EXPECT_DEBUG_DEATH(Use->getInstructionID(), "composite");
}

} // namespace
