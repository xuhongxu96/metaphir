#include "metaphir/Matching/NaiveMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Matching/Matchers.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using MIRInstruction = llvm::metaphir::Instruction;
using MIRTarget = llvm::metaphir::Target;

static std::unique_ptr<Module> parseModule(StringRef IR, LLVMContext &Context) {
  SMDiagnostic Error;
  return parseAssemblyString(IR, Error, Context);
}

TEST(NaiveMatcherTest, EnforcesRepeatedBindings) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MatcherOperand PatternOperands[] = {{nullptr, X}, {nullptr, X}};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_add, "",
                                          {}, {}, PatternOperands, nullptr,
                                          Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @same(i32 %x) {
          %r = add i32 %x, %x
          ret i32 %r
        }

        define i32 @different(i32 %x, i32 %y) {
          %r = add i32 %x, %y
          ret i32 %r
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Same(*Module->getFunction("same"));
  MIRTarget Different(*Module->getFunction("different"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Same).empty());
  EXPECT_TRUE(Matcher.match(*Pat, Different).empty());
}

TEST(NaiveMatcherTest, RequiresEveryRootAndFiltersPrograms) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::get(Context, "y", MetaType::Value, Range);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, X}};
  MatcherOperand SubOperands[] = {{nullptr, Y}, {nullptr, Y}};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_add, "",
                                          {}, {}, AddOperands, nullptr, Range,
                                          Block));
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_sub, "",
                                          {}, {}, SubOperands, nullptr, Range,
                                          Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @complete(i32 %x) {
          %a = add i32 %x, %x
          %s = sub i32 %x, %x
          ret i32 %s
        }

        define i32 @incomplete(i32 %x) {
          %a = add i32 %x, %x
          ret i32 %a
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Complete(*Module->getFunction("complete"));
  MIRTarget Incomplete(*Module->getFunction("incomplete"));
  const MIRTarget *Programs[] = {&Complete, &Incomplete};
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Complete).empty());
  EXPECT_TRUE(Matcher.match(*Pat, Incomplete).empty());
}

TEST(NaiveMatcherTest, MetaVariablesMatchTypeCompatibleInstructions) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *I =
      MetaVariable::get(Context, "i", MetaType::Instruction, Range);
  Pat->addMetaVariable(Block);
  Pat->addMetaVariable(I);
  MatcherOperand PatternOperands[] = {{nullptr, I}};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_freeze, "",
                                          {}, {}, PatternOperands, nullptr,
                                          Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @f(i32 %x) {
          %sum = add i32 %x, %x
          %result = freeze i32 %sum
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(NaiveMatcherTest, ReportsIncompleteSuccessfulInstantiationAsUnexpected) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaVariable *Unbound =
      MetaVariable::get(Context, "unbound", MetaType::Value, Range);
  Pat->addMetaVariable(Block);
  Pat->addMetaVariable(X);
  Pat->addMetaVariable(Unbound);
  MatcherOperand Operands[] = {{nullptr, X}};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_freeze, "",
                                          {}, {}, Operands, nullptr, Range,
                                          Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @f(i32 %x) {
          %result = freeze i32 %x
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  NaiveMatcher Matcher;
  EXPECT_DEATH(Matcher.match(*Pat, Program),
               "successful match did not instantiate meta variable "
               "'\\?unbound'");
}

TEST(NaiveMatcherTest, NonValueMetaTypesFailToMatchLLVMValues) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  ConstantInt *Target =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);

  for (MetaType Type : {MetaType::Type, MetaType::CmpPredicate,
                        MetaType::TypeArray, MetaType::ValueArray}) {
    MetaVariable *Variable =
        MetaVariable::get(Context, "variable", Type, Range);
    Instantiation State;
    EXPECT_FALSE(matchValue(*Variable, *Target, State));
  }
}

TEST(NaiveMatcherTest, RejectsUnknownMetaTypeAsUnexpected) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  MetaVariable *Variable =
      MetaVariable::get(Context, "unknown", MetaType::Unknown, Range);
  ConstantInt *Target =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);

  EXPECT_DEATH(
      {
        Instantiation State;
        (void)matchValue(*Variable, *Target, State);
      },
      "unexpected meta type 'Unknown'");
}

