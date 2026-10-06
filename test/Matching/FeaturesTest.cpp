#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/FeatureQuery.h"
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
    Query = FeatureQuery::compute(Variants, &Context);
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

  /// Whether the function passes with value-tracking facts recorded.
  bool passesWithValueFacts(StringRef Name) {
    return Query.mayMatch(
        FunctionFeatures::compute(*M->getFunction(Name), ValueFacts));
  }

  static constexpr FeatureOptions ValueFacts{/*ValueFacts=*/true};

  // Every function with a match, and every variant with a match there, must
  // pass the filter, with or without value-tracking facts.
  void expectSound() {
    for (const Function &F : *M) {
      if (F.isDeclaration())
        continue;
      SCOPED_TRACE(F.getName());
      Target Program(F);
      PatternMatcher Matcher(&Context);
      EXPECT_EQ(Matcher.match(Variants, Program, nullptr, nullptr, &Query),
                Matcher.match(Variants, Program));
      for (const FeatureOptions &Options : {FeatureOptions(), ValueFacts}) {
        FunctionFeatures Features = FunctionFeatures::compute(F, Options);
        for (auto [Index, Variant] : enumerate(Variants)) {
          if (!PatternMatcher(&Context).match(*Variant, Target(F)).empty()) {
            EXPECT_TRUE(Query.mayMatchVariant(Index, Features))
                << "variant " << Index << " pruned with value facts "
                << Options.ValueFacts;
          }
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
  ASSERT_EQ(Query.size(), 1u);
  EXPECT_EQ(Query.getRequirement(0).Instructions,
            uint64_t(1) << MIRInstruction::I_udiv);
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
  EXPECT_EQ(Query.size(), 2u);
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
  // A conditional branch is a br too, though its operands differ.
  EXPECT_FALSE(matches(*M->getFunction("conditional")));
  EXPECT_TRUE(
      FunctionFeatures::compute(*M->getFunction("conditional")).Instructions &
      uint64_t(1) << MIRInstruction::I_br);
}

TEST_F(FeaturesTest, RequiresNamedFlags) {
  parse(R"(
    %r = lshr exact i32 ?x, ?y
  )",
        R"(
    define i32 @exact(i32 %x, i32 %y) {
      %r = lshr exact i32 %x, %y
      ret i32 %r
    }
    define i32 @inexact(i32 %x, i32 %y) {
      %r = lshr i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("exact"));
  EXPECT_FALSE(passes("inexact"));
}

// A supported flag the pattern does not name may be present or absent.
TEST_F(FeaturesTest, OmittedFlagsMayBeEither) {
  parse(R"(
    %r = add i32 ?x, ?y
  )",
        R"(
    define i32 @plain(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @nsw(i32 %x, i32 %y) {
      %r = add nsw i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("plain"));
  EXPECT_TRUE(matches(*M->getFunction("nsw")));
  EXPECT_TRUE(passes("nsw"));
}

TEST_F(FeaturesTest, NegatedFlagsMustBeAbsent) {
  parse(R"(
    %r = add !nsw i32 ?x, ?y
  )",
        R"(
    define i32 @plain(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @nsw(i32 %x, i32 %y) {
      %r = add nsw i32 %x, %y
      ret i32 %r
    }
    define i32 @nuw(i32 %x, i32 %y) {
      %r = add nuw i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("plain"));
  EXPECT_FALSE(matches(*M->getFunction("nsw")));
  EXPECT_FALSE(passes("nsw"));
  EXPECT_TRUE(passes("nuw"));
}

TEST_F(FeaturesTest, CapturedFlagsMayBeEither) {
  parse(R"(
    %r = add nsw:?nsw i32 ?x, ?y
  )",
        R"(
    define i32 @plain(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @nsw(i32 %x, i32 %y) {
      %r = add nsw i32 %x, %y
      ret i32 %r
    }
    define i32 @nuw(i32 %x, i32 %y) {
      %r = add nuw i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("plain"));
  EXPECT_TRUE(passes("nsw"));
  EXPECT_TRUE(passes("nuw"));
}

TEST_F(FeaturesTest, RequiresCastResultWidths) {
  parse(R"(
    ;; treatIntAsVec(true)
    %t = trunc i32 ?x to i1
  )",
        R"(
    define i1 @to_i1(i32 %x) {
      %t = trunc i32 %x to i1
      ret i1 %t
    }
    define <2 x i1> @to_v2i1(<2 x i32> %x) {
      %t = trunc <2 x i32> %x to <2 x i1>
      ret <2 x i1> %t
    }
    define i8 @to_i8(i32 %x) {
      %t = trunc i32 %x to i8
      ret i8 %t
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("to_v2i1")));
  EXPECT_TRUE(passes("to_i1"));
  EXPECT_TRUE(passes("to_v2i1"));
  EXPECT_FALSE(passes("to_i8"));
}

TEST_F(FeaturesTest, RequiresBinaryResultWidths) {
  parse(R"(
    %r = mul i8 ?x, ?y
  )",
        R"(
    define i8 @i8(i8 %x, i8 %y) {
      %r = mul i8 %x, %y
      ret i8 %r
    }
    define i32 @i32(i32 %x, i32 %y) {
      %r = mul i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("i8"));
  EXPECT_FALSE(passes("i32"));
}

// Instructions using the same value are siblings. A variable can stand for a
// constant, so instructions using the same constant are siblings too.
TEST_F(FeaturesTest, RequiresSiblings) {
  parse(R"(
    %rem = and i32 ?x, 1
    %div = lshr i32 ?x, 2
    %add = add i32 %rem, %div
  )",
        R"(
    define i32 @shared(i32 %x) {
      %rem = and i32 %x, 1
      %div = lshr i32 %x, 2
      %add = add i32 %rem, %div
      ret i32 %add
    }
    define i32 @separate(i32 %x, i32 %y) {
      %rem = and i32 %x, 1
      %div = lshr i32 %y, 2
      %add = add i32 %rem, %div
      ret i32 %add
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("shared")));
  EXPECT_TRUE(passes("shared"));
  EXPECT_FALSE(passes("separate"));
}

// An instruction whose ':o' alternative may match instead uses nothing.
TEST_F(FeaturesTest, OrSelfInstructionsAreNotSiblings) {
  parse(R"(
    %a = add:o i32 ?x, 1
    %m = mul i32 ?x, %a
  )",
        R"(
    define i32 @self(i32 %x) {
      %m = mul i32 %x, %x
      ret i32 %m
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("self")));
  EXPECT_TRUE(passes("self"));
}

// A phi's incoming blocks are not among its operands.
TEST_F(FeaturesTest, PhiBlocksAreNotSiblings) {
  parse(R"(
    ?loop:
    %v = phi i32 [?init, ?entry], [?next, ?loop]
    ?entry:
    br label ?loop
  )",
        R"(
    define i32 @loop(i32 %n) {
    entry:
      br label %loop
    loop:
      %v = phi i32 [0, %entry], [%v2, %loop]
      %v2 = add i32 %v, 1
      %c = icmp slt i32 %v2, %n
      br i1 %c, label %loop, label %exit
    exit:
      ret i32 %v
    }
  )");
  EXPECT_TRUE(passes("loop"));
}

TEST_F(FeaturesTest, RequiresNamedLiterals) {
  parse(R"(
    ;; treatIntAsVec(true)
    %r = and i32 ?x, 1
  )",
        R"(
    define i32 @one(i32 %x) {
      %r = and i32 %x, 1
      ret i32 %r
    }
    define <2 x i32> @splat(<2 x i32> %x) {
      %r = and <2 x i32> %x, <i32 1, i32 poison>
      ret <2 x i32> %r
    }
    define i32 @two(i32 %x) {
      %r = and i32 %x, 2
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("splat")));
  EXPECT_TRUE(passes("one"));
  EXPECT_TRUE(passes("splat"));
  EXPECT_FALSE(passes("two"));
}

// A literal matches the constants of its value, however they are read.
TEST_F(FeaturesTest, LiteralsMatchEitherReading) {
  parse(R"(
    %r = add i8 ?x, -1
  )",
        R"(
    define i8 @all_ones(i8 %x) {
      %r = add i8 %x, 255
      ret i8 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("all_ones")));
  EXPECT_TRUE(passes("all_ones"));
}

