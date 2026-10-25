#include "metaphir/Index/FunctionPack.h"
#include "metaphir/Index/FunctionPacker.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"
#include <regex>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class FunctionPackTest : public testing::Test {
protected:
  LLVMContext Context;
  std::unique_ptr<Module> M;
  /// The packs of M's functions, by name.
  StringMap<FunctionPack> Packs;

  void pack(StringRef IR) {
    SMDiagnostic Error;
    M = parseAssemblyString(IR, Error, Context);
    ASSERT_NE(M, nullptr) << Error.getMessage().str();
    ASSERT_FALSE(errorToBool(
        packFunctions(*M, [&](const Function &F, FunctionPack Pack) {
          Packs[F.getName()] = std::move(Pack);
          return Error::success();
        })));
  }

  /// The pack of F, encoded, decoded and read back.
  std::unique_ptr<UnpackedFunction> unpack(StringRef F, LLVMContext &Into) {
    std::string Encoded;
    Packs[F].encode(Encoded);
    Expected<FunctionPack> Decoded = FunctionPack::decode(Encoded);
    EXPECT_TRUE(static_cast<bool>(Decoded)) << toString(Decoded.takeError());
    if (!Decoded)
      return nullptr;
    Expected<std::unique_ptr<UnpackedFunction>> Unpacked =
        UnpackedFunction::read(*Decoded, Into);
    EXPECT_TRUE(static_cast<bool>(Unpacked)) << toString(Unpacked.takeError());
    return Unpacked ? std::move(*Unpacked) : nullptr;
  }

  // The function as text, with metadata references written as "!N": a
  // function printed alone numbers its metadata by what the rest of its module
  // holds, so the numbers differ between the packed and the unpacked module.
  static std::string print(const Function &F) {
    std::string Str;
    raw_string_ostream OS(Str);
    F.print(OS);
    return std::regex_replace(Str, std::regex("![0-9]+"), "!N");
  }

  static std::string printOperand(const llvm::Value &V) {
    std::string Str;
    raw_string_ostream OS(Str);
    V.printAsOperand(OS, /*PrintType=*/false);
    return Str;
  }
};

TEST_F(FunctionPackTest, RoundTripsTheFunction) {
  pack(R"(
    target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128"
    target triple = "x86_64-unknown-linux-gnu"
    @g = internal global i32 7, align 16
    @c = private unnamed_addr constant [2 x i8] c"hi"
    @common = common global i32 0
    declare i32 @ext(i32) nounwind
    define internal fastcc i32 @h(i32 %x) {
      ret i32 %x
    }
    define i32 @f(i32 %x) {
      %v = load i32, ptr @g, !range !0
      %p = getelementptr i8, ptr @c, i64 1
      %a = call i32 @ext(i32 %v)
      %b = call fastcc i32 @h(i32 %a)
      store i32 %b, ptr @common
      ret i32 %b
    }
    !0 = !{i32 0, i32 10}
  )");
  LLVMContext Into;
  unsigned Diagnostics = 0;
  Into.setDiagnosticHandlerCallBack(
      [](const DiagnosticInfo *, void *Count) {
        ++*static_cast<unsigned *>(Count);
      },
      &Diagnostics);
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  EXPECT_EQ(print(F->getFunction()), print(*M->getFunction("f")));
  const auto &Load = cast<LoadInst>(F->getFunction().front().front());
  const MDNode *Range = Load.getMetadata(LLVMContext::MD_range);
  ASSERT_NE(Range, nullptr);
  ASSERT_EQ(Range->getNumOperands(), 2u);
  EXPECT_EQ(mdconst::extract<ConstantInt>(Range->getOperand(0))->getZExtValue(),
            0u);
  EXPECT_EQ(mdconst::extract<ConstantInt>(Range->getOperand(1))->getZExtValue(),
            10u);
  // Without debug info, reading the pack finds none to drop.
  EXPECT_EQ(Diagnostics, 0u);

  const Module &Packed = *F->getFunction().getParent();
  EXPECT_EQ(Packed.getDataLayoutStr(), M->getDataLayoutStr());
  EXPECT_EQ(Packed.getTargetTriple(), M->getTargetTriple());
  const GlobalVariable *G = Packed.getNamedGlobal("g");
  ASSERT_NE(G, nullptr);
  EXPECT_EQ(G->getLinkage(), GlobalValue::InternalLinkage);
  EXPECT_EQ(G->getAlign(), MaybeAlign(16));
  const GlobalVariable *C = Packed.getNamedGlobal("c");
  ASSERT_NE(C, nullptr);
  EXPECT_TRUE(C->isConstant());
  EXPECT_EQ(C->getUnnamedAddr(), GlobalValue::UnnamedAddr::Global);
  const GlobalVariable *Common = Packed.getNamedGlobal("common");
  ASSERT_NE(Common, nullptr);
  EXPECT_EQ(Common->getLinkage(), GlobalValue::CommonLinkage);
  const Function *H = Packed.getFunction("h");
  ASSERT_NE(H, nullptr);
  EXPECT_EQ(H->getLinkage(), GlobalValue::InternalLinkage);
  EXPECT_EQ(H->getCallingConv(), CallingConv::Fast);
  const Function *Ext = Packed.getFunction("ext");
  ASSERT_NE(Ext, nullptr);
  EXPECT_TRUE(Ext->isDeclaration());
  EXPECT_TRUE(Ext->doesNotThrow());
}

