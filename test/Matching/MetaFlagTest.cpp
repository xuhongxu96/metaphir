#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "test/TestUtils.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
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

using MIRInstruction = llvm::metaphir::Instruction;

namespace {

MetaFlag *makeFlag(MIRContext &Context, StringRef Name,
                   ArrayRef<MetaFlag::Argument> Arguments = {},
                   SourceRange Range = {}) {
  MetaFlag::MetaFlagID ID = MetaFlag::getMetaFlagID(Name);
  if (ID != MetaFlag::UnknownMetaFlag)
    return MetaFlag::getBuiltin(Context, ID, Arguments, Range);
  return MetaFlag::getUserDefined(Context, Name, Arguments, Range);
}

Pattern *makePatternWithOperandFlag(MIRContext &Context, MetaFlag *Flag) {
  auto *X = MetaVariable::get(Context, "x", MetaType::Value, {});
  MatcherOperand Operand;
  Operand.Val = X;
  SmallVector<MetaFlag *, 1> Flags = {Flag};
  Operand.setMetaFlags(Context, Flags);

  SmallVector<MatcherOperand, 1> Operands = {Operand};
  auto *Inst = MIRInstruction::get(Context, MIRInstruction::I_add, "", {}, {},
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
  MIRInstruction *Inst =
      MIRInstruction::get(Context, MIRInstruction::I_add, "", {}, Flags, {},
                          nullptr, SourceRange{}, nullptr);
  EXPECT_TRUE(Inst->hasMetaFlag(MetaFlag::MF_c));
  EXPECT_TRUE(Inst->hasMetaFlag(MetaFlag::MF_o));
  EXPECT_FALSE(Inst->hasMetaFlag(MetaFlag::MF_not));
  EXPECT_FALSE(Inst->hasMetaFlag(MetaFlag::MF_or));
}

TEST(MetaFlagTest, PreservesMatcherHandledFlagsDuringLowering) {
  MIRContext Context;
  SmallVector<MetaFlag *, 2> Flags = {makeFlag(Context, "c"),
                                      makeFlag(Context, "o")};
  auto *Inst = MIRInstruction::get(Context, MIRInstruction::I_add, "", {},
                                   Flags, {}, nullptr, {}, nullptr);
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
  MetaVariable *ParameterVars[] = {
      MetaVariable::get(Context, "subject", MetaType::Unknown, {})};
  auto *Def = new (Context.pImpl->Alloc) MetaFlagDef(
      "broken", MetaFlag::OperandPlacement, Parameters, ParameterVars, nullptr);
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
  Pattern *P =
      makePatternWithOperandFlag(Context, makeFlag(Context, "not", Arguments));
  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
  ASSERT_FALSE(static_cast<bool>(Lowered));
  std::string Message = toString(Lowered.takeError());
  EXPECT_NE(Message.find("requires one nested flag"), std::string::npos);
}

TEST(MetaFlagTest, LowersUseCountFlagsToConstraints) {
  MIRContext Context;
  SourceMgr SM;
  Pattern *P = test::parseAndLower(
      R"(
        %r = add:s i32 ?x:su, ?y
      )",
      SM, Context);
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
  SourceMgr SM;
  Pattern *P = test::parseAndLower(
      R"(
        %r = add i32 ?x:or(:s, :su), ?y:not(:s)
      )",
      SM, Context);
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

TEST(MetaFlagTest,
     NonDestructiveDesugaringPreservesFlagsAndAvoidsSyntheticCapture) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(
      R"(
        %r = add:s i32 ?x:su, ?y
      )",
      SM, Context);
  ASSERT_NE(P, nullptr);
  ASSERT_EQ(P->getInstructions().size(), 1u);
  MIRInstruction *I = P->getInstructions().front();

  // Before lowering: instruction has :s, operand ?x has :su, capture is null.
  EXPECT_EQ(I->getCapture(), nullptr);
  EXPECT_EQ(I->getMetaFlags().size(), 1u);
  EXPECT_EQ(I->getMetaFlags()[0]->getName(), "s");
  ASSERT_GE(I->getUnkeyedOperands().size(), 1u);
  EXPECT_EQ(I->getUnkeyedOperands()[0].MetaFlags.size(), 1u);
  EXPECT_EQ(I->getUnkeyedOperands()[0].MetaFlags[0]->getName(), "su");

  // Run lowering.
  auto VariantsOrErr = PatternLowering(Context).lower(P);
  ASSERT_TRUE(static_cast<bool>(VariantsOrErr));
  ASSERT_EQ(VariantsOrErr->getVariants().size(), 1u);
  Pattern *Variant = VariantsOrErr->getVariants().front();

  // After lowering: instruction and operand metaflags MUST NOT be stripped or
  // mutated.
  EXPECT_EQ(I->getCapture(), nullptr);
  EXPECT_EQ(I->getMetaFlags().size(), 1u);
  EXPECT_EQ(I->getMetaFlags()[0]->getName(), "s");
  EXPECT_EQ(I->getUnkeyedOperands()[0].MetaFlags.size(), 1u);
  EXPECT_EQ(I->getUnkeyedOperands()[0].MetaFlags[0]->getName(), "su");

  // Constraints should have been generated and added to Variant.
  ASSERT_EQ(Variant->getConstraints().size(), 2u);

  // Check that the constraint for :s directly targets MIRInstruction *I as its
  // subject.
  bool FoundDirectInstSubject = false;
  for (const Constraint *C : Variant->getConstraints()) {
    if (const auto *OC = dyn_cast<OperatorConstraint>(C)) {
      if (OC->getOperator() == "hasOneUse" && !OC->getArguments().empty()) {
        if (const auto *VC =
                dyn_cast<VariableConstraint>(OC->getArguments().front())) {
          if (VC->getVariable() == I)
            FoundDirectInstSubject = true;
        }
      }
    }
  }
  EXPECT_TRUE(FoundDirectInstSubject);
}

