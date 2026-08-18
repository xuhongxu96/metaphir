#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/IR/Constraints.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/Matching/Instantiation.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Error.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class ConstraintInterpreterTest : public testing::Test {
protected:
  MIRContext Context;
  SourceRange Range;
  ConstraintInterpreter Interpreter;
  Instantiation State;

  IntegerConstraint *integer(int64_t Value) {
    return IntegerConstraint::get(Context, Value, Range);
  }

  BooleanConstraint *boolean(bool Value) {
    return BooleanConstraint::get(Context, Value, Range);
  }

  OperatorConstraint *operation(Constraint::ConstraintID Kind, StringRef Name,
                                std::initializer_list<Constraint *> Arguments) {
    Constraint::OperatorID ID = Constraint::getOperatorID(Name, Kind);
    std::optional<Constraint::OperatorSchema> Schema =
        Constraint::getOperatorSchema(ID);
    Constraint::ResultType Result =
        Schema ? Schema->Result : Constraint::BooleanResult;
    return OperatorConstraint::get(Context, Kind, Result, Name, Arguments,
                                   Range);
  }

  OperatorConstraint *unary(StringRef Name, Constraint *Operand) {
    return operation(Constraint::Unary, Name, {Operand});
  }

  OperatorConstraint *binary(StringRef Name, Constraint *Left,
                             Constraint *Right) {
    return operation(Constraint::Binary, Name, {Left, Right});
  }

  OperatorConstraint *call(StringRef Name, Constraint *Left,
                           Constraint *Right) {
    return operation(Constraint::Call, Name, {Left, Right});
  }

  ArrayAccessConstraint *access(Constraint *Array, Constraint *Index,
                                Constraint::ResultType Type) {
    return ArrayAccessConstraint::get(Context, Type, Array, Index, Range);
  }

  ArrayConstraint *array(Constraint::ResultType Type,
                         std::initializer_list<Constraint *> Elements) {
    return ArrayConstraint::get(Context, Type, Elements, Range);
  }

  ConstraintValue evaluate(const Constraint &Expression) {
    return cantFail(Interpreter.evaluate(Expression, State));
  }

  int64_t evaluateInteger(const Constraint &Expression) {
    return evaluate(Expression).getInteger().getSExtValue();
  }

  bool evaluateBoolean(const Constraint &Expression) {
    return evaluate(Expression).getBoolean();
  }
};

TEST_F(ConstraintInterpreterTest, EvaluatesLiteralsAndVariables) {
  MetaVariable *Bits = MetaVariable::get(Context, "bits", MetaType::Nat, Range);
  MetaVariable *Flag =
      MetaVariable::get(Context, "flag", MetaType::Bool, Range);
  VariableConstraint *BitsExpression =
      VariableConstraint::get(Context, Bits, Constraint::IntegerResult, Range);
  VariableConstraint *FlagExpression =
      VariableConstraint::get(Context, Flag, Constraint::BooleanResult, Range);
  State.bind(*Bits, APInt(16, 42));
  State.bind(*Flag, true);

  EXPECT_EQ(evaluateInteger(*integer(-7)), -7);
  EXPECT_TRUE(evaluateBoolean(*boolean(true)));
  EXPECT_EQ(evaluateInteger(*BitsExpression), 42);
  EXPECT_TRUE(evaluateBoolean(*FlagExpression));
}

TEST_F(ConstraintInterpreterTest, EvaluatesArithmeticOperators) {
  EXPECT_EQ(evaluateInteger(*binary("+", integer(7), integer(5))), 12);
  EXPECT_EQ(evaluateInteger(*binary("-", integer(7), integer(12))), -5);
  EXPECT_EQ(evaluateInteger(*binary("*", integer(-3), integer(4))), -12);
  EXPECT_EQ(evaluateInteger(*unary("-", integer(9))), -9);
  EXPECT_EQ(evaluateInteger(*call("sdiv", integer(-9), integer(2))), -4);
  EXPECT_EQ(evaluateInteger(*call("udiv", integer(9), integer(2))), 4);
  EXPECT_EQ(evaluateInteger(*call("srem", integer(-9), integer(4))), -1);
  EXPECT_EQ(evaluateInteger(*call("urem", integer(9), integer(4))), 1);
  EXPECT_EQ(evaluateInteger(*call("lshr", integer(16), integer(2))), 4);
  EXPECT_EQ(evaluateInteger(*call("ashr", integer(-16), integer(2))), -4);
}

