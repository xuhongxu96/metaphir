//===- ExprEvaluator.h - Evaluate mpir_expr in a value domain ---*- C++ -*-===//
//
// The one evaluator of constraint expressions, parameterized by a value
// domain: the matcher's concrete values on the IR (ConcreteEvaluator), and the
// index's abstract values on a function's features (IndexQuery). Both
// evaluate an expression's structure here alike (literals, arrays and their
// indexing, '&&' and '||', calls of constraint definitions, and errors), so
// the index's evaluation is sound if the domain's own operations are: how a
// leaf reads, and how an operator applies.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_EXPREVALUATOR_H
#define METAPHIR_EXEC_EXPREVALUATOR_H

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Exec/ConstraintDispatch.inc"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "mlir/IR/SymbolTable.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Error.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// Evaluates mpir_expr in Domain, which provides:
///
///   using Value;     what an expression evaluates to
///   using Argument;  what a constraint definition's parameter is bound to
///   Value lift(ConstraintValue);   a value known exactly
///   const ConstraintValue *known(const Value &);  null if not known
///   Value unknown();
///   Expected<Value> read(mpir_expr::ReadOp);  a read outside definitions
///   Expected<Argument> pass(Value, mlir::Value Apply);
///   Expected<Value> readArgument(mpir_expr::ReadOp, const Argument &);
///   template <class Op>
///   Expected<Value> apply(ArrayRef<Value> Operands, mpir_expr::CallOp);
///   template <class Op>
///   Expected<Value> applyValueTracking(ArrayRef<Value> Operands,
///                                      mpir_expr::CallOp,
///                                      const Value *Context,
///                                      mlir::Value Anchor);
///
/// An error is one the evaluation certainly has, in either domain.
template <class Domain> class ExprEvaluator {
public:
  using Value = typename Domain::Value;

  /// How deeply calls of constraint definitions may nest.
  static constexpr unsigned MaxCallDepth = 256;

  explicit ExprEvaluator(Domain &D) : D(D) {}

  Expected<Value> evaluate(mlir::Value E) {
    Frame F;
    return eval(E, F);
  }

private:
  /// Resolve the reads of the body being evaluated: the domain's leaves in
  /// the expression evaluate starts with, or the arguments one call passes a
  /// constraint definition, which sees nothing else.
  struct Frame {
    /// The argument each of a definition's parameters (its body's block
    /// arguments) is bound to.
    DenseMap<mlir::Value, typename Domain::Argument> Arguments;
    /// How many definition calls the frame is nested in.
    unsigned Depth = 0;
    /// The instruction the call of the definition is anchored at, if any.
    mlir::Value Anchor;
  };

  /// The instruction a call in F with anchor Own is anchored at: its own in
  /// the expression evaluate starts with, and in a definition, which is
  /// isolated from the pattern, its caller's.
  static mlir::Value anchorOf(mlir::Value Own, const Frame &F) {
    if (F.Depth == 0)
      return Own;
    assert(!Own && "a call in a constraint definition has an anchor");
    return F.Anchor;
  }

  Domain &D;

  Expected<SmallVector<Value, 2>> evalAll(mlir::ValueRange Values, Frame &F) {
    SmallVector<Value, 2> Result;
    for (mlir::Value V : Values) {
      Expected<Value> Each = eval(V, F);
      if (!Each)
        return Each.takeError();
      Result.push_back(std::move(*Each));
    }
    return Result;
  }

  Expected<Value> read(mpir_expr::ReadOp Read, Frame &F) {
    mlir::Value V = Read.getValue();
    auto It = F.Arguments.find(V);
    if (It != F.Arguments.end())
      return D.readArgument(Read, It->second);
    // A definition is outside the plan and the query: it reads only its
    // parameters.
    if (F.Depth != 0)
      return make_error<detail::ConstraintEvaluationError>(
          Read.getResult(), describeVariable(V, "is not instantiated"));
    return D.read(Read);
  }

  /// Build the array literal Array of the values of its elements.
  Expected<Value> buildArray(mpir_expr::ArrayOp Array,
                             ArrayRef<Value> Elements) {
    SmallVector<ConstraintValue, 2> Known;
    for (const Value &Element : Elements) {
      const ConstraintValue *Each = D.known(Element);
      if (!Each)
        return D.unknown();
      Known.push_back(*Each);
    }
    switch (mpir::sortOf(Array)) {
    case Sort::TypeArray: {
      Binding::TypeArray Types;
      for (const ConstraintValue &Element : Known)
        Types.push_back(Element.getType());
      return D.lift(ConstraintValue::getTypeArray(std::move(Types)));
    }
    case Sort::ValueArray: {
      Binding::ValueArray Values;
      for (const ConstraintValue &Element : Known)
        Values.push_back(Element.getValue());
      return D.lift(ConstraintValue::getValueArray(std::move(Values)));
    }
    default: {
      ConstraintValue::StringArrayStorage Strings;
      for (const ConstraintValue &Element : Known) {
        Expected<std::string> String =
            detail::requireString(Element, Array.getResult());
        if (!String)
          return String.takeError();
        Strings.push_back(std::move(*String));
      }
      return D.lift(ConstraintValue::getStringArray(std::move(Strings)));
    }
    }
  }

  /// Read Position as an index into an array of Size elements.
  static Expected<uint64_t> requireIndex(const ConstraintValue &Position,
                                         size_t Size, mlir::Value Expression) {
    Expected<APSInt> Index = detail::requireInteger(Position, Expression);
    if (!Index)
      return Index.takeError();
    if (Index->isSigned() && Index->isNegative())
      return make_error<detail::ConstraintEvaluationError>(
          Expression, "array index is negative");
    uint64_t At = Index->getLimitedValue();
    if (At >= Size)
      return make_error<detail::ConstraintEvaluationError>(
          Expression, "array index is out of bounds");
    return At;
  }

  /// Evaluate an index into an array literal whose elements the domain does
  /// not all know: the element it selects is as known as it is. Building
  /// the array can still fail where an element must become a string, so the
  /// index is unknown if an unknown element might.
  Expected<Value> evalLiteralIndex(mpir_expr::ArrayOp Array,
                                   mpir_expr::IndexOp Access,
                                   ArrayRef<Value> Elements, Frame &F) {
    mlir::Value Expression = Access.getResult();
    bool IsString = mpir::sortOf(Array) != Sort::TypeArray &&
                    mpir::sortOf(Array) != Sort::ValueArray;
    bool MayFail = false;
    if (IsString)
      for (auto [Element, Operand] : zip(Elements, Array.getElements())) {
        if (const ConstraintValue *Known = D.known(Element)) {
          Expected<std::string> String =
              detail::requireString(*Known, Array.getResult());
          if (!String)
            return String.takeError();
        } else if (mpir::sortOf(Operand) != Sort::String) {
          MayFail = true;
        }
      }
    Expected<Value> IndexValue = eval(Access.getIndex(), F);
    if (!IndexValue)
      return IndexValue.takeError();
    const ConstraintValue *Position = D.known(*IndexValue);
    if (!Position || MayFail)
      return D.unknown();
    Expected<uint64_t> At =
        requireIndex(*Position, Elements.size(), Expression);
    if (!At)
      return At.takeError();
    const Value &Selected = Elements[*At];
    if (!IsString)
      return Selected;
    const ConstraintValue *Known = D.known(Selected);
    if (!Known)
      return D.unknown();
    Expected<std::string> String =
        detail::requireString(*Known, Array.getResult());
    if (!String)
      return String.takeError();
    return D.lift(ConstraintValue::getString(std::move(*String)));
  }

  Expected<Value> evalIndex(mpir_expr::IndexOp Access, Frame &F) {
    mlir::Value Expression = Access.getResult();
    std::optional<Value> ArrayValue;
    if (auto Literal = Access.getArray().getDefiningOp<mpir_expr::ArrayOp>()) {
      Expected<SmallVector<Value, 2>> Elements =
          evalAll(Literal.getElements(), F);
      if (!Elements)
        return Elements.takeError();
      if (!all_of(*Elements, [&](const Value &V) { return D.known(V); }))
        return evalLiteralIndex(Literal, Access, *Elements, F);
      Expected<Value> Built = buildArray(Literal, *Elements);
      if (!Built)
        return Built.takeError();
      ArrayValue = std::move(*Built);
    } else {
      Expected<Value> Evaluated = eval(Access.getArray(), F);
      if (!Evaluated)
        return Evaluated.takeError();
      ArrayValue = std::move(*Evaluated);
    }
    Expected<Value> IndexValue = eval(Access.getIndex(), F);
    if (!IndexValue)
      return IndexValue.takeError();
    const ConstraintValue *Array = D.known(*ArrayValue);
    const ConstraintValue *Position = D.known(*IndexValue);
    if (!Array || !Position)
      return D.unknown();
    switch (Array->getKind()) {
    case ConstraintValue::TypeArray: {
      Expected<uint64_t> At =
          requireIndex(*Position, Array->getTypeArray().size(), Expression);
      if (!At)
        return At.takeError();
      return D.lift(ConstraintValue::getType(Array->getTypeArray()[*At]));
    }
    case ConstraintValue::ValueArray: {
      Expected<uint64_t> At =
          requireIndex(*Position, Array->getValueArray().size(), Expression);
      if (!At)
        return At.takeError();
      return D.lift(ConstraintValue::getValue(Array->getValueArray()[*At]));
    }
    case ConstraintValue::StringArray: {
      Expected<uint64_t> At =
          requireIndex(*Position, Array->getStringArray().size(), Expression);
      if (!At)
        return At.takeError();
      return D.lift(ConstraintValue::getString(Array->getStringArray()[*At]));
    }
    default:
      llvm_unreachable("array access constraint has a non-array operand");
    }
  }

  /// Evaluate '&&' or '||' in Kleene's logic: the right side only if the
  /// left does not decide, and a side the domain does not know decides
  /// nothing. An error propagates where the evaluation certainly reaches it.
  Expected<Value> evalLogical(mpir_expr::CallOp Call, bool IsOr, Frame &F) {
    mlir::Value Expression = Call.getResult();
    mlir::OperandRange Arguments = Call.getArgs();
    Expected<Value> Left = eval(Arguments[0], F);
    if (!Left)
      return Left.takeError();
    if (const ConstraintValue *Known = D.known(*Left)) {
      Expected<bool> LeftValue = detail::requireBoolean(*Known, Expression);
      if (!LeftValue)
        return LeftValue.takeError();
      if (*LeftValue == IsOr)
        return D.lift(ConstraintValue::getBoolean(*LeftValue));
      Expected<Value> Right = eval(Arguments[1], F);
      if (!Right)
        return Right.takeError();
      const ConstraintValue *RightKnown = D.known(*Right);
      if (!RightKnown)
        return D.unknown();
      Expected<bool> RightValue =
          detail::requireBoolean(*RightKnown, Expression);
      if (!RightValue)
        return RightValue.takeError();
      return D.lift(ConstraintValue::getBoolean(*RightValue));
    }
    // The left side may decide, so the evaluation may not reach the right
    // one: only a right side that decides decides.
    Expected<Value> Right = eval(Arguments[1], F);
    if (!Right) {
      consumeError(Right.takeError());
      return D.unknown();
    }
    if (const ConstraintValue *RightKnown = D.known(*Right)) {
      Expected<bool> RightValue =
          detail::requireBoolean(*RightKnown, Expression);
      if (!RightValue) {
        consumeError(RightValue.takeError());
        return D.unknown();
      }
      if (*RightValue == IsOr)
        return D.lift(ConstraintValue::getBoolean(*RightValue));
    }
    return D.unknown();
  }

  Expected<Value> evalCall(mpir_expr::CallOp Call, Frame &F) {
    mlir::OperandRange Arguments = Call.getArgs();
    auto Builtin = [&](auto Descriptor) -> Expected<Value> {
      using Op = decltype(Descriptor);
      if constexpr (Op::ShortCircuits) {
        return evalLogical(Call,
                           Call.getOperatorID() == constraint::O_LogicalOr, F);
      } else {
        Expected<SmallVector<Value, 2>> Operands = evalAll(Arguments, F);
        if (!Operands)
          return Operands.takeError();
        return D.template apply<Op>(*Operands, Call);
      }
    };
    // A value-tracking operator: its first BaseArity arguments are operands,
    // and an optional last one is the context instruction; without it, the
    // instruction the constraint is anchored at.
    auto ValueTrack = [&](auto Descriptor,
                          unsigned BaseArity) -> Expected<Value> {
      using Op = decltype(Descriptor);
      Expected<SmallVector<Value, 2>> Operands =
          evalAll(Arguments.take_front(BaseArity), F);
      if (!Operands)
        return Operands.takeError();
      std::optional<Value> Context;
      if (Arguments.size() > BaseArity) {
        Expected<Value> Explicit = eval(Arguments[BaseArity], F);
        if (!Explicit)
          return Explicit.takeError();
        Context = std::move(*Explicit);
      }
      return D.template applyValueTracking<Op>(*Operands, Call,
                                               Context ? &*Context : nullptr,
                                               anchorOf(Call.getAnchor(), F));
    };
    return visitOperator<Expected<Value>>(
        Call.getOperatorID(), Builtin, ValueTrack, [&]() -> Expected<Value> {
          // Every operator of the table is dispatched.
          // LCOV_EXCL_START
          return make_error<detail::ConstraintEvaluationError>(
              Call.getResult(), "constraint operator without a descriptor");
          // LCOV_EXCL_STOP
        });
  }

  Expected<Value> evalApply(mpir_expr::ApplyOp Apply, Frame &F) {
    mlir::Value Expression = Apply.getResult();
    auto Def =
        mlir::SymbolTable::lookupNearestSymbolFrom<mpir::ConstraintDefOp>(
            Apply, Apply.getCalleeAttr());
    if (!Def)
      return make_error<detail::ConstraintEvaluationError>(
          Expression, Twine("unknown operator '") + Apply.getCallee() + "'");
    if (F.Depth == MaxCallDepth)
      return make_error<detail::ConstraintEvaluationError>(
          Expression, "user-defined constraints are nested too deeply");
    mlir::Block &Body = Def.getBody().front();
    Frame Callee;
    Callee.Depth = F.Depth + 1;
    Callee.Anchor = anchorOf(Apply.getAnchor(), F);
    for (auto [Index, Arg] : enumerate(Apply.getArgs())) {
      Expected<Value> Each = eval(Arg, F);
      if (!Each)
        return Each.takeError();
      Expected<typename Domain::Argument> Argument =
          D.pass(std::move(*Each), Expression);
      if (!Argument)
        return Argument.takeError();
      Callee.Arguments.insert_or_assign(Body.getArgument(Index),
                                        std::move(*Argument));
    }
    mlir::Value Result = (*Body.getOps<mpir::YieldOp>().begin()).getValue();
    return eval(Result, Callee);
  }

  Expected<Value> eval(mlir::Value E, Frame &F) {
    mlir::Operation *Def = E.getDefiningOp();

    if (auto Int = dyn_cast_or_null<mpir_expr::IntOp>(Def))
      return D.lift(ConstraintValue::getInteger(Int.getAPSInt()));
    if (auto Bool = dyn_cast_or_null<mpir_expr::BoolOp>(Def))
      return D.lift(ConstraintValue::getBoolean(Bool.getValue()));
    if (auto Str = dyn_cast_or_null<mpir_expr::StrOp>(Def))
      return D.lift(ConstraintValue::getString(Str.getValue()));

    if (auto Read = dyn_cast_or_null<mpir_expr::ReadOp>(Def))
      return read(Read, F);

    if (auto Array = dyn_cast_or_null<mpir_expr::ArrayOp>(Def)) {
      Expected<SmallVector<Value, 2>> Elements =
          evalAll(Array.getElements(), F);
      if (!Elements)
        return Elements.takeError();
      return buildArray(Array, *Elements);
    }

    if (auto Access = dyn_cast_or_null<mpir_expr::IndexOp>(Def))
      return evalIndex(Access, F);

    if (auto Call = dyn_cast_or_null<mpir_expr::CallOp>(Def))
      return evalCall(Call, F);

    if (auto Apply = dyn_cast_or_null<mpir_expr::ApplyOp>(Def))
      return evalApply(Apply, F);

    return make_error<detail::ConstraintEvaluationError>(
        E, "not a constraint expression");
  }
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_EXPREVALUATOR_H