TEST(MetaFlagTest, CompositeInliningSharesPrecedingAndCOWDownstream) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(
      R"(
        match foldTest [] Binary (?ty ?a, ?b) {
          %r1 = add ?ty ?a, ?b
        } or {
          %r2 = sub ?ty ?a, ?b
        }

        %prec = mul i32 ?x, ?y
        %mid = foldTest i32 %prec, ?z
        %down_indep = xor i32 ?x, ?y
        %down_dep = and i32 %mid, ?z
      )",
      SM, Context);
  ASSERT_NE(P, nullptr);
  ASSERT_EQ(P->getInstructions().size(), 4u);
  MIRInstruction *OrigPrec = P->getInstructions()[0];
  MIRInstruction *OrigComp = P->getInstructions()[1];
  (void)OrigComp;
  MIRInstruction *OrigDownIndep = P->getInstructions()[2];
  MIRInstruction *OrigDownDep = P->getInstructions()[3];

  auto VariantsOrErr = PatternLowering(Context).lower(P);
  ASSERT_TRUE(static_cast<bool>(VariantsOrErr));
  ASSERT_EQ(VariantsOrErr->getVariants().size(), 2u);

  Pattern *V0 = VariantsOrErr->getVariants()[0];
  Pattern *V1 = VariantsOrErr->getVariants()[1];

  // Each branch has: %prec, inlined branch inst (%r1 or %r2), %down_indep,
  // %down_dep.
  ASSERT_EQ(V0->getInstructions().size(), 4u);
  ASSERT_EQ(V1->getInstructions().size(), 4u);

  // 1. Preceding instruction (%prec) is shared across all branches by raw
  // pointer (0 copies).
  EXPECT_EQ(V0->getInstructions()[0], OrigPrec);
  EXPECT_EQ(V1->getInstructions()[0], OrigPrec);

  // 2. Downstream independent instruction (%down_indep) doesn't use inlined
  // insts, so it is also shared by raw pointer.
  EXPECT_EQ(V0->getInstructions()[2], OrigDownIndep);
  EXPECT_EQ(V1->getInstructions()[2], OrigDownIndep);

  // 3. Downstream dependent instruction (%down_dep) uses %mid, so it is COW
  // duplicated.
  EXPECT_NE(V0->getInstructions()[3], OrigDownDep);
  EXPECT_NE(V1->getInstructions()[3], OrigDownDep);
  EXPECT_NE(V0->getInstructions()[3], V1->getInstructions()[3]);

  // The duplicated instruction shares ResultName slice without re-saving.
  EXPECT_EQ(V0->getInstructions()[3]->getResultName().data(),
            OrigDownDep->getResultName().data());
  EXPECT_EQ(V1->getInstructions()[3]->getResultName().data(),
            OrigDownDep->getResultName().data());

  // Operand 0 of %down_dep is remapped to the respective inlined root.
  EXPECT_EQ(V0->getInstructions()[3]->getUnkeyedOperands()[0].Val,
            V0->getInstructions()[1]);
  EXPECT_EQ(V1->getInstructions()[3]->getUnkeyedOperands()[0].Val,
            V1->getInstructions()[1]);
}

