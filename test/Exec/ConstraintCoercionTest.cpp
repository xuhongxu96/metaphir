#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Error.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using namespace llvm::metaphir::detail;

namespace {

/// Coercions name the expression whose value they coerce in their errors:
/// here, the integer 0.
class ConstraintCoercionTest : public testing::Test {
protected:
  ConstraintCoercionTest()
      : Module(mlir::ModuleOp::create(mlir::UnknownLoc::get(&Context))) {
    Context.loadDialect<mpir::PatternDialect, mpir_expr::ExprDialect>();
    mlir::OpBuilder Builder(&Context);
    Builder.setInsertionPointToEnd(Module->getBody());
    Zero = mpir_expr::IntOp::create(Builder, Builder.getUnknownLoc(),
                                    APSInt(APInt(64, 0), false));
  }

  mlir::MLIRContext Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module;
  mlir::Value Zero;

  mlir::Value zero() { return Zero; }
};

// Coercion of a value into the same kind is the identity coercion.
TEST_F(ConstraintCoercionTest, IdentityCoercionReturnsTheValue) {
  ConstraintValue Boolean = ConstraintValue::getBoolean(true);
  Expected<ConstraintValue> Result =
      coerce(Boolean, ConstraintValue::Boolean, zero());
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_TRUE(Result->getBoolean());

  ConstraintValue IntegerValue =
      ConstraintValue::getInteger(APSInt(APInt(16, 7), true));
  Result = coerce(IntegerValue, ConstraintValue::Integer, zero());
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_EQ(Result->getInteger(), APSInt(APInt(16, 7), true));
}

// Boolean and Integer are mutually coercible.
TEST_F(ConstraintCoercionTest, CoercesBooleanAndInteger) {
  ConstraintValue False = ConstraintValue::getBoolean(false);
  ConstraintValue True = ConstraintValue::getBoolean(true);

  EXPECT_TRUE(canCoerceTo(False, ConstraintValue::Integer));
  Expected<ConstraintValue> Zero =
      coerce(False, ConstraintValue::Integer, zero());
  ASSERT_TRUE(static_cast<bool>(Zero));
  EXPECT_EQ(Zero->getInteger(), APSInt(APInt(1, 0), true));
  Expected<ConstraintValue> One =
      coerce(True, ConstraintValue::Integer, zero());
  ASSERT_TRUE(static_cast<bool>(One));
  EXPECT_EQ(One->getInteger(), APSInt(APInt(1, 1), true));

  EXPECT_TRUE(canCoerceTo(*One, ConstraintValue::Boolean));
  ConstraintValue Five =
      ConstraintValue::getInteger(APSInt(APInt(16, 5), true));
  Expected<ConstraintValue> FiveBool =
      coerce(Five, ConstraintValue::Boolean, zero());
  ASSERT_TRUE(static_cast<bool>(FiveBool));
  EXPECT_TRUE(FiveBool->getBoolean());
  ConstraintValue ZeroInt =
      ConstraintValue::getInteger(APSInt(APInt(16, 0), true));
  Expected<ConstraintValue> ZeroBool =
      coerce(ZeroInt, ConstraintValue::Boolean, zero());
  ASSERT_TRUE(static_cast<bool>(ZeroBool));
  EXPECT_FALSE(ZeroBool->getBoolean());
}

// A Value binding is coercible to an integer only when it is an integer
// constant or a splat of one.
TEST_F(ConstraintCoercionTest, CoercesConstantIntegerValueToInteger) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  ConstraintValue Constant =
      ConstraintValue::getValue(ConstantInt::get(I32, 42));

  EXPECT_TRUE(canCoerceTo(Constant, ConstraintValue::Integer));
  Expected<ConstraintValue> Result =
      coerce(Constant, ConstraintValue::Integer, zero());
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_EQ(Result->getInteger().getSExtValue(), 42);

  // A Value that is not a constant integer is not numeric and cannot satisfy
  // an integer demand.
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  ConstraintValue NonConstant = ConstraintValue::getValue(Add.get());
  EXPECT_FALSE(isNumeric(NonConstant));
  Expected<ConstraintValue> Error =
      coerce(NonConstant, ConstraintValue::Integer, zero());
  ASSERT_FALSE(Error);
  EXPECT_EQ(toString(Error.takeError()),
            "cannot evaluate constraint '0': expected an integer-valued "
            "constant operand");
}

// Types and values stringify to their printed representation.
TEST_F(ConstraintCoercionTest, CoercesTypesAndValuesToStrings) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));

  ConstraintValue TypeValue = ConstraintValue::getType(I32);
  EXPECT_TRUE(isStringLike(TypeValue));
  Expected<ConstraintValue> TypeString =
      coerce(TypeValue, ConstraintValue::String, zero());
  ASSERT_TRUE(static_cast<bool>(TypeString));
  EXPECT_EQ(TypeString->getString(), "i32");

  ConstraintValue ValueBinding = ConstraintValue::getValue(Add.get());
  EXPECT_TRUE(isStringLike(ValueBinding));
  Expected<ConstraintValue> ValueString =
      coerce(ValueBinding, ConstraintValue::String, zero());
  ASSERT_TRUE(static_cast<bool>(ValueString));
  EXPECT_NE(ValueString->getString().find("add"), StringRef::npos);
}

