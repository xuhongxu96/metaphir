//===- ExprEvaluatorTest.cpp - Evaluating mpir_expr on the IR ----------===//
//
// The constraint operators' semantics, as the evaluator of the mpir_expr
// dialect computes them on what a match bound: expressions are built as
// mpir_expr operations, reading the slots of a plan.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/ExprEvaluator.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/Binding.h"
#include "metaphir/Matching/UseOracle.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
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
#include <initializer_list>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

using Value = mlir::Value;

/// Builds expressions of the mpir_expr dialect, and evaluates them on the
/// bindings of their slots.
class ExprEvaluatorTest : public testing::Test {
protected:
  /// A meta variable or an instruction matcher, a slot of the bindings.
  struct Var {
    unsigned Slot;
    std::string Name;
    bool IsInstruction = false;
  };

  ExprEvaluatorTest()
      : Builder(&Context),
        PlanModule(mlir::ModuleOp::create(mlir::UnknownLoc::get(&Context))) {
    Context.loadDialect<mpir::PatternDialect, mpir_expr::ExprDialect,
                        mpir_plan::PlanDialect>();
    Builder.setInsertionPointToEnd(PlanModule->getBody());
  }

  mlir::MLIRContext Context;
  mlir::OpBuilder Builder;
  mlir::OwningOpRef<mlir::ModuleOp> PlanModule;
  ExprEvaluator Evaluator;
  std::vector<Binding> Slots;

  mlir::Location loc() { return Builder.getUnknownLoc(); }
  mpir::SortType sortType(Sort S) { return mpir::SortType::get(&Context, S); }

  Var var(StringRef Name, Sort) {
    Slots.emplace_back();
    return {unsigned(Slots.size() - 1), Name.str()};
  }
  Var instruction(StringRef Name) {
    Var V = var(Name, Sort::Instruction);
    V.IsInstruction = true;
    return V;
  }
  void bind(const Var &V, Binding B) { Slots[V.Slot] = B; }

  /// What V's slot is, as an expression reads it.
  Value slot(const Var &V) {
    auto Op = mpir_plan::SlotOp::create(
        Builder, loc(),
        sortType(V.IsInstruction ? Sort::Instruction : Sort::Value),
        Builder.getI32IntegerAttr(V.Slot));
    Op->setAttr(V.IsInstruction ? "result_name" : "var_name",
                Builder.getStringAttr(V.Name));
    return Op;
  }
  Value read(const Var &V, Sort As) {
    return mpir_expr::ReadOp::create(Builder, loc(), sortType(As), slot(V));
  }

  Value integer(int64_t V) {
    return integer(APSInt(APInt(64, uint64_t(V), true), V >= 0));
  }
  Value integer(const APSInt &V) {
    return mpir_expr::IntOp::create(Builder, loc(), V);
  }
  Value boolean(bool V) { return mpir_expr::BoolOp::create(Builder, loc(), V); }
  Value string(StringRef V) {
    return mpir_expr::StrOp::create(Builder, loc(), V);
  }

  /// A built-in operator when Name is one, and a call of a 'constraint'
  /// definition otherwise.
  Value operation(constraint::OperatorKind Kind, StringRef Name,
                  std::initializer_list<Value> Arguments) {
    constraint::OperatorID ID = constraint::getOperatorID(Name, Kind);
    if (ID == constraint::UnknownOperator)
      return mpir_expr::ApplyOp::create(
          Builder, loc(), sortType(Sort::Boolean),
          mlir::FlatSymbolRefAttr::get(&Context, Name),
          SmallVector<Value, 4>(Arguments));
    return mpir_expr::CallOp::create(
        Builder, loc(), sortType(constraint::getOperatorSchema(ID)->Result),
        unsigned(ID), unsigned(Kind), SmallVector<Value, 4>(Arguments),
        Value());
  }
  Value unary(StringRef Name, Value Operand) {
    return operation(constraint::Unary, Name, {Operand});
  }
  Value binary(StringRef Name, Value Left, Value Right) {
    return operation(constraint::Binary, Name, {Left, Right});
  }
  Value call(StringRef Name, Value Operand) {
    return operation(constraint::Call, Name, {Operand});
  }
  Value call(StringRef Name, Value Left, Value Right) {
    return operation(constraint::Call, Name, {Left, Right});
  }
  Value array(Sort Type, std::initializer_list<Value> Elements) {
    return mpir_expr::ArrayOp::create(Builder, loc(), sortType(Type),
                                      SmallVector<Value, 4>(Elements));
  }
  Value access(Value Array, Value Index, Sort Type) {
    return mpir_expr::IndexOp::create(Builder, loc(), sortType(Type), Array,
                                      Index);
  }
  /// A value-tracking operator anchored at the instruction At.
  Value anchored(Value Operator, const Var &At) {
    cast<mpir_expr::CallOp>(Operator.getDefiningOp())
        .getAnchorMutable()
        .assign(slot(At));
    return Operator;
  }

  Expected<ConstraintValue> evaluateResult(Value E) {
    return Evaluator.evaluate(E, [&](unsigned Slot) -> const Binding * {
      return std::holds_alternative<std::monostate>(Slots[Slot].Data)
                 ? nullptr
                 : &Slots[Slot];
    });
  }
  ConstraintValue evaluate(Value E) { return cantFail(evaluateResult(E)); }
  int64_t evaluateInteger(Value E) {
    return evaluate(E).getInteger().getSExtValue();
  }
  bool evaluateBoolean(Value E) { return evaluate(E).getBoolean(); }
};

