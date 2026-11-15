//===- PlanMatcherTest.cpp - Matching compiled patterns on LLVM IR -------===//
//
// Patterns compiled through the whole pipeline and matched by the plan
// interpreter: what they match, and what the matches bind.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/PlanMatcher.h"
#include "metaphir/Exec/CompiledPattern.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class PlanMatcherTest : public testing::Test {
protected:
  std::unique_ptr<CompiledPattern> compile(StringRef Source,
                                           bool Warnings = false) {
    std::string Errors;
    raw_string_ostream OS(Errors);
    unsigned NumWarnings = 0;
    auto Pattern = CompiledPattern::compile(
        MemoryBuffer::getMemBufferCopy(Source, "pattern"), OS, nullptr, {},
        [&](SourceMgr &SM) {
          SM.setDiagHandler(
              [](const SMDiagnostic &, void *Count) {
                ++*static_cast<unsigned *>(Count);
              },
              &NumWarnings);
        });
    EXPECT_EQ(NumWarnings != 0, Warnings) << Source.str();
    EXPECT_NE(Pattern, nullptr) << Errors;
    return Pattern;
  }

  std::unique_ptr<Module> parse(StringRef IR) {
    SMDiagnostic Diag;
    std::unique_ptr<Module> M = parseAssemblyString(IR, Diag, LLVMContext);
    if (!M)
      Diag.print("test", errs());
    return M;
  }

  std::vector<PlanMatch> match(const CompiledPattern &Pattern,
                               const Function &F) {
    return PlanMatcher(*Pattern.Program).match(F);
  }

  /// What the meta variable ?Name is bound to in Match.
  const Binding *lookup(const CompiledPattern &Pattern, const PlanMatch &Match,
                        StringRef Name) {
    for (auto [Slot, Info] : enumerate(Pattern.Program->getSlots()))
      if (!Info.IsInstruction && Info.Name == Name)
        return Match.lookup(Slot);
    ADD_FAILURE() << "no meta variable ?" << Name.str();
    return nullptr;
  }

  /// The binding of ?Name in the first match of Pattern in the first
  /// function IR defines. The module stays until the next call, for what
  /// the binding points to.
  std::optional<Binding> bindingOf(StringRef Pattern, StringRef IR,
                                   StringRef Name) {
    std::unique_ptr<CompiledPattern> P = compile(Pattern);
    Kept = parse(IR);
    Module *M = Kept.get();
    if (!P || !M)
      return std::nullopt;
    auto Defined = find_if(
        M->functions(), [](const Function &F) { return !F.isDeclaration(); });
    if (Defined == M->functions().end())
      return std::nullopt;
    std::vector<PlanMatch> Matches = match(*P, *Defined);
    if (Matches.empty()) {
      ADD_FAILURE() << "no match of " << Pattern.str();
      return std::nullopt;
    }
    const Binding *B = lookup(*P, Matches.front(), Name);
    if (!B)
      return std::nullopt;
    return *B;
  }

  llvm::LLVMContext LLVMContext;
  std::unique_ptr<Module> Kept;
};

TEST_F(PlanMatcherTest, EnforcesRepeatedBindings) {
  auto Pattern = compile("%r = add i32 ?x, ?x\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @same(i32 %x) {
      %r = add i32 %x, %x
      ret i32 %r
    }
    define i32 @different(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("same")).size(), 1u);
  EXPECT_TRUE(match(*Pattern, *M->getFunction("different")).empty());
}

TEST_F(PlanMatcherTest, RequiresEveryRoot) {
  auto Pattern = compile("%a = add i32 ?x, ?x\n%s = sub i32 ?y, ?y\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @complete(i32 %x) {
      %a = add i32 %x, %x
      %s = sub i32 %x, %x
      ret i32 %s
    }
    define i32 @incomplete(i32 %x) {
      %a = add i32 %x, %x
      ret i32 %a
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_FALSE(match(*Pattern, *M->getFunction("complete")).empty());
  EXPECT_TRUE(match(*Pattern, *M->getFunction("incomplete")).empty());
}

// ':c' tries the operands in both orders.
TEST_F(PlanMatcherTest, CommutativeMatchesSwappedOperands) {
  auto Pattern = compile("%r = add:c i32 1, ?x\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("f")).size(), 1u);
}

// ':o' admits its operand in place of the instruction.
TEST_F(PlanMatcherTest, OrSelfAdmitsTheOperandAsRoot) {
  auto Pattern = compile("%sub = sub i32 ?x, ?y\n%r = add:o(1) i32 ?x, %sub\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @f(i32 %x, i32 %y) {
      %r = sub i32 %x, %y
      ret i32 %r
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("f")).size(), 1u);
}

// Each branch of a matcher is an alternative of the pattern.
TEST_F(PlanMatcherTest, MatchesEachBranchOfAMatcher) {
  auto Pattern = compile(R"(
    match addOrSub [] Binary (?ty ?a, ?b) {
      %r1 = add ?ty ?a, ?b
    } or {
      %r2 = sub ?ty ?a, ?b
    }
    %r = addOrSub i32 ?x, ?y
  )");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @both(i32 %a, i32 %b) {
      %1 = add i32 %a, %b
      %2 = sub i32 %a, %b
      ret i32 %1
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("both")).size(), 2u);
}

