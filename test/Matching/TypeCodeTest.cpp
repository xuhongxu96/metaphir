//===- TypeCodeTest.cpp - Encoding types in index files -------------------===//
//
// Types are stored in index files as codes. A code encodes and decodes back
// to the type it was made of, and a code that does not decode to a type is
// rejected rather than asserted on.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Matching/TypeCode.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(TypeCodeTest, ByteTypesRoundTrip) {
  LLVMContext Context;
  llvm::Type *B8 = llvm::Type::getByte8Ty(Context);
  TypeCode Code = encodeType(*B8);
  EXPECT_EQ(decodeType(Code, Context), B8);
  EXPECT_EQ(getIntegerElementWidth(Code), 0u);
}

TEST(TypeCodeTest, RejectsByteWidthsOutOfRange) {
  LLVMContext Context;
  // The kind of a byte code, without its width: a byte of no width has no type.
  TypeCode Kind = encodeType(*llvm::Type::getByte8Ty(Context)) & 0xf;
  EXPECT_EQ(decodeType(Kind, Context), nullptr);
}

TEST(TypeCodeTest, IntegerElementWidthOfFloatingPointIsNone) {
  LLVMContext Context;
  TypeCode Float = encodeType(*llvm::Type::getFloatTy(Context));
  EXPECT_EQ(getIntegerElementWidth(Float), 0u);
}

TEST(TypeCodeTest, OpaqueCodesHaveNoType) {
  LLVMContext Context;
  EXPECT_EQ(decodeType(OpaqueType, Context), nullptr);
  EXPECT_EQ(decodeType(NoType, Context), nullptr);
}

} // namespace
