#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/Values.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

// Built-in metaflags (:c, :o, :or, :not) are defined in MetaFlags.def.
// Use count flags (:s, :su) and predicate flags (:zero, etc.) are standard
// library 'metaflag' definitions that PatternLowering desugars into
// constraints.

using namespace llvm;
using namespace llvm::metaphir;

namespace {

MetaFlag *makeFlag(MIRContext &Context, StringRef Name,
                   ArrayRef<MetaFlag::Argument> Arguments = {},
                   SourceRange Range = {}) {
  return MetaFlag::get(Context, Name, Arguments, Range);
}

static Pattern *parseAndLowerPattern(StringRef IR, MIRContext &Context) {
  SourceMgr SM;
  SMDiagnostic Error;
  std::unique_ptr<MemoryBuffer> Buf = MemoryBuffer::getMemBuffer(IR);
  SM.AddNewSourceBuffer(std::move(Buf), SMLoc());
  MIRParser Parser(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM,
                   Error, Context);
  Pattern *Result = nullptr;
  if (!Parser.parse(Result)) {
    Expected<PatternVariants> Lowered = PatternLowering(Context).lower(Result);
    if (!Lowered)
      return nullptr;
    return Result;
  }
  return nullptr;
}

static Pattern *makePatternWithOperandFlag(MIRContext &Context,
                                           MetaFlag *Flag) {
  auto *X = MetaVariable::get(Context, "x", MetaType::Value, {});
  MatcherOperand Operand;
  Operand.Val = X;
  SmallVector<MetaFlag *, 1> Flags = {Flag};
  Operand.setMetaFlags(Context, Flags);

  SmallVector<MatcherOperand, 1> Operands = {Operand};
  auto *Inst = Instruction::get(Context, Instruction::I_add, "", {}, {},
                                Operands, nullptr, {}, nullptr);
  Pattern *P = Pattern::get(Context);
  P->addInstruction(Inst);
  return P;
}

TEST(MetaFlagTest, InstructionHasMetaFlagSearchesByID) {
  MIRContext Context;
  SmallVector<MetaFlag *, 4> Flags = {
      makeFlag(Context, "c"),
      makeFlag(Context, "o", {{MetaFlag::Argument::Integer, 42}})};
  Instruction *Inst =
      Instruction::get(Context, Instruction::I_add, "", {}, Flags, {}, nullptr,
                       SourceRange{}, nullptr);
  EXPECT_TRUE(Inst->hasMetaFlag(MetaFlag::MF_c));
  EXPECT_TRUE(Inst->hasMetaFlag(MetaFlag::MF_o));
  EXPECT_FALSE(Inst->hasMetaFlag(MetaFlag::MF_not));
  EXPECT_FALSE(Inst->hasMetaFlag(MetaFlag::MF_or));
}

TEST(MetaFlagTest, PreservesMatcherHandledFlagsDuringLowering) {
  MIRContext Context;
  SmallVector<MetaFlag *, 2> Flags = {makeFlag(Context, "c"),
                                      makeFlag(Context, "o")};
  auto *Inst = Instruction::get(Context, Instruction::I_add, "", {}, Flags,
                                {}, nullptr, {}, nullptr);
  Pattern *P = Pattern::get(Context);
  P->addInstruction(Inst);

  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
  ASSERT_TRUE(static_cast<bool>(Lowered));
  ASSERT_EQ(P->getConstraints().size(), 0u);
  ASSERT_EQ(P->getInstructions()[0]->getMetaFlags().size(), 2u);
}

TEST(MetaFlagTest, ReportsMalformedMetaFlagDefinition) {
  MIRContext Context;
  StringRef Parameters[] = {"subject"};
  auto *Def = new (Context.pImpl->Alloc)
      MetaFlagDef("broken", MetaFlag::OperandPlacement, Parameters, {}, nullptr);
  Context.registerMetaFlagDef(Def);

  Pattern *P = makePatternWithOperandFlag(Context, makeFlag(Context, "broken"));
  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
  ASSERT_FALSE(static_cast<bool>(Lowered));
  std::string Message = toString(Lowered.takeError());
  EXPECT_NE(Message.find("empty body"), std::string::npos);
}

TEST(MetaFlagTest, ReportsUnlowerableNotChild) {
  MIRContext Context;
  MetaFlag::Argument BadArgument;
  BadArgument.K = MetaFlag::Argument::Flag;
  BadArgument.FlagValue = nullptr;
  ArrayRef<MetaFlag::Argument> Arguments(&BadArgument, 1);
  Pattern *P = makePatternWithOperandFlag(
      Context, makeFlag(Context, "not", Arguments));
  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
  ASSERT_FALSE(static_cast<bool>(Lowered));
  std::string Message = toString(Lowered.takeError());
  EXPECT_NE(Message.find("requires one nested flag"), std::string::npos);
}

TEST(MetaFlagTest, LowersUseCountFlagsToConstraints) {
  MIRContext Context;
  Pattern *P = parseAndLowerPattern(
      R"(
        %r = add:s i32 ?x:su, ?y
      )",
      Context);
  ASSERT_NE(P, nullptr);
  // :s on the instruction lowers to hasOneUse(%r), :su on ?x lowers to
  // hasOneUser(?x).
  ASSERT_EQ(P->getConstraints().size(), 2u);

  std::string C0Text, C1Text;
  raw_string_ostream S0(C0Text), S1(C1Text);
  S0 << *P->getConstraints()[0];
  S1 << *P->getConstraints()[1];
  EXPECT_TRUE(C0Text.find("hasOneUse") != std::string::npos ||
              C1Text.find("hasOneUse") != std::string::npos);
  EXPECT_TRUE(C0Text.find("hasOneUser") != std::string::npos ||
              C1Text.find("hasOneUser") != std::string::npos);
}

TEST(MetaFlagTest, LowersOrAndNotCombinatorsWithUseCountFlags) {
  MIRContext Context;
  Pattern *P = parseAndLowerPattern(
      R"(
        %r = add i32 ?x:or(:s, :su), ?y:not(:s)
      )",
      Context);
  ASSERT_NE(P, nullptr);
  // :or(:s, :su) lowers to (|| (hasoneuse ?x) (hasoneuser ?x))
  // :not(:s) lowers to (! (hasoneuse ?y))
  ASSERT_EQ(P->getConstraints().size(), 2u);

  std::string C0Text, C1Text;
  raw_string_ostream S0(C0Text), S1(C1Text);
  S0 << *P->getConstraints()[0];
  S1 << *P->getConstraints()[1];

  EXPECT_TRUE(C0Text.find("||") != std::string::npos ||
              C1Text.find("||") != std::string::npos);
  EXPECT_TRUE(C0Text.find("!") != std::string::npos ||
              C1Text.find("!") != std::string::npos);
}

} // namespace