TEST_F(PlanMatcherTest, InstructionAndMetaVariableCanShareName) {
  // The parser warns about the shared name.
  auto Pattern = compile("%x = add i32 ?x, ?y\n%res = sub i32 %x, ?x\n",
                         /*Warnings=*/true);
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define i32 @f(i32 %a, i32 %b) {
      %1 = add i32 %a, %b
      %2 = sub i32 %1, %a
      ret i32 %2
    }
  )");
  ASSERT_NE(M, nullptr);
  std::vector<PlanMatch> Matches = match(*Pattern, *M->getFunction("f"));
  ASSERT_EQ(Matches.size(), 1u);
  const Binding *X = lookup(*Pattern, Matches[0], "x");
  ASSERT_NE(X, nullptr);
  EXPECT_EQ(std::get<const llvm::Value *>(X->Data),
            M->getFunction("f")->getArg(0));
}

TEST_F(PlanMatcherTest, MatchesVectorTypes) {
  auto Pattern = compile(R"(
    %trunc = trunc <?n x i?big> ?x to <?n x i?small>
    %sub = sub <?n x i?small> ?zero:zero, %trunc
    %zext = zext <?n x i?small> %sub to <?n x i?big>
  )");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define <2 x i128> @vec(<2 x i128> %x) {
      %t = trunc <2 x i128> %x to <2 x i64>
      %s = sub <2 x i64> zeroinitializer, %t
      %z = zext <2 x i64> %s to <2 x i128>
      ret <2 x i128> %z
    }
  )");
  ASSERT_NE(M, nullptr);
  std::vector<PlanMatch> Matches = match(*Pattern, *M->getFunction("vec"));
  ASSERT_EQ(Matches.size(), 1u);
  EXPECT_EQ(*lookup(*Pattern, Matches[0], "n"), Binding(APInt(64, 2)));
  EXPECT_EQ(*lookup(*Pattern, Matches[0], "small"), Binding(APInt(64, 64)));
}

// A metaflag on an instruction constrains the instruction itself.
TEST_F(PlanMatcherTest, MetaFlagsConstrainTheirInstruction) {
  auto Pattern = compile(R"(
    %sat = call:s i32 @llvm.uadd.sat(i32 ?x, i32 ?c)
    %res = add i32 %sat, ?c
  )");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
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
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("single_use")).size(), 1u);

  PlanMatcher Matcher(*Pattern->Program);
  SmallVector<PlanRejection, 1> Rejections;
  bool HadStructuralMatch = false;
  EXPECT_TRUE(
      Matcher
          .match(*M->getFunction("multi_use"), &Rejections, &HadStructuralMatch)
          .empty());
  EXPECT_TRUE(HadStructuralMatch);
  ASSERT_EQ(Rejections.size(), 1u);
  EXPECT_EQ(Rejections[0].Reason, "");
}

// The value-tracking analyses are cached per function. A function freed
// between matches can be reallocated at the same address for the next module;
// its analyses must be rebuilt, or dominating conditions of the new function
// are missed.
TEST_F(PlanMatcherTest, RebuildsAnalysesForReallocatedFunction) {
  auto Pattern = compile("%r = udiv i32 ?x, ?y\n;; isKnownNegative(?y)\n");
  ASSERT_NE(Pattern, nullptr);
  PlanMatcher Matcher(*Pattern->Program);

  auto First = parse(R"(
    define i32 @f(i32 %x, i32 %y) {
      %r = udiv i32 %x, %y
      ret i32 %r
    }
  )");
  ASSERT_NE(First, nullptr);
  const Function *FirstFunction = First->getFunction("f");
  EXPECT_TRUE(Matcher.match(*FirstFunction).empty());
  First.reset();

  auto Second = parse(R"(
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
  )");
  ASSERT_NE(Second, nullptr);
  const Function *SecondFunction = Second->getFunction("f");
  if (SecondFunction != FirstFunction)
    GTEST_SKIP() << "the allocator did not reuse the function's address";
  EXPECT_EQ(Matcher.match(*SecondFunction).size(), 1u);
}

