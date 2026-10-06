#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/UseOracle.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "test/TestUtils.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class ConstraintInterpreterTest : public test::ConstraintTest {
protected:
  ConstraintInterpreter Interpreter;
  Instantiation State;

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
  MetaVariable *Bits =
      MetaVariable::create(Context, "bits", MetaType::Nat, Range);
  MetaVariable *Flag =
      MetaVariable::create(Context, "flag", MetaType::Bool, Range);
  VariableConstraint *BitsExpression = VariableConstraint::create(
      Context, Bits, Constraint::IntegerResult, Range);
  VariableConstraint *FlagExpression = VariableConstraint::create(
      Context, Flag, Constraint::BooleanResult, Range);
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
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  Constant *One = ConstantInt::get(I32, 1);
  Constant *Two = ConstantInt::get(I32, 2);

  MetaVariable *Types =
      MetaVariable::create(Context, "types", MetaType::TypeArray, Range);
  MetaVariable *Values =
      MetaVariable::create(Context, "values", MetaType::ValueArray, Range);
  VariableConstraint *TypesExpression = VariableConstraint::create(
      Context, Types, Constraint::TypeArrayResult, Range);
  VariableConstraint *ValuesExpression = VariableConstraint::create(
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
      MetaVariable::create(Context, "element_type", MetaType::Type, Range);
  MetaVariable *ElementValue =
      MetaVariable::create(Context, "element_value", MetaType::Value, Range);
  VariableConstraint *TypeExpression = VariableConstraint::create(
      Context, ElementType, Constraint::TypeResult, Range);
  VariableConstraint *ValueExpression = VariableConstraint::create(
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
            {StringConstraint::create(Context, "i8", Range),
             StringConstraint::create(Context, "i32", Range)});
  ArrayConstraint *ValueStrings =
      array(Constraint::StringArrayResult,
            {StringConstraint::create(Context, "1", Range),
             StringConstraint::create(Context, "2", Range)});
  EXPECT_TRUE(evaluateBoolean(*binary("==", TypesExpression, TypeStrings)));
  EXPECT_TRUE(evaluateBoolean(*binary("==", ValuesExpression, ValueStrings)));
  EXPECT_EQ(evaluate(*access(TypeStrings, integer(1), Constraint::StringResult))
                .getString(),
            "i32");
}

TEST_F(ConstraintInterpreterTest, EvaluatesIsaPredicates) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  MetaVariable *Value =
      MetaVariable::create(Context, "value", MetaType::Value, Range);
  VariableConstraint *ValueExpression = VariableConstraint::create(
      Context, Value, Constraint::ValueResult, Range);
  State.bind(*Value, Add.get());

  EXPECT_TRUE(evaluateBoolean(
      *call("isa", ValueExpression,
            StringConstraint::create(Context, "BinaryOperator", Range))));
  EXPECT_FALSE(evaluateBoolean(
      *call("isa", ValueExpression,
            StringConstraint::create(Context, "CallInst", Range))));
  std::string InstructionText;
  raw_string_ostream InstructionStream(InstructionText);
  Add->print(InstructionStream);
  EXPECT_TRUE(evaluateBoolean(*binary(
      "==", ValueExpression,
      StringConstraint::create(Context, InstructionStream.str(), Range))));
  EXPECT_NE(InstructionText.find("add i32 1, 2"), std::string::npos);
  MetaVariable *TypeVariable =
      MetaVariable::create(Context, "type", MetaType::Type, Range);
  VariableConstraint *TypeExpression = VariableConstraint::create(
      Context, TypeVariable, Constraint::TypeResult, Range);
  State.bind(*TypeVariable, I32);
  EXPECT_TRUE(evaluateBoolean(*binary(
      "==", TypeExpression, StringConstraint::create(Context, "i32", Range))));

  OperatorConstraint *UnknownClass =
      call("isa", ValueExpression,
           StringConstraint::create(Context, "ImaginaryValue", Range));
  Expected<ConstraintValue> Result = Interpreter.evaluate(*UnknownClass, State);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(isa ?value \"ImaginaryValue\")': "
            "unknown LLVM value class 'ImaginaryValue'");
}