TEST(NaiveMatcherTest, RecursivelyMatchesAndBindsOperandTypes) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*Freeze, Target, State));
  ASSERT_NE(State.lookup(*Element), nullptr);
  EXPECT_EQ(*State.lookup(*Element),
            Instantiation::Binding(llvm::Type::getInt32Ty(LLVMContext)));
  ASSERT_NE(State.lookup(*Count), nullptr);
  EXPECT_EQ(*State.lookup(*Count), Instantiation::Binding(APInt(64, 4)));
}

TEST(NaiveMatcherTest, MatchesDerivedTypesAndCapturesShapeParameters) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  llvm::Type *Float = llvm::Type::getFloatTy(LLVMContext);
  llvm::Type *Pointer = llvm::PointerType::get(LLVMContext, 0);

  auto expectMatch = [](llvm::metaphir::Type *Matcher,
                        const llvm::Type *Target) {
    Instantiation State;
    EXPECT_TRUE(matchType(*Matcher, *Target, State))
        << "matcher type " << *Matcher;
  };
  auto expectNoMatch = [](llvm::metaphir::Type *Matcher,
                          const llvm::Type *Target) {
    Instantiation State;
    EXPECT_FALSE(matchType(*Matcher, *Target, State))
        << "matcher type " << *Matcher;
  };

  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::HalfTyID),
      llvm::Type::getHalfTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::BFloatTyID),
      llvm::Type::getBFloatTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::FloatTyID),
      Float);
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::DoubleTyID),
      llvm::Type::getDoubleTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::FP128TyID),
      llvm::Type::getFP128Ty(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::VoidTyID),
      llvm::Type::getVoidTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::LabelTyID),
      llvm::Type::getLabelTy(LLVMContext));
  expectMatch(llvm::metaphir::IntegerType::get(Context, 32), I32);
  expectMatch(llvm::metaphir::ByteType::get(Context, 8),
              llvm::Type::getByte8Ty(LLVMContext));
  expectMatch(llvm::metaphir::PointerType::get(Context), Pointer);

  llvm::Type *StructElements[] = {I8, I32};
  llvm::StructType *TargetStruct =
      llvm::StructType::get(LLVMContext, StructElements, false);
  llvm::StructType *PackedTargetStruct =
      llvm::StructType::get(LLVMContext, StructElements, true);
  llvm::StructType *OpaqueTargetStruct = llvm::StructType::create(LLVMContext);
  expectMatch(llvm::metaphir::StructType::get(
                  Context, {llvm::metaphir::IntegerType::get(Context, 8),
                            llvm::metaphir::IntegerType::get(Context, 32)}),
              TargetStruct);
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context,
                    {llvm::metaphir::IntegerType::get(Context, 8),
                     llvm::metaphir::IntegerType::get(Context, 32)},
                    true),
                TargetStruct);
  expectNoMatch(
      llvm::metaphir::StructType::get(
          Context, {llvm::metaphir::IntegerType::get(Context, 8)}),
      llvm::StructType::get(LLVMContext, llvm::ArrayRef<llvm::Type *>({I32})));
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context,
                    {llvm::metaphir::IntegerType::get(Context, 8),
                     llvm::metaphir::IntegerType::get(Context, 32)},
                    false),
                PackedTargetStruct);
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context, {llvm::metaphir::IntegerType::get(Context, 8),
                              llvm::metaphir::IntegerType::get(Context, 32)}),
                OpaqueTargetStruct);

  auto *Array = llvm::metaphir::ArrayType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 32), 4);
  expectMatch(Array, llvm::ArrayType::get(I32, 4));
  expectNoMatch(Array, llvm::ArrayType::get(I32, 3));

  auto *FixedVector = llvm::metaphir::VectorType::get(
      Context, false, llvm::metaphir::IntegerType::get(Context, 32), 4);
  auto *ScalableVector = llvm::metaphir::VectorType::get(
      Context, true, llvm::metaphir::IntegerType::get(Context, 32), 4);
  expectMatch(FixedVector, llvm::FixedVectorType::get(I32, 4));
  expectMatch(ScalableVector, llvm::ScalableVectorType::get(I32, 4));
  expectNoMatch(FixedVector, llvm::ScalableVectorType::get(I32, 4));

  llvm::Type *Parameters[] = {I8, Pointer};
  auto *Function = llvm::metaphir::FunctionType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 32),
      {llvm::metaphir::IntegerType::get(Context, 8),
       llvm::metaphir::PointerType::get(Context)},
      false);
  expectMatch(Function, llvm::FunctionType::get(I32, Parameters, false));
  expectNoMatch(Function, llvm::FunctionType::get(I32, Parameters, true));

  MetaVariable *Element =
      MetaVariable::get(Context, "element", MetaType::Type, Range);
  Instantiation ElementState;
  EXPECT_TRUE(matchType(*llvm::metaphir::MetaIRType::get(Context, Element),
                        *I32, ElementState));
  EXPECT_EQ(*ElementState.lookup(*Element), Instantiation::Binding(I32));

  MetaVariable *Bits = MetaVariable::get(Context, "bits", MetaType::Nat, Range);
  Instantiation BitsState;
  EXPECT_TRUE(
      matchType(*llvm::metaphir::MetaIntegerType::get(Context, Bits, false),
                *I32, BitsState));
  EXPECT_EQ(*BitsState.lookup(*Bits), Instantiation::Binding(APInt(64, 32)));

  MetaVariable *ByteBits =
      MetaVariable::get(Context, "byte_bits", MetaType::Nat, Range);
  Instantiation ByteBitsState;
  EXPECT_TRUE(
      matchType(*llvm::metaphir::MetaIntegerType::get(Context, ByteBits, true),
                *llvm::Type::getByte8Ty(LLVMContext), ByteBitsState));
  EXPECT_EQ(*ByteBitsState.lookup(*ByteBits),
            Instantiation::Binding(APInt(64, 8)));

  MetaVariable *Count =
      MetaVariable::get(Context, "count", MetaType::Nat, Range);
  auto *CountedArray = llvm::metaphir::ArrayType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 8), 0, Count);
  Instantiation CountState;
  EXPECT_TRUE(
      matchType(*CountedArray, *llvm::ArrayType::get(I8, 6), CountState));
  EXPECT_EQ(*CountState.lookup(*Count), Instantiation::Binding(APInt(64, 6)));
}

