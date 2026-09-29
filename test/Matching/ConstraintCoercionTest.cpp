#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/IR/Constraints.h"
#include "metaphir/IR/MIRContext.h"
#include "test/TestUtils.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Error.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using namespace llvm::metaphir::detail;

using ConstraintCoercionTest = test::ConstraintTest;

namespace {

// Coercion of a value into the same kind is the identity coercion.
TEST_F(ConstraintCoercionTest, IdentityCoercionReturnsTheValue) {
  ConstraintValue Boolean = ConstraintValue::getBoolean(true);
  Expected<ConstraintValue> Result =
      coerce(Boolean, ConstraintValue::Boolean, *integer(0));
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_TRUE(Result->getBoolean());

  ConstraintValue IntegerValue =
      ConstraintValue::getInteger(APSInt(APInt(16, 7), true));
  Result = coerce(IntegerValue, ConstraintValue::Integer, *integer(0));
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_EQ(Result->getInteger(), APSInt(APInt(16, 7), true));
}

// Boolean and Integer are mutually coercible.
TEST_F(ConstraintCoercionTest, CoercesBooleanAndInteger) {
  ConstraintValue False = ConstraintValue::getBoolean(false);
  ConstraintValue True = ConstraintValue::getBoolean(true);

  EXPECT_TRUE(canCoerceTo(False, ConstraintValue::Integer));
  Expected<ConstraintValue> Zero =
      coerce(False, ConstraintValue::Integer, *integer(0));
  ASSERT_TRUE(static_cast<bool>(Zero));
  EXPECT_EQ(Zero->getInteger(), APSInt(APInt(1, 0), true));
  Expected<ConstraintValue> One =
      coerce(True, ConstraintValue::Integer, *integer(0));
  ASSERT_TRUE(static_cast<bool>(One));
  EXPECT_EQ(One->getInteger(), APSInt(APInt(1, 1), true));

  EXPECT_TRUE(canCoerceTo(*One, ConstraintValue::Boolean));
  ConstraintValue Five =
      ConstraintValue::getInteger(APSInt(APInt(16, 5), true));
  Expected<ConstraintValue> FiveBool =
      coerce(Five, ConstraintValue::Boolean, *integer(0));
  ASSERT_TRUE(static_cast<bool>(FiveBool));
  EXPECT_TRUE(FiveBool->getBoolean());
  ConstraintValue ZeroInt =
      ConstraintValue::getInteger(APSInt(APInt(16, 0), true));
  Expected<ConstraintValue> ZeroBool =
      coerce(ZeroInt, ConstraintValue::Boolean, *integer(0));
  ASSERT_TRUE(static_cast<bool>(ZeroBool));
  EXPECT_FALSE(ZeroBool->getBoolean());
}

// A Value binding is coercible to an integer only when it is a constant int.
TEST_F(ConstraintCoercionTest, CoercesConstantIntegerValueToInteger) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  ConstraintValue Constant =
      ConstraintValue::getValue(ConstantInt::get(I32, 42));

  EXPECT_TRUE(canCoerceTo(Constant, ConstraintValue::Integer));
  Expected<ConstraintValue> Result =
      coerce(Constant, ConstraintValue::Integer, *integer(0));
  ASSERT_TRUE(static_cast<bool>(Result));
  EXPECT_EQ(Result->getInteger().getSExtValue(), 42);

  // A Value that is not a constant integer is not numeric and cannot satisfy
  // an integer demand.
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  ConstraintValue NonConstant = ConstraintValue::getValue(Add.get());
  EXPECT_FALSE(isNumeric(NonConstant));
  Expected<ConstraintValue> Error =
      coerce(NonConstant, ConstraintValue::Integer, *integer(0));
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
      coerce(TypeValue, ConstraintValue::String, *integer(0));
  ASSERT_TRUE(static_cast<bool>(TypeString));
  EXPECT_EQ(TypeString->getString(), "i32");

  ConstraintValue ValueBinding = ConstraintValue::getValue(Add.get());
  EXPECT_TRUE(isStringLike(ValueBinding));
  Expected<ConstraintValue> ValueString =
      coerce(ValueBinding, ConstraintValue::String, *integer(0));
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
      ConstraintValue::getTypeArray(Instantiation::TypeArray{I8, I32});
  EXPECT_TRUE(isStringArrayLike(Types));
  Expected<ConstraintValue> TypeStrings =
      coerce(Types, ConstraintValue::StringArray, *integer(0));
  ASSERT_TRUE(static_cast<bool>(TypeStrings));
  EXPECT_EQ(TypeStrings->getStringArray(),
            (ConstraintValue::StringArrayStorage{"i8", "i32"}));

  ConstraintValue Values =
      ConstraintValue::getValueArray(Instantiation::ValueArray{One, Two});
  EXPECT_TRUE(isStringArrayLike(Values));
  Expected<ConstraintValue> ValueStrings =
      coerce(Values, ConstraintValue::StringArray, *integer(0));
  ASSERT_TRUE(static_cast<bool>(ValueStrings));
  EXPECT_EQ(ValueStrings->getStringArray(),
            (ConstraintValue::StringArrayStorage{"1", "2"}));
}

// require* helpers forward errors and reject incoercible operands.
TEST_F(ConstraintCoercionTest, RequireHelpersReportCoercionErrors) {
  Expected<bool> Boolean = requireBoolean(
      ConstraintValue::getInteger(APSInt(APInt(16, 0), true)), *integer(0));
  ASSERT_TRUE(static_cast<bool>(Boolean));
  EXPECT_FALSE(*Boolean);

  Expected<APSInt> Integer =
      requireInteger(ConstraintValue::getBoolean(true), *integer(0));
  ASSERT_TRUE(static_cast<bool>(Integer));
  EXPECT_EQ(Integer->getZExtValue(), 1u);

  Expected<bool> BadBoolean =
      requireBoolean(ConstraintValue::getString("true"), *integer(0));
  ASSERT_FALSE(BadBoolean);
  EXPECT_EQ(toString(BadBoolean.takeError()),
            "cannot evaluate constraint '0': expected a boolean-coercible "
            "operand");

  Expected<APSInt> BadInteger =
      requireInteger(ConstraintValue::getString("1"), *integer(0));
  ASSERT_FALSE(BadInteger);
  EXPECT_EQ(toString(BadInteger.takeError()),
            "cannot evaluate constraint '0': expected an integer-coercible "
            "operand");

  Expected<ConstraintValue> BadString =
      coerce(ConstraintValue::getInteger(APSInt(APInt(16, 1), true)),
             ConstraintValue::String, *integer(0));
  ASSERT_FALSE(BadString);
  EXPECT_EQ(toString(BadString.takeError()),
            "cannot evaluate constraint '0': expected a string-coercible "
            "operand");

  Expected<ConstraintValue::StringArrayStorage> BadArray =
      requireStringArray(ConstraintValue::getBoolean(true), *integer(0));
  ASSERT_FALSE(BadArray);
  EXPECT_EQ(toString(BadArray.takeError()),
            "cannot evaluate constraint '0': expected a string-array-coercible "
            "operand");
}

} // namespace