TEST_F(FeaturesTest, RequiresComparedLiterals) {
  parse(R"(
    %c = icmp eq i32 ?x, ?k
    ;; (?k == 0 || ?k == 1)
  )",
        R"(
    define i1 @one(i32 %x) {
      %c = icmp eq i32 %x, 1
      ret i1 %c
    }
    define i1 @five(i32 %x) {
      %c = icmp eq i32 %x, 5
      ret i1 %c
    }
    define i1 @variable(i32 %x, i32 %y) {
      %c = icmp eq i32 %x, %y
      ret i1 %c
    }
  )");
  EXPECT_TRUE(passes("one"));
  EXPECT_FALSE(passes("five"));
  EXPECT_FALSE(passes("variable"));
}

TEST_F(FeaturesTest, RequiresConstantClasses) {
  parse(R"(
    %r = and:c i32 ?x, ?m:lowBitMask
  )",
        R"(
    define i32 @mask(i32 %x) {
      %r = and i32 %x, 7
      ret i32 %r
    }
    define i32 @swapped(i32 %x) {
      %r = and i32 7, %x
      ret i32 %r
    }
    define i32 @not_mask(i32 %x) {
      %r = and i32 %x, 6
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("mask"));
  EXPECT_TRUE(passes("swapped"));
  EXPECT_FALSE(passes("not_mask"));
}

