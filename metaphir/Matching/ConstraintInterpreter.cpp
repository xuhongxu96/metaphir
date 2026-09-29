#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/ErrorHandling.h"
#include <optional>

namespace llvm {
namespace metaphir {

using namespace detail;

ConstraintInterpreter::ConstraintInterpreter(MIRContext *Context)
    : Analysis(std::make_unique<ValueTrackContext>()), Context(Context) {}

ConstraintInterpreter::~ConstraintInterpreter() = default;

SimplifyQuery
ConstraintInterpreter::getValueTrackQuery(const llvm::Instruction *CtxI) {
  return Analysis->getQuery(CtxI);
}

Expected<ConstraintValue>
ConstraintInterpreter::evaluate(const Constraint &Expression,
                                const Instantiation &State) {
  switch (Expression.getConstraintID()) {
  case Constraint::Integer:
  case Constraint::Boolean:
  case Constraint::String:
    return evalLiteral(Expression, State);
  case Constraint::Array:
    return evalArray(cast<ArrayConstraint>(Expression), State);
  case Constraint::Variable:
    return evalVariable(cast<VariableConstraint>(Expression), State);
  case Constraint::ArrayAccess:
    return evalArrayAccess(cast<ArrayAccessConstraint>(Expression), State);
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call:
    return evalOperator(cast<OperatorConstraint>(Expression), State);
  }
  llvm_unreachable("unknown constraint ID");
}

Expected<const llvm::Instruction *>
ConstraintInterpreter::resolveValueTrackContext(
    ArrayRef<Constraint *> Arguments, unsigned BaseArity,
    const Instantiation &State, const Constraint &Expression) {
  if (Arguments.size() > BaseArity) {
    Expected<ConstraintValue> Context = evaluate(*Arguments[BaseArity], State);
    if (!Context)
      return Context.takeError();
    Expected<const llvm::Value *> Value =
        requireValue(std::move(*Context), Expression);
    if (!Value)
      return Value.takeError();
    if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
      return Instruction;
    return make_error<ConstraintEvaluationError>(
        Expression, "expected an instruction context operand");
  }

  const metaphir::Instruction *Pattern = Expression.getContextInstruction();
  if (!Pattern)
    return make_error<ConstraintEvaluationError>(
        Expression, "no context instruction for value-tracking operator "
                    "(place the constraint after an instruction or pass ?ctx "
                    "explicitly)");
  if (const Instantiation::Binding *Binding = State.lookup(*Pattern))
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
      if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
        return Instruction;
  return make_error<ConstraintEvaluationError>(
      Expression, "no context instruction for value-tracking operator "
                  "(place the constraint after an instruction or pass ?ctx "
                  "explicitly)");
}

Expected<ConstraintValue> ConstraintInterpreter::evaluateValueTrack(
    ArrayRef<Constraint *> Arguments, unsigned BaseArity,
    const Instantiation &State, const Constraint &Expression, ValueTrackOp Op) {
  SmallVector<ConstraintValue, 2> Values;
  Values.reserve(BaseArity);
  for (const Constraint *Argument : Arguments.take_front(BaseArity)) {
    Expected<ConstraintValue> Value = evaluate(*Argument, State);
    if (!Value)
      return Value.takeError();
    Values.push_back(std::move(*Value));
  }

  Expected<const llvm::Instruction *> Context =
      resolveValueTrackContext(Arguments, BaseArity, State, Expression);
  if (!Context)
    return Context.takeError();
  SimplifyQuery Query = getValueTrackQuery(*Context);
  return Op(Values, Query, Expression);
}

Expected<ConstraintValue>
ConstraintInterpreter::evalLiteral(const Constraint &Expression,
                                   const Instantiation &) {
  switch (Expression.getConstraintID()) {
  case Constraint::Integer: {
    int64_t Value = cast<IntegerConstraint>(Expression).getValue();
    return ConstraintValue::getInteger(
        APSInt(APInt(64, static_cast<uint64_t>(Value), true), Value >= 0));
  }
  case Constraint::Boolean:
    return ConstraintValue::getBoolean(
        cast<BooleanConstraint>(Expression).getValue());
  case Constraint::String:
    return ConstraintValue::getString(
        cast<StringConstraint>(Expression).getValue());
  default:
    llvm_unreachable("not a literal constraint");
  }
}

Expected<ConstraintValue>
ConstraintInterpreter::evalVariable(const VariableConstraint &Expression,
                                    const Instantiation &State) {
  const Value &Variable = *Expression.getVariable();
  const Instantiation::Binding *Binding = State.lookup(Variable);
  auto FormatMsg = [&](StringRef Msg) -> std::string {
    if (const auto *MV = dyn_cast<MetaVariable>(&Variable))
      return (Twine("meta variable '?") + MV->getName() + "' " + Msg).str();
    std::string Str;
    raw_string_ostream OS(Str);
    OS << Variable;
    return (Twine("variable '") + OS.str() + "' " + Msg).str();
  };
  if (!Binding)
    return make_error<ConstraintEvaluationError>(
        Expression, FormatMsg("is not instantiated"));

  switch (Expression.getResultType()) {
  case Constraint::IntegerResult:
    if (const auto *Integer = std::get_if<APSInt>(&Binding->Data))
      return ConstraintValue::getInteger(*Integer);
    // An IR constant is read as a signed number, as in coerceValueToInteger.
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getInteger(
            APSInt(CI->getValue(), /*isUnsigned=*/false));
    break;
  case Constraint::BooleanResult:
    if (const auto *Boolean = std::get_if<bool>(&Binding->Data))
      return ConstraintValue::getBoolean(*Boolean);
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getBoolean(CI->isOne());
    break;
  case Constraint::StringResult:
    if (const auto *Predicate = std::get_if<CmpInst::Predicate>(&Binding->Data))
      return ConstraintValue::getString(CmpInst::getPredicateName(*Predicate));
    if (const auto *ID = std::get_if<Intrinsic::ID>(&Binding->Data))
      return ConstraintValue::getString(Intrinsic::getBaseName(*ID));
    break;
  case Constraint::TypeResult:
    if (const auto *Type = std::get_if<const llvm::Type *>(&Binding->Data))
      return ConstraintValue::getType(*Type);
    break;
  case Constraint::ValueResult:
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding->Data))
      return ConstraintValue::getValue(*Value);
    break;
  case Constraint::TypeArrayResult:
    if (const auto *Types =
            std::get_if<Instantiation::TypeArray>(&Binding->Data))
      return ConstraintValue::getTypeArray(*Types);
    break;
  case Constraint::ValueArrayResult:
    if (const auto *Values =
            std::get_if<Instantiation::ValueArray>(&Binding->Data))
      return ConstraintValue::getValueArray(*Values);
    break;
  case Constraint::Unknown:
    return std::visit(
        [&](const auto &Val) -> Expected<ConstraintValue> {
          using T = std::decay_t<decltype(Val)>;
          if constexpr (std::is_same_v<T, const llvm::Value *>)
            return ConstraintValue::getValue(Val);
          else if constexpr (std::is_same_v<T, const llvm::Type *>)
            return ConstraintValue::getType(Val);
          else if constexpr (std::is_same_v<T, APSInt>)
            return ConstraintValue::getInteger(Val);
          else if constexpr (std::is_same_v<T, bool>)
            return ConstraintValue::getBoolean(Val);
          else if constexpr (std::is_same_v<T, CmpInst::Predicate>)
            return ConstraintValue::getString(CmpInst::getPredicateName(Val));
          else if constexpr (std::is_same_v<T, Intrinsic::ID>)
            return ConstraintValue::getString(Intrinsic::getBaseName(Val));
          else if constexpr (std::is_same_v<T, Instantiation::TypeArray>)
            return ConstraintValue::getTypeArray(Val);
          else if constexpr (std::is_same_v<T, Instantiation::ValueArray>)
            return ConstraintValue::getValueArray(Val);
          else
            return make_error<ConstraintEvaluationError>(
                Expression, FormatMsg("has an incompatible binding"));
        },
        Binding->Data);
  default:
    llvm_unreachable("variable constraint has no result type");
  }