TEST_F(ConstraintInterpreterTest, EvaluatesUsePredicates) {
  LLVMContext LLVMContext;
  SMDiagnostic Error;
  std::unique_ptr<Module> M = parseAssemblyString(
      R"(
        define i32 @f(i32 %x, i32 %y) {
          %a = add i32 %x, %y
          %b = add i32 %a, %a
          %c = add i32 %b, 1
          ret i32 %c
        }
      )",
      Error, LLVMContext);
  ASSERT_NE(M, nullptr);
  Function *F = M->getFunction("f");
  auto It = F->getEntryBlock().begin();
  const llvm::Instruction *A = &*It++;
  const llvm::Instruction *B = &*It++;

  MetaVariable *ValA =
      MetaVariable::create(Context, "a", MetaType::Value, Range);
  MetaVariable *ValB =
      MetaVariable::create(Context, "b", MetaType::Value, Range);
  VariableConstraint *ExprA =
      VariableConstraint::create(Context, ValA, Constraint::ValueResult, Range);
  VariableConstraint *ExprB =
      VariableConstraint::create(Context, ValB, Constraint::ValueResult, Range);
  State.bind(*ValA, A);
  State.bind(*ValB, B);

  EXPECT_FALSE(evaluateBoolean(*call("hasOneUse", ExprA)));
  EXPECT_TRUE(evaluateBoolean(*call("hasOneUser", ExprA)));

  EXPECT_TRUE(evaluateBoolean(*call("hasOneUse", ExprB)));
  EXPECT_TRUE(evaluateBoolean(*call("hasOneUser", ExprB)));
}

/// Claims every value it is asked about has one use but two users.
class OneUseOracle : public UseOracle {
public:
  std::optional<ModuleUses> getModuleUses(const llvm::Value &V) override {
    Asked.push_back(&V);
    return ModuleUses{/*OneUse=*/true, /*OneUser=*/false};
  }
  SmallVector<const llvm::Value *, 2> Asked;
};

TEST_F(ConstraintInterpreterTest, AsksUseOracleAboutConstants) {
  LLVMContext LLVMContext;
  SMDiagnostic Error;
  std::unique_ptr<Module> M = parseAssemblyString(
      R"(
        @g = global i32 0
        define i32 @f() {
          %a = load i32, ptr @g
          %b = load i32, ptr @g
          %c = add i32 %a, %b
          ret i32 %c
        }
      )",
      Error, LLVMContext);
  ASSERT_NE(M, nullptr);
  const llvm::Instruction *A = &M->getFunction("f")->getEntryBlock().front();

  MetaVariable *Global =
      MetaVariable::create(Context, "g", MetaType::Value, Range);
  MetaVariable *Load =
      MetaVariable::create(Context, "a", MetaType::Value, Range);
  VariableConstraint *GlobalExpr = VariableConstraint::create(
      Context, Global, Constraint::ValueResult, Range);
  VariableConstraint *LoadExpr =
      VariableConstraint::create(Context, Load, Constraint::ValueResult, Range);
  State.bind(*Global, M->getNamedGlobal("g"));
  State.bind(*Load, A);

  OneUseOracle Oracle;
  Interpreter.setUseOracle(&Oracle);
  // The function uses @g twice, but its module is what counts.
  EXPECT_TRUE(evaluateBoolean(*call("hasOneUse", GlobalExpr)));
  EXPECT_FALSE(evaluateBoolean(*call("hasOneUser", GlobalExpr)));
  // Instructions are only used in their function.
  EXPECT_TRUE(evaluateBoolean(*call("hasOneUse", LoadExpr)));
  EXPECT_TRUE(evaluateBoolean(*call("hasOneUser", LoadExpr)));
  EXPECT_EQ(Oracle.Asked.size(), 2u);
}

