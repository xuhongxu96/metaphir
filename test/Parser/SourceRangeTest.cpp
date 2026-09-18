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
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// Parses Source, returning the pattern and leaving the definitions registered
// in Context.
Pattern *parsePattern(StringRef Source, SourceMgr &SM, MIRContext &Context) {
  MemoryBufferRef Buffer(Source, "<test>");
  SM.AddNewSourceBuffer(MemoryBuffer::getMemBuffer(Buffer), SMLoc());
  SMDiagnostic Error;
  MIRParser Parser(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM,
                   Error, Context);
  Pattern *Result = nullptr;
  if (Parser.parse(Result))
    return nullptr;
  return Result;
}

// Line and column the range points at, one-based, as SourceMgr reports them.
std::pair<unsigned, unsigned> lineAndColumn(const SourceMgr &SM,
                                            SourceRange Range) {
  auto LC = SM.getLineAndColumn(Range.Begin);
  return {LC.first, LC.second};
}

TEST(SourceRangeTest, ConstraintDefinitionParameters) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = parsePattern(R"(constraint pair(?a, ?b) {
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
  Pattern *P = parsePattern(R"(metaflag :between(?v, ?lo, ?hi) {
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
  Pattern *P = parsePattern(R"(match addm [] Binary (?ty ?x, ?y) {
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

TEST(SourceRangeTest, SynthesizedInstructionCapture) {
  SourceMgr SM;
  MIRContext Context;
  Pattern *P = parsePattern(R"(metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

%r = add:isaddop i32 ?x, ?y
)",
                            SM, Context);
  ASSERT_NE(P, nullptr);
  ASSERT_EQ(P->getInstructions().size(), 1u);

  // The pattern named no capture, so lowering synthesizes one for the flag's
  // subject; it reports the instruction's own location.
  Instruction *I = P->getInstructions().front();
  ASSERT_EQ(I->getCapture(), nullptr);
  ASSERT_TRUE(static_cast<bool>(PatternLowering(Context).lower(P)));
  MetaVariable *Capture = I->getCapture();
  ASSERT_NE(Capture, nullptr);
  EXPECT_TRUE(Capture->getSourceRange().Begin.isValid());
  EXPECT_EQ(Capture->getSourceRange().Begin, I->getSourceRange().Begin);
  // Hidden from reported bindings by the '_' prefix.
  EXPECT_EQ(Capture->getName(), "_");
}

} // namespace
