//===- OpcodePredicatesTest.cpp - Flags of each kind of instruction ------===//
//
// A semantic flag is present on the instructions that can carry it, and
// absent on the rest: each flag is checked on an instruction of each kind.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Matching/OpcodePredicates.h"
#include "test/TestUtils.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

/// The first instruction of the function f in IR.
const llvm::Instruction *firstInstruction(llvm::Module &M, StringRef Name) {
  return &M.getFunction(Name)->getEntryBlock().front();
}

TEST(OpcodePredicatesTest, FlagsOnTheirInstructions) {
  llvm::LLVMContext Context;
  std::unique_ptr<llvm::Module> M = test::parseLLVMModule(R"(
    define i32 @add(i32 %x) {
      %r = add nsw nuw i32 %x, 1
      ret i32 %r
    }
    define i32 @udiv(i32 %x) {
      %r = udiv exact i32 %x, 3
      ret i32 %r
    }
    define i32 @or(i32 %x) {
      %r = or disjoint i32 %x, 3
      ret i32 %r
    }
    define i32 @load(ptr %p) {
      %r = load volatile i32, ptr %p
      ret i32 %r
    }
    define void @store(ptr %p) {
      store volatile i32 1, ptr %p
      ret void
    }
    define ptr @gep(ptr %p) {
      %r = getelementptr inbounds nusw nuw i32, ptr %p, i64 1
      ret ptr %r
    }
    define i32 @zext(i8 %x) {
      %r = zext nneg i8 %x to i32
      ret i32 %r
    }
    define i1 @icmp(i32 %x) {
      %r = icmp samesign ult i32 %x, 3
      ret i1 %r
    }
    define ptr @alloca() {
      %r = alloca inalloca i32
      ret ptr %r
    }
    define i32 @fadd(float %x) {
      %r = fadd nnan float %x, 1.0
      %s = fptosi float %x to i32
      ret i32 %s
    }
  )",
                                                           Context);
  ASSERT_NE(M, nullptr);
  using instruction_flag::FlagID;

  // Each flag on an instruction that carries it.
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nsw, *firstInstruction(*M, "add")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nuw, *firstInstruction(*M, "add")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_exact, *firstInstruction(*M, "udiv")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_disjoint, *firstInstruction(*M, "or")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_volatile, *firstInstruction(*M, "load")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_volatile, *firstInstruction(*M, "store")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_inbounds, *firstInstruction(*M, "gep")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nusw, *firstInstruction(*M, "gep")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nuw, *firstInstruction(*M, "gep")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nneg, *firstInstruction(*M, "zext")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_samesign, *firstInstruction(*M, "icmp")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_inalloca, *firstInstruction(*M, "alloca")));
  EXPECT_TRUE(hasSemanticFlag(FlagID::F_nnan, *firstInstruction(*M, "fadd")));

  // A flag an instruction cannot carry is absent.
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_exact, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_disjoint, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_inalloca, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_volatile, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_inbounds, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_nusw, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_samesign, *firstInstruction(*M, "add")));
  // The flags of floating-point operations are not carried by integers.
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_nnan, *firstInstruction(*M, "add")));
  EXPECT_FALSE(hasSemanticFlag(FlagID::F_fast, *firstInstruction(*M, "add")));
}

} // namespace