// Arrays of types and values stringify elementwise.
TEST_F(ConstraintCoercionTest, CoercesArraysToStringArrays) {
  LLVMContext LLVMContext;
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  Constant *One = ConstantInt::get(I32, 1);
  Constant *Two = ConstantInt::get(I32, 2);

  ConstraintValue Types =
      ConstraintValue::getTypeArray(Binding::TypeArray{I8, I32});
  EXPECT_TRUE(isStringArrayLike(Types));
  Expected<ConstraintValue> TypeStrings =
      coerce(Types, ConstraintValue::StringArray, zero());
  ASSERT_TRUE(static_cast<bool>(TypeStrings));
  EXPECT_EQ(TypeStrings->getStringArray(),
            (ConstraintValue::StringArrayStorage{"i8", "i32"}));

  ConstraintValue Values =
      ConstraintValue::getValueArray(Binding::ValueArray{One, Two});
  EXPECT_TRUE(isStringArrayLike(Values));
  Expected<ConstraintValue> ValueStrings =
      coerce(Values, ConstraintValue::StringArray, zero());
  ASSERT_TRUE(static_cast<bool>(ValueStrings));
  EXPECT_EQ(ValueStrings->getStringArray(),
            (ConstraintValue::StringArrayStorage{"1", "2"}));
}

// require* helpers forward errors and reject incoercible operands.
TEST_F(ConstraintCoercionTest, RequireHelpersReportCoercionErrors) {
  Expected<bool> Boolean = requireBoolean(
      ConstraintValue::getInteger(APSInt(APInt(16, 0), true)), zero());
  ASSERT_TRUE(static_cast<bool>(Boolean));
  EXPECT_FALSE(*Boolean);

  Expected<APSInt> Integer =
      requireInteger(ConstraintValue::getBoolean(true), zero());
  ASSERT_TRUE(static_cast<bool>(Integer));
  EXPECT_EQ(Integer->getZExtValue(), 1u);

  Expected<bool> BadBoolean =
      requireBoolean(ConstraintValue::getString("true"), zero());
  ASSERT_FALSE(BadBoolean);
  EXPECT_EQ(toString(BadBoolean.takeError()),
            "cannot evaluate constraint '0': expected a boolean-coercible "
            "operand");

  Expected<APSInt> BadInteger =
      requireInteger(ConstraintValue::getString("1"), zero());
  ASSERT_FALSE(BadInteger);
  EXPECT_EQ(toString(BadInteger.takeError()),
            "cannot evaluate constraint '0': expected an integer-coercible "
            "operand");

  Expected<ConstraintValue> BadString =
      coerce(ConstraintValue::getInteger(APSInt(APInt(16, 1), true)),
             ConstraintValue::String, zero());
  ASSERT_FALSE(BadString);
  EXPECT_EQ(toString(BadString.takeError()),
            "cannot evaluate constraint '0': expected a string-coercible "
            "operand");

  Expected<ConstraintValue::StringArrayStorage> BadArray =
      requireStringArray(ConstraintValue::getBoolean(true), zero());
  ASSERT_FALSE(BadArray);
  EXPECT_EQ(toString(BadArray.takeError()),
            "cannot evaluate constraint '0': expected a string-array-coercible "
            "operand");
}

// A failed coercion names what it was coercing to, for each kind of value.
TEST_F(ConstraintCoercionTest, NamesEveryTargetOfAFailedCoercion) {
  llvm::LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  for (ConstraintValue::ValueKind Target :
       {ConstraintValue::Integer, ConstraintValue::Boolean,
        ConstraintValue::String, ConstraintValue::StringArray,
        ConstraintValue::Type, ConstraintValue::Value,
        ConstraintValue::TypeArray, ConstraintValue::ValueArray,
        ConstraintValue::BitVector}) {
    Expected<ConstraintValue> Result =
        coerce(ConstraintValue::getTypeArray({I32}), Target, zero());
    if (Result)
      continue;
    std::string Message = toString(Result.takeError());
    EXPECT_NE(Message.find("cannot"), std::string::npos) << Message;
  }
}

// A value array coerces to the array of its values' texts.
TEST_F(ConstraintCoercionTest, CoercesValueArraysToTexts) {
  llvm::LLVMContext LLVMContext;
  llvm::Constant *One = ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 1);
  Expected<ConstraintValue> Result = coerce(
      ConstraintValue::getValueArray({One, One}), ConstraintValue::StringArray, zero());
  ASSERT_TRUE(bool(Result));
  EXPECT_EQ(Result->getStringArray().size(), 2u);
  EXPECT_EQ(Result->getStringArray()[0], "1");
}

// Equality of arrays and of known bits compares their contents.
TEST_F(ConstraintCoercionTest, ComparesArraysAndKnownBits) {
  llvm::LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  llvm::Constant *One = ConstantInt::get(I32, 1);
  auto equal = [&](ConstraintValue L, ConstraintValue R) {
    return cantFail(evaluateEquality(std::move(L), std::move(R), zero()));
  };
  EXPECT_TRUE(equal(ConstraintValue::getTypeArray({I32}), ConstraintValue::getTypeArray({I32})));
  EXPECT_FALSE(equal(ConstraintValue::getTypeArray({I32}), ConstraintValue::getTypeArray({})));
  EXPECT_TRUE(equal(ConstraintValue::getValueArray({One}), ConstraintValue::getValueArray({One})));
  EXPECT_FALSE(equal(ConstraintValue::getValueArray({One}), ConstraintValue::getValueArray({})));
  EXPECT_TRUE(equal(ConstraintValue::getStringArray({"a"}), ConstraintValue::getStringArray({"a"})));
  EXPECT_FALSE(equal(ConstraintValue::getStringArray({"a"}), ConstraintValue::getStringArray({"b"})));
  llvm::KnownBits Bits(8);
  EXPECT_TRUE(equal(ConstraintValue::getKnownBits(Bits), ConstraintValue::getKnownBits(Bits)));
}

} // namespace