TEST_F(ConstraintInterpreterTest, EvaluatesBooleanAndEqualityOperators) {
  EXPECT_TRUE(evaluateBoolean(*binary("||", boolean(false), boolean(true))));
  EXPECT_FALSE(evaluateBoolean(*binary("&&", boolean(true), boolean(false))));
  EXPECT_TRUE(evaluateBoolean(*unary("!", boolean(false))));
  EXPECT_TRUE(evaluateBoolean(*binary("==", integer(3), integer(3))));
  EXPECT_TRUE(evaluateBoolean(*binary("!=", boolean(true), boolean(false))));
  EXPECT_EQ(evaluateInteger(*binary("+", boolean(true), integer(2))), 3);
  EXPECT_TRUE(evaluateBoolean(*binary("&&", integer(2), boolean(true))));
  EXPECT_FALSE(evaluateBoolean(*unary("!", integer(1))));
  EXPECT_TRUE(evaluateBoolean(*binary("==", boolean(true), integer(1))));
}

TEST_F(ConstraintInterpreterTest, EvaluatesSignedAndUnsignedComparisons) {
  EXPECT_TRUE(evaluateBoolean(*call("slt", integer(-1), integer(1))));
  EXPECT_TRUE(evaluateBoolean(*call("sle", integer(1), integer(1))));
  EXPECT_TRUE(evaluateBoolean(*call("sgt", integer(2), integer(-1))));
  EXPECT_TRUE(evaluateBoolean(*call("sge", integer(2), integer(2))));
  EXPECT_TRUE(evaluateBoolean(*call("ult", integer(1), integer(2))));
  EXPECT_TRUE(evaluateBoolean(*call("ule", integer(2), integer(2))));
  EXPECT_TRUE(evaluateBoolean(*call("ugt", integer(3), integer(2))));
  EXPECT_TRUE(evaluateBoolean(*call("uge", integer(3), integer(3))));
}

TEST_F(ConstraintInterpreterTest, ShortCircuitsLogicalOperators) {
  OperatorConstraint *Unknown =
      operation(Constraint::Call, "unknown", {integer(1)});
  EXPECT_TRUE(evaluateBoolean(*binary("||", boolean(true), Unknown)));
  EXPECT_FALSE(evaluateBoolean(*binary("&&", boolean(false), Unknown)));
}

