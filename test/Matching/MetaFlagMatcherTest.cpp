#include "metaphir/Matching/MetaFlagMatcher.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Values.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

static MetaFlag *makeFlag(MIRContext &Context, StringRef Name,
                          ArrayRef<MetaFlag::Argument> Arguments = {},
                          SourceRange Range = {}) {
  return MetaFlag::get(Context, Name, Arguments, Range);
}

static MetaFlag::Argument nestedFlag(MetaFlag *Flag) {
  MetaFlag::Argument Arg;
  Arg.K = MetaFlag::Argument::Flag;
  Arg.FlagValue = Flag;
  return Arg;
}

static std::unique_ptr<Module> parseModule(StringRef IR, LLVMContext &Context) {
  SMDiagnostic Error;
  return parseAssemblyString(IR, Error, Context);
}

TEST(MetaFlagMatcherTest, MatchesAllOnes) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *AllOnes =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), -1, true);
  ConstantInt *NotAllOnes =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "allones")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*AllOnes));
  EXPECT_FALSE(Matcher.matchOperandFlags(*NotAllOnes));
}

TEST(MetaFlagMatcherTest, MatchesZero) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *Zero = ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);
  ConstantInt *One = ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "zero")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Zero));
  EXPECT_FALSE(Matcher.matchOperandFlags(*One));
}

TEST(MetaFlagMatcherTest, MatchesLowBitMask) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *LowBitMask =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 255);
  ConstantInt *NotMask =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 5);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "lowbitmask")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*LowBitMask));
  EXPECT_FALSE(Matcher.matchOperandFlags(*NotMask));
}

TEST(MetaFlagMatcherTest, ForbidsPoison) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *Safe = ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 7);
  auto *Poison = PoisonValue::get(llvm::Type::getInt32Ty(LLVMContext));

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "forbidpoison")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Safe));
  EXPECT_FALSE(Matcher.matchOperandFlags(*Poison));
}

TEST(MetaFlagMatcherTest, MatchesIntegralConstant) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *Integral =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 17);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "integralconstant")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Integral));

  // A floating-point constant is not an integral constant.
  ConstantFP *Float = ConstantFP::get(llvm::Type::getFloatTy(LLVMContext), 1.0);
  EXPECT_FALSE(Matcher.matchOperandFlags(*Float));
}

TEST(MetaFlagMatcherTest, MatchesZeroFP) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantFP *Zero = ConstantFP::get(llvm::Type::getFloatTy(LLVMContext), 0.0);
  ConstantFP *One = ConstantFP::get(llvm::Type::getFloatTy(LLVMContext), 1.0);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "zerofp")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Zero));
  EXPECT_FALSE(Matcher.matchOperandFlags(*One));
}

TEST(MetaFlagMatcherTest, MatchesPoison) {
  MIRContext Context;
  LLVMContext LLVMContext;
  auto *Poison = PoisonValue::get(llvm::Type::getInt32Ty(LLVMContext));
  ConstantInt *One = ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "poison")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Poison));
  EXPECT_FALSE(Matcher.matchOperandFlags(*One));
}

TEST(MetaFlagMatcherTest, MatchesAPInt) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *APInt =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 42);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "apint")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*APInt));

  // A floating-point constant is not an APInt.
  ConstantFP *Float = ConstantFP::get(llvm::Type::getFloatTy(LLVMContext), 1.0);
  EXPECT_FALSE(Matcher.matchOperandFlags(*Float));
}

TEST(MetaFlagMatcherTest, MatchesConstantInt) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *Integer =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 17);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "constantint")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Integer));

  // An undefined value is not a ConstantInt.
  auto *Undef = UndefValue::get(llvm::Type::getInt32Ty(LLVMContext));
  EXPECT_FALSE(Matcher.matchOperandFlags(*Undef));
}

TEST(MetaFlagMatcherTest, MatchesConstantSplat) {
  MIRContext Context;
  LLVMContext LLVMContext;

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "constantsplat")};
  MetaFlagMatcher Matcher(Flags);

  // A scalar integer constant is a splat.
  ConstantInt *Scalar =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 5);
  EXPECT_TRUE(Matcher.matchOperandFlags(*Scalar));

  // A splat vector constant matches.
  auto *SplatVector = ConstantVector::getSplat(
      ElementCount::getFixed(4),
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 5));
  EXPECT_TRUE(Matcher.matchOperandFlags(*SplatVector));

  // A non-splat vector does not match.
  auto *NonSplatVector = ConstantVector::get(
      {ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1),
       ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 2)});
  EXPECT_FALSE(Matcher.matchOperandFlags(*NonSplatVector));
}