TEST_F(ExprEvaluatorTest, EvaluatesLiteralsAndVariables) {
  Var Bits = var("bits", Sort::Nat);
  Var Flag = var("flag", Sort::Boolean);
  Value BitsExpression = read(Bits, Sort::Integer);
  Value FlagExpression = read(Flag, Sort::Boolean);
  bind(Bits, APInt(16, 42));
  bind(Flag, true);

  EXPECT_EQ(evaluateInteger(integer(-7)), -7);
  EXPECT_TRUE(evaluateBoolean(boolean(true)));
  EXPECT_EQ(evaluateInteger(BitsExpression), 42);
  EXPECT_TRUE(evaluateBoolean(FlagExpression));
}

TEST_F(ExprEvaluatorTest, EvaluatesArithmeticOperators) {
  EXPECT_EQ(evaluateInteger(binary("+", integer(7), integer(5))), 12);
  EXPECT_EQ(evaluateInteger(binary("-", integer(7), integer(12))), -5);
  EXPECT_EQ(evaluateInteger(binary("*", integer(-3), integer(4))), -12);
  EXPECT_EQ(evaluateInteger(unary("-", integer(9))), -9);
  EXPECT_EQ(evaluateInteger(call("sdiv", integer(-9), integer(2))), -4);
  EXPECT_EQ(evaluateInteger(call("udiv", integer(9), integer(2))), 4);
  EXPECT_EQ(evaluateInteger(call("srem", integer(-9), integer(4))), -1);
  EXPECT_EQ(evaluateInteger(call("urem", integer(9), integer(4))), 1);
  EXPECT_EQ(evaluateInteger(call("lshr", integer(16), integer(2))), 4);
  EXPECT_EQ(evaluateInteger(call("ashr", integer(-16), integer(2))), -4);
}

TEST_F(ExprEvaluatorTest, EvaluatesWideIntegersExactly) {
  APSInt Max64(APInt::getMaxValue(64), /*isUnsigned=*/true);
  Value Wide = integer(Max64);
  EXPECT_EQ(evaluate(Wide).getInteger(), Max64);
  EXPECT_TRUE(evaluateBoolean(call("ugt", Wide, integer(0))));

  // Without a bit width, results grow instead of wrapping.
  APSInt Sum = evaluate(binary("+", Wide, integer(1))).getInteger();
  EXPECT_EQ(Sum.getActiveBits(), 65u);
  APSInt Shifted = evaluate(call("shl", integer(1), integer(70))).getInteger();
  EXPECT_EQ(Shifted.countr_zero(), 70u);
  EXPECT_EQ(Shifted.popcount(), 1u);
  EXPECT_EQ(evaluateInteger(call("lshr", integer(1), integer(64))), 0);
  EXPECT_EQ(evaluateInteger(call("ashr", integer(-8), integer(100))), -1);

  // With a bit width, operators behave like the LLVM instructions.
  EXPECT_EQ(evaluateInteger(operation(constraint::Call, "shl",
                                      {integer(1), integer(7), integer(8)})),
            -128);
}

TEST_F(ExprEvaluatorTest, ReadsBitWidthResultsAsLLVMDoes) {
  auto withWidth = [&](StringRef Name, int64_t L, int64_t R, int64_t W) {
    return operation(constraint::Call, Name,
                     {integer(L), integer(R), integer(W)});
  };
  // '==' compares values, and reads a W-bit result as signed.
  EXPECT_TRUE(evaluateBoolean(
      binary("==", withWidth("add", 127, 1, 8), integer(-128))));
  EXPECT_FALSE(
      evaluateBoolean(binary("==", withWidth("add", 127, 1, 8), integer(128))));
  EXPECT_TRUE(evaluateBoolean(
      binary("==", operation(constraint::Call, "neg", {integer(1), integer(8)}),
             integer(-1))));
  // The unsigned comparisons read it as unsigned, as 'icmp ult' does.
  EXPECT_TRUE(
      evaluateBoolean(call("ugt", withWidth("add", 127, 1, 8), integer(127))));
  EXPECT_TRUE(
      evaluateBoolean(call("slt", withWidth("add", 127, 1, 8), integer(0))));
  // 'eq' compares the low W bits.
  EXPECT_TRUE(evaluateBoolean(withWidth("eq", -1, 255, 8)));
  EXPECT_TRUE(evaluateBoolean(withWidth("eq", 300, 44, 8)));
  EXPECT_FALSE(evaluateBoolean(withWidth("eq", 1, 257, 16)));
}

TEST_F(ExprEvaluatorTest, EvaluatesBooleanAndEqualityOperators) {
  EXPECT_TRUE(evaluateBoolean(binary("||", boolean(false), boolean(true))));
  EXPECT_FALSE(evaluateBoolean(binary("&&", boolean(true), boolean(false))));
  EXPECT_TRUE(evaluateBoolean(unary("!", boolean(false))));
  EXPECT_TRUE(evaluateBoolean(binary("==", integer(3), integer(3))));
  EXPECT_TRUE(evaluateBoolean(binary("!=", boolean(true), boolean(false))));
  EXPECT_EQ(evaluateInteger(binary("+", boolean(true), integer(2))), 3);
  EXPECT_TRUE(evaluateBoolean(binary("&&", integer(2), boolean(true))));
  EXPECT_FALSE(evaluateBoolean(unary("!", integer(1))));
  EXPECT_TRUE(evaluateBoolean(binary("==", boolean(true), integer(1))));
}