  return make_error<ConstraintEvaluationError>(
      Expression, FormatMsg("has an incompatible binding"));
}

Expected<ConstraintValue>
ConstraintInterpreter::evalArray(const ArrayConstraint &Expression,
                                 const Instantiation &State) {
  switch (Expression.getResultType()) {
  case Constraint::TypeArrayResult: {
    Instantiation::TypeArray Types;
    for (const Constraint *Element : Expression.getElements()) {
      Expected<ConstraintValue> Result = evaluate(*Element, State);
      if (!Result)
        return Result.takeError();
      if (Result->getKind() != ConstraintValue::Type)
        llvm_unreachable("type array constraint has a non-type element");
      Types.push_back(Result->getType());
    }
    return ConstraintValue::getTypeArray(std::move(Types));
  }
  case Constraint::ValueArrayResult: {
    Instantiation::ValueArray Values;
    for (const Constraint *Element : Expression.getElements()) {
      Expected<ConstraintValue> Result = evaluate(*Element, State);
      if (!Result)
        return Result.takeError();
      if (Result->getKind() != ConstraintValue::Value)
        llvm_unreachable("value array constraint has a non-value element");
      Values.push_back(Result->getValue());
    }
    return ConstraintValue::getValueArray(std::move(Values));
  }
  case Constraint::StringArrayResult: {
    ConstraintValue::StringArrayStorage Strings;
    for (const Constraint *Element : Expression.getElements()) {
      Expected<std::string> Result =
          requireString(evaluate(*Element, State), Expression);
      if (!Result)
        return Result.takeError();
      Strings.push_back(std::move(*Result));
    }
    return ConstraintValue::getStringArray(std::move(Strings));
  }
  default:
    llvm_unreachable("array constraint has a non-array result type");
  }
}