TEST(MetaFlagMatcherTest, MatchesPowerOfTwo) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *PowerOfTwo =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 8);
  ConstantInt *NotPowerOfTwo =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 3);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "poweroftwo")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.matchOperandFlags(*PowerOfTwo));
  EXPECT_FALSE(Matcher.matchOperandFlags(*NotPowerOfTwo));
}

TEST(MetaFlagMatcherTest, OrMatchesAnyNestedFlag) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *AllOnes =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), -1, true);
  ConstantInt *PoisonLike =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);
  ConstantInt *Neither =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 7);

  MetaFlag *AllOnesFlag = makeFlag(Context, "allones");
  MetaFlag *ZeroFlag = makeFlag(Context, "zero");
  SmallVector<MetaFlag *, 4> Flags = {
      makeFlag(Context, "or", {nestedFlag(AllOnesFlag), nestedFlag(ZeroFlag)})};
  MetaFlagMatcher Matcher(Flags);

  EXPECT_TRUE(Matcher.matchOperandFlags(*AllOnes));
  EXPECT_TRUE(Matcher.matchOperandFlags(*PoisonLike));
  EXPECT_FALSE(Matcher.matchOperandFlags(*Neither));
}

TEST(MetaFlagMatcherTest, NotNegatesNestedFlag) {
  MIRContext Context;
  LLVMContext LLVMContext;
  auto *Poison = PoisonValue::get(llvm::Type::getInt32Ty(LLVMContext));
  ConstantInt *NotPoison =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);

  MetaFlag *PoisonFlag = makeFlag(Context, "poison");
  SmallVector<MetaFlag *, 4> Flags = {
      makeFlag(Context, "not", {nestedFlag(PoisonFlag)})};
  MetaFlagMatcher Matcher(Flags);

  EXPECT_TRUE(Matcher.matchOperandFlags(*NotPoison));
  EXPECT_FALSE(Matcher.matchOperandFlags(*Poison));
}

TEST(MetaFlagMatcherTest, AllFlagsMustMatch) {
  MIRContext Context;
  LLVMContext LLVMContext;
  ConstantInt *AllOnes =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), -1, true);
  ConstantInt *NotAllOnes =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1);

  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "allones"),
                                      makeFlag(Context, "constantint")};
  MetaFlagMatcher Matcher(Flags);

  // Both flags match: -1 is all-ones and an integral constant.
  EXPECT_TRUE(Matcher.matchOperandFlags(*AllOnes));

  // One flag fails: 1 is an integral constant but not all-ones.
  EXPECT_FALSE(Matcher.matchOperandFlags(*NotAllOnes));
}

TEST(MetaFlagMatcherTest, HasMetaFlagSearchesByID) {
  MIRContext Context;
  SmallVector<MetaFlag *, 4> Flags = {makeFlag(Context, "allones"),
                                      makeFlag(Context, "zero")};
  MetaFlagMatcher Matcher(Flags);
  EXPECT_TRUE(Matcher.hasMetaFlag(MetaFlag::MF_allones));
  EXPECT_TRUE(Matcher.hasMetaFlag(MetaFlag::MF_zero));
  EXPECT_FALSE(Matcher.hasMetaFlag(MetaFlag::MF_poweroftwo));
}

TEST(MetaFlagMatcherTest, MatchesUseCountFlags) {
  MIRContext Context;
  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        define i32 @f(i32 %x, i32 %y) {
          %a = add i32 %x, %y
          %b = add i32 %a, %a
          %c = add i32 %b, 1
          ret i32 %c
        }
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);
  Function *F = Module->getFunction("f");
  auto It = F->getEntryBlock().begin();
  const llvm::Instruction &A = *It++; // %a: used twice
  const llvm::Instruction &B = *It++; // %b: used once

  // MF_su (has one user): both %a and %b have a single user.
  SmallVector<MetaFlag *, 4> SuFlags = {makeFlag(Context, "su")};
  MetaFlagMatcher SuMatcher(SuFlags);
  EXPECT_TRUE(SuMatcher.matchOperandFlags(B));
  EXPECT_TRUE(SuMatcher.matchOperandFlags(A));
  EXPECT_TRUE(SuMatcher.matchUseFlags(B));
  EXPECT_TRUE(SuMatcher.matchUseFlags(A));

  // MF_s (has one use): %b is used once; %a is used twice.
  SmallVector<MetaFlag *, 4> SFlags = {makeFlag(Context, "s")};
  MetaFlagMatcher SMatcher(SFlags);
  EXPECT_TRUE(SMatcher.matchOperandFlags(B));
  EXPECT_FALSE(SMatcher.matchOperandFlags(A));
  EXPECT_TRUE(SMatcher.matchUseFlags(B));
  EXPECT_FALSE(SMatcher.matchUseFlags(A));
}