// ':constantInt' is a user-defined constraint around isa.
TEST_F(FeaturesTest, EvaluatesUserDefinedConstraints) {
  parse(R"(
    %r = and i32 ?x, ?m:constantInt
  )",
        R"(
    define i32 @constant(i32 %x) {
      %r = and i32 %x, 3
      ret i32 %r
    }
    define i32 @variable(i32 %x, i32 %y) {
      %r = and i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("constant"));
  EXPECT_FALSE(passes("variable"));
}

TEST_F(FeaturesTest, RequiresOneUse) {
  parse(R"(
    %a = add:s i32 ?x, ?y
    %r = mul i32 %a, ?z
  )",
        R"(
    define i32 @once(i32 %x, i32 %y, i32 %z) {
      %a = add i32 %x, %y
      %r = mul i32 %a, %z
      ret i32 %r
    }
    define i32 @twice(i32 %x, i32 %y, i32 %z) {
      %a = add i32 %x, %y
      %r = mul i32 %a, %z
      %s = sub i32 %r, %a
      ret i32 %s
    }
  )");
  EXPECT_TRUE(passes("once"));
  EXPECT_FALSE(passes("twice"));
}

// With ':o', the instruction may be its operand, whose uses count.
TEST_F(FeaturesTest, OrSelfConstraintsApplyToTheOperand) {
  parse(R"(
    %d = sub i32 ?x, ?y
    %r = add:s:o i32 %d, 1
  )",
        R"(
    define i32 @self(i32 %x, i32 %y) {
      %d = sub i32 %x, %y
      ret i32 %d
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("self")));
  EXPECT_TRUE(passes("self"));
}

TEST_F(FeaturesTest, RequiresValueTrackingFacts) {
  parse(R"(
    %d = udiv i32 ?x, ?y:knownNegative
  )",
        R"(
    define i32 @constant(i32 %x) {
      %d = udiv i32 %x, -2
      ret i32 %d
    }
    define i32 @sign_bit(i32 %x, i32 %n) {
      %y = or i32 %n, -2147483648
      %d = udiv i32 %x, %y
      ret i32 %d
    }
    define i32 @assumed(i32 %x, i32 %n) {
      %c = icmp slt i32 %n, 0
      call void @llvm.assume(i1 %c)
      %d = udiv i32 %x, %n
      ret i32 %d
    }
    define i32 @dominated(i32 %x, i32 %n) {
    entry:
      %c = icmp slt i32 %n, 0
      br i1 %c, label %negative, label %other
    negative:
      %d = udiv i32 %x, %n
      ret i32 %d
    other:
      ret i32 0
    }
    define i32 @unknown(i32 %x, i32 %n) {
      %d = udiv i32 %x, %n
      ret i32 %d
    }
    define i32 @dividend(i32 %n) {
      %d = udiv i32 -1, %n
      ret i32 %d
    }
    declare void @llvm.assume(i1)
  )");
  for (StringRef Name : {"constant", "sign_bit", "assumed", "dominated"}) {
    EXPECT_TRUE(matches(*M->getFunction(Name))) << Name;
    EXPECT_TRUE(passesWithValueFacts(Name)) << Name;
  }
  EXPECT_FALSE(passesWithValueFacts("unknown"));
  EXPECT_FALSE(passesWithValueFacts("dividend"));
  // Without the facts, value tracking is unknown.
  EXPECT_TRUE(passes("unknown"));
}

TEST_F(FeaturesTest, RequiresKnownZeroBits) {
  parse(R"(
    %r = add i32 ?x, ?y
    ;; maskedValueIsZero(?x, 3)
  )",
        R"(
    define i32 @by4(i32 %v, i32 %y) {
      %x = shl i32 %v, 2
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @by2(i32 %v, i32 %y) {
      %x = shl i32 %v, 1
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("by4")));
  EXPECT_TRUE(passesWithValueFacts("by4"));
  EXPECT_FALSE(passesWithValueFacts("by2"));
}

TEST_F(FeaturesTest, RequiresKnownLeadingZeros) {
  parse(R"(
    %r = add i32 ?x, ?y
    ;; maskedValueIsZero(?x, -256)
  )",
        R"(
    define i32 @byte(i32 %v, i32 %y) {
      %x = and i32 %v, 255
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @nine_bits(i32 %v, i32 %y) {
      %x = and i32 %v, 511
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("byte")));
  EXPECT_TRUE(passesWithValueFacts("byte"));
  EXPECT_FALSE(passesWithValueFacts("nine_bits"));
}