TEST_F(ExprEvaluatorTest, EvaluatesSignedAndUnsignedComparisons) {
  EXPECT_TRUE(evaluateBoolean(call("slt", integer(-1), integer(1))));
  EXPECT_TRUE(evaluateBoolean(call("sle", integer(1), integer(1))));
  EXPECT_TRUE(evaluateBoolean(call("sgt", integer(2), integer(-1))));
  EXPECT_TRUE(evaluateBoolean(call("sge", integer(2), integer(2))));
  EXPECT_TRUE(evaluateBoolean(call("ult", integer(1), integer(2))));
  EXPECT_TRUE(evaluateBoolean(call("ule", integer(2), integer(2))));
  EXPECT_TRUE(evaluateBoolean(call("ugt", integer(3), integer(2))));
  EXPECT_TRUE(evaluateBoolean(call("uge", integer(3), integer(3))));
}

TEST_F(ExprEvaluatorTest, ShortCircuitsLogicalOperators) {
  Value Unknown = operation(constraint::Call, "unknown", {integer(1)});
  EXPECT_TRUE(evaluateBoolean(binary("||", boolean(true), Unknown)));
  EXPECT_FALSE(evaluateBoolean(binary("&&", boolean(false), Unknown)));
}

TEST_F(ExprEvaluatorTest, AccessesTypeAndValueArrays) {
  LLVMContext LLVMContext;
  llvm::Type *I8 = llvm::Type::getInt8Ty(LLVMContext);
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  Constant *One = ConstantInt::get(I32, 1);
  Constant *Two = ConstantInt::get(I32, 2);

  Var Types = var("types", Sort::TypeArray);
  Var Values = var("values", Sort::ValueArray);
  Value TypesExpression = read(Types, Sort::TypeArray);
  Value ValuesExpression = read(Values, Sort::ValueArray);
  bind(Types, Binding::TypeArray{I8, I32});
  bind(Values, Binding::ValueArray{One, Two});

  ConstraintValue TypeElement =
      evaluate(access(TypesExpression, integer(1), Sort::Type));
  ConstraintValue ValueElement =
      evaluate(access(ValuesExpression, integer(0), Sort::Value));
  EXPECT_EQ(TypeElement.getType(), I32);
  EXPECT_EQ(ValueElement.getValue(), One);

  EXPECT_TRUE(evaluateBoolean(
      binary("==", access(TypesExpression, integer(0), Sort::Type),
             access(TypesExpression, integer(0), Sort::Type))));
  EXPECT_TRUE(evaluateBoolean(
      binary("!=", access(ValuesExpression, integer(0), Sort::Value),
             access(ValuesExpression, integer(1), Sort::Value))));

  Var ElementType = var("element_type", Sort::Type);
  Var ElementValue = var("element_value", Sort::Value);
  Value TypeExpression = read(ElementType, Sort::Type);
  Value ValueExpression = read(ElementValue, Sort::Value);
  bind(ElementType, I8);
  bind(ElementValue, One);

  ConstraintValue TypeLiteral =
      evaluate(array(Sort::TypeArray, {TypeExpression, TypeExpression}));
  ConstraintValue ValueLiteral =
      evaluate(array(Sort::ValueArray, {ValueExpression, ValueExpression}));
  EXPECT_EQ(TypeLiteral.getTypeArray(), (Binding::TypeArray{I8, I8}));
  EXPECT_EQ(ValueLiteral.getValueArray(), (Binding::ValueArray{One, One}));

  Value TypeStrings = array(Sort::StringArray, {string("i8"), string("i32")});
  Value ValueStrings = array(Sort::StringArray, {string("1"), string("2")});
  EXPECT_TRUE(evaluateBoolean(binary("==", TypesExpression, TypeStrings)));
  EXPECT_TRUE(evaluateBoolean(binary("==", ValuesExpression, ValueStrings)));
  EXPECT_EQ(evaluate(access(TypeStrings, integer(1), Sort::String)).getString(),
            "i32");
}

TEST_F(ExprEvaluatorTest, EvaluatesIsaPredicates) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  Var Subject = var("value", Sort::Value);
  Value ValueExpression = read(Subject, Sort::Value);
  bind(Subject, Add.get());

  EXPECT_TRUE(
      evaluateBoolean(call("isa", ValueExpression, string("BinaryOperator"))));
  EXPECT_FALSE(
      evaluateBoolean(call("isa", ValueExpression, string("CallInst"))));
  std::string InstructionText;
  raw_string_ostream InstructionStream(InstructionText);
  Add->print(InstructionStream);
  EXPECT_TRUE(evaluateBoolean(
      binary("==", ValueExpression, string(InstructionStream.str()))));
  EXPECT_NE(InstructionText.find("add i32 1, 2"), std::string::npos);
  Var TypeVariable = var("type", Sort::Type);
  Value TypeExpression = read(TypeVariable, Sort::Type);
  bind(TypeVariable, I32);
  EXPECT_TRUE(evaluateBoolean(binary("==", TypeExpression, string("i32"))));

  Value UnknownClass = call("isa", ValueExpression, string("ImaginaryValue"));
  Expected<ConstraintValue> Result = evaluateResult(UnknownClass);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(isa ?value \"ImaginaryValue\")': "
            "unknown LLVM value class 'ImaginaryValue'");
}