TEST_F(FunctionPackTest, KeepsTheOrderOfUseLists) {
  pack(R"(
    @g = global i32 0
    define i32 @f(i32 %x, i1 %c) {
    entry:
      %a = add i32 %x, 1
      %b = mul i32 %x, %a
      %d = sdiv i32 %b, %x
      store i32 %x, ptr @g
      %l = load i32, ptr @g
      br i1 %c, label %next, label %next
    next:
      %s = add i32 %a, %d
      %t = add i32 %a, %l
      ret i32 %t
    }
  )");
  // Analyses that walk only some of a value's uses depend on their order,
  // which parsing does not decide: one other than its order is kept.
  Function &Original = *M->getFunction("f");
  BasicBlock &Next = *std::next(Original.begin());
  Value &A = *Original.getEntryBlock().begin();
  for (Value *V : {static_cast<Value *>(Original.getArg(0)), &A,
                   static_cast<Value *>(&Next),
                   static_cast<Value *>(M->getNamedGlobal("g"))})
    V->reverseUseList();
  Packs.clear();
  ASSERT_FALSE(
      errorToBool(packFunctions(*M, [&](const Function &F, FunctionPack Pack) {
        Packs[F.getName()] = std::move(Pack);
        return Error::success();
      })));

  // A use, by the text of its user and the operand it is.
  auto Uses = [](const Value &V) {
    std::vector<std::string> Result;
    for (const Use &U : V.uses()) {
      std::string Text;
      raw_string_ostream OS(Text);
      U.getUser()->print(OS);
      Result.push_back(Text + " #" + std::to_string(U.getOperandNo()));
    }
    return Result;
  };
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> Unpacked = unpack("f", Into);
  ASSERT_NE(Unpacked, nullptr);
  const Function &F = Unpacked->getFunction();
  EXPECT_EQ(Uses(*F.getArg(0)), Uses(*Original.getArg(0)));
  EXPECT_EQ(Uses(*F.getEntryBlock().begin()), Uses(A));
  EXPECT_EQ(Uses(*std::next(F.begin())), Uses(Next));
  EXPECT_EQ(Uses(*F.getParent()->getNamedGlobal("g")),
            Uses(*M->getNamedGlobal("g")));
}

TEST_F(FunctionPackTest, TellsHowConstantsAreUsedInTheModule) {
  pack(R"(
    @shared = global i32 0
    @own = global i32 0
    define void @f() {
      store i32 1, ptr @shared
      store i32 2, ptr @own
      store i32 3, ptr getelementptr (i8, ptr @own, i64 4)
      ret void
    }
    define void @g() {
      store i32 4, ptr @shared
      ret void
    }
  )");
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  const Module &Packed = *F->getFunction().getParent();

  std::optional<ModuleUses> Shared =
      F->getModuleUses(*Packed.getNamedGlobal("shared"));
  ASSERT_TRUE(Shared.has_value());
  EXPECT_EQ(Shared->NumUses, 2u);
  EXPECT_FALSE(Shared->OneUser);
  // Used by a store and by the getelementptr.
  std::optional<ModuleUses> Own =
      F->getModuleUses(*Packed.getNamedGlobal("own"));
  ASSERT_TRUE(Own.has_value());
  EXPECT_EQ(Own->NumUses, 2u);
  auto *Store =
      cast<StoreInst>(std::next(F->getFunction().getEntryBlock().begin(), 2));
  std::optional<ModuleUses> Offset =
      F->getModuleUses(*Store->getPointerOperand());
  ASSERT_TRUE(Offset.has_value());
  EXPECT_EQ(Offset->NumUses, 1u);
  EXPECT_TRUE(Offset->OneUser);
}

