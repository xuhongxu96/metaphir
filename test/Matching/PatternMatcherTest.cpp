#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "test/TestUtils.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using MIRInstruction = llvm::metaphir::Instruction;
using MIRTarget = llvm::metaphir::Target;

namespace {

TEST(PatternMatcherTest, EnforcesRepeatedBindings) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MatcherOperand PatternOperands[] = {{nullptr, X}, {nullptr, X}};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_add, "",
                                             {}, {}, PatternOperands, nullptr,
                                             Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
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
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Same).empty());
  EXPECT_TRUE(Matcher.match(*Pat, Different).empty());
}

TEST(PatternMatcherTest, RequiresEveryRootAndFiltersPrograms) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, X}};
  MatcherOperand SubOperands[] = {{nullptr, Y}, {nullptr, Y}};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_add, "",
                                             {}, {}, AddOperands, nullptr,
                                             Range, Block));
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_sub, "",
                                             {}, {}, SubOperands, nullptr,
                                             Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
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
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Complete).empty());
  EXPECT_TRUE(Matcher.match(*Pat, Incomplete).empty());
}

TEST(PatternMatcherTest, MetaVariablesMatchTypeCompatibleInstructions) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *I =
      MetaVariable::create(Context, "i", MetaType::Instruction, Range);
  Pat->addMetaVariable(Block);
  Pat->addMetaVariable(I);
  MatcherOperand PatternOperands[] = {{nullptr, I}};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_freeze,
                                             "", {}, {}, PatternOperands,
                                             nullptr, Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
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
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(PatternMatcherTest, ReportsIncompleteSuccessfulInstantiationAsUnexpected) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MetaVariable *Unbound =
      MetaVariable::create(Context, "unbound", MetaType::Value, Range);
  Pat->addMetaVariable(Block);
  Pat->addMetaVariable(X);
  Pat->addMetaVariable(Unbound);
  MatcherOperand Operands[] = {{nullptr, X}};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_freeze,
                                             "", {}, {}, Operands, nullptr,
                                             Range, Block));

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

  MIRTarget Program(*Module->getFunction("f"));
  PatternMatcher Matcher;
  EXPECT_DEATH(Matcher.match(*Pat, Program),
               "successful match did not instantiate meta variable "
               "'\\?unbound'");
}

TEST(PatternMatcherTest, EnforcesInstructionBlockMembership) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MatcherOperand Operands[] = {{nullptr, X}, {nullptr, X}};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_add, "",
                                             {}, {}, Operands, nullptr, Range,
                                             Block));
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_sub, "",
                                             {}, {}, Operands, nullptr, Range,
                                             Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
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
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, SameBlock).empty());
  EXPECT_TRUE(Matcher.match(*Pat, DifferentBlocks).empty());
}

TEST(PatternMatcherTest, AllowsInstructionOperandsFromOtherBlocks) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Entry =
      MetaVariable::create(Context, "entry", MetaType::BasicBlock, Range);
  MetaVariable *Next =
      MetaVariable::create(Context, "next", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, X}};
  MIRInstruction *Add =
      MIRInstruction::create(Context, MIRInstruction::I_add, "add", {}, {},
                             AddOperands, nullptr, Range, Entry);
  MatcherOperand FreezeOperands[] = {{nullptr, Add}};
  MIRInstruction *Freeze =
      MIRInstruction::create(Context, MIRInstruction::I_freeze, "", {}, {},
                             FreezeOperands, nullptr, Range, Next);
  Pat->addInstruction(Add);
  Pat->addInstruction(Freeze);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
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
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(PatternMatcherTest, InstructionMatcherControlsCommutativeOperands) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  IntegerConstant *One =
      IntegerConstant::create(Context, APSInt(APInt(32, 1), false), Range);
  MatcherOperand Operands[] = {{nullptr, One}, {nullptr, X}};
  MetaFlag *Commutative =
      MetaFlag::createBuiltin(Context, MetaFlag::MF_c, {}, Range);
  MetaFlag *MetaFlags[] = {Commutative};
  Pat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_add, "",
                                             {}, MetaFlags, Operands, nullptr,
                                             Range, Block));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %x) {
          %result = add i32 %x, 1
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(PatternMatcherTest, OrSelfAdmitsSelectedOperandAsRoot) {
  MIRContext Context;
  SourceRange Range;
  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);

  MatcherOperand SubOperands[] = {{nullptr, X}, {nullptr, Y}};
  MIRInstruction *Sub =
      MIRInstruction::create(Context, MIRInstruction::I_sub, "sub", {}, {},
                             SubOperands, nullptr, Range, Block);
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, Sub}};
  MetaFlag::Argument OperandIndex;
  OperandIndex.K = MetaFlag::Argument::Integer;
  OperandIndex.IntegerValue = 1;
  MetaFlag *OrSelf =
      MetaFlag::createBuiltin(Context, MetaFlag::MF_o, OperandIndex, Range);
  MetaFlag *MetaFlags[] = {OrSelf};
  MIRInstruction *Add =
      MIRInstruction::create(Context, MIRInstruction::I_add, "", {}, MetaFlags,
                             AddOperands, nullptr, Range, Block);
  Pat->addInstruction(Sub);
  Pat->addInstruction(Add);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %x, i32 %y) {
          %result = sub i32 %x, %y
          ret i32 %result
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Program(*Module->getFunction("f"));
  PatternMatcher Matcher;
  EXPECT_FALSE(Matcher.match(*Pat, Program).empty());
}