// Use counts other than hasOneUse's come from the IR, except for values used
// across functions, whose module only the oracle knows: it tells one use from
// more, as the bound value has at least one.
TEST_F(ConstraintInterpreterTest, CountsUsesWithTheUseOracle) {
  LLVMContext LLVMContext;
  SMDiagnostic Error;
  std::unique_ptr<Module> M = parseAssemblyString(
      R"(
        @g = global i32 0
        define i32 @f() {
          %a = load i32, ptr @g
          %b = load i32, ptr @g
          %c = add i32 %a, %a
          ret i32 %c
        }
      )",
      Error, LLVMContext);
  ASSERT_NE(M, nullptr);
  const llvm::Instruction *A = &M->getFunction("f")->getEntryBlock().front();

  MetaVariable *Global =
      MetaVariable::create(Context, "g", MetaType::Value, Range);
  MetaVariable *Load =
      MetaVariable::create(Context, "a", MetaType::Value, Range);
  VariableConstraint *GlobalExpr = VariableConstraint::create(
      Context, Global, Constraint::ValueResult, Range);
  VariableConstraint *LoadExpr =
      VariableConstraint::create(Context, Load, Constraint::ValueResult, Range);
  State.bind(*Global, M->getNamedGlobal("g"));
  State.bind(*Load, A);
  auto Uses = [&](StringRef Name, Constraint *Value, int64_t N) {
    return operation(Constraint::Call, Name, {Value, integer(N)});
  };

  // %a has two uses, by one user.
  EXPECT_TRUE(evaluateBoolean(*Uses("hasNUses", LoadExpr, 2)));
  EXPECT_FALSE(evaluateBoolean(*Uses("hasNUses", LoadExpr, 1)));
  EXPECT_TRUE(evaluateBoolean(*Uses("hasNUsesOrMore", LoadExpr, 2)));
  EXPECT_FALSE(evaluateBoolean(*Uses("hasNUsesOrMore", LoadExpr, 3)));

  OneUseOracle Oracle;
  Interpreter.setUseOracle(&Oracle);
  // The function uses @g twice, but its module is what counts.
  EXPECT_TRUE(evaluateBoolean(*Uses("hasNUses", GlobalExpr, 1)));
  EXPECT_FALSE(evaluateBoolean(*Uses("hasNUsesOrMore", GlobalExpr, 2)));
  EXPECT_TRUE(evaluateBoolean(*Uses("hasNUsesOrMore", GlobalExpr, 1)));
  // Other counts are unknown.
  Expected<ConstraintValue> Three =
      Interpreter.evaluate(*Uses("hasNUses", GlobalExpr, 3), State);
  EXPECT_FALSE(static_cast<bool>(Three));
  consumeError(Three.takeError());
}

TEST_F(ConstraintInterpreterTest, EvaluatesOpcodePredicates) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  auto Cast = std::unique_ptr<CastInst>(
      CastInst::Create(llvm::Instruction::ZExt, Add.get(),
                       llvm::Type::getInt64Ty(LLVMContext), "extended"));
  MetaVariable *Value =
      MetaVariable::create(Context, "value", MetaType::Value, Range);
  VariableConstraint *ValueExpression = VariableConstraint::create(
      Context, Value, Constraint::ValueResult, Range);
  State.bind(*Value, Cast.get());

  EXPECT_TRUE(evaluateBoolean(
      *binary("==", operation(Constraint::Call, "opcode", {ValueExpression}),
              StringConstraint::create(Context, "zext", Range))));
  EXPECT_FALSE(evaluateBoolean(
      *binary("==", operation(Constraint::Call, "opcode", {ValueExpression}),
              StringConstraint::create(Context, "add", Range))));

  MetaVariable *IntegerValue =
      MetaVariable::create(Context, "integer_value", MetaType::Value, Range);
  VariableConstraint *IntegerExpression = VariableConstraint::create(
      Context, IntegerValue, Constraint::ValueResult, Range);
  State.bind(*IntegerValue, ConstantInt::get(I32, 1));
  OperatorConstraint *NonInstruction =
      operation(Constraint::Call, "opcode", {IntegerExpression});
  Expected<ConstraintValue> Result =
      Interpreter.evaluate(*NonInstruction, State);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(opcode ?integer_value)': expected an "
            "instruction operand");
}

TEST_F(ConstraintInterpreterTest, ConvertsSymbolicBindingsToStrings) {
  MetaVariable *Predicate =
      MetaVariable::create(Context, "predicate", MetaType::CmpPredicate, Range);
  MetaVariable *IntrinsicVariable =
      MetaVariable::create(Context, "intrinsic", MetaType::IntrinsicID, Range);
  VariableConstraint *PredicateExpression = VariableConstraint::create(
      Context, Predicate, Constraint::StringResult, Range);
  VariableConstraint *IntrinsicExpression = VariableConstraint::create(
      Context, IntrinsicVariable, Constraint::StringResult, Range);
  State.bind(*Predicate, CmpInst::ICMP_SLT);
  State.bind(*IntrinsicVariable, Intrinsic::abs);

  EXPECT_EQ(evaluate(*PredicateExpression).getString(), "slt");
  EXPECT_EQ(evaluate(*IntrinsicExpression).getString(), "llvm.abs");
  EXPECT_TRUE(evaluateBoolean(
      *binary("==", PredicateExpression,
              StringConstraint::create(Context, "slt", Range))));
  EXPECT_TRUE(evaluateBoolean(
      *binary("==", IntrinsicExpression,
              StringConstraint::create(Context, "llvm.abs", Range))));
}

