#include "metaphir/Matching/InstructionMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Values.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/SubtreeMatcher.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"
#include "test/TestUtils.h"

using namespace llvm;
using namespace llvm::metaphir;
using MIRInstruction = llvm::metaphir::Instruction;

namespace {

// Matches a single instruction matcher against a target instruction by
// constructing an InstructionMatcher directly (backed by a fresh
// SubtreeMatcher), storing the first successful instantiation.
bool matchesInstruction(const MIRInstruction &Pat,
                        const llvm::Instruction &Target, Instantiation &State) {
  MatchResults Results = InstructionMatcher(Pat, Target, State).match();
  if (Results.empty())
    return false;
  State = std::move(Results.front());
  return true;
}

TEST(InstructionMatcherTest, RecursivelyMatchesAndBindsOperandTypes) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *Element =
      MetaVariable::get(Context, "element", MetaType::Type, Range);
  MetaVariable *Count =
      MetaVariable::get(Context, "count", MetaType::Nat, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  llvm::metaphir::Type *Array = llvm::metaphir::ArrayType::get(
      Context, MetaIRType::get(Context, Element), 0, Count);
  MatcherOperand Operands[] = {{Array, X}};
  MIRInstruction *Freeze =
      MIRInstruction::get(Context, MIRInstruction::I_freeze, "", {}, {},
                          Operands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define [4 x i32] @f([4 x i32] %x) {
          %result = freeze [4 x i32] %x
          ret [4 x i32] %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation State;
  const llvm::Instruction &Target =
      Module->getFunction("f")->getEntryBlock().front();
  ASSERT_TRUE(matchesInstruction(*Freeze, Target, State));
  ASSERT_NE(State.lookup(*Element), nullptr);
  EXPECT_EQ(*State.lookup(*Element),
            Instantiation::Binding(llvm::Type::getInt32Ty(LLVMContext)));
  ASSERT_NE(State.lookup(*Count), nullptr);
  EXPECT_EQ(*State.lookup(*Count), Instantiation::Binding(APInt(64, 4)));
}

TEST(InstructionMatcherTest, BindsStandaloneResultTypes) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *ResultType =
      MetaVariable::get(Context, "result_type", MetaType::Type, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MatcherOperand Operands[] = {
      {llvm::metaphir::IntegerType::get(Context, 8), X},
      {MetaIRType::get(Context, ResultType), nullptr, false, false},
  };
  MIRInstruction *ZExt =
      MIRInstruction::get(Context, MIRInstruction::I_zext, "", {}, {}, Operands,
                          nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(i8 %x) {
          %result = zext i8 %x to i32
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation State;
  const llvm::Instruction &Target =
      Module->getFunction("f")->getEntryBlock().front();
  ASSERT_TRUE(matchesInstruction(*ZExt, Target, State));
  ASSERT_NE(State.lookup(*ResultType), nullptr);
  EXPECT_EQ(*State.lookup(*ResultType),
            Instantiation::Binding(llvm::Type::getInt32Ty(LLVMContext)));
}

TEST(InstructionMatcherTest, ReportsUnsupportedCommutativeLayout) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaFlag *Commutative =
      MetaFlag::getBuiltin(Context, MetaFlag::MF_c, {}, Range);
  MetaFlag *Flags[] = {Commutative};
  MatcherOperand Operands[] = {{nullptr, X}};
  MIRInstruction *Freeze =
      MIRInstruction::get(Context, MIRInstruction::I_freeze, "", {}, Flags,
                          Operands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %x) {
          %result = freeze i32 %x
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);
  const llvm::Instruction &Target =
      Module->getFunction("f")->getEntryBlock().front();

  EXPECT_DEATH(
      {
        Instantiation State;
        (void)matchesInstruction(*Freeze, Target, State);
      },
      "commutative matcher 'freeze' has unsupported operand count 1");
}

TEST(InstructionMatcherTest, BindsPredicatesAndCapturedSemanticFlags) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::get(Context, "y", MetaType::Value, Range);
  MetaVariable *Predicate =
      MetaVariable::get(Context, "predicate", MetaType::CmpPredicate, Range);
  MetaVariable *HasNSW =
      MetaVariable::get(Context, "has_nsw", MetaType::Bool, Range);

  MatcherOperand CompareOperands[] = {
      {nullptr, Predicate, false, false, nullptr, nullptr,
       MatcherOperand::Predicate},
      {nullptr, X},
      {nullptr, Y},
  };
  MIRInstruction *Compare =
      MIRInstruction::get(Context, MIRInstruction::I_icmp, "", {}, {},
                          CompareOperands, nullptr, Range, Block);
  InstructionFlag Flags[] = {{InstructionFlag::F_nsw, HasNSW}};
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, Y}};
  MIRInstruction *Add =
      MIRInstruction::get(Context, MIRInstruction::I_add, "", Flags, {},
                          AddOperands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i1 @compare(i32 %x, i32 %y) {
          %result = icmp slt i32 %x, %y
          ret i1 %result
        }

        define i32 @add(i32 %x, i32 %y) {
          %result = add i32 %x, %y
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation CompareState;
  const llvm::Instruction &TargetCompare =
      Module->getFunction("compare")->getEntryBlock().front();
  ASSERT_TRUE(matchesInstruction(*Compare, TargetCompare, CompareState));
  ASSERT_NE(CompareState.lookup(*Predicate), nullptr);
  EXPECT_EQ(*CompareState.lookup(*Predicate), CmpInst::ICMP_SLT);

  Instantiation AddState;
  const llvm::Instruction &TargetAdd =
      Module->getFunction("add")->getEntryBlock().front();
  ASSERT_TRUE(matchesInstruction(*Add, TargetAdd, AddState));
  ASSERT_NE(AddState.lookup(*HasNSW), nullptr);
  EXPECT_EQ(*AddState.lookup(*HasNSW), false);
}

TEST(InstructionMatcherTest, MatchesAndBindsKeyedIntegerOperands) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *Pointer =
      MetaVariable::get(Context, "pointer", MetaType::Value, Range);
  MetaVariable *Alignment =
      MetaVariable::get(Context, "alignment", MetaType::Nat, Range);

  MatcherOperand TypeOnly;
  TypeOnly.Ty = llvm::metaphir::IntegerType::get(Context, 32);
  TypeOnly.IsInstructionOperand = false;
  MatcherOperand PointerOperand{llvm::metaphir::PointerType::get(Context),
                                Pointer};
  MatcherOperand AlignmentOperand;
  AlignmentOperand.Val = Alignment;
  AlignmentOperand.IsInstructionOperand = false;
  AlignmentOperand.Key = MatcherOperand::Alignment;
  MatcherOperand Operands[] = {TypeOnly, PointerOperand, AlignmentOperand};
  MIRInstruction *Load =
      MIRInstruction::get(Context, MIRInstruction::I_load, "", {}, {}, Operands,
                          nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(ptr %pointer) {
          %result = load i32, ptr %pointer, align 8
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation State;
  const llvm::Instruction &Target =
      Module->getFunction("f")->getEntryBlock().front();
  ASSERT_TRUE(matchesInstruction(*Load, Target, State));
  ASSERT_NE(State.lookup(*Alignment), nullptr);
  EXPECT_EQ(*State.lookup(*Alignment), Instantiation::Binding(APInt(64, 8)));
}

TEST(InstructionMatcherTest, MatchesFastMathFlagsThroughInstructionInterface) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *Condition =
      MetaVariable::get(Context, "condition", MetaType::Bool, Range);
  MetaVariable *TrueValue =
      MetaVariable::get(Context, "true_value", MetaType::Value, Range);
  MetaVariable *FalseValue =
      MetaVariable::get(Context, "false_value", MetaType::Value, Range);
  InstructionFlag Flags[] = {{InstructionFlag::F_nnan, nullptr}};
  MatcherOperand Operands[] = {
      {nullptr, Condition},
      {nullptr, TrueValue},
      {nullptr, FalseValue},
  };
  MIRInstruction *Select =
      MIRInstruction::get(Context, MIRInstruction::I_select, "", Flags, {},
                          Operands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define float @with_flag(i1 %condition, float %x, float %y) {
          %result = select nnan i1 %condition, float %x, float %y
          ret float %result
        }

        define float @without_flag(i1 %condition, float %x, float %y) {
          %result = select i1 %condition, float %x, float %y
          ret float %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation State;
  EXPECT_TRUE(matchesInstruction(
      *Select, Module->getFunction("with_flag")->getEntryBlock().front(),
      State));
  State = {};
  EXPECT_FALSE(matchesInstruction(
      *Select, Module->getFunction("without_flag")->getEntryBlock().front(),
      State));
}

TEST(InstructionMatcherTest, CapturesTrailingCallArgumentTypesAndValues) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *Prefix =
      MetaVariable::get(Context, "prefix", MetaType::Value, Range);
  MetaVariable *Types =
      MetaVariable::get(Context, "types", MetaType::TypeArray, Range);
  MetaVariable *Values =
      MetaVariable::get(Context, "values", MetaType::ValueArray, Range);
  llvm::metaphir::Type *I32 = llvm::metaphir::IntegerType::get(Context, 32);
  MatcherOperand Operands[] = {
      {I32, nullptr, false, false},
      {nullptr, llvm::metaphir::GlobalValue::get(Context, "callee", Range)},
      {I32, Prefix},
      {nullptr, nullptr, true, true, Types, Values},
  };
  MIRInstruction *Call =
      MIRInstruction::get(Context, MIRInstruction::I_call, "", {}, {}, Operands,
                          nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        declare i32 @callee(i32, i8, ptr)
        define i32 @caller(i32 %x, i8 %y, ptr %p) {
          %result = call i32 @callee(i32 %x, i8 %y, ptr %p)
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);
  const llvm::Instruction &Target =
      Module->getFunction("caller")->getEntryBlock().front();

  Instantiation State;
  ASSERT_TRUE(matchesInstruction(*Call, Target, State));
  const auto &CapturedTypes =
      std::get<Instantiation::TypeArray>(State.lookup(*Types)->Data);
  const auto &CapturedValues =
      std::get<Instantiation::ValueArray>(State.lookup(*Values)->Data);
  ASSERT_EQ(CapturedTypes.size(), 2u);
  EXPECT_TRUE(CapturedTypes[0]->isIntegerTy(8));
  EXPECT_TRUE(CapturedTypes[1]->isPointerTy());
  ASSERT_EQ(CapturedValues.size(), 2u);
  EXPECT_EQ(CapturedValues[0]->getName(), "y");
  EXPECT_EQ(CapturedValues[1]->getName(), "p");
}

TEST(InstructionMatcherTest, CapturesAggregateIndicesAsValueArray) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *Aggregate =
      MetaVariable::get(Context, "aggregate", MetaType::Value, Range);
  MetaVariable *Indices =
      MetaVariable::get(Context, "indices", MetaType::ValueArray, Range);
  llvm::metaphir::Type *I8 = llvm::metaphir::IntegerType::get(Context, 8);
  llvm::metaphir::Type *I16 = llvm::metaphir::IntegerType::get(Context, 16);
  llvm::metaphir::Type *I32 = llvm::metaphir::IntegerType::get(Context, 32);
  llvm::metaphir::Type *InnerElements[] = {I8, I16};
  llvm::metaphir::Type *Inner =
      llvm::metaphir::StructType::get(Context, InnerElements);
  llvm::metaphir::Type *OuterElements[] = {I32, Inner};
  llvm::metaphir::Type *Outer =
      llvm::metaphir::StructType::get(Context, OuterElements);
  MatcherOperand Operands[] = {
      {Outer, Aggregate},
      {nullptr, nullptr, true, true, nullptr, Indices},
  };
  MIRInstruction *Extract =
      MIRInstruction::get(Context, MIRInstruction::I_extractvalue, "", {}, {},
                          Operands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i8 @extract({i32, {i8, i16}} %aggregate) {
          %result = extractvalue {i32, {i8, i16}} %aggregate, 1, 0
          ret i8 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);
  const llvm::Instruction &Target =
      Module->getFunction("extract")->getEntryBlock().front();

  Instantiation State;
  ASSERT_TRUE(matchesInstruction(*Extract, Target, State));
  const auto &Captured =
      std::get<Instantiation::ValueArray>(State.lookup(*Indices)->Data);
  ASSERT_EQ(Captured.size(), 2u);
  EXPECT_EQ(cast<ConstantInt>(Captured[0])->getZExtValue(), 1u);
  EXPECT_EQ(cast<ConstantInt>(Captured[1])->getZExtValue(), 0u);
}

} // namespace
