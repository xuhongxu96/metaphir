#ifndef METAPHIR_MATCHING_CONSTRAINTEVALUATOR_H
#define METAPHIR_MATCHING_CONSTRAINTEVALUATOR_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Operators/Arithmetic.h"
#include "metaphir/Matching/Operators/CmpPredicates.h"
#include "metaphir/Matching/Operators/ValuePredicates.h"
#include "metaphir/Matching/Operators/ValueTracking.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/ErrorHandling.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// Evaluates constraint expressions in a domain: on the IR (ConcreteDomain),
/// or on the features of a function in a corpus index.
///
/// The evaluator walks the expression, evaluates operands, short-circuits
/// logical operators, and substitutes user-defined constraints. The domain
/// decides what values are, how variables are bound, and how each operator
/// descriptor (Op<ID>, see Operators/) is applied:
///
///   Value, State, Context          the domain's value, bindings and
///                                  value-tracking context types
///   fromConcrete(ConstraintValue)  a literal's value
///   variable(E, State)             a variable's value
///   array(E, Elements), arrayAccess(E, Array, Index)
///   apply<Op>(Operands, E)         an operator on evaluated operands
///   explicitContext(Value, E), defaultContext(E, State),
///   applyValueTrack<Op>(Operands, Context, E)
///                                  a value-tracking operator
///   decides(ID, Left, E)           whether Left alone decides a logical
///                                  operator, and if so its result
///   combine(ID, Left, Right, E)    the logical operator on both sides,
///                                  where Right may be an error
///   bindParameter(State, Parameter, Value, E)
template <class Domain> class ConstraintEvaluator {
public:
  using Value = typename Domain::Value;
  using State = typename Domain::State;

  /// Definitions holds the 'constraint' definitions calls refer to; without
  /// it, only built-in operators can be evaluated.
  ConstraintEvaluator(Domain &D, const MIRContext *Definitions)
      : D(D), Definitions(Definitions) {}

  Expected<Value> evaluate(const Constraint &Expression, const State &S) {
    switch (Expression.getConstraintID()) {
    case Constraint::Integer: {
      int64_t Integer = cast<IntegerConstraint>(Expression).getValue();
      return D.fromConcrete(ConstraintValue::getInteger(APSInt(
          APInt(64, static_cast<uint64_t>(Integer), true), Integer >= 0)));
    }
    case Constraint::Boolean:
      return D.fromConcrete(ConstraintValue::getBoolean(
          cast<BooleanConstraint>(Expression).getValue()));
    case Constraint::String:
      return D.fromConcrete(ConstraintValue::getString(
          cast<StringConstraint>(Expression).getValue()));
    case Constraint::Variable:
      return D.variable(cast<VariableConstraint>(Expression), S);
    case Constraint::Array: {
      const auto &Array = cast<ArrayConstraint>(Expression);
      Expected<SmallVector<Value, 2>> Elements =
          evaluateAll(Array.getElements(), S);
      if (!Elements)
        return Elements.takeError();
      return D.array(Array, std::move(*Elements));
    }
    case Constraint::ArrayAccess: {
      const auto &Access = cast<ArrayAccessConstraint>(Expression);
      Expected<Value> Array = evaluate(*Access.getArray(), S);
      if (!Array)
        return Array.takeError();
      Expected<Value> Index = evaluate(*Access.getIndex(), S);
      if (!Index)
        return Index.takeError();
      return D.arrayAccess(Access, std::move(*Array), std::move(*Index));
    }
    case Constraint::Unary:
    case Constraint::Binary:
    case Constraint::Call:
      return evalOperator(cast<OperatorConstraint>(Expression), S);
    }
    llvm_unreachable("unknown constraint ID");
  }

private:
  Expected<SmallVector<Value, 2>> evaluateAll(ArrayRef<Constraint *> Arguments,
                                              const State &S) {
    SmallVector<Value, 2> Values;
    Values.reserve(Arguments.size());
    for (const Constraint *Argument : Arguments) {
      Expected<Value> Result = evaluate(*Argument, S);
      if (!Result)
        return Result.takeError();
      Values.push_back(std::move(*Result));
    }
    return Values;
  }

  Expected<Value> evalOperator(const OperatorConstraint &Operator,
                               const State &S) {
#ifndef NDEBUG
    if (std::optional<Constraint::OperatorSchema> Schema =
            Constraint::getOperatorSchema(Operator.getOperatorID()))
      assert(Operator.getArguments().size() >= Schema->MinArity &&
             Operator.getArguments().size() <= Schema->MaxArity &&
             "built-in constraint operator has invalid arity");
#endif
    switch (Operator.getOperatorID()) {
    case Constraint::UnknownOperator:
      return evalUserDefinedCall(Operator, S);
#define MIR_CONSTRAINT_OPERATOR_ID(ID, Name, Kind)                             \
  case Constraint::O_##ID:                                                     \
    return evalBuiltin<Op##ID>(Operator, S);
#define MIR_CONSTRAINT_VALUE_TRACK_OPERATOR(ID, Name, Kind, Result, BaseArity) \
  case Constraint::O_##ID:                                                     \
    return evalValueTrack<Op##ID>(Operator, BaseArity, S);
#include "metaphir/IR/ConstraintOperators.def"
    default:
      break;
    }
    llvm_unreachable("constraint operator without a descriptor");
  }

  template <class Op>
  Expected<Value> evalBuiltin(const OperatorConstraint &Operator,
                              const State &S) {
    if constexpr (Op::ShortCircuits) {
      return evalLogical(Operator, S);
    } else {
      Expected<SmallVector<Value, 2>> Operands =
          evaluateAll(Operator.getArguments(), S);
      if (!Operands)
        return Operands.takeError();
      return D.template apply<Op>(*Operands, Operator);
    }
  }

  /// A value-tracking operator: its first BaseArity arguments are operands,
  /// and an optional last one is the context instruction; without it, the
  /// constraint's context instruction is used.
  template <class Op>
  Expected<Value> evalValueTrack(const OperatorConstraint &Operator,
                                 unsigned BaseArity, const State &S) {
    ArrayRef<Constraint *> Arguments = Operator.getArguments();
    Expected<SmallVector<Value, 2>> Operands =
        evaluateAll(Arguments.take_front(BaseArity), S);
    if (!Operands)
      return Operands.takeError();
    if (Arguments.size() > BaseArity) {
      Expected<Value> Explicit = evaluate(*Arguments[BaseArity], S);
      if (!Explicit)
        return Explicit.takeError();
      auto Context = D.explicitContext(std::move(*Explicit), Operator);
      if (!Context)
        return Context.takeError();
      return D.template applyValueTrack<Op>(*Operands, *Context, Operator);
    }
    auto Context = D.defaultContext(Operator, S);
    if (!Context)
      return Context.takeError();
    return D.template applyValueTrack<Op>(*Operands, *Context, Operator);
  }

  /// '&&' and '||': the right side is evaluated only if the left does not
  /// decide the result.
  Expected<Value> evalLogical(const OperatorConstraint &Operator,
                              const State &S) {
    ArrayRef<Constraint *> Arguments = Operator.getArguments();
    Constraint::OperatorID ID = Operator.getOperatorID();
    Expected<Value> Left = evaluate(*Arguments[0], S);
    if (!Left)
      return Left.takeError();
    Expected<std::optional<Value>> Decided = D.decides(ID, *Left, Operator);
    if (!Decided)
      return Decided.takeError();
    if (*Decided)
      return std::move(**Decided);
    // The domain decides what an error on the right means: on the IR, the
    // error; with the left unknown, perhaps just a rejection.
    return D.combine(ID, std::move(*Left), evaluate(*Arguments[1], S),
                     Operator);
  }

  /// A call to a 'constraint' definition: its body, with the parameters
  /// bound to the evaluated arguments.
  Expected<Value> evalUserDefinedCall(const OperatorConstraint &Operator,
                                      const State &S) {
    ArrayRef<Constraint *> Arguments = Operator.getArguments();
    const ConstraintDef *Def =
        Definitions ? Definitions->getConstraintDef(Operator.getOperator())
                    : nullptr;
    if (!Def)
      return make_error<detail::ConstraintEvaluationError>(
          Operator, Twine("unknown operator '") + Operator.getOperator() + "'");
    if (Arguments.size() != Def->getParameters().size())
      return make_error<detail::ConstraintEvaluationError>(
          Operator, "wrong number of arguments to user-defined constraint '" +
                        Operator.getOperator() + "'");
    // Definitions can only call earlier ones, so calls cannot recurse;
    // the limit guards against contexts built by hand.
    if (CallDepth == MaxCallDepth)
      return make_error<detail::ConstraintEvaluationError>(
          Operator, "user-defined constraints are nested too deeply");
    State SubState = S;
    for (size_t I = 0; I < Arguments.size(); ++I) {
      Expected<Value> Argument = evaluate(*Arguments[I], S);
      if (!Argument)
        return Argument.takeError();
      if (Error E = D.bindParameter(SubState, *Def->getParameterVars()[I],
                                    std::move(*Argument), Operator))
        return E;
    }
    ++CallDepth;
    Expected<Value> Result = evaluate(*Def->getBody(), SubState);
    --CallDepth;
    return Result;
  }

  Domain &D;
  const MIRContext *Definitions;
  /// Nesting of user-defined constraint calls being evaluated.
  unsigned CallDepth = 0;
  static constexpr unsigned MaxCallDepth = 256;
};

} // namespace metaphir
} // namespace llvm

#endif
