#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Parser/MIRParser.h"
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

std::unique_ptr<Module> parseModule(StringRef IR, LLVMContext &Context) {
  SMDiagnostic Error;
  return parseAssemblyString(IR, Error, Context);
}

Pattern *parsePattern(StringRef IR, MIRContext &Context) {
  SourceMgr SM;
  MemoryBufferRef F(IR, "<string>");
  SM.AddNewSourceBuffer(MemoryBuffer::getMemBuffer(F), SMLoc());
  SMDiagnostic Error;
  MIRParser Parser(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM,
                   Error, Context);
  Pattern *Result = nullptr;
  if (!Parser.parse(Result)) {
    // Operand metaflags are defined in the standard library, so matching
    // requires lowering to desugar them into constraints.
    Expected<PatternVariants> Lowered = PatternLowering(Context).lower(Result);
    if (!Lowered)
      llvm_unreachable("Failed to lower pattern");
    return Result;
  }
  llvm_unreachable("Failed to parse pattern");
}

TEST(End2EndTest, VectorTypeMatching) {
  LLVMContext LContext;
  MIRContext MContext;
  auto Pattern = parsePattern(
      R"(
        %trunc = trunc <?n x i?big> ?x to <?n x i?small>
        %sub = sub <?n x i?small> ?zero:zero, %trunc
        %zext = zext:?anch <?n x i?small> %sub to <?n x i?big>
      )",
      MContext);
  ASSERT_NE(Pattern, nullptr);

  auto Module = parseModule(
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

} // namespace