TEST_F(ConstraintInterpreterTest, ReportsEvaluationErrors) {
  MetaVariable *Missing =
      MetaVariable::create(Context, "missing", MetaType::Nat, Range);
  VariableConstraint *MissingExpression = VariableConstraint::create(
      Context, Missing, Constraint::IntegerResult, Range);
  Expected<ConstraintValue> MissingResult =
      Interpreter.evaluate(*MissingExpression, State);
  ASSERT_FALSE(MissingResult);
  EXPECT_EQ(toString(MissingResult.takeError()),
            "cannot evaluate constraint '?missing': meta variable '?missing' "
            "is not instantiated");

  MetaVariable *Flag =
      MetaVariable::create(Context, "flag", MetaType::Bool, Range);
  VariableConstraint *FlagExpression = VariableConstraint::create(
      Context, Flag, Constraint::BooleanResult, Range);
  State.bind(*Flag, APInt(1, 1));
  Expected<ConstraintValue> IncompatibleResult =
      Interpreter.evaluate(*FlagExpression, State);
  ASSERT_FALSE(IncompatibleResult);
  EXPECT_EQ(toString(IncompatibleResult.takeError()),
            "cannot evaluate constraint '?flag': meta variable '?flag' has an "
            "incompatible binding");

  metaphir::Instruction *InstSubject =
      metaphir::Instruction::create(Context, metaphir::Instruction::I_add,
                                    "sum", {}, {}, {}, nullptr, Range, nullptr);
  VariableConstraint *UninstInstExpr = VariableConstraint::create(
      Context, InstSubject, Constraint::ValueResult, Range);
  Expected<ConstraintValue> UninstInstRes =
      Interpreter.evaluate(*UninstInstExpr, State);
  ASSERT_FALSE(UninstInstRes);
  EXPECT_EQ(toString(UninstInstRes.takeError()),
            "cannot evaluate constraint '%sum': variable '%sum' "
            "is not instantiated");

  VariableConstraint *IncompatInstExpr = VariableConstraint::create(
      Context, InstSubject, Constraint::IntegerResult, Range);
  State.bind(*InstSubject, true);
  Expected<ConstraintValue> IncompatInstRes =
      Interpreter.evaluate(*IncompatInstExpr, State);
  ASSERT_FALSE(IncompatInstRes);
  EXPECT_EQ(toString(IncompatInstRes.takeError()),
            "cannot evaluate constraint '%sum': variable '%sum' has an "
            "incompatible binding");

  OperatorConstraint *DivisionByZero = call("udiv", integer(1), integer(0));
  Expected<ConstraintValue> DivisionResult =
      Interpreter.evaluate(*DivisionByZero, State);
  ASSERT_FALSE(DivisionResult);
  EXPECT_EQ(toString(DivisionResult.takeError()),
            "cannot evaluate constraint '(udiv 1 0)': division by zero");

  for (StringRef Operator : {"sdiv", "srem", "urem"}) {
    Expected<ConstraintValue> Result =
        Interpreter.evaluate(*call(Operator, integer(1), integer(0)), State);
    EXPECT_FALSE(Result);
    EXPECT_FALSE(toString(Result.takeError()).empty());
  }

  OperatorConstraint *Unknown =
      operation(Constraint::Call, "custom", {integer(1)});
  Expected<ConstraintValue> UnknownResult =
      Interpreter.evaluate(*Unknown, State);
  ASSERT_FALSE(UnknownResult);
  EXPECT_EQ(
      toString(UnknownResult.takeError()),
      "cannot evaluate constraint '(custom 1)': unknown operator 'custom'");

  MetaVariable *Values =
      MetaVariable::create(Context, "values", MetaType::ValueArray, Range);
  VariableConstraint *ValuesExpression = VariableConstraint::create(
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

  OperatorConstraint *InvalidShift = call("lshr", integer(1), integer(64));
  Expected<ConstraintValue> ShiftResult =
      Interpreter.evaluate(*InvalidShift, State);
  ASSERT_FALSE(ShiftResult);
  EXPECT_EQ(toString(ShiftResult.takeError()),
            "cannot evaluate constraint '(lshr 1 64)': shift amount is out of "
            "range");

  OperatorConstraint *NegativeShift = call("ashr", integer(1), integer(-1));
  Expected<ConstraintValue> NegativeShiftResult =
      Interpreter.evaluate(*NegativeShift, State);
  ASSERT_FALSE(NegativeShiftResult);
  EXPECT_EQ(toString(NegativeShiftResult.takeError()),
            "cannot evaluate constraint '(ashr 1 -1)': shift amount is "
            "out of range");
}

TEST_F(ConstraintInterpreterTest, RejectsInvalidCoercionsAndComparisons) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  Constant *Value = ConstantInt::get(I32, 1);
  MetaVariable *ValueVariable =
      MetaVariable::create(Context, "value", MetaType::Value, Range);
  VariableConstraint *ValueExpression = VariableConstraint::create(
      Context, ValueVariable, Constraint::ValueResult, Range);
  State.bind(*ValueVariable, Value);

  Expected<ConstraintValue> IntegerResult =
      Interpreter.evaluate(*binary("+", ValueExpression, integer(1)), State);
  ASSERT_TRUE(static_cast<bool>(IntegerResult));
  EXPECT_EQ(IntegerResult->getInteger().getSExtValue(), 2);

  Expected<ConstraintValue> BooleanResult = Interpreter.evaluate(
      *binary("&&", ValueExpression, boolean(true)), State);
  ASSERT_FALSE(BooleanResult);
  EXPECT_EQ(toString(BooleanResult.takeError()),
            "cannot evaluate constraint '(&& ?value true)': expected a "
            "boolean-coercible operand");

  Expected<ConstraintValue> EqualityResult = Interpreter.evaluate(
      *binary("==", integer(1), StringConstraint::create(Context, "1", Range)),
      State);
  ASSERT_FALSE(EqualityResult);
  EXPECT_EQ(toString(EqualityResult.takeError()),
            "cannot evaluate constraint '(== 1 \"1\")': equality operands "
            "have different types");

  Expected<ConstraintValue> IsaValueResult = Interpreter.evaluate(
      *call("isa", integer(1),
            StringConstraint::create(Context, "Value", Range)),
      State);
  ASSERT_FALSE(IsaValueResult);
  EXPECT_EQ(toString(IsaValueResult.takeError()),
            "cannot evaluate constraint '(isa 1 \"Value\")': expected an "
            "LLVM value operand");

  Expected<ConstraintValue> IsaNameResult =
      Interpreter.evaluate(*call("isa", ValueExpression, integer(1)), State);
  ASSERT_FALSE(IsaNameResult);
  EXPECT_EQ(toString(IsaNameResult.takeError()),
            "cannot evaluate constraint '(isa ?value 1)': expected a "
            "string-coercible operand");

  Expected<ConstraintValue> NegativeIndexResult = Interpreter.evaluate(
      *access(array(Constraint::StringArrayResult,
                    {StringConstraint::create(Context, "value", Range)}),
              integer(-1), Constraint::StringResult),
      State);
  ASSERT_FALSE(NegativeIndexResult);
  EXPECT_EQ(toString(NegativeIndexResult.takeError()),
            "cannot evaluate constraint '[\"value\"][-1]': array index "
            "is negative");
}

