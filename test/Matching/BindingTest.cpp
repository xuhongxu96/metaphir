#include "metaphir/Matching/Binding.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class BindingTest : public testing::Test {
protected:
  LLVMContext Context;
  std::unique_ptr<Module> M;

  void SetUp() override {
    SMDiagnostic Error;
    M = parseAssemblyString(R"(
      define i32 @f(i32 %x) {
        %y = add i32 %x, 1
        ret i32 %y
      }
    )",
                            Error, Context);
    ASSERT_NE(M, nullptr) << Error.getMessage().str();
  }

  const Function &f() { return *M->getFunction("f"); }

  static std::string print(const Binding &B, ModuleSlotTracker *Slots) {
    std::string Str;
    raw_string_ostream OS(Str);
    printBinding(OS, B, Slots);
    return Str;
  }
};

TEST_F(BindingTest, PrintsEveryKindOfValue) {
  const Function &F = f();
  const Value *Named = &*F.getEntryBlock().begin();
  const Value *Argument = F.getArg(0);
  EXPECT_EQ(print(Binding(Named), nullptr), "%y");
  EXPECT_EQ(print(Binding(Argument), nullptr), "%x");
  EXPECT_EQ(print(Binding(Type::getInt32Ty(Context)), nullptr), "i32");
  EXPECT_EQ(print(Binding(CmpInst::ICMP_ULT), nullptr), "ult");
  EXPECT_EQ(print(Binding(Intrinsic::ctlz), nullptr), "llvm.ctlz");
  EXPECT_EQ(print(Binding(APInt(8, 5)), nullptr), "5");
  EXPECT_EQ(print(Binding(APSInt(APInt(8, 255), /*isUnsigned=*/false)),
                  nullptr),
            "-1");
  EXPECT_EQ(print(Binding(true), nullptr), "true");
  EXPECT_EQ(print(Binding(false), nullptr), "false");
}

TEST_F(BindingTest, PrintsListsOfTypesAndValues) {
  const Function &F = f();
  Binding::TypeArray Types = {Type::getInt32Ty(Context),
                              Type::getInt8Ty(Context)};
  EXPECT_EQ(print(Binding(Types), nullptr), "[i32, i8]");
  // Named values print by name, unnamed ones by their number.
  Binding::ValueArray Values = {F.getArg(0), &*F.getEntryBlock().begin(),
                                ConstantInt::get(Type::getInt32Ty(Context), 7)};
  EXPECT_EQ(print(Binding(Values), nullptr), "[%x, %y, 7]");
}

TEST_F(BindingTest, NumbersUnnamedValuesThroughTheSlotTracker) {
  const Function &F = f();
  ModuleSlotTracker Slots(M.get());
  Slots.incorporateFunction(F);
  Binding::ValueArray Values = {ConstantInt::get(Type::getInt32Ty(Context), 7)};
  EXPECT_EQ(print(Binding(Values), &Slots), "[7]");
  EXPECT_EQ(print(Binding(F.getArg(0)), &Slots), "%x");
}

TEST_F(BindingTest, StreamsTheBinding) {
  std::string Str;
  raw_string_ostream OS(Str);
  OS << Binding(f().getArg(0));
  EXPECT_EQ(OS.str(), "%x");
}

TEST_F(BindingTest, PredicatesAreTheSameIfSpelledTheSame) {
  EXPECT_EQ(Binding(CmpInst::ICMP_ULT), Binding(CmpInst::FCMP_ULT));
  EXPECT_EQ(Binding(CmpInst::ICMP_EQ), Binding(CmpInst::ICMP_EQ));
  EXPECT_NE(Binding(CmpInst::ICMP_ULT), Binding(CmpInst::FCMP_UGT));
  // 'eq' is icmp's only; fcmp's equality is 'oeq' or 'ueq'.
  EXPECT_NE(Binding(CmpInst::ICMP_EQ), Binding(CmpInst::FCMP_OEQ));
}

} // namespace