TEST_F(ExprEvaluatorTest, EvaluatesUsePredicates) {
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

  Var ValA = var("a", Sort::Value);
  Var ValB = var("b", Sort::Value);
  Value ExprA = read(ValA, Sort::Value);
  Value ExprB = read(ValB, Sort::Value);
  bind(ValA, A);
  bind(ValB, B);

  EXPECT_FALSE(evaluateBoolean(call("hasOneUse", ExprA)));
  EXPECT_TRUE(evaluateBoolean(call("hasOneUser", ExprA)));

  EXPECT_TRUE(evaluateBoolean(call("hasOneUse", ExprB)));
  EXPECT_TRUE(evaluateBoolean(call("hasOneUser", ExprB)));
}

/// Claims every value it is asked about has one use but two users.
class OneUseOracle : public UseOracle {
public:
  std::optional<ModuleUses> getModuleUses(const llvm::Value &V) override {
    Asked.push_back(&V);
    return ModuleUses{/*NumUses=*/1, /*OneUser=*/false};
  }
  SmallVector<const llvm::Value *, 2> Asked;
};

TEST_F(ExprEvaluatorTest, AsksUseOracleAboutConstants) {
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

  Var Global = var("g", Sort::Value);
  Var Load = var("a", Sort::Value);
  Value GlobalExpr = read(Global, Sort::Value);
  Value LoadExpr = read(Load, Sort::Value);
  bind(Global, M->getNamedGlobal("g"));
  bind(Load, A);

  OneUseOracle Oracle;
  Evaluator.setUseOracle(&Oracle);
  // The function uses @g twice, but its module is what counts.
  EXPECT_TRUE(evaluateBoolean(call("hasOneUse", GlobalExpr)));
  EXPECT_FALSE(evaluateBoolean(call("hasOneUser", GlobalExpr)));
  // Instructions are only used in their function.
  EXPECT_TRUE(evaluateBoolean(call("hasOneUse", LoadExpr)));
  EXPECT_TRUE(evaluateBoolean(call("hasOneUser", LoadExpr)));
  EXPECT_EQ(Oracle.Asked.size(), 2u);
}

// Use counts come from the IR, except for values used across functions,
// whose module only the oracle knows.
TEST_F(ExprEvaluatorTest, CountsUsesWithTheUseOracle) {
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

  Var Global = var("g", Sort::Value);
  Var Load = var("a", Sort::Value);
  Value GlobalExpr = read(Global, Sort::Value);
  Value LoadExpr = read(Load, Sort::Value);
  bind(Global, M->getNamedGlobal("g"));
  bind(Load, A);
  auto Uses = [&](StringRef Name, Value Value, int64_t N) {
    return operation(constraint::Call, Name, {Value, integer(N)});
  };

  // %a has two uses, by one user.
  EXPECT_TRUE(evaluateBoolean(Uses("hasNUses", LoadExpr, 2)));
  EXPECT_FALSE(evaluateBoolean(Uses("hasNUses", LoadExpr, 1)));
  EXPECT_TRUE(evaluateBoolean(Uses("hasNUsesOrMore", LoadExpr, 2)));
  EXPECT_FALSE(evaluateBoolean(Uses("hasNUsesOrMore", LoadExpr, 3)));

  OneUseOracle Oracle;
  Evaluator.setUseOracle(&Oracle);
  // The function uses @g twice, but its module is what counts.
  EXPECT_TRUE(evaluateBoolean(Uses("hasNUses", GlobalExpr, 1)));
  EXPECT_FALSE(evaluateBoolean(Uses("hasNUses", GlobalExpr, 2)));
  EXPECT_FALSE(evaluateBoolean(Uses("hasNUses", GlobalExpr, 3)));
  EXPECT_TRUE(evaluateBoolean(Uses("hasNUsesOrMore", GlobalExpr, 1)));
  EXPECT_FALSE(evaluateBoolean(Uses("hasNUsesOrMore", GlobalExpr, 2)));
}

TEST_F(ExprEvaluatorTest, EvaluatesOpcodePredicates) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  auto Add = std::unique_ptr<BinaryOperator>(BinaryOperator::CreateAdd(
      ConstantInt::get(I32, 1), ConstantInt::get(I32, 2), "sum"));
  auto Cast = std::unique_ptr<CastInst>(
      CastInst::Create(llvm::Instruction::ZExt, Add.get(),
                       llvm::Type::getInt64Ty(LLVMContext), "extended"));
  Var Subject = var("value", Sort::Value);
  Value ValueExpression = read(Subject, Sort::Value);
  bind(Subject, Cast.get());

  EXPECT_TRUE(evaluateBoolean(
      binary("==", operation(constraint::Call, "opcode", {ValueExpression}),
             string("zext"))));
  EXPECT_FALSE(evaluateBoolean(
      binary("==", operation(constraint::Call, "opcode", {ValueExpression}),
             string("add"))));

  Var IntegerValue = var("integer_value", Sort::Value);
  Value IntegerExpression = read(IntegerValue, Sort::Value);
  bind(IntegerValue, ConstantInt::get(I32, 1));
  Value NonInstruction =
      operation(constraint::Call, "opcode", {IntegerExpression});
  Expected<ConstraintValue> Result = evaluateResult(NonInstruction);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(opcode ?integer_value)': expected an "
            "instruction operand");
}

TEST_F(ExprEvaluatorTest, ConvertsSymbolicBindingsToStrings) {
  Var Predicate = var("predicate", Sort::CmpPredicate);
  Var IntrinsicVariable = var("intrinsic", Sort::IntrinsicID);
  Value PredicateExpression = read(Predicate, Sort::String);
  Value IntrinsicExpression = read(IntrinsicVariable, Sort::String);
  bind(Predicate, CmpInst::ICMP_SLT);
  bind(IntrinsicVariable, Intrinsic::abs);

  EXPECT_EQ(evaluate(PredicateExpression).getString(), "slt");
  EXPECT_EQ(evaluate(IntrinsicExpression).getString(), "llvm.abs");
  EXPECT_TRUE(
      evaluateBoolean(binary("==", PredicateExpression, string("slt"))));
  EXPECT_TRUE(
      evaluateBoolean(binary("==", IntrinsicExpression, string("llvm.abs"))));
}

