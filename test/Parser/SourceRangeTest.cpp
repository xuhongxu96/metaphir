// Every meta variable carries a source range. MetaVariable::get requires one,
// so the interesting cases are the ones a caller could previously have left
// empty by omission: the parameters of a 'constraint' or 'metaflag' definition,
// the parameters bound per branch of a 'match', and the variables
// PatternLowering synthesizes.

#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/Parser/MIRParser.h"
#include "test/TestUtils.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// Line and column the range points at, one-based, as SourceMgr reports them.
std::pair<unsigned, unsigned> lineAndColumn(const SourceMgr &SM,
                                            SourceRange Range) {
  auto LC = SM.getLineAndColumn(Range.Begin);
  return {LC.first, LC.second};
}

TEST(SourceRangeTest, ConstraintDefinitionParameters) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(R"(constraint pair(?a, ?b) {
	?a == ?b
}

%r = add i32 ?x, ?y
)",
                                  SM, Context);
  ASSERT_NE(P, nullptr);

  ConstraintDef *Def = Context.getConstraintDef("pair");
  ASSERT_NE(Def, nullptr);
  ASSERT_EQ(Def->getParameterVars().size(), 2u);
  for (MetaVariable *V : Def->getParameterVars())
    EXPECT_TRUE(V->getSourceRange().Begin.isValid());

  // '?a' and '?b' are on the first line, at their own columns.
  EXPECT_EQ(lineAndColumn(SM, Def->getParameterVars()[0]->getSourceRange()),
            std::make_pair(1u, 17u));
  EXPECT_EQ(lineAndColumn(SM, Def->getParameterVars()[1]->getSourceRange()),
            std::make_pair(1u, 21u));
}

TEST(SourceRangeTest, MetaFlagDefinitionParameters) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(R"(metaflag :between(?v, ?lo, ?hi) {
	sle(?lo, ?v) && sle(?v, ?hi)
}

%r = add i32 ?x, ?c:between(1, 2)
)",
                                  SM, Context);
  ASSERT_NE(P, nullptr);

  MetaFlagDef *Def = Context.getMetaFlagDef("between");
  ASSERT_NE(Def, nullptr);
  ASSERT_EQ(Def->getParameterVars().size(), 3u);
  for (MetaVariable *V : Def->getParameterVars()) {
    EXPECT_TRUE(V->getSourceRange().Begin.isValid());
    // All three are declared on the first line.
    EXPECT_EQ(lineAndColumn(SM, V->getSourceRange()).first, 1u);
  }
}

TEST(SourceRangeTest, MatchParametersBoundPerBranch) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(R"(match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addm i32 ?a, ?b
)",
                                  SM, Context);
  ASSERT_NE(P, nullptr);

  CompositeMatcher *CM = Context.getCompositeMatcher("addm");
  ASSERT_NE(CM, nullptr);
  ASSERT_EQ(CM->getParameters().size(), 3u);
  for (const ParameterDef &Param : CM->getParameters()) {
    EXPECT_TRUE(Param.Range.Begin.isValid());
    EXPECT_EQ(lineAndColumn(SM, Param.Range).first, 1u);
  }
}

TEST(SourceRangeTest, InstructionDirectSubjectConstraint) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = test::parsePattern(R"(metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

%r = add:isaddop i32 ?x, ?y
)",
                                  SM, Context);
  ASSERT_NE(P, nullptr);
  ASSERT_EQ(P->getInstructions().size(), 1u);

  // The pattern named no capture. Lowering does not mutate or synthesize a
  // capture on the instruction; instead, the constraint directly targets the
  // instruction node.
  metaphir::Instruction *I = P->getInstructions().front();
  ASSERT_EQ(I->getCapture(), nullptr);
  auto VariantsOrErr = PatternLowering(Context).lower(P);
  ASSERT_TRUE(static_cast<bool>(VariantsOrErr));
  EXPECT_EQ(I->getCapture(), nullptr);
  ASSERT_EQ(VariantsOrErr->getVariants().size(), 1u);
  Pattern *Variant = VariantsOrErr->getVariants().front();
  ASSERT_FALSE(Variant->getConstraints().empty());
  // The first argument of the binary opcode check is (opcode %r), whose
  // operand is the Instruction itself.
  auto *C = dyn_cast<OperatorConstraint>(Variant->getConstraints().front());
  ASSERT_NE(C, nullptr);
  ASSERT_GE(C->getArguments().size(), 1u);
  auto *OpcodeCall = dyn_cast<OperatorConstraint>(C->getArguments().front());
  ASSERT_NE(OpcodeCall, nullptr);
  ASSERT_EQ(OpcodeCall->getArguments().size(), 1u);
  auto *VarC = dyn_cast<VariableConstraint>(OpcodeCall->getArguments().front());
  ASSERT_NE(VarC, nullptr);
  EXPECT_EQ(VarC->getVariable(), I);
}

} // namespace
