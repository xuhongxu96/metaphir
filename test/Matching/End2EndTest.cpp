#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "test/TestUtils.h"
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

namespace {

TEST(End2EndTest, VectorTypeMatching) {
  LLVMContext LContext;
  MIRContext MContext;
  SourceMgr SM;
  Pattern *Pattern = test::parseAndLower(
      R"(
        %trunc = trunc <?n x i?big> ?x to <?n x i?small>
        %sub = sub <?n x i?small> ?zero:zero, %trunc
        %zext = zext:?anch <?n x i?small> %sub to <?n x i?big>
      )",
      SM, MContext);
  ASSERT_NE(Pattern, nullptr);

  auto Module = test::parseLLVMModule(
      R"(
define <2 x i128> @vec(<2 x i128> %x) {
  %t = trunc <2 x i128> %x to <2 x i64>
  %s = sub <2 x i64> zeroinitializer, %t
  %z = zext <2 x i64> %s to <2 x i128>
  ret <2 x i128> %z
}
      )",
      LContext);
  ASSERT_NE(Module, nullptr);
  ASSERT_EQ(Module->getFunctionList().size(), 1u);
  auto &Function = *Module->functions().begin();
  Target Program(Function);

  PatternMatcher Matcher;
  MatchResults Matches = Matcher.match(*Pattern, Program);
  ASSERT_EQ(Matches.size(), 1u);
}

TEST(End2EndTest, LocalInstructionAndMetaVarSameName) {
  LLVMContext LContext;
  MIRContext MContext;

  SourceMgr SM;
  Pattern *Parsed = test::parsePattern(R"(
    %foo = add i32 ?foo, ?y
    %bar = sub:?anch i32 %foo, ?foo
  )",
                                       SM, MContext);
  ASSERT_NE(Parsed, nullptr);

  Expected<PatternVariants> Lowered = PatternLowering(MContext).lower(Parsed);
  ASSERT_TRUE(static_cast<bool>(Lowered));

  auto Module = test::parseLLVMModule(
      R"(
define i32 @test(i32 %in1, i32 %in2) {
  %1 = add i32 %in1, %in2
  %2 = sub i32 %1, %in1
  ret i32 %2
}
      )",
      LContext);
  ASSERT_NE(Module, nullptr);
  auto &Function = *Module->functions().begin();
  Target Program(Function);

  PatternMatcher Matcher;
  MatchResults Matches = Matcher.match(*Lowered, Program);
  EXPECT_EQ(Matches.size(), 1u);
}

} // namespace