TEST_F(ExprEvaluatorTest, ReportsEvaluationErrors) {
  Var Missing = var("missing", Sort::Nat);
  Value MissingExpression = read(Missing, Sort::Integer);
  Expected<ConstraintValue> MissingResult = evaluateResult(MissingExpression);
  ASSERT_FALSE(MissingResult);
  EXPECT_EQ(toString(MissingResult.takeError()),
            "cannot evaluate constraint '?missing': meta variable '?missing' "
            "is not instantiated");

  Var Flag = var("flag", Sort::Boolean);
  Value FlagExpression = read(Flag, Sort::Boolean);
  bind(Flag, APInt(1, 1));
  Expected<ConstraintValue> IncompatibleResult = evaluateResult(FlagExpression);
  ASSERT_FALSE(IncompatibleResult);
  EXPECT_EQ(toString(IncompatibleResult.takeError()),
            "cannot evaluate constraint '?flag': meta variable '?flag' has an "
            "incompatible binding");

  Var InstSubject = instruction("sum");
  Value UninstInstExpr = read(InstSubject, Sort::Value);
  Expected<ConstraintValue> UninstInstRes = evaluateResult(UninstInstExpr);
  ASSERT_FALSE(UninstInstRes);
  EXPECT_EQ(toString(UninstInstRes.takeError()),
            "cannot evaluate constraint '%sum': variable '%sum' "
            "is not instantiated");

  Value IncompatInstExpr = read(InstSubject, Sort::Integer);
  bind(InstSubject, true);
  Expected<ConstraintValue> IncompatInstRes = evaluateResult(IncompatInstExpr);
  ASSERT_FALSE(IncompatInstRes);
  EXPECT_EQ(toString(IncompatInstRes.takeError()),
            "cannot evaluate constraint '%sum': variable '%sum' has an "
            "incompatible binding");

  Value DivisionByZero = call("udiv", integer(1), integer(0));
  Expected<ConstraintValue> DivisionResult = evaluateResult(DivisionByZero);
  ASSERT_FALSE(DivisionResult);
  EXPECT_EQ(toString(DivisionResult.takeError()),
            "cannot evaluate constraint '(udiv 1 0)': division by zero");

  for (StringRef Operator : {"sdiv", "srem", "urem"}) {
    Expected<ConstraintValue> Result =
        evaluateResult(call(Operator, integer(1), integer(0)));
    EXPECT_FALSE(Result);
    EXPECT_FALSE(toString(Result.takeError()).empty());
  }

  Value Unknown = operation(constraint::Call, "custom", {integer(1)});
  Expected<ConstraintValue> UnknownResult = evaluateResult(Unknown);
  ASSERT_FALSE(UnknownResult);
  EXPECT_EQ(
      toString(UnknownResult.takeError()),
      "cannot evaluate constraint '(custom 1)': unknown operator 'custom'");

  Var Values = var("values", Sort::ValueArray);
  Value ValuesExpression = read(Values, Sort::ValueArray);
  bind(Values, Binding::ValueArray{});
  Value OutOfBounds = access(ValuesExpression, integer(0), Sort::Value);
  Expected<ConstraintValue> BoundsResult = evaluateResult(OutOfBounds);
  ASSERT_FALSE(BoundsResult);
  EXPECT_EQ(toString(BoundsResult.takeError()),
            "cannot evaluate constraint '?values[0]': array index is out of "
            "bounds");

  Value InvalidShift = operation(constraint::Call, "lshr",
                                 {integer(1), integer(64), integer(64)});
  Expected<ConstraintValue> ShiftResult = evaluateResult(InvalidShift);
  ASSERT_FALSE(ShiftResult);
  EXPECT_EQ(
      toString(ShiftResult.takeError()),
      "cannot evaluate constraint '(lshr 1 64 64)': shift amount is out of "
      "range");

  Value NegativeShift = call("ashr", integer(1), integer(-1));
  Expected<ConstraintValue> NegativeShiftResult = evaluateResult(NegativeShift);
  ASSERT_FALSE(NegativeShiftResult);
  EXPECT_EQ(toString(NegativeShiftResult.takeError()),
            "cannot evaluate constraint '(ashr 1 -1)': shift amount is "
            "out of range");
}