Expected<ConstraintValue>
ConstraintInterpreter::evalArrayAccess(const ArrayAccessConstraint &Access,
                                       const Instantiation &State) {
  Expected<ConstraintValue> Array = evaluate(*Access.getArray(), State);
  if (!Array)
    return Array.takeError();
  Expected<APSInt> Index =
      requireInteger(evaluate(*Access.getIndex(), State), Access);
  if (!Index)
    return Index.takeError();
  if (Index->isSigned() && Index->isNegative())
    return make_error<ConstraintEvaluationError>(Access,
                                                 "array index is negative");
  uint64_t Position = Index->getLimitedValue();

  switch (Array->getKind()) {
  case ConstraintValue::TypeArray: {
    const Instantiation::TypeArray &Types = Array->getTypeArray();
    if (Position >= Types.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getType(Types[Position]);
  }
  case ConstraintValue::ValueArray: {
    const Instantiation::ValueArray &Values = Array->getValueArray();
    if (Position >= Values.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getValue(Values[Position]);
  }
  case ConstraintValue::StringArray: {
    const ConstraintValue::StringArrayStorage &Strings =
        Array->getStringArray();
    if (Position >= Strings.size())
      return make_error<ConstraintEvaluationError>(
          Access, "array index is out of bounds");
    return ConstraintValue::getString(Strings[Position]);
  }
  default:
    llvm_unreachable("array access constraint has a non-array operand");
  }
}

Expected<ConstraintValue>
ConstraintInterpreter::evalOperator(const OperatorConstraint &Operator,
                                    const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  if (std::optional<Constraint::OperatorSchema> Schema =
          Constraint::getOperatorSchema(Operator.getOperatorID()))
    assert(Arguments.size() >= Schema->MinArity &&
           Arguments.size() <= Schema->MaxArity &&
           "built-in constraint operator has invalid arity");

  switch (Operator.getOperatorID()) {
  case Constraint::O_LogicalOr:
  case Constraint::O_LogicalAnd:
    return evalLogical(Operator, State);
  case Constraint::O_Not:
  case Constraint::O_Negate:
    return evalUnary(Operator, State);
  case Constraint::O_Lshr:
  case Constraint::O_Ashr:
  case Constraint::O_Shl:
    return evalShift(Operator, State);
  case Constraint::UnknownOperator:
    return evalUserDefinedCall(Operator, State);
  default:
    break;
  }

  // Interpreted built-ins (isa, log2, popcount, value-tracking) are
  // table-driven so that adding a new interpreted operator is a one-line
  // change in the .def file.
  switch (Operator.getOperatorID()) {
#define MIR_CONSTRAINT_INTERPRETED_OPERATOR(ID, Name, Kind, Result, Arity)     \
  case Constraint::O_##ID:                                                     \
    return evaluate##ID(*this, Operator.getArguments(), State, Operator);
#define MIR_CONSTRAINT_VALUE_TRACK_OPERATOR(ID, Name, Kind, Result, BaseArity) \
  case Constraint::O_##ID:                                                     \
    return evaluateValueTrack(Operator.getArguments(), BaseArity, State,       \
                              Operator, evaluate##ID);
#include "metaphir/IR/ConstraintOperators.def"
  default:
    break;
  }

  return evalArithmetic(Operator, State);
}

Expected<ConstraintValue>
ConstraintInterpreter::evalUserDefinedCall(const OperatorConstraint &Operator,
                                           const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  const ConstraintDef *Def =
      Context ? Context->getConstraintDef(Operator.getOperator()) : nullptr;
  if (!Def)
    return make_error<ConstraintEvaluationError>(
        Operator, Twine("unknown operator '") + Operator.getOperator() + "'");

  if (Arguments.size() != Def->getParameters().size())
    return make_error<ConstraintEvaluationError>(
        Operator, "wrong number of arguments to user-defined constraint '" +
                      Operator.getOperator() + "'");
  // Definitions can only call earlier ones, so calls cannot recurse;
  // the limit guards against contexts built by hand.
  if (CallDepth == MaxCallDepth)
    return make_error<ConstraintEvaluationError>(
        Operator, "user-defined constraints are nested too deeply");
  Instantiation SubState = State;
  for (size_t I = 0; I < Arguments.size(); ++I) {
    Expected<ConstraintValue> ArgVal = evaluate(*Arguments[I], State);
    if (!ArgVal)
      return ArgVal.takeError();
    MetaVariable *ParamVar = Def->getParameterVars()[I];
    std::optional<Instantiation::Binding> ArgBinding;
    switch (ArgVal->getKind()) {
    case ConstraintValue::Integer:
      ArgBinding = Instantiation::Binding(ArgVal->getInteger());
      break;
    case ConstraintValue::Boolean:
      ArgBinding = Instantiation::Binding(ArgVal->getBoolean());
      break;
    case ConstraintValue::Type:
      ArgBinding = Instantiation::Binding(ArgVal->getType());
      break;
    case ConstraintValue::Value:
      ArgBinding = Instantiation::Binding(ArgVal->getValue());
      break;
    case ConstraintValue::TypeArray:
      ArgBinding = Instantiation::Binding(ArgVal->getTypeArray());
      break;
    case ConstraintValue::ValueArray:
      ArgBinding = Instantiation::Binding(ArgVal->getValueArray());
      break;
    default:
      break;
    }
    if (!ArgBinding)
      return make_error<ConstraintEvaluationError>(
          Operator, "unsupported argument type for user-defined constraint");
    SubState.bind(*ParamVar, std::move(*ArgBinding));
  }
  ++CallDepth;
  Expected<ConstraintValue> Result = evaluate(*Def->getBody(), SubState);
  --CallDepth;
  return Result;
}

Expected<std::optional<unsigned>>
ConstraintInterpreter::evalOptionalBitWidth(const OperatorConstraint &Operator,
                                            unsigned ArgumentIndex,
                                            const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  if (Arguments.size() <= ArgumentIndex)
    return std::nullopt;
  Expected<APSInt> Width =
      requireInteger(evaluate(*Arguments[ArgumentIndex], State), Operator);
  if (!Width)
    return Width.takeError();
  if (Width->isNegative() || Width->isZero() ||
      Width->ugt(llvm::IntegerType::MAX_INT_BITS))
    return make_error<ConstraintEvaluationError>(
        Operator, "bitwidth must be between 1 and " +
                      Twine(llvm::IntegerType::MAX_INT_BITS));
  return static_cast<unsigned>(Width->getZExtValue());
}

Expected<ConstraintValue>
ConstraintInterpreter::evalLogical(const OperatorConstraint &Operator,
                                   const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  Expected<bool> Left =
      requireBoolean(evaluate(*Arguments[0], State), Operator);
  if (!Left)
    return Left.takeError();
  bool IsOr = Operator.getOperatorID() == Constraint::O_LogicalOr;
  if ((*Left && IsOr) || (!*Left && !IsOr))
    return ConstraintValue::getBoolean(*Left);
  Expected<bool> Right =
      requireBoolean(evaluate(*Arguments[1], State), Operator);
  if (!Right)
    return Right.takeError();
  return ConstraintValue::getBoolean(*Right);
}

Expected<ConstraintValue>
ConstraintInterpreter::evalUnary(const OperatorConstraint &Operator,
                                 const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  if (Operator.getOperatorID() == Constraint::O_Not) {
    Expected<bool> Operand =
        requireBoolean(evaluate(*Arguments[0], State), Operator);
    if (!Operand)
      return Operand.takeError();
    return ConstraintValue::getBoolean(!*Operand);
  }

  // O_Negate
  Expected<std::optional<unsigned>> BitWidth =
      evalOptionalBitWidth(Operator, 1, State);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<APSInt> Operand =
      requireInteger(evaluate(*Arguments[0], State), Operator);
  if (!Operand)
    return Operand.takeError();
  if (*BitWidth)
    *Operand = castToBitWidth(*Operand, **BitWidth);
  if (*BitWidth)
    return integerResult(-static_cast<const APInt &>(*Operand),
                         Operand->isUnsigned());
  APSInt Extended = extend(*Operand, Operand->getBitWidth() + 1, false);
  return integerResult(-static_cast<const APInt &>(Extended), false);
}

Expected<ConstraintValue>
ConstraintInterpreter::evalShift(const OperatorConstraint &Operator,
                                 const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  Expected<std::optional<unsigned>> BitWidth =
      evalOptionalBitWidth(Operator, 2, State);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<APSInt> Value =
      requireInteger(evaluate(*Arguments[0], State), Operator);
  if (!Value)
    return Value.takeError();
  if (*BitWidth)
    *Value = castToBitWidth(*Value, **BitWidth);
  Expected<APSInt> Amount =
      requireInteger(evaluate(*Arguments[1], State), Operator);
  if (!Amount)
    return Amount.takeError();
  if ((Amount->isSigned() && Amount->isNegative()) ||
      Amount->uge(Value->getBitWidth()))
    return make_error<ConstraintEvaluationError>(
        Operator, "shift amount is out of range");
  // Without an explicit width, shl keeps the bits shifted out of the
  // operand's width, like the other arithmetic operators.
  if (!*BitWidth && Operator.getOperatorID() == Constraint::O_Shl)
    *Value = extend(*Value, Value->getBitWidth() + Amount->getZExtValue(),
                    Value->isUnsigned());
  const APInt &Integer = *Value;
  APInt Result;
  switch (Operator.getOperatorID()) {
  case Constraint::O_Lshr:
    Result = Integer.lshr(Amount->getLimitedValue());
    break;
  case Constraint::O_Ashr:
    Result = Integer.ashr(Amount->getLimitedValue());
    break;
  case Constraint::O_Shl:
    Result = Integer.shl(Amount->getLimitedValue());
    break;
  default:
    llvm_unreachable("invalid shift operator");
  }
  return integerResult(std::move(Result),
                       Operator.getOperatorID() != Constraint::O_Ashr &&
                           Value->isUnsigned());
}

Expected<ConstraintValue>
ConstraintInterpreter::evalArithmetic(const OperatorConstraint &Operator,
                                      const Instantiation &State) {
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  Expected<ConstraintValue> LeftResult = evaluate(*Arguments[0], State);
  if (!LeftResult)
    return LeftResult.takeError();
  Expected<ConstraintValue> RightResult = evaluate(*Arguments[1], State);
  if (!RightResult)
    return RightResult.takeError();

  if (Operator.getOperatorID() == Constraint::O_Equal ||
      Operator.getOperatorID() == Constraint::O_NotEqual) {
    Expected<bool> Equal = evaluateEquality(std::move(*LeftResult),
                                            std::move(*RightResult), Operator);
    if (!Equal)
      return Equal.takeError();
    return ConstraintValue::getBoolean(
        Operator.getOperatorID() == Constraint::O_Equal ? *Equal : !*Equal);
  }

  Expected<APSInt> Left = requireInteger(std::move(LeftResult), Operator);
  if (!Left)
    return Left.takeError();
  Expected<APSInt> Right = requireInteger(std::move(RightResult), Operator);
  if (!Right)
    return Right.takeError();

  std::optional<unsigned> BitWidth;
  if (Expected<std::optional<unsigned>> Width =
          evalOptionalBitWidth(Operator, 2, State)) {
    BitWidth = *Width;
  } else {
    return Width.takeError();
  }

  bool Unsigned = Left->isUnsigned() && Right->isUnsigned();
  unsigned ExtraBits = 0;
  if (BitWidth) {
    *Left = castToBitWidth(*Left, *BitWidth);
    *Right = castToBitWidth(*Right, *BitWidth);
  } else {
    switch (Operator.getOperatorID()) {
    case Constraint::O_Multiply:
      ExtraBits = std::min(Left->getBitWidth(), Right->getBitWidth());
      break;
    case Constraint::O_Add:
    case Constraint::O_Subtract:
    // The most negative value divided by -1 needs one more bit.
    case Constraint::O_SDiv:
      ExtraBits = 1;
      break;
    default:
      break;
    }
  }
  auto [LHS, RHS] = widen(*Left, *Right, ExtraBits);
  const APInt &L = LHS;
  const APInt &R = RHS;

  switch (Operator.getOperatorID()) {
  case Constraint::O_Add:
    return integerResult(L + R, Unsigned);
  case Constraint::O_Subtract:
    return integerResult(L - R, false);
  case Constraint::O_Multiply:
    return integerResult(L * R, Unsigned);
  case Constraint::O_And:
    return integerResult(L & R, Unsigned);
  case Constraint::O_Or:
    return integerResult(L | R, Unsigned);
  case Constraint::O_Xor:
    return integerResult(L ^ R, Unsigned);
  case Constraint::O_SDiv:
  case Constraint::O_UDiv:
  case Constraint::O_SRem:
  case Constraint::O_URem:
    if (R.isZero())
      return make_error<ConstraintEvaluationError>(Operator,
                                                   "division by zero");
    if (Operator.getOperatorID() == Constraint::O_SDiv)
      return integerResult(L.sdiv(R), false);
    if (Operator.getOperatorID() == Constraint::O_UDiv)
      return integerResult(L.udiv(R), true);
    if (Operator.getOperatorID() == Constraint::O_SRem)
      return integerResult(L.srem(R), false);
    return integerResult(L.urem(R), true);
  case Constraint::O_SLT:
    return ConstraintValue::getBoolean(L.slt(R));
  case Constraint::O_ULT:
    return ConstraintValue::getBoolean(L.ult(R));
  case Constraint::O_SLE:
    return ConstraintValue::getBoolean(L.sle(R));
  case Constraint::O_ULE:
    return ConstraintValue::getBoolean(L.ule(R));
  case Constraint::O_SGT:
    return ConstraintValue::getBoolean(L.sgt(R));
  case Constraint::O_UGT:
    return ConstraintValue::getBoolean(L.ugt(R));
  case Constraint::O_SGE:
    return ConstraintValue::getBoolean(L.sge(R));
  case Constraint::O_UGE:
    return ConstraintValue::getBoolean(L.uge(R));
  default:
    llvm_unreachable("constraint operator handled before integer evaluation");
  }
}

} // namespace metaphir
} // namespace llvm