TEST_F(PlanMatcherTest, BindsOperandTypeParameters) {
  StringRef Freeze = R"(
    define [4 x i32] @f([4 x i32] %x) {
      %r = freeze [4 x i32] %x
      ret [4 x i32] %r
    }
  )";
  EXPECT_EQ(
      bindingOf("%r = freeze [?count x ?element] ?x\n", Freeze, "element"),
      Binding(llvm::Type::getInt32Ty(LLVMContext)));
  EXPECT_EQ(bindingOf("%r = freeze [?count x ?element] ?x\n", Freeze, "count"),
            Binding(APInt(64, 4)));
}

TEST_F(PlanMatcherTest, BindsResultTypes) {
  EXPECT_EQ(bindingOf("%r = zext i8 ?x to ?result_type\n", R"(
    define i32 @f(i8 %x) {
      %r = zext i8 %x to i32
      ret i32 %r
    }
  )",
                      "result_type"),
            Binding(llvm::Type::getInt32Ty(LLVMContext)));
}

TEST_F(PlanMatcherTest, BindsPredicatesAndCapturedFlags) {
  EXPECT_EQ(bindingOf("%r = icmp ?predicate i32 ?x, ?y\n", R"(
    define i1 @f(i32 %x, i32 %y) {
      %r = icmp slt i32 %x, %y
      ret i1 %r
    }
  )",
                      "predicate"),
            Binding(CmpInst::ICMP_SLT));
  EXPECT_EQ(bindingOf("%r = add nsw:?has_nsw i32 ?x, ?y\n", R"(
    define i32 @f(i32 %x, i32 %y) {
      %r = add i32 %x, %y
      ret i32 %r
    }
  )",
                      "has_nsw"),
            Binding(false));
}

TEST_F(PlanMatcherTest, BindsKeyedIntegerOperands) {
  EXPECT_EQ(bindingOf("%r = load i32, ptr ?pointer, align ?alignment\n", R"(
    define i32 @f(ptr %p) {
      %r = load i32, ptr %p, align 8
      ret i32 %r
    }
  )",
                      "alignment"),
            Binding(APInt(64, 8)));
}

TEST_F(PlanMatcherTest, RequiresFastMathFlags) {
  auto Pattern = compile("%r = select nnan i1 ?c, float ?x, float ?y\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define float @with_flag(i1 %c, float %x, float %y) {
      %r = select nnan i1 %c, float %x, float %y
      ret float %r
    }
    define float @without_flag(i1 %c, float %x, float %y) {
      %r = select i1 %c, float %x, float %y
      ret float %r
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("with_flag")).size(), 1u);
  EXPECT_TRUE(match(*Pattern, *M->getFunction("without_flag")).empty());
}

TEST_F(PlanMatcherTest, CapturesTrailingCallArguments) {
  StringRef Call = R"(
    declare i32 @callee(i32, i8, ptr)
    define i32 @caller(i32 %x, i8 %y, ptr %p) {
      %r = call i32 @callee(i32 %x, i8 %y, ptr %p)
      ret i32 %r
    }
  )";
  StringRef Pattern = "%r = call i32 @callee(i32 ?prefix, ...?types ?values)\n";
  std::optional<Binding> Types = bindingOf(Pattern, Call, "types");
  ASSERT_TRUE(Types);
  const auto &CapturedTypes = std::get<Binding::TypeArray>(Types->Data);
  ASSERT_EQ(CapturedTypes.size(), 2u);
  EXPECT_TRUE(CapturedTypes[0]->isIntegerTy(8));
  EXPECT_TRUE(CapturedTypes[1]->isPointerTy());

  std::optional<Binding> Values = bindingOf(Pattern, Call, "values");
  ASSERT_TRUE(Values);
  const auto &CapturedValues = std::get<Binding::ValueArray>(Values->Data);
  ASSERT_EQ(CapturedValues.size(), 2u);
  EXPECT_EQ(CapturedValues[0]->getName(), "y");
  EXPECT_EQ(CapturedValues[1]->getName(), "p");
}