TEST(NaiveMatcherTest, BindsStandaloneResultTypes) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*ZExt, Target, State));
  ASSERT_NE(State.lookup(*ResultType), nullptr);
  EXPECT_EQ(*State.lookup(*ResultType),
            Instantiation::Binding(llvm::Type::getInt32Ty(LLVMContext)));
}

TEST(NaiveMatcherTest, EnforcesInstructionBlockMembership) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MatcherOperand Operands[] = {{nullptr, X}, {nullptr, X}};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_add, "",
                                          {}, {}, Operands, nullptr, Range,
                                          Block));
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_sub, "",
                                          {}, {}, Operands, nullptr, Range,
                                          Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @same_block(i32 %x) {
        entry:
          %a = add i32 %x, %x
          %s = sub i32 %x, %x
          ret i32 %s
        }

        define i32 @different_blocks(i32 %x) {
        entry:
          %a = add i32 %x, %x
          br label %next
        next:
          %s = sub i32 %x, %x
          ret i32 %s
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget SameBlock(*Module->getFunction("same_block"));
  MIRTarget DifferentBlocks(*Module->getFunction("different_blocks"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, SameBlock).empty());
  EXPECT_TRUE(Matcher.match(*Pat, DifferentBlocks).empty());
}

TEST(NaiveMatcherTest, AllowsInstructionOperandsFromOtherBlocks) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Entry =
      MetaVariable::get(Context, "entry", MetaType::BasicBlock, Range);
  MetaVariable *Next =
      MetaVariable::get(Context, "next", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, X}};
  MIRInstruction *Add =
      MIRInstruction::get(Context, MIRInstruction::I_add, "add", {}, {},
                          AddOperands, nullptr, Range, Entry);
  MatcherOperand FreezeOperands[] = {{nullptr, Add}};
  MIRInstruction *Freeze =
      MIRInstruction::get(Context, MIRInstruction::I_freeze, "", {}, {},
                          FreezeOperands, nullptr, Range, Next);
  Pat->addInstruction(Add);
  Pat->addInstruction(Freeze);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @cross_block(i32 %x) {
        entry:
          %add = add i32 %x, %x
          br label %next
        next:
          %result = freeze i32 %add
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("cross_block"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(NaiveMatcherTest, InstructionMatcherControlsCommutativeOperands) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  IntegerConstant *One =
      IntegerConstant::get(Context, APSInt(APInt(32, 1), false), Range);
  MatcherOperand Operands[] = {{nullptr, One}, {nullptr, X}};
  MetaFlag *Commutative = MetaFlag::get(Context, "c", {}, Range);
  MetaFlag *MetaFlags[] = {Commutative};
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_add, "",
                                          {}, MetaFlags, Operands, nullptr,
                                          Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @f(i32 %x) {
          %result = add i32 %x, 1
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(NaiveMatcherTest, ReportsUnsupportedCommutativeLayout) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaFlag *Commutative = MetaFlag::get(Context, "c", {}, Range);
  MetaFlag *Flags[] = {Commutative};
  MatcherOperand Operands[] = {{nullptr, X}};
  MIRInstruction *Freeze =
      MIRInstruction::get(Context, MIRInstruction::I_freeze, "", {}, Flags,
                          Operands, nullptr, Range, Block);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
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
        (void)matchValue(*Freeze, Target, State);
      },
      "commutative matcher 'freeze' has unsupported operand count 1");
}