TEST(MetaFlagTest, DirectInstructionSubjectEndToEndMatching) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(
      R"(
        %sat = call:s i32 @llvm.uadd.sat(i32 ?x, i32 ?c)
        %res = add i32 %sat, ?c
      )",
      SM, Context);
  ASSERT_NE(P, nullptr);

  auto VariantsOrErr = PatternLowering(Context).lower(P);
  ASSERT_TRUE(static_cast<bool>(VariantsOrErr));

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = test::parseLLVMModule(
      R"(
        declare i32 @llvm.uadd.sat.i32(i32, i32)

        define i32 @single_use(i32 %x, i32 %c) {
          %sat = call i32 @llvm.uadd.sat.i32(i32 %x, i32 %c)
          %res = add i32 %sat, %c
          ret i32 %res
        }

        define i32 @multi_use(i32 %x, i32 %c) {
          %sat = call i32 @llvm.uadd.sat.i32(i32 %x, i32 %c)
          %extra = mul i32 %sat, 2
          %res = add i32 %sat, %c
          ret i32 %res
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  PatternMatcher Matcher;
  ConstraintInterpreter Interpreter(&Context);
  const Pattern *Variant = VariantsOrErr->getVariants().front();

  Target SingleTarget(*Module->getFunction("single_use"));
  MatchResults SingleMatches = Matcher.match(*Variant, SingleTarget);
  ASSERT_EQ(SingleMatches.size(), 1u);
  // Verify constraints evaluate to true on single_use.
  for (const Constraint *C : Variant->getConstraints()) {
    Expected<ConstraintValue> Res = Interpreter.evaluate(*C, SingleMatches[0]);
    ASSERT_TRUE(static_cast<bool>(Res));
    EXPECT_TRUE(Res->getBoolean());
  }

  Target MultiTarget(*Module->getFunction("multi_use"));
  MatchResults MultiMatches = Matcher.match(*Variant, MultiTarget);
  ASSERT_EQ(MultiMatches.size(), 1u);
  // Verify constraint hasOneUse(%sat) evaluates to false on multi_use.
  bool ConstraintSatisfied = true;
  for (const Constraint *C : Variant->getConstraints()) {
    Expected<ConstraintValue> Res = Interpreter.evaluate(*C, MultiMatches[0]);
    if (!Res || !Res->getBoolean())
      ConstraintSatisfied = false;
  }
  EXPECT_FALSE(ConstraintSatisfied);
}

// Lowering builds new patterns and leaves its input untouched, so lowering the
// same pattern twice gives the same result.
TEST(MetaFlagTest, LoweringLeavesItsInputUnchanged) {
  MIRContext Context;
  SourceMgr SM;
  Pattern *P = test::parsePattern("%r = add:s i32 ?x:su, ?y\n", SM, Context);
  ASSERT_NE(P, nullptr);
  ASSERT_TRUE(P->getConstraints().empty());
  for (int Round = 0; Round != 2; ++Round) {
    Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
    ASSERT_TRUE(static_cast<bool>(Lowered));
    ASSERT_EQ(Lowered->size(), 1u);
    EXPECT_NE((*Lowered)[0], P);
    EXPECT_EQ((*Lowered)[0]->getConstraints().size(), 2u);
  }
  EXPECT_TRUE(P->getConstraints().empty());
}

} // namespace