TEST_F(FeaturesTest, RequiresSignedRanges) {
  parse(R"(
    %r = add i32 ?x, ?y
    ;; inSignedRange(?x, -1, 1)
  )",
        R"(
    define i32 @sign(i32 %v, i32 %y) {
      %x = ashr i32 %v, 31
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @byte(i32 %v, i32 %y) {
      %x = ashr i32 %v, 24
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("sign")));
  EXPECT_TRUE(passesWithValueFacts("sign"));
  EXPECT_FALSE(passesWithValueFacts("byte"));
}

TEST_F(FeaturesTest, RequiresUnsignedRanges) {
  parse(R"(
    %r = add i32 ?x, ?y
    ;; inUnsignedRange(?x, 0, 255)
  )",
        R"(
    define i32 @byte(i32 %v, i32 %y) {
      %x = lshr i32 %v, 24
      %r = add i32 %x, %y
      ret i32 %r
    }
    define i32 @half(i32 %v, i32 %y) {
      %x = lshr i32 %v, 16
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("byte")));
  EXPECT_TRUE(passesWithValueFacts("byte"));
  EXPECT_FALSE(passesWithValueFacts("half"));
}

// The constant classes added after PatternMatch.h's matchers are recorded
// too.
TEST_F(FeaturesTest, RequiresSignMasks) {
  parse(R"(
    %r = and i32 ?x, ?c:signMask
  )",
        R"(
    define i32 @sign_mask(i32 %x) {
      %r = and i32 %x, -2147483648
      ret i32 %r
    }
    define i32 @other(i32 %x) {
      %r = and i32 %x, -2
      ret i32 %r
    }
  )");
  EXPECT_TRUE(passes("sign_mask"));
  EXPECT_FALSE(matches(*M->getFunction("other")));
  EXPECT_FALSE(passes("other"));
}

// Type variables are bound from the signatures of the instructions.
TEST_F(FeaturesTest, BindsTypeVariables) {
  parse(R"(
    ;; treatIntAsVec(true)
    %r = add i?bits ?x, ?y
    ;; sgt(?bits, 8)
  )",
        R"(
    define i8 @narrow(i8 %x, i8 %y) {
      %r = add i8 %x, %y
      ret i8 %r
    }
    define i32 @wide(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
    define <2 x i32> @vector(<2 x i32> %x, <2 x i32> %y) {
      %r = add <2 x i32> %x, %y
      ret <2 x i32> %r
    }
  )");
  EXPECT_FALSE(passes("narrow"));
  EXPECT_TRUE(passes("wide"));
  EXPECT_TRUE(matches(*M->getFunction("vector")));
  EXPECT_TRUE(passes("vector"));
}

// The types of different instructions must agree on shared variables.
TEST_F(FeaturesTest, JoinsSignatures) {
  parse(R"(
    %t = trunc i?big ?x to i?small
    %z = zext i?small %t to i?big
  )",
        R"(
    define i64 @agree(i64 %x) {
      %t = trunc i64 %x to i32
      %z = zext i32 %t to i64
      ret i64 %z
    }
    define i128 @disagree(i64 %x) {
      %t = trunc i64 %x to i32
      %z = zext i32 %t to i128
      ret i128 %z
    }
  )");
  EXPECT_TRUE(passes("agree"));
  EXPECT_FALSE(matches(*M->getFunction("disagree")));
  EXPECT_FALSE(passes("disagree"));
}

TEST_F(FeaturesTest, JoinsWidthConstraints) {
  parse(R"(
    %s = ashr i?bits ?x, ?bm1
    ;; ?bm1 == ?bits - 1
  )",
        R"(
    define i32 @sign(i32 %x) {
      %s = ashr i32 %x, 31
      ret i32 %s
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("sign")));
  EXPECT_TRUE(passes("sign"));
}

// A type the index does not encode binds nothing.
TEST_F(FeaturesTest, OpaqueTypesMatchAnything) {
  parse(R"(
    %f = freeze ?ty ?x
    ;; ?ty == ?ty
  )",
        R"(
    define { i32, i32 } @aggregate({ i32, i32 } %x) {
      %f = freeze { i32, i32 } %x
      ret { i32, i32 } %f
    }
  )");
  EXPECT_TRUE(matches(*M->getFunction("aggregate")));
  EXPECT_TRUE(passes("aggregate"));
}

// ':c' matches operands in either order, so types bind either way.
TEST_F(FeaturesTest, BindsSwappedOperandTypes) {
  parse(R"(
    %r = call:c i?n @llvm.umax(i?n ?x, i?n 1)
    ;; sgt(?n, 8)
  )",
        R"(
    define i32 @umax(i32 %x) {
      %r = call i32 @llvm.umax.i32(i32 1, i32 %x)
      ret i32 %r
    }
    declare i32 @llvm.umax.i32(i32, i32)
  )");
  EXPECT_TRUE(matches(*M->getFunction("umax")));
  EXPECT_TRUE(passes("umax"));
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