TEST(NaiveMatcherTest, OrSelfAdmitsSelectedOperandAsRoot) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::get(Context, "y", MetaType::Value, Range);

  MatcherOperand SubOperands[] = {{nullptr, X}, {nullptr, Y}};
  MIRInstruction *Sub =
      MIRInstruction::get(Context, MIRInstruction::I_sub, "sub", {}, {},
                          SubOperands, nullptr, Range, Block);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, Sub}};
  MetaFlag::Argument OperandIndex;
  OperandIndex.K = MetaFlag::Argument::Integer;
  OperandIndex.IntegerValue = 1;
  MetaFlag *OrSelf = MetaFlag::get(Context, "o", OperandIndex, Range);
  MetaFlag *MetaFlags[] = {OrSelf};
  MIRInstruction *Add =
      MIRInstruction::get(Context, MIRInstruction::I_add, "", {}, MetaFlags,
                          AddOperands, nullptr, Range, Block);
  Pat->addInstruction(Sub);
  Pat->addInstruction(Add);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @f(i32 %x, i32 %y) {
          %result = sub i32 %x, %y
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(NaiveMatcherTest, BindsPredicatesAndCapturedSemanticFlags) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*Compare, TargetCompare, CompareState));
  ASSERT_NE(CompareState.lookup(*Predicate), nullptr);
  EXPECT_EQ(*CompareState.lookup(*Predicate), CmpInst::ICMP_SLT);

  Instantiation AddState;
  const llvm::Instruction &TargetAdd =
      Module->getFunction("add")->getEntryBlock().front();
  ASSERT_TRUE(matchValue(*Add, TargetAdd, AddState));
  ASSERT_NE(AddState.lookup(*HasNSW), nullptr);
  EXPECT_EQ(*AddState.lookup(*HasNSW), false);
}

TEST(NaiveMatcherTest, MatchesAndBindsKeyedIntegerOperands) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*Load, Target, State));
  ASSERT_NE(State.lookup(*Alignment), nullptr);
  EXPECT_EQ(*State.lookup(*Alignment), Instantiation::Binding(APInt(64, 8)));
}

TEST(NaiveMatcherTest, MatchesFastMathFlagsThroughInstructionInterface) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  EXPECT_TRUE(matchValue(
      *Select, Module->getFunction("with_flag")->getEntryBlock().front(),
      State));
  State = {};
  EXPECT_FALSE(matchValue(
      *Select, Module->getFunction("without_flag")->getEntryBlock().front(),
      State));
}