TEST_F(ConstraintInterpreterTest, EvaluatesValueTrackingOperators) {
  LLVMContext LLVMContext;
  Module Module("module", LLVMContext);
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *Float = llvm::Type::getFloatTy(LLVMContext);
  FunctionType *FunctionType =
      FunctionType::get(I8, {I8, I8, I8}, /*isVarArg=*/false);
  Function *Fn = Function::Create(
      FunctionType, llvm::GlobalValue::ExternalLinkage, "f", Module);
  AttrBuilder Ranges(LLVMContext);
  Ranges.addRangeAttr(ConstantRange(APInt(8, 0), APInt(8, 16)));
  Fn->getArg(1)->addAttrs(Ranges);
  Fn->getArg(2)->addAttrs(Ranges);
  BasicBlock *Block = BasicBlock::Create(LLVMContext, "entry", Fn);
  auto *Inner =
      BinaryOperator::CreateUDiv(Fn->getArg(0), Fn->getArg(1), "inner", Block);
  auto *Root = BinaryOperator::CreateUDiv(Inner, Fn->getArg(2), "root", Block);
  ReturnInst::Create(LLVMContext, ConstantInt::get(I8, 0), Block);

  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);
  MetaVariable *Z = MetaVariable::create(Context, "z", MetaType::Value, Range);
  MetaVariable *Ctx =
      MetaVariable::create(Context, "ctx", MetaType::Value, Range);
  VariableConstraint *YExpression =
      VariableConstraint::create(Context, Y, Constraint::ValueResult, Range);
  VariableConstraint *ZExpression =
      VariableConstraint::create(Context, Z, Constraint::ValueResult, Range);
  VariableConstraint *CtxExpression =
      VariableConstraint::create(Context, Ctx, Constraint::ValueResult, Range);
  State.bind(*Y, Fn->getArg(1));
  State.bind(*Z, Fn->getArg(2));
  State.bind(*Ctx, Root);

  // y and z are constrained to [0, 15], so y*z fits in i8 without unsigned
  // overflow; signed overflow is possible (15*15 > 127).
  EXPECT_TRUE(evaluateBoolean(
      *operation(Constraint::Call, "noOverflow",
                 {StringConstraint::create(Context, "umul", Range), YExpression,
                  ZExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(
      *operation(Constraint::Call, "noOverflow",
                 {StringConstraint::create(Context, "smul", Range), YExpression,
                  ZExpression, CtxExpression})));

  // 255 * 2 does not fit in i8.
  MetaVariable *Big =
      MetaVariable::create(Context, "big", MetaType::Value, Range);
  MetaVariable *Two =
      MetaVariable::create(Context, "two", MetaType::Value, Range);
  VariableConstraint *BigExpression =
      VariableConstraint::create(Context, Big, Constraint::ValueResult, Range);
  VariableConstraint *TwoExpression =
      VariableConstraint::create(Context, Two, Constraint::ValueResult, Range);
  State.bind(*Big, ConstantInt::get(I8, 255));
  State.bind(*Two, ConstantInt::get(I8, 2));
  EXPECT_FALSE(evaluateBoolean(
      *operation(Constraint::Call, "noOverflow",
                 {StringConstraint::create(Context, "umul", Range),
                  BigExpression, TwoExpression, CtxExpression})));

  // Sign predicates on the range-constrained argument.
  EXPECT_TRUE(evaluateBoolean(*operation(Constraint::Call, "isKnownNonNegative",
                                         {YExpression, CtxExpression})));

  // Known bits of the constant 5 (0b00000101): ones mask 0x05, zeros 0xFA.
  MetaVariable *Const =
      MetaVariable::create(Context, "c", MetaType::Value, Range);
  VariableConstraint *ConstExpression = VariableConstraint::create(
      Context, Const, Constraint::ValueResult, Range);
  State.bind(*Const, ConstantInt::get(I8, 5));
  EXPECT_TRUE(evaluateBoolean(*operation(Constraint::Call, "isKnownNonZero",
                                         {ConstExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(*operation(Constraint::Call, "isKnownPowerOfTwo",
                                          {ConstExpression, CtxExpression})));
  EXPECT_TRUE(evaluateBoolean(*operation(Constraint::Call, "isKnownPositive",
                                         {ConstExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(*operation(Constraint::Call, "isKnownNegative",
                                          {ConstExpression, CtxExpression})));

  // Constant 4 is a power of two.
  MetaVariable *Four =
      MetaVariable::create(Context, "four", MetaType::Value, Range);
  VariableConstraint *FourExpression =
      VariableConstraint::create(Context, Four, Constraint::ValueResult, Range);
  State.bind(*Four, ConstantInt::get(I8, 4));
  EXPECT_TRUE(evaluateBoolean(*operation(Constraint::Call, "isKnownPowerOfTwo",
                                         {FourExpression, CtxExpression})));

  Expected<ConstraintValue> KnownBits =
      Interpreter.evaluate(*operation(Constraint::Call, "knownBits",
                                      {ConstExpression, CtxExpression}),
                           State);
  ASSERT_TRUE(static_cast<bool>(KnownBits));
  EXPECT_EQ(KnownBits->getKnownBits().One, APInt(8, 0x05));
  EXPECT_EQ(KnownBits->getKnownBits().Zero, APInt(8, 0xFA));

  OperatorConstraint *KnownBitsCall = operation(
      Constraint::Call, "knownBits", {ConstExpression, CtxExpression});
  Expected<ConstraintValue> Zeros = Interpreter.evaluate(
      *operation(Constraint::Call, "knownZeros", {KnownBitsCall}), State);
  ASSERT_TRUE(static_cast<bool>(Zeros));
  EXPECT_EQ(Zeros->getInteger(), APSInt(APInt(8, 0xFA), true));
  Expected<ConstraintValue> Ones = Interpreter.evaluate(
      *operation(Constraint::Call, "knownOnes", {KnownBitsCall}), State);
  ASSERT_TRUE(static_cast<bool>(Ones));
  EXPECT_EQ(Ones->getInteger(), APSInt(APInt(8, 0x05), true));

  // Bit-vector equality compares both masks.
  EXPECT_TRUE(
      evaluateBoolean(*binary("==",
                              operation(Constraint::Call, "knownBits",
                                        {ConstExpression, CtxExpression}),
                              operation(Constraint::Call, "knownBits",
                                        {ConstExpression, CtxExpression}))));

  // masked-value-is-zero: 5 & 8 == 0, 5 & 4 != 0.
  EXPECT_TRUE(evaluateBoolean(
      *operation(Constraint::Call, "maskedValueIsZero",
                 {ConstExpression, integer(8), CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(
      *operation(Constraint::Call, "maskedValueIsZero",
                 {ConstExpression, integer(4), CtxExpression})));

  // Unknown overflow kind.
  Expected<ConstraintValue> UnknownKind = Interpreter.evaluate(
      *operation(Constraint::Call, "noOverflow",
                 {StringConstraint::create(Context, "foo", Range),
                  ConstExpression, ConstExpression, CtxExpression}),
      State);
  ASSERT_FALSE(UnknownKind);
  EXPECT_EQ(toString(UnknownKind.takeError()),
            "cannot evaluate constraint '(noOverflow \"foo\" ?c ?c ?ctx)': "
            "unknown overflow kind 'foo'");

  // Non-integer operand.
  MetaVariable *FloatValue =
      MetaVariable::create(Context, "float_value", MetaType::Value, Range);
  VariableConstraint *FloatExpression = VariableConstraint::create(
      Context, FloatValue, Constraint::ValueResult, Range);
  State.bind(*FloatValue, ConstantFP::get(Float, 1.0));
  Expected<ConstraintValue> NonInteger =
      Interpreter.evaluate(*operation(Constraint::Call, "isKnownNonNegative",
                                      {FloatExpression, CtxExpression}),
                           State);
  ASSERT_FALSE(NonInteger);
  EXPECT_EQ(toString(NonInteger.takeError()),
            "cannot evaluate constraint '(isKnownNonNegative ?float_value "
            "?ctx)': expected an integer-typed value operand");

  // Context that is a value but not an instruction.
  Expected<ConstraintValue> BadContext =
      Interpreter.evaluate(*operation(Constraint::Call, "isKnownNonZero",
                                      {ConstExpression, BigExpression}),
                           State);
  ASSERT_FALSE(BadContext);
  EXPECT_EQ(toString(BadContext.takeError()),
            "cannot evaluate constraint '(isKnownNonZero ?c ?big)': expected "
            "an instruction context operand");
}

TEST_F(ConstraintInterpreterTest, ResolvesDefaultValueTrackContext) {
  LLVMContext LLVMContext;
  Module Module("module", LLVMContext);
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  FunctionType *FunctionType =
      FunctionType::get(I8, {I8, I8, I8}, /*isVarArg=*/false);
  Function *Fn = Function::Create(
      FunctionType, llvm::GlobalValue::ExternalLinkage, "f", Module);
  AttrBuilder Ranges(LLVMContext);
  Ranges.addRangeAttr(ConstantRange(APInt(8, 0), APInt(8, 16)));
  Fn->getArg(1)->addAttrs(Ranges);
  Fn->getArg(2)->addAttrs(Ranges);
  BasicBlock *Block = BasicBlock::Create(LLVMContext, "entry", Fn);
  auto *Inner =
      BinaryOperator::CreateUDiv(Fn->getArg(0), Fn->getArg(1), "inner", Block);
  auto *Root = BinaryOperator::CreateUDiv(Inner, Fn->getArg(2), "root", Block);
  ReturnInst::Create(LLVMContext, ConstantInt::get(I8, 0), Block);

  MetaVariable *Y = MetaVariable::create(Context, "y", MetaType::Value, Range);
  MetaVariable *Z = MetaVariable::create(Context, "z", MetaType::Value, Range);
  VariableConstraint *YExpression =
      VariableConstraint::create(Context, Y, Constraint::ValueResult, Range);
  VariableConstraint *ZExpression =
      VariableConstraint::create(Context, Z, Constraint::ValueResult, Range);
  State.bind(*Y, Fn->getArg(1));
  State.bind(*Z, Fn->getArg(2));

  // The pattern instruction preceding the constraint supplies the context.
  auto *PatternInst = metaphir::Instruction::create(
      Context, metaphir::Instruction::I_udiv, "root", /*Flags=*/{},
      /*MetaFlags=*/{},
      /*Operands=*/{}, /*Capture=*/nullptr, Range, /*ParentBlock=*/nullptr);
  State.bind(*PatternInst, Instantiation::Binding(Root));
  OperatorConstraint *NoOverflow =
      operation(Constraint::Call, "noOverflow",
                {StringConstraint::create(Context, "umul", Range), YExpression,
                 ZExpression});
  NoOverflow->setContextInstruction(PatternInst);

  EXPECT_TRUE(evaluateBoolean(*NoOverflow));

  // Without a resolvable context instruction the operator reports an error.
  OperatorConstraint *Unanchored =
      operation(Constraint::Call, "noOverflow",
                {StringConstraint::create(Context, "umul", Range), YExpression,
                 ZExpression});
  Expected<ConstraintValue> Result = Interpreter.evaluate(*Unanchored, State);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(noOverflow \"umul\" ?y ?z)': no "
            "context instruction for value-tracking operator (place the "
            "constraint after an instruction or pass ?ctx explicitly)");
}

TEST_F(ConstraintInterpreterTest, ValueTrackContextBuildsLazily) {
  LLVMContext LLVMContext;
  Module Module("module", LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  FunctionType *FunctionType = FunctionType::get(I32, {}, false);
  Function *Fn = Function::Create(
      FunctionType, llvm::GlobalValue::ExternalLinkage, "f", Module);
  BasicBlock *Block = BasicBlock::Create(LLVMContext, "entry", Fn);
  auto *One = BinaryOperator::CreateAdd(ConstantInt::get(I32, 1),
                                        ConstantInt::get(I32, 1), "one", Block);
  ReturnInst::Create(LLVMContext, ConstantInt::get(I32, 0), Block);

  metaphir::detail::ValueTrackContext Context;
  EXPECT_FALSE(Context.hasMaterializedDominatorTree());
  EXPECT_FALSE(Context.hasMaterializedAssumptionCache());
  EXPECT_FALSE(Context.hasMaterializedTargetLibraryInfo());
  (void)Context.getQuery(One);
  EXPECT_TRUE(Context.hasMaterializedDominatorTree());
  EXPECT_TRUE(Context.hasMaterializedAssumptionCache());
  EXPECT_TRUE(Context.hasMaterializedTargetLibraryInfo());
}

// The integer predicates answer false for an operand that is not an integer;
// the failed coercion must be consumed (an unchecked llvm::Error aborts in
// builds with LLVM_ENABLE_ABI_BREAKING_CHECKS).
TEST_F(ConstraintInterpreterTest, IntegerPredicatesRejectNonIntegers) {
  for (StringRef Name :
       {"isPower2", "isZero", "isAllOnes", "isLowBitMask", "isPower2OrZero",
        "isLowBitMaskOrZero", "isNegative", "isNonNegative",
        "isStrictlyPositive", "isNonPositive", "isNonZeroInt"}) {
    SCOPED_TRACE(Name);
    EXPECT_FALSE(evaluateBoolean(
        *call(Name, StringConstraint::create(Context, "x", Range))));
  }
}

} // namespace
