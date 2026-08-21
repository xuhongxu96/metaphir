#include "metaphir/Matching/TypeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/Matching/Instantiation.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

TEST(TypeMatcherTest, MatchesDerivedTypesAndCapturesShapeParameters) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  llvm::Type *Float = llvm::Type::getFloatTy(LLVMContext);
  llvm::Type *Pointer = llvm::PointerType::get(LLVMContext, 0);

  auto expectMatch = [&](llvm::metaphir::Type *M, const llvm::Type *Target) {
    Instantiation State;
    EXPECT_TRUE(TypeMatcher(*M, *Target, State).match())
        << "matcher type " << *M;
  };
  auto expectNoMatch = [&](llvm::metaphir::Type *M, const llvm::Type *Target) {
    Instantiation State;
    EXPECT_FALSE(TypeMatcher(*M, *Target, State).match())
        << "matcher type " << *M;
  };

  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::HalfTyID),
      llvm::Type::getHalfTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::BFloatTyID),
      llvm::Type::getBFloatTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::FloatTyID),
      Float);
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::DoubleTyID),
      llvm::Type::getDoubleTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::FP128TyID),
      llvm::Type::getFP128Ty(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::VoidTyID),
      llvm::Type::getVoidTy(LLVMContext));
  expectMatch(
      llvm::metaphir::Type::get(Context, llvm::metaphir::Type::LabelTyID),
      llvm::Type::getLabelTy(LLVMContext));
  expectMatch(llvm::metaphir::IntegerType::get(Context, 32), I32);
  expectMatch(llvm::metaphir::ByteType::get(Context, 8),
              llvm::Type::getByte8Ty(LLVMContext));
  expectMatch(llvm::metaphir::PointerType::get(Context), Pointer);

  llvm::Type *StructElements[] = {I8, I32};
  llvm::StructType *TargetStruct =
      llvm::StructType::get(LLVMContext, StructElements, false);
  llvm::StructType *PackedTargetStruct =
      llvm::StructType::get(LLVMContext, StructElements, true);
  llvm::StructType *OpaqueTargetStruct = llvm::StructType::create(LLVMContext);
  expectMatch(llvm::metaphir::StructType::get(
                  Context, {llvm::metaphir::IntegerType::get(Context, 8),
                            llvm::metaphir::IntegerType::get(Context, 32)}),
              TargetStruct);
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context,
                    {llvm::metaphir::IntegerType::get(Context, 8),
                     llvm::metaphir::IntegerType::get(Context, 32)},
                    true),
                TargetStruct);
  expectNoMatch(
      llvm::metaphir::StructType::get(
          Context, {llvm::metaphir::IntegerType::get(Context, 8)}),
      llvm::StructType::get(LLVMContext, llvm::ArrayRef<llvm::Type *>({I32})));
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context,
                    {llvm::metaphir::IntegerType::get(Context, 8),
                     llvm::metaphir::IntegerType::get(Context, 32)},
                    false),
                PackedTargetStruct);
  expectNoMatch(llvm::metaphir::StructType::get(
                    Context, {llvm::metaphir::IntegerType::get(Context, 8),
                              llvm::metaphir::IntegerType::get(Context, 32)}),
                OpaqueTargetStruct);

  auto *Array = llvm::metaphir::ArrayType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 32), 4);
  expectMatch(Array, llvm::ArrayType::get(I32, 4));
  expectNoMatch(Array, llvm::ArrayType::get(I32, 3));

  auto *FixedVector = llvm::metaphir::VectorType::get(
      Context, false, llvm::metaphir::IntegerType::get(Context, 32), 4);
  auto *ScalableVector = llvm::metaphir::VectorType::get(
      Context, true, llvm::metaphir::IntegerType::get(Context, 32), 4);
  expectMatch(FixedVector, llvm::FixedVectorType::get(I32, 4));
  expectMatch(ScalableVector, llvm::ScalableVectorType::get(I32, 4));
  expectNoMatch(FixedVector, llvm::ScalableVectorType::get(I32, 4));

  llvm::Type *Parameters[] = {I8, Pointer};
  auto *Function = llvm::metaphir::FunctionType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 32),
      {llvm::metaphir::IntegerType::get(Context, 8),
       llvm::metaphir::PointerType::get(Context)},
      false);
  expectMatch(Function, llvm::FunctionType::get(I32, Parameters, false));
  expectNoMatch(Function, llvm::FunctionType::get(I32, Parameters, true));

  MetaVariable *Element =
      MetaVariable::get(Context, "element", MetaType::Type, Range);
  Instantiation ElementState;
  EXPECT_TRUE(TypeMatcher(*llvm::metaphir::MetaIRType::get(Context, Element),
                          *I32, ElementState)
                  .match());
  EXPECT_EQ(*ElementState.lookup(*Element), Instantiation::Binding(I32));

  MetaVariable *Bits = MetaVariable::get(Context, "bits", MetaType::Nat, Range);
  Instantiation BitsState;
  EXPECT_TRUE(
      TypeMatcher(*llvm::metaphir::MetaIntegerType::get(Context, Bits, false),
                  *I32, BitsState)
          .match());
  EXPECT_EQ(*BitsState.lookup(*Bits), Instantiation::Binding(APInt(64, 32)));

  MetaVariable *ByteBits =
      MetaVariable::get(Context, "byte_bits", MetaType::Nat, Range);
  Instantiation ByteBitsState;
  EXPECT_TRUE(TypeMatcher(*llvm::metaphir::MetaIntegerType::get(Context,
                                                                ByteBits, true),
                          *llvm::Type::getByte8Ty(LLVMContext), ByteBitsState)
                  .match());
  EXPECT_EQ(*ByteBitsState.lookup(*ByteBits),
            Instantiation::Binding(APInt(64, 8)));

  MetaVariable *Count =
      MetaVariable::get(Context, "count", MetaType::Nat, Range);
  auto *CountedArray = llvm::metaphir::ArrayType::get(
      Context, llvm::metaphir::IntegerType::get(Context, 8), 0, Count);
  Instantiation CountState;
  EXPECT_TRUE(
      TypeMatcher(*CountedArray, *llvm::ArrayType::get(I8, 6), CountState)
          .match());
  EXPECT_EQ(*CountState.lookup(*Count), Instantiation::Binding(APInt(64, 6)));
}