TEST_F(ConstraintInterpreterTest, AccessesTypeAndValueArrays) {
  LLVMContext LLVMContext;
  Type *I8 = Type::getInt8Ty(LLVMContext);
  Type *I32 = Type::getInt32Ty(LLVMContext);
  Constant *One = ConstantInt::get(I32, 1);
  Constant *Two = ConstantInt::get(I32, 2);

  MetaVariable *Types =
      MetaVariable::get(Context, "types", MetaType::TypeArray, Range);
  MetaVariable *Values =
      MetaVariable::get(Context, "values", MetaType::ValueArray, Range);
  VariableConstraint *TypesExpression = VariableConstraint::get(
      Context, Types, Constraint::TypeArrayResult, Range);
  VariableConstraint *ValuesExpression = VariableConstraint::get(
      Context, Values, Constraint::ValueArrayResult, Range);
  State.bind(*Types, Instantiation::TypeArray{I8, I32});
  State.bind(*Values, Instantiation::ValueArray{One, Two});

  ConstraintValue TypeElement =
      evaluate(*access(TypesExpression, integer(1), Constraint::TypeResult));
  ConstraintValue ValueElement =
      evaluate(*access(ValuesExpression, integer(0), Constraint::ValueResult));
  EXPECT_EQ(TypeElement.getType(), I32);
  EXPECT_EQ(ValueElement.getValue(), One);

  EXPECT_TRUE(evaluateBoolean(
      *binary("==", access(TypesExpression, integer(0), Constraint::TypeResult),
              access(TypesExpression, integer(0), Constraint::TypeResult))));
  EXPECT_TRUE(evaluateBoolean(*binary(
      "!=", access(ValuesExpression, integer(0), Constraint::ValueResult),
      access(ValuesExpression, integer(1), Constraint::ValueResult))));

  MetaVariable *ElementType =
      MetaVariable::get(Context, "element_type", MetaType::Type, Range);
  MetaVariable *ElementValue =
      MetaVariable::get(Context, "element_value", MetaType::Value, Range);
  VariableConstraint *TypeExpression = VariableConstraint::get(
      Context, ElementType, Constraint::TypeResult, Range);
  VariableConstraint *ValueExpression = VariableConstraint::get(
      Context, ElementValue, Constraint::ValueResult, Range);
  State.bind(*ElementType, I8);
  State.bind(*ElementValue, One);

  ConstraintValue TypeLiteral = evaluate(
      *array(Constraint::TypeArrayResult, {TypeExpression, TypeExpression}));
  ConstraintValue ValueLiteral = evaluate(
      *array(Constraint::ValueArrayResult, {ValueExpression, ValueExpression}));
  EXPECT_EQ(TypeLiteral.getTypeArray(), (Instantiation::TypeArray{I8, I8}));
  EXPECT_EQ(ValueLiteral.getValueArray(),
            (Instantiation::ValueArray{One, One}));

  ArrayConstraint *TypeStrings =
      array(Constraint::StringArrayResult,
            {StringConstraint::get(Context, "i8", Range),
             StringConstraint::get(Context, "i32", Range)});
  ArrayConstraint *ValueStrings =
      array(Constraint::StringArrayResult,
            {StringConstraint::get(Context, "1", Range),
             StringConstraint::get(Context, "2", Range)});
  EXPECT_TRUE(evaluateBoolean(*binary("==", TypesExpression, TypeStrings)));
  EXPECT_TRUE(evaluateBoolean(*binary("==", ValuesExpression, ValueStrings)));
  EXPECT_EQ(evaluate(*access(TypeStrings, integer(1), Constraint::StringResult))
                .getString(),
            "i32");
}

TEST_F(ConstraintInterpreterTest, EvaluatesIsaPredicates) {
  LLVMContext LLVMContext;
  Type *I32 = Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  MetaVariable *Value =
      MetaVariable::get(Context, "value", MetaType::Value, Range);
  VariableConstraint *ValueExpression =
      VariableConstraint::get(Context, Value, Constraint::ValueResult, Range);
  State.bind(*Value, Add.get());

  EXPECT_TRUE(evaluateBoolean(
      *call("isa", ValueExpression,
            StringConstraint::get(Context, "BinaryOperator", Range))));
  EXPECT_FALSE(evaluateBoolean(
      *call("isa", ValueExpression,
            StringConstraint::get(Context, "CallInst", Range))));
  std::string InstructionText;
  raw_string_ostream InstructionStream(InstructionText);
  Add->print(InstructionStream);
  EXPECT_TRUE(evaluateBoolean(
      *binary("==", ValueExpression,
              StringConstraint::get(Context, InstructionStream.str(), Range))));
  EXPECT_NE(InstructionText.find("add i32 1, 2"), std::string::npos);
  MetaVariable *TypeVariable =
      MetaVariable::get(Context, "type", MetaType::Type, Range);
  VariableConstraint *TypeExpression = VariableConstraint::get(
      Context, TypeVariable, Constraint::TypeResult, Range);
  State.bind(*TypeVariable, I32);
  EXPECT_TRUE(evaluateBoolean(*binary(
      "==", TypeExpression, StringConstraint::get(Context, "i32", Range))));

  OperatorConstraint *UnknownClass =
      call("isa", ValueExpression,
           StringConstraint::get(Context, "ImaginaryValue", Range));
  Expected<ConstraintValue> Result = Interpreter.evaluate(*UnknownClass, State);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(isa ?value \"ImaginaryValue\")': "
            "unknown LLVM value class 'ImaginaryValue'");
}