TEST_F(ExprEvaluatorTest, RejectsInvalidCoercionsAndComparisons) {
  LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  Constant *One = ConstantInt::get(I32, 1);
  Var ValueVariable = var("value", Sort::Value);
  Value ValueExpression = read(ValueVariable, Sort::Value);
  bind(ValueVariable, One);

  Expected<ConstraintValue> IntegerResult =
      evaluateResult(binary("+", ValueExpression, integer(1)));
  ASSERT_TRUE(static_cast<bool>(IntegerResult));
  EXPECT_EQ(IntegerResult->getInteger().getSExtValue(), 2);

  Expected<ConstraintValue> BooleanResult =
      evaluateResult(binary("&&", ValueExpression, boolean(true)));
  ASSERT_FALSE(BooleanResult);
  EXPECT_EQ(toString(BooleanResult.takeError()),
            "cannot evaluate constraint '(&& ?value true)': expected a "
            "boolean-coercible operand");

  Expected<ConstraintValue> EqualityResult =
      evaluateResult(binary("==", integer(1), string("1")));
  ASSERT_FALSE(EqualityResult);
  EXPECT_EQ(toString(EqualityResult.takeError()),
            "cannot evaluate constraint '(== 1 \"1\")': equality operands "
            "have different types");

  Expected<ConstraintValue> IsaValueResult =
      evaluateResult(call("isa", integer(1), string("Value")));
  ASSERT_FALSE(IsaValueResult);
  EXPECT_EQ(toString(IsaValueResult.takeError()),
            "cannot evaluate constraint '(isa 1 \"Value\")': expected an "
            "LLVM value operand");

  Expected<ConstraintValue> IsaNameResult =
      evaluateResult(call("isa", ValueExpression, integer(1)));
  ASSERT_FALSE(IsaNameResult);
  EXPECT_EQ(toString(IsaNameResult.takeError()),
            "cannot evaluate constraint '(isa ?value 1)': expected a "
            "string-coercible operand");

  Expected<ConstraintValue> NegativeIndexResult = evaluateResult(access(
      array(Sort::StringArray, {string("value")}), integer(-1), Sort::String));
  ASSERT_FALSE(NegativeIndexResult);
  EXPECT_EQ(toString(NegativeIndexResult.takeError()),
            "cannot evaluate constraint '[\"value\"][-1]': array index "
            "is negative");
}