TEST_F(FunctionPackTest, KeepsTheNumbersOfUnnamedGlobals) {
  pack(R"(
    @0 = global i32 0
    @1 = global i32 1
    @2 = global i32 2
    declare void @3()
    define void @f() {
      store i32 0, ptr @2
      call void @3()
      ret void
    }
    define void @4() {
      store i32 0, ptr @0
      ret void
    }
  )");
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  const BasicBlock &Entry = F->getFunction().getEntryBlock();
  auto It = Entry.begin();
  EXPECT_EQ(printOperand(*cast<StoreInst>(*It++).getPointerOperand()), "@2");
  EXPECT_EQ(printOperand(*cast<CallInst>(*It).getCalledOperand()), "@3");

  // An unnamed function is found as well.
  std::unique_ptr<UnpackedFunction> Four = unpack("", Into);
  ASSERT_NE(Four, nullptr);
  EXPECT_EQ(printOperand(Four->getFunction()), "@4");
  EXPECT_EQ(
      printOperand(*cast<StoreInst>(Four->getFunction().getEntryBlock().front())
                        .getPointerOperand()),
      "@0");
}

TEST_F(FunctionPackTest, StubsAliasesAndIFuncs) {
  pack(R"(
    @g = internal global [4 x i32] zeroinitializer
    @a = internal alias i32, getelementptr (i8, ptr @g, i64 4)
    @0 = alias i32, ptr @g
    @i = ifunc void (), ptr @resolve
    define internal ptr @resolve() {
      ret ptr null
    }
    define void @f() {
      store i32 1, ptr @a
      store i32 2, ptr @0
      call void @i()
      ret void
    }
  )");
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  EXPECT_EQ(print(F->getFunction()), print(*M->getFunction("f")));
  const Module &Packed = *F->getFunction().getParent();
  const GlobalAlias *A = Packed.getNamedAlias("a");
  ASSERT_NE(A, nullptr);
  EXPECT_EQ(printOperand(*A->getAliasee()),
            "getelementptr (i8, ptr @g, i64 4)");
  const GlobalIFunc *I = Packed.getNamedIFunc("i");
  ASSERT_NE(I, nullptr);
  EXPECT_EQ(I->getResolverFunction()->getName(), "resolve");
}

TEST_F(FunctionPackTest, KeepsDebugInfo) {
  pack(R"(
    define i32 @f(i32 %x) !dbg !4 {
      %y = add i32 %x, 1, !dbg !6
      ret i32 %y, !dbg !6
    }
    !llvm.dbg.cu = !{!0}
    !llvm.module.flags = !{!3}
    !0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug)
    !1 = !DIFile(filename: "f.c", directory: "/")
    !3 = !{i32 2, !"Debug Info Version", i32 3}
    !4 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 1, type: !5, unit: !0, spFlags: DISPFlagDefinition)
    !5 = !DISubroutineType(types: !{})
    !6 = !DILocation(line: 2, scope: !4)
  )");
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  const llvm::Instruction &Add = F->getFunction().getEntryBlock().front();
  ASSERT_TRUE(Add.getDebugLoc());
  EXPECT_EQ(Add.getDebugLoc().getLine(), 2u);
}

TEST_F(FunctionPackTest, PacksModulesThatDoNotVerify) {
  // The matcher takes such modules too.
  pack(R"(
    define i64 @f(i1 %c, i64 %t) {
    entry:
      br i1 %c, label %a, label %b
    a:
      %s = sub i64 0, %t
      br label %b
    b:
      %z = add i64 %s, 1
      ret i64 %z
    }
  )");
  LLVMContext Into;
  std::unique_ptr<UnpackedFunction> F = unpack("f", Into);
  ASSERT_NE(F, nullptr);
  EXPECT_EQ(print(F->getFunction()), print(*M->getFunction("f")));
}

TEST_F(FunctionPackTest, SkipsDeclarations) {
  pack(R"(
    declare void @d()
    define void @f() {
      call void @d()
      ret void
    }
  )");
  EXPECT_EQ(Packs.size(), 1u);
  EXPECT_TRUE(Packs.count("f"));
}

TEST_F(FunctionPackTest, RejectsMalformedPacks) {
  EXPECT_TRUE(errorToBool(FunctionPack::decode("").takeError()));
  pack(R"(
    define void @f() {
      ret void
    }
  )");
  std::string Encoded;
  Packs["f"].encode(Encoded);
  Expected<FunctionPack> Cut =
      FunctionPack::decode(StringRef(Encoded).drop_back(4));
  ASSERT_TRUE(static_cast<bool>(Cut));
  LLVMContext Into;
  EXPECT_FALSE(static_cast<bool>(UnpackedFunction::read(*Cut, Into)));
}

} // namespace