TEST_F(ConstraintInterpreterTest, ConvertsSymbolicBindingsToStrings) {
  MetaVariable *Predicate =
      MetaVariable::get(Context, "predicate", MetaType::CmpPredicate, Range);
  MetaVariable *IntrinsicVariable =
      MetaVariable::get(Context, "intrinsic", MetaType::IntrinsicID, Range);
  VariableConstraint *PredicateExpression = VariableConstraint::get(
      Context, Predicate, Constraint::StringResult, Range);
  VariableConstraint *IntrinsicExpression = VariableConstraint::get(
      Context, IntrinsicVariable, Constraint::StringResult, Range);
  State.bind(*Predicate, CmpInst::ICMP_SLT);
  State.bind(*IntrinsicVariable, Intrinsic::abs);

  EXPECT_EQ(evaluate(*PredicateExpression).getString(), "slt");
  EXPECT_EQ(evaluate(*IntrinsicExpression).getString(), "llvm.abs");
  EXPECT_TRUE(
      evaluateBoolean(*binary("==", PredicateExpression,
                              StringConstraint::get(Context, "slt", Range))));
  EXPECT_TRUE(evaluateBoolean(
      *binary("==", IntrinsicExpression,
              StringConstraint::get(Context, "llvm.abs", Range))));
}

TEST_F(ConstraintInterpreterTest, ReportsEvaluationErrors) {
  MetaVariable *Missing =
      MetaVariable::get(Context, "missing", MetaType::Nat, Range);
  VariableConstraint *MissingExpression = VariableConstraint::get(
      Context, Missing, Constraint::IntegerResult, Range);
  Expected<ConstraintValue> MissingResult =
      Interpreter.evaluate(*MissingExpression, State);
  ASSERT_FALSE(MissingResult);
  EXPECT_EQ(toString(MissingResult.takeError()),
            "cannot evaluate constraint '?missing': meta variable '?missing' "
            "is not instantiated");

  MetaVariable *Flag =
      MetaVariable::get(Context, "flag", MetaType::Bool, Range);
  VariableConstraint *FlagExpression =
      VariableConstraint::get(Context, Flag, Constraint::BooleanResult, Range);
  State.bind(*Flag, APInt(1, 1));
  Expected<ConstraintValue> IncompatibleResult =
      Interpreter.evaluate(*FlagExpression, State);
  ASSERT_FALSE(IncompatibleResult);
  EXPECT_EQ(toString(IncompatibleResult.takeError()),
            "cannot evaluate constraint '?flag': meta variable '?flag' has an "
            "incompatible binding");

  OperatorConstraint *DivisionByZero = call("udiv", integer(1), integer(0));
  Expected<ConstraintValue> DivisionResult =
      Interpreter.evaluate(*DivisionByZero, State);
  ASSERT_FALSE(DivisionResult);
  EXPECT_EQ(toString(DivisionResult.takeError()),
            "cannot evaluate constraint '(udiv 1 0)': division by zero");

  OperatorConstraint *Unknown =
      operation(Constraint::Call, "custom", {integer(1)});
  Expected<ConstraintValue> UnknownResult =
      Interpreter.evaluate(*Unknown, State);
  ASSERT_FALSE(UnknownResult);
  EXPECT_EQ(
      toString(UnknownResult.takeError()),
      "cannot evaluate constraint '(custom 1)': unknown operator 'custom'");

  MetaVariable *Values =
      MetaVariable::get(Context, "values", MetaType::ValueArray, Range);
  VariableConstraint *ValuesExpression = VariableConstraint::get(
      Context, Values, Constraint::ValueArrayResult, Range);
  State.bind(*Values, Instantiation::ValueArray{});
  ArrayAccessConstraint *OutOfBounds =
      access(ValuesExpression, integer(0), Constraint::ValueResult);
  Expected<ConstraintValue> BoundsResult =
      Interpreter.evaluate(*OutOfBounds, State);
  ASSERT_FALSE(BoundsResult);
  EXPECT_EQ(toString(BoundsResult.takeError()),
            "cannot evaluate constraint '?values[0]': array index is out of "
            "bounds");

  OperatorConstraint *InvalidShift =
      call("lshr", integer(1), integer(64));
  Expected<ConstraintValue> ShiftResult =
      Interpreter.evaluate(*InvalidShift, State);
  ASSERT_FALSE(ShiftResult);
  EXPECT_EQ(toString(ShiftResult.takeError()),
            "cannot evaluate constraint '(lshr 1 64)': shift amount is out of "
            "range");
}

} // namespace