TEST_F(ExprEvaluatorTest, EvaluatesValueTrackingOperators) {
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

  Var Y = var("y", Sort::Value);
  Var Z = var("z", Sort::Value);
  Var Ctx = var("ctx", Sort::Value);
  Value YExpression = read(Y, Sort::Value);
  Value ZExpression = read(Z, Sort::Value);
  Value CtxExpression = read(Ctx, Sort::Value);
  bind(Y, Fn->getArg(1));
  bind(Z, Fn->getArg(2));
  bind(Ctx, Root);

  // y and z are constrained to [0, 15], so y*z fits in i8 without unsigned
  // overflow; signed overflow is possible (15*15 > 127).
  EXPECT_TRUE(evaluateBoolean(
      operation(constraint::Call, "noOverflow",
                {string("umul"), YExpression, ZExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(
      operation(constraint::Call, "noOverflow",
                {string("smul"), YExpression, ZExpression, CtxExpression})));

  // 255 * 2 does not fit in i8.
  Var Big = var("big", Sort::Value);
  Var Two = var("two", Sort::Value);
  Value BigExpression = read(Big, Sort::Value);
  Value TwoExpression = read(Two, Sort::Value);
  bind(Big, ConstantInt::get(I8, 255));
  bind(Two, ConstantInt::get(I8, 2));
  EXPECT_FALSE(evaluateBoolean(operation(
      constraint::Call, "noOverflow",
      {string("umul"), BigExpression, TwoExpression, CtxExpression})));

  // Sign predicates on the range-constrained argument.
  EXPECT_TRUE(evaluateBoolean(operation(constraint::Call, "isKnownNonNegative",
                                        {YExpression, CtxExpression})));

  // Known bits of the constant 5 (0b00000101): ones mask 0x05, zeros 0xFA.
  Var Const = var("c", Sort::Value);
  Value ConstExpression = read(Const, Sort::Value);
  bind(Const, ConstantInt::get(I8, 5));
  EXPECT_TRUE(evaluateBoolean(operation(constraint::Call, "isKnownNonZero",
                                        {ConstExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(operation(constraint::Call, "isKnownPowerOfTwo",
                                         {ConstExpression, CtxExpression})));
  EXPECT_TRUE(evaluateBoolean(operation(constraint::Call, "isKnownPositive",
                                        {ConstExpression, CtxExpression})));
  EXPECT_FALSE(evaluateBoolean(operation(constraint::Call, "isKnownNegative",
                                         {ConstExpression, CtxExpression})));

  // Constant 4 is a power of two.
  Var Four = var("four", Sort::Value);
  Value FourExpression = read(Four, Sort::Value);
  bind(Four, ConstantInt::get(I8, 4));
  EXPECT_TRUE(evaluateBoolean(operation(constraint::Call, "isKnownPowerOfTwo",
                                        {FourExpression, CtxExpression})));

  Expected<ConstraintValue> KnownBits = evaluateResult(operation(
      constraint::Call, "knownBits", {ConstExpression, CtxExpression}));
  ASSERT_TRUE(static_cast<bool>(KnownBits));
  EXPECT_EQ(KnownBits->getKnownBits().One, APInt(8, 0x05));
  EXPECT_EQ(KnownBits->getKnownBits().Zero, APInt(8, 0xFA));

  Value KnownBitsCall = operation(constraint::Call, "knownBits",
                                  {ConstExpression, CtxExpression});
  Expected<ConstraintValue> Zeros = evaluateResult(
      operation(constraint::Call, "knownZeros", {KnownBitsCall}));
  ASSERT_TRUE(static_cast<bool>(Zeros));
  EXPECT_EQ(Zeros->getInteger(), APSInt(APInt(8, 0xFA), true));
  Expected<ConstraintValue> Ones =
      evaluateResult(operation(constraint::Call, "knownOnes", {KnownBitsCall}));
  ASSERT_TRUE(static_cast<bool>(Ones));
  EXPECT_EQ(Ones->getInteger(), APSInt(APInt(8, 0x05), true));

  // Bit-vector equality compares both masks.
  EXPECT_TRUE(
      evaluateBoolean(binary("==",
                             operation(constraint::Call, "knownBits",
                                       {ConstExpression, CtxExpression}),
                             operation(constraint::Call, "knownBits",
                                       {ConstExpression, CtxExpression}))));

  // masked-value-is-zero: 5 & 8 == 0, 5 & 4 != 0.
  EXPECT_TRUE(
      evaluateBoolean(operation(constraint::Call, "maskedValueIsZero",
                                {ConstExpression, integer(8), CtxExpression})));
  EXPECT_FALSE(
      evaluateBoolean(operation(constraint::Call, "maskedValueIsZero",
                                {ConstExpression, integer(4), CtxExpression})));

  // Unknown overflow kind.
  Expected<ConstraintValue> UnknownKind = evaluateResult(operation(
      constraint::Call, "noOverflow",
      {string("foo"), ConstExpression, ConstExpression, CtxExpression}));
  ASSERT_FALSE(UnknownKind);
  EXPECT_EQ(toString(UnknownKind.takeError()),
            "cannot evaluate constraint '(noOverflow \"foo\" ?c ?c ?ctx)': "
            "unknown overflow kind 'foo'");

  // Non-integer operand.
  Var FloatValue = var("float_value", Sort::Value);
  Value FloatExpression = read(FloatValue, Sort::Value);
  bind(FloatValue, ConstantFP::get(Float, 1.0));
  Expected<ConstraintValue> NonInteger =
      evaluateResult(operation(constraint::Call, "isKnownNonNegative",
                               {FloatExpression, CtxExpression}));
  ASSERT_FALSE(NonInteger);
  EXPECT_EQ(toString(NonInteger.takeError()),
            "cannot evaluate constraint '(isKnownNonNegative ?float_value "
            "?ctx)': expected an integer-typed value operand");

  // Context that is a value but not an instruction.
  Expected<ConstraintValue> BadContext = evaluateResult(operation(
      constraint::Call, "isKnownNonZero", {ConstExpression, BigExpression}));
  ASSERT_FALSE(BadContext);
  EXPECT_EQ(toString(BadContext.takeError()),
            "cannot evaluate constraint '(isKnownNonZero ?c ?big)': expected "
            "an instruction context operand");
}

TEST_F(ExprEvaluatorTest, ResolvesDefaultValueTrackContext) {
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

  Var Y = var("y", Sort::Value);
  Var Z = var("z", Sort::Value);
  Value YExpression = read(Y, Sort::Value);
  Value ZExpression = read(Z, Sort::Value);
  bind(Y, Fn->getArg(1));
  bind(Z, Fn->getArg(2));

  // The pattern instruction preceding the constraint supplies the context.
  Var PatternInst = instruction("root");
  bind(PatternInst, Binding(Root));
  Value NoOverflow =
      anchored(operation(constraint::Call, "noOverflow",
                         {string("umul"), YExpression, ZExpression}),
               PatternInst);

  EXPECT_TRUE(evaluateBoolean(NoOverflow));

  // Without a resolvable context instruction the operator reports an error.
  Value Unanchored = operation(constraint::Call, "noOverflow",
                               {string("umul"), YExpression, ZExpression});
  Expected<ConstraintValue> Result = evaluateResult(Unanchored);
  ASSERT_FALSE(Result);
  EXPECT_EQ(toString(Result.takeError()),
            "cannot evaluate constraint '(noOverflow \"umul\" ?y ?z)': no "
            "context instruction for value-tracking operator (place the "
            "constraint after an instruction or pass ?ctx explicitly)");
}

TEST_F(ExprEvaluatorTest, ValueTrackContextBuildsLazily) {
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
TEST_F(ExprEvaluatorTest, IntegerPredicatesRejectNonIntegers) {
  for (StringRef Name :
       {"isPower2", "isZero", "isAllOnes", "isLowBitMask", "isPower2OrZero",
        "isLowBitMaskOrZero", "isNegative", "isNonNegative",
        "isStrictlyPositive", "isNonPositive", "isNonZeroInt"}) {
    SCOPED_TRACE(Name);
    EXPECT_FALSE(evaluateBoolean(call(Name, string("x"))));
  }
}

// A variable's binding, read as each sort: a constant reads as its number or
// truth value; predicates and intrinsics read as their names; a binding of
// another kind is incompatible.
TEST_F(ExprEvaluatorTest, ReadsBindingsAsTheirSort) {
  llvm::LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  llvm::Constant *Seven = ConstantInt::get(I32, 7);
  llvm::Constant *True1 =
      ConstantInt::get(llvm::Type::getInt1Ty(LLVMContext), 1);
  Var V = var("v", Sort::Integer);

  auto readAs = [&](Sort S, Binding B) {
    Value R = read(V, S);
    return readBinding(R, B);
  };
  EXPECT_EQ(cantFail(readAs(Sort::Integer, Binding(Seven))).getInteger(),
            APSInt(APInt(32, 7), false));
  EXPECT_EQ(cantFail(readAs(Sort::Integer, Binding(APSInt(APInt(8, 3), true))))
                .getInteger(),
            APSInt(APInt(8, 3), true));
  EXPECT_TRUE(cantFail(readAs(Sort::Boolean, Binding(True1))).getBoolean());
  EXPECT_FALSE(cantFail(readAs(Sort::Boolean, Binding(false))).getBoolean());
  EXPECT_EQ(
      cantFail(readAs(Sort::String, Binding(CmpInst::ICMP_ULT))).getString(),
      "ult");
  EXPECT_EQ(
      cantFail(readAs(Sort::String, Binding(Intrinsic::ctlz))).getString(),
      "llvm.ctlz");
  EXPECT_TRUE(cantFail(readAs(Sort::Type, Binding(I32))).getType() == I32);
  EXPECT_TRUE(cantFail(readAs(Sort::Value, Binding(Seven))).getValue() ==
              Seven);
  EXPECT_EQ(cantFail(readAs(Sort::TypeArray, Binding(Binding::TypeArray{I32})))
                .getTypeArray()
                .size(),
            1u);
  EXPECT_EQ(
      cantFail(readAs(Sort::ValueArray, Binding(Binding::ValueArray{Seven})))
          .getValueArray()
          .size(),
      1u);
  // A binding of another kind is not a value of the sort.
  EXPECT_FALSE(bool(readAs(Sort::Integer, Binding(I32))));
  EXPECT_FALSE(bool(readAs(Sort::Boolean, Binding(Binding::TypeArray{}))));
  EXPECT_FALSE(bool(readAs(Sort::String, Binding(false))));
  EXPECT_FALSE(bool(readAs(Sort::Type, Binding(Seven))));
  EXPECT_FALSE(bool(readAs(Sort::Value, Binding(false))));
  EXPECT_FALSE(bool(readAs(Sort::TypeArray, Binding(Seven))));
  EXPECT_FALSE(bool(readAs(Sort::ValueArray, Binding(I32))));
}

// A variable of unknown sort reads whatever its binding is, as its own kind.
TEST_F(ExprEvaluatorTest, ReadsUnknownSortBindingsAsTheyAre) {
  llvm::LLVMContext LLVMContext;
  llvm::Type *I32 = llvm::Type::getInt32Ty(LLVMContext);
  llvm::Constant *Seven = ConstantInt::get(I32, 7);
  Var V = var("u", Sort::Unknown);
  auto readUnknown = [&](Binding B) {
    return readBinding(read(V, Sort::Unknown), B);
  };
  EXPECT_TRUE(cantFail(readUnknown(Binding(Seven))).getValue() == Seven);
  EXPECT_TRUE(cantFail(readUnknown(Binding(I32))).getType() == I32);
  EXPECT_EQ(
      cantFail(readUnknown(Binding(APSInt(APInt(8, 2), false)))).getInteger(),
      APSInt(APInt(8, 2), false));
  EXPECT_TRUE(cantFail(readUnknown(Binding(true))).getBoolean());
  EXPECT_EQ(cantFail(readUnknown(Binding(CmpInst::ICMP_EQ))).getString(), "eq");
  EXPECT_EQ(cantFail(readUnknown(Binding(Intrinsic::umin))).getString(),
            "llvm.umin");
  EXPECT_EQ(cantFail(readUnknown(Binding(Binding::TypeArray{I32})))
                .getTypeArray()
                .size(),
            1u);
  EXPECT_EQ(cantFail(readUnknown(Binding(Binding::ValueArray{Seven})))
                .getValueArray()
                .size(),
            1u);
  EXPECT_FALSE(bool(readUnknown(Binding())));
}

TEST_F(ExprEvaluatorTest, ReportsOperatorsWithoutDescriptors) {
  Expected<ConstraintValue> Result =
      evaluateResult(operation(constraint::Call, "isZero", {integer(0)}));
  consumeError(Result.takeError());
}

TEST_F(ExprEvaluatorTest, ReportsErrorsOfEveryPart) {
  Var Missing = var("missing", Sort::Nat);
  Value Bad = read(Missing, Sort::Integer);
  Value BadArray = read(Missing, Sort::ValueArray);
  Value Empty = array(Sort::ValueArray, {});
  // The message of the error E evaluates to, which must contain Text.
  auto Reports = [&](Value E, StringRef Text) {
    Expected<ConstraintValue> Result = evaluateResult(E);
    if (Result) {
      ADD_FAILURE() << "evaluated to " << Result->getKind();
      return;
    }
    std::string Message = toString(Result.takeError());
    EXPECT_NE(Message.find(Text.str()), std::string::npos)
        << Text.str() << ": " << Message;
  };

  // Array elements, of each kind of array.
  Reports(array(Sort::ValueArray, {read(Missing, Sort::Value)}),
          "not instantiated");
  Reports(array(Sort::StringArray, {integer(1)}), "string");

  // Accesses: the array, the index, and the index's kind and bounds.
  Reports(access(BadArray, integer(0), Sort::Value), "not instantiated");
  Reports(access(Empty, Bad, Sort::Value), "not instantiated");
  Reports(access(Empty, string("x"), Sort::Value), "integer");
  Reports(access(array(Sort::TypeArray, {}), integer(0), Sort::Type),
          "out of bounds");
  Reports(access(array(Sort::StringArray, {}), integer(0), Sort::String),
          "out of bounds");

  // Logical operators: the right operand, evaluated and as a boolean.
  Reports(binary("&&", boolean(true), read(Missing, Sort::Boolean)),
          "not instantiated");
  Reports(binary("&&", boolean(true), string("x")), "boolean");

  // Value-tracking operators: their operands, and an explicit context.
  Reports(call("knownBits", read(Missing, Sort::Value)), "not instantiated");
  Reports(call("knownBits", integer(1), read(Missing, Sort::Value)),
          "not instantiated");
  Reports(call("knownBits", integer(1), integer(2)), "value");

  // Expressions that are not constraint expressions at all.
  Reports(slot(Missing), "not a constraint expression");
}

} // namespace