TEST(NaiveMatcherTest, EvaluatesOperandMetaFlags) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::get(Context);
  MetaVariable *Block =
      MetaVariable::get(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::get(Context, "x", MetaType::Value, Range);
  MetaVariable *Constant =
      MetaVariable::get(Context, "constant", MetaType::Value, Range);
  MetaFlag *AllOnes = MetaFlag::get(Context, "allones", {}, Range);
  MatcherOperand Operands[] = {{nullptr, X}, {nullptr, Constant}};
  MetaFlag *OperandFlags[] = {AllOnes};
  Operands[1].setMetaFlags(Context, OperandFlags);
  Pat->addInstruction(MIRInstruction::get(Context, MIRInstruction::I_add, "",
                                          {}, {}, Operands, nullptr, Range,
                                          Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @all_ones(i32 %x) {
          %result = add i32 %x, -1
          ret i32 %result
        }

        define i32 @not_all_ones(i32 %x) {
          %result = add i32 %x, 1
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget AllOnesTarget(*Module->getFunction("all_ones"));
  MIRTarget OtherTarget(*Module->getFunction("not_all_ones"));
  NaiveMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, AllOnesTarget).empty());
  EXPECT_TRUE(Matcher.match(*Pat, OtherTarget).empty());
}

TEST(NaiveMatcherTest, InstantiationsRepresentNonValueBindings) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Pred =
      MetaVariable::get(Context, "pred", MetaType::CmpPredicate, Range);
  Instantiation::Binding Predicate(CmpInst::ICMP_EQ);
  Instantiation::Binding OtherPredicate(CmpInst::ICMP_NE);
  Instantiation::Binding Integer(APInt(32, 17));
  Instantiation::Binding Flag(true);

  EXPECT_EQ(Predicate, Instantiation::Binding(CmpInst::ICMP_EQ));
  EXPECT_NE(Predicate, OtherPredicate);
  EXPECT_EQ(Integer, Instantiation::Binding(APInt(32, 17)));
  EXPECT_EQ(Flag, Instantiation::Binding(true));

  Instantiation State;
  State.bind(*Pred, Predicate);
  ASSERT_NE(State.lookup(*Pred), nullptr);
  EXPECT_EQ(*State.lookup(*Pred), Predicate);
}

TEST(NaiveMatcherTest, AggregateConstantsRequireMatchingShape) {
  MIRContext Context;
  SourceRange Range;
  llvm::metaphir::Type *I32 = llvm::metaphir::IntegerType::get(Context, 32);
  llvm::metaphir::Value *Elements[] = {
      IntegerConstant::get(Context, APSInt(APInt(32, 1), false), Range),
      IntegerConstant::get(Context, APSInt(APInt(32, 2), false), Range),
  };
  llvm::metaphir::Type *Types[] = {I32, I32};
  AggregateConstant *Array = AggregateConstant::get(
      Context, Types, Elements, AggregateConstant::Square, Range);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        @array = constant [2 x i32] [i32 1, i32 2]
        @wrong_elements = constant [2 x i32] [i32 1, i32 3]
        @vector = constant <2 x i32> <i32 1, i32 2>
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation ArrayBindings;
  EXPECT_TRUE(matchValue(*Array,
                         *Module->getGlobalVariable("array")->getInitializer(),
                         ArrayBindings));
  Instantiation WrongElementBindings;
  EXPECT_FALSE(matchValue(
      *Array, *Module->getGlobalVariable("wrong_elements")->getInitializer(),
      WrongElementBindings));
  Instantiation VectorBindings;
  EXPECT_FALSE(
      matchValue(*Array, *Module->getGlobalVariable("vector")->getInitializer(),
                 VectorBindings));
}

TEST(NaiveMatcherTest, CapturesTrailingCallArgumentTypesAndValues) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*Call, Target, State));
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

TEST(NaiveMatcherTest, CapturesAggregateIndicesAsValueArray) {
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
  std::unique_ptr<Module> Module = parseModule(
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
  ASSERT_TRUE(matchValue(*Extract, Target, State));
  const auto &Captured =
      std::get<Instantiation::ValueArray>(State.lookup(*Indices)->Data);
  ASSERT_EQ(Captured.size(), 2u);
  EXPECT_EQ(cast<ConstantInt>(Captured[0])->getZExtValue(), 1u);
  EXPECT_EQ(cast<ConstantInt>(Captured[1])->getZExtValue(), 0u);
}