TEST_F(PlanMatcherTest, CapturesAggregateIndices) {
  std::optional<Binding> Indices = bindingOf(
      "%r = extractvalue {i32, {i8, i16}} ?aggregate, ...?indices\n", R"(
    define i8 @f({i32, {i8, i16}} %aggregate) {
      %r = extractvalue {i32, {i8, i16}} %aggregate, 1, 0
      ret i8 %r
    }
  )",
      "indices");
  ASSERT_TRUE(Indices);
  const auto &Captured = std::get<Binding::ValueArray>(Indices->Data);
  ASSERT_EQ(Captured.size(), 2u);
  EXPECT_EQ(cast<ConstantInt>(Captured[0])->getZExtValue(), 1u);
  EXPECT_EQ(cast<ConstantInt>(Captured[1])->getZExtValue(), 0u);
}

TEST_F(PlanMatcherTest, AggregateConstantsRequireTheirShape) {
  auto Pattern = compile("%r = freeze [2 x i32] [i32 1, i32 2]\n");
  ASSERT_NE(Pattern, nullptr);
  auto M = parse(R"(
    define [2 x i32] @array() {
      %r = freeze [2 x i32] [i32 1, i32 2]
      ret [2 x i32] %r
    }
    define [2 x i32] @wrong_elements() {
      %r = freeze [2 x i32] [i32 1, i32 3]
      ret [2 x i32] %r
    }
    define <2 x i32> @vector() {
      %r = freeze <2 x i32> <i32 1, i32 2>
      ret <2 x i32> %r
    }
  )");
  ASSERT_NE(M, nullptr);
  EXPECT_EQ(match(*Pattern, *M->getFunction("array")).size(), 1u);
  EXPECT_TRUE(match(*Pattern, *M->getFunction("wrong_elements")).empty());
  EXPECT_TRUE(match(*Pattern, *M->getFunction("vector")).empty());
}

// Whether 'freeze PatternType ?x' matches the freeze of a TargetType.
struct TypeCase {
  const char *Pattern;
  const char *Target;
  bool Matches;
};

TEST_F(PlanMatcherTest, MatchesTypes) {
  const TypeCase Cases[] = {
      {"half", "half", true},
      {"bfloat", "bfloat", true},
      {"float", "float", true},
      {"double", "double", true},
      {"fp128", "fp128", true},
      {"float", "double", false},
      {"i32", "i32", true},
      {"i32", "i64", false},
      {"b8", "b8", true},
      {"ptr", "ptr", true},
      {"{i8, i32}", "{i8, i32}", true},
      {"<{i8, i32}>", "{i8, i32}", false},
      {"{i8, i32}", "<{i8, i32}>", false},
      {"{i8}", "{i32}", false},
      {"[4 x i32]", "[4 x i32]", true},
      {"[4 x i32]", "[3 x i32]", false},
      {"<4 x i32>", "<4 x i32>", true},
      {"<vscale x 4 x i32>", "<vscale x 4 x i32>", true},
      {"<4 x i32>", "<vscale x 4 x i32>", false},
      {"?t", "i32", true},
      {"i?bits", "i32", true},
      {"b?bits", "b8", true},
      {"[?n x i8]", "[6 x i8]", true},
  };
  for (const TypeCase &Case : Cases) {
    std::string Pattern =
        (Twine("%r = freeze ") + Case.Pattern + " ?x\n").str();
    std::string Function =
        (Twine("define void @f(") + Case.Target + " %x) {\n  %r = freeze " +
         Case.Target + " %x\n  ret void\n}\n")
            .str();
    std::unique_ptr<CompiledPattern> P = compile(Pattern);
    std::unique_ptr<Module> M = parse(Function);
    ASSERT_TRUE(P && M) << Case.Pattern << " / " << Case.Target;
    EXPECT_EQ(!match(*P, *M->getFunction("f")).empty(), Case.Matches)
        << Case.Pattern << " / " << Case.Target;
  }
  EXPECT_EQ(bindingOf("%r = freeze i?bits ?x\n",
                      "define void @f(i32 %x) {\n  %r = freeze i32 %x\n  ret "
                      "void\n}\n",
                      "bits"),
            Binding(APInt(64, 32)));
  EXPECT_EQ(bindingOf("%r = freeze b?bits ?x\n",
                      "define void @f(b8 %x) {\n  %r = freeze b8 %x\n  ret "
                      "void\n}\n",
                      "bits"),
            Binding(APInt(64, 8)));
}

TEST(BindingTest, ComparesNonValueBindings) {
  Binding Predicate(CmpInst::ICMP_EQ);
  EXPECT_EQ(Predicate, Binding(CmpInst::ICMP_EQ));
  EXPECT_NE(Predicate, Binding(CmpInst::ICMP_NE));
  EXPECT_EQ(Binding(APInt(32, 17)), Binding(APInt(32, 17)));
  EXPECT_EQ(Binding(true), Binding(true));
}

} // namespace
