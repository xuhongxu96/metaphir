#include "metaphir/Matching/UseOracle.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(UseOracleTest, ReadsTheUsesOfALazyModuleOnce) {
  LLVMContext Context;
  SMDiagnostic Error;
  std::unique_ptr<Module> Source = parseAssemblyString(
      "define i32 @f(i32 %x) {\n  ret i32 %x\n}\n", Error, Context);
  ASSERT_NE(Source, nullptr);
  std::string Bytes;
  raw_string_ostream OS(Bytes);
  WriteBitcodeToFile(*Source, OS);
  OS.flush();
  auto Buffer = MemoryBuffer::getMemBufferCopy(Bytes);
  Expected<std::unique_ptr<Module>> Lazy =
      getLazyBitcodeModule(Buffer->getMemBufferRef(), Context);
  ASSERT_TRUE(static_cast<bool>(Lazy)) << toString(Lazy.takeError());
  MaterializingUseOracle Oracle(**Lazy);
  EXPECT_FALSE(Oracle.getModuleUses(*(*Lazy)->getFunction("f")));
  // Materialized once: a second query reads nothing more.
  EXPECT_FALSE(Oracle.getModuleUses(*(*Lazy)->getFunction("f")));
}

} // namespace
