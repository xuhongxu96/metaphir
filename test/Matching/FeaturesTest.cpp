#include "metaphir/Matching/Features.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Matching/Target.h"
#include "test/TestUtils.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using MIRInstruction = llvm::metaphir::Instruction;

namespace {

class FeaturesTest : public testing::Test {
protected:
  MIRContext Context;
  SourceMgr SM;
  LLVMContext IRContext;
  std::unique_ptr<Module> M;
  PatternVariants Variants;
  FeatureQuery Query;

  void parse(StringRef PatternSource, StringRef IR) {
    Pattern *Parsed = test::parsePattern(PatternSource, SM, Context);
    ASSERT_NE(Parsed, nullptr);
    Expected<PatternVariants> Lowered = PatternLowering(Context).lower(Parsed);
    ASSERT_TRUE(static_cast<bool>(Lowered)) << toString(Lowered.takeError());
    Variants = std::move(*Lowered);
    Query = FeatureQuery::compute(Variants);
    M = test::parseLLVMModule(IR, IRContext);
    ASSERT_NE(M, nullptr);
    expectSound();
  }

  bool matches(const Function &F) {
    return !PatternMatcher(&Context).match(Variants, Target(F)).empty();
  }

  bool passes(StringRef Name) {
    return Query.mayMatch(FunctionFeatures::compute(*M->getFunction(Name)));
  }

  // Every function with a match, and every variant with a match there, must
  // pass the filter.
  void expectSound() {
    for (const Function &F : *M) {
      if (F.isDeclaration())
        continue;
      SCOPED_TRACE(F.getName());
      FunctionFeatures Features = FunctionFeatures::compute(F);
      Target Program(F);
      PatternMatcher Matcher(&Context);
      EXPECT_EQ(Matcher.match(Variants, Program, nullptr, nullptr, &Query),
                Matcher.match(Variants, Program));
      for (auto [Index, Variant] : enumerate(Variants)) {
        if (!PatternMatcher(&Context).match(*Variant, Target(F)).empty()) {
          EXPECT_TRUE(Query.mayMatchVariant(Index, Features));
        }
      }
    }
  }
};

TEST_F(FeaturesTest, RequiresTheInstructions) {
  parse(R"(
    %r = udiv i32 ?x, ?y
  )",
        R"(
    define i32 @udiv(i32 %x, i32 %y) {
      %r = udiv i32 %x, %y
      ret i32 %r
    }
    define i32 @add(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  ASSERT_EQ(Query.getVariants().size(), 1u);
  EXPECT_EQ(Query.getVariants()[0].Instructions, uint64_t(1)
                                                     << MIRInstruction::I_udiv);
  EXPECT_TRUE(passes("udiv"));
  EXPECT_FALSE(passes("add"));
}

TEST_F(FeaturesTest, RequiresOperandEdges) {
  parse(R"(
    %a = add i32 ?x, ?y
    %r = mul i32 %a, ?z
  )",
        R"(
    define i32 @connected(i32 %x, i32 %y) {
      %a = add i32 %x, %y
      %r = mul i32 %a, %y
      ret i32 %r
    }
    define i32 @apart(i32 %x, i32 %y) {
      %a = add i32 %x, %y
      %r = mul i32 %x, %y
      %s = sub i32 %a, %r
      ret i32 %s
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("connected")));
  EXPECT_TRUE(passes("connected"));
  EXPECT_FALSE(passes("apart"));
}

TEST_F(FeaturesTest, AnyVariantSuffices) {
  parse(R"(
    %r = zextOrSext i8 ?x to i32
  )",
        R"(
    define i32 @zext(i8 %x) {
      %r = zext i8 %x to i32
      ret i32 %r
    }
    define i32 @sext(i8 %x) {
      %r = sext i8 %x to i32
      ret i32 %r
    }
    define i8 @trunc(i32 %x) {
      %r = trunc i32 %x to i8
      ret i8 %r
    }
  )");
  EXPECT_EQ(Query.getVariants().size(), 2u);
  EXPECT_TRUE(matches(*M->getFunction("zext")));
  EXPECT_TRUE(matches(*M->getFunction("sext")));
  EXPECT_TRUE(passes("zext"));
  EXPECT_TRUE(passes("sext"));
  EXPECT_FALSE(passes("trunc"));
}

TEST_F(FeaturesTest, OrSelfDoesNotRequireItsInstruction) {
  parse(R"(
    %difference = sub i32 ?x, ?y
    add:o i32 %difference, 1
  )",
        R"(
    define i32 @self(i32 %x, i32 %y) {
      %difference = sub i32 %x, %y
      ret i32 %difference
    }
    define i32 @neither(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("self")));
  EXPECT_TRUE(passes("self"));
  EXPECT_FALSE(passes("neither"));
}