TEST(PatternMatcherTest, MatchesPatternVariants) {
  MIRContext Context;
  SourceRange Range;

  Pattern *AddPat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);
  MatcherOperand Operands[] = {{nullptr, X}, {nullptr, Y}};
  AddPat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_add,
                                                "", {}, {}, Operands, nullptr,
                                                Range, Block));

  Pattern *SubPat = Pattern::create(Context);
  SubPat->addInstruction(MIRInstruction::create(Context, MIRInstruction::I_sub,
                                                "", {}, {}, Operands, nullptr,
                                                Range, Block));

  PatternVariants Variants;
  Variants.addVariant(AddPat);
  Variants.addVariant(SubPat);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @both(i32 %a, i32 %b) {
          %1 = add i32 %a, %b
          %2 = sub i32 %a, %b
          ret i32 %1
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Target(*Module->getFunction("both"));
  PatternMatcher Matcher;
  MatchResults Matches = Matcher.match(Variants, Target);
  EXPECT_EQ(Matches.size(), 2u);
}

TEST(PatternMatcherTest, InstructionAndMetaVariableCanShareName) {
  MIRContext Context;
  SourceRange Range;

  Pattern *Pat = Pattern::create(Context);
  MetaVariable *Block =
      MetaVariable::create(Context, "block", MetaType::BasicBlock, Range);
  MetaVariable *X = MetaVariable::create(Context, "x", MetaType::Value, Range);
  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);

  // %x = add i32 ?x, ?y
  MatcherOperand AddOperands[] = {{nullptr, X}, {nullptr, Y}};
  MIRInstruction *Add =
      MIRInstruction::create(Context, MIRInstruction::I_add, "x", {}, {},
                             AddOperands, nullptr, Range, Block);
  Pat->addInstruction(Add);

  // %res = sub i32 %x, ?x
  MatcherOperand SubOperands[] = {{nullptr, Add}, {nullptr, X}};
  MIRInstruction *Sub =
      MIRInstruction::create(Context, MIRInstruction::I_sub, "res", {}, {},
                             SubOperands, nullptr, Range, Block);
  Pat->addInstruction(Sub);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %a, i32 %b) {
          %1 = add i32 %a, %b
          %2 = sub i32 %1, %a
          ret i32 %2
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  MIRTarget Target(*Module->getFunction("f"));
  PatternMatcher Matcher;
  MatchResults Matches = Matcher.match(*Pat, Target);
  EXPECT_EQ(Matches.size(), 1u);
  if (!Matches.empty()) {
    EXPECT_EQ(std::get<const llvm::Value *>(Matches[0].lookup(*X)->Data),
              Module->getFunction("f")->getArg(0));
  }
}

// The value-tracking analyses are cached per function. A function freed
// between matches can be reallocated at the same address for the next module;
// its analyses must be rebuilt, or dominating conditions of the new function
// are missed.
TEST(PatternMatcherTest, RebuildsAnalysesForReallocatedFunction) {
  MIRContext Context;
  SourceMgr SM;
  Pattern *Pat = test::parseAndLower(R"(
    %r = udiv i32 ?x, ?y
    ;; isKnownNegative(?y)
  )",
                                     SM, Context);
  ASSERT_NE(Pat, nullptr);
  PatternMatcher Matcher(&Context);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> First = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %x, i32 %y) {
          %r = udiv i32 %x, %y
          ret i32 %r
        }
      )",
      LLVMContext);
  ASSERT_NE(First, nullptr);
  const Function *FirstFunction = First->getFunction("f");
  EXPECT_TRUE(Matcher.match(*Pat, MIRTarget(*FirstFunction)).empty());
  First.reset();

  std::unique_ptr<Module> Second = test::parseLLVMModule(
      R"(
        define i32 @f(i32 %x, i32 %y) {
        entry:
          %c = icmp slt i32 %y, 0
          br i1 %c, label %then, label %else
        then:
          %r = udiv i32 %x, %y
          ret i32 %r
        else:
          ret i32 0
        }
      )",
      LLVMContext);
  ASSERT_NE(Second, nullptr);
  const Function *SecondFunction = Second->getFunction("f");
  if (SecondFunction != FirstFunction)
    GTEST_SKIP() << "the allocator did not reuse the function's address";
  EXPECT_EQ(Matcher.match(*Pat, MIRTarget(*SecondFunction)).size(), 1u);
}

} // namespace