TEST_F(FeaturesTest, OrSelfOfAComposite) {
  parse(R"(
    match addop [] Binary (?ty ?x, ?y) {
      %ret = add ?ty ?x, ?y
    }

    %value = sub i32 ?x, ?y
    %r = addop:o i32 %value, 0
  )",
        R"(
    define i32 @self(i32 %x, i32 %y) {
      %r = sub i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("self")));
  EXPECT_TRUE(passes("self"));
}

// Two pattern instructions can match the same instruction, so requiring an
// instruction once is all a filter may do.
TEST_F(FeaturesTest, PatternInstructionsCanShareATarget) {
  parse(R"(
    %a = add i32 ?x, ?y
    %b = add i32 ?x, ?y
    %c = sub i32 %a, %b
  )",
        R"(
    define i32 @shared(i32 %x, i32 %y) {
      %t = add i32 %x, %y
      %s = sub i32 %t, %t
      ret i32 %s
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("shared")));
  EXPECT_TRUE(passes("shared"));
}

TEST_F(FeaturesTest, RequiresIntrinsicsByBaseName) {
  parse(R"(
    %ctlz = call i32 @llvm.ctlz(i32 ?x, i1 ?isz)
  )",
        R"(
    define i32 @ctlz(i32 %x) {
      %r = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
      ret i32 %r
    }
    define i32 @cttz(i32 %x) {
      %r = call i32 @llvm.cttz.i32(i32 %x, i1 false)
      ret i32 %r
    }
    declare i32 @llvm.ctlz.i32(i32, i1)
    declare i32 @llvm.cttz.i32(i32, i1)
  )");
  EXPECT_TRUE(matches(*M->getFunction("ctlz")));
  EXPECT_TRUE(passes("ctlz"));
  EXPECT_FALSE(passes("cttz"));
}

TEST_F(FeaturesTest, RequiresNamedGlobals) {
  parse(R"(
    %r = call i32 @foo(i32 ?x)
  )",
        R"(
    define i32 @callsFoo(i32 %x) {
      %r = call i32 @foo(i32 %x)
      ret i32 %r
    }
    define i32 @callsBar(i32 %x) {
      %r = call i32 @bar(i32 %x)
      ret i32 %r
    }
    declare i32 @foo(i32)
    declare i32 @bar(i32)
  )");
  EXPECT_TRUE(matches(*M->getFunction("callsFoo")));
  EXPECT_TRUE(passes("callsFoo"));
  EXPECT_FALSE(passes("callsBar"));
}

TEST_F(FeaturesTest, InvokeIsNotACall) {
  parse(R"(
    %r = call i32 @foo(i32 ?x)
  )",
        R"(
    define i32 @invokes(i32 %x) personality ptr null {
      %r = invoke i32 @foo(i32 %x) to label %ok unwind label %bad
    ok:
      ret i32 %r
    bad:
      %l = landingpad { ptr, i32 } cleanup
      ret i32 0
    }
    declare i32 @foo(i32)
  )");
  EXPECT_FALSE(matches(*M->getFunction("invokes")));
  EXPECT_FALSE(passes("invokes"));
}

// Pattern instructions match instructions only, never constant expressions.
TEST_F(FeaturesTest, ConstantExpressionsAreNotInstructions) {
  parse(R"(
    %p = ptrtoint ptr ?g to i64
    %r = add i64 %p, 1
  )",
        R"(
    @g = global i32 0
    define i64 @constant() {
      %r = add i64 ptrtoint (ptr @g to i64), 1
      ret i64 %r
    }
  )");
  EXPECT_FALSE(matches(*M->getFunction("constant")));
  EXPECT_FALSE(passes("constant"));
}

TEST_F(FeaturesTest, BothBranchKindsAreBranches) {
  parse(R"(
    br label ?next
  )",
        R"(
    define void @unconditional() {
      br label %next
    next:
      ret void
    }
    define void @conditional(i1 %c) {
      br i1 %c, label %next, label %next
    next:
      ret void
    }
  )");
  EXPECT_TRUE(passes("unconditional"));
  EXPECT_TRUE(passes("conditional"));
}

TEST_F(FeaturesTest, MergedFeaturesAdmitEveryFunction) {
  parse(R"(
    %a = add i32 ?x, ?y
    %r = mul i32 %a, ?z
  )",
        R"(
    define i32 @connected(i32 %x, i32 %y) {
      %a = add i32 %x, %y
      %r = mul i32 %a, %y
      ret i32 %r
    }
    define i32 @other(i32 %x) {
      %r = call i32 @foo(i32 %x)
      ret i32 %r
    }
    declare i32 @foo(i32)
  )");
  FunctionFeatures Module;
  for (const Function &F : *M)
    if (!F.isDeclaration())
      Module.merge(FunctionFeatures::compute(F));
  EXPECT_TRUE(Query.mayMatch(Module));
  EXPECT_TRUE(Module.hasGlobal(hashGlobal(*M->getFunction("foo"))));
}

} // namespace
