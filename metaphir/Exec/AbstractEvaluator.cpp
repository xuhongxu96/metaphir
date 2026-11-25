#include "metaphir/Exec/AbstractEvaluator.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Exec/ConcreteEvaluator.h"
#include "metaphir/Exec/ExprEvaluator.h"

namespace llvm {
namespace metaphir {

using namespace detail;

namespace {
/// The index's values: what a function's features say of a pattern value.
///
/// A leaf is a type the typing binds, the sites of an IR value, or unknown.
/// An operator on known operands computes its result as on the IR; on
/// others, it applies its abstract() face, or is unknown. A known boolean B
/// stands for "B, or an evaluation error": either rejects a match when B is
/// false.
class AbstractDomain {
public:
  using Value = AbstractValue;
  using Argument = AbstractValue;

  AbstractDomain(const FunctionFeatures &Features, ArrayRef<Binding> Types)
      : Features(Features), Types(Types) {}

  Value lift(ConstraintValue V) const {
    return AbstractValue::concrete(std::move(V));
  }
  const ConstraintValue *known(const Value &V) const {
    return V.isConcrete() ? &V.getConcrete() : nullptr;
  }
  Value unknown() const { return AbstractValue::unknown(); }

  Expected<Value> read(mpir_expr::ReadOp Read) {
    mlir::Value V = Read.getValue();
    if (auto Sites = V.getDefiningOp<mpir_index::SitesOp>()) {
      ::llvm::metaphir::Sites Of;
      for (mlir::Attribute A : Sites.getSites())
        Of.push_back(mpir_index::decodeSite(A));
      return AbstractValue::sites(std::move(Of));
    }
    if (auto Var = V.getDefiningOp<mpir_index::TypeVarOp>()) {
      unsigned Slot = Var.getSlot();
      if (Slot < Types.size() &&
          !std::holds_alternative<std::monostate>(Types[Slot].Data)) {
        Expected<ConstraintValue> Type = readBinding(Read, Types[Slot]);
        if (!Type)
          return Type.takeError();
        return lift(std::move(*Type));
      }
    }
    // Whatever the IR binds it to is not known here.
    return unknown();
  }

  Expected<Argument> pass(Value V, mlir::Value) { return V; }
  Expected<Value> readArgument(mpir_expr::ReadOp, const Argument &A) {
    return A;
  }

  template <class Op>
  Expected<Value> apply(ArrayRef<Value> Operands, mpir_expr::CallOp Call) {
    mlir::Value Expression = Call.getResult();
    if (std::optional<SmallVector<ConstraintValue, 2>> Known =
            allKnown(Operands)) {
      // No operand is an IR value here, so how one is used is not asked.
      Expected<ConstraintValue> Result = Op::concrete(
          ConcreteCall{*Known, Expression, [](const llvm::Value &) {
                         return std::optional<ModuleUses>();
                       }});
      if (!Result)
        return Result.takeError();
      return lift(std::move(*Result));
    }
    if constexpr (detail::HasAbstract<Op>::value)
      return Op::abstract(AbstractCall{Operands, Expression, Features});
    return unknown();
  }

  /// Apply a value-tracking operator at the node its anchor is; an explicit
  /// context is no node the index knows.
  template <class Op>
  Expected<Value>
  applyValueTracking(ArrayRef<Value> Operands, mpir_expr::CallOp Call,
                     const Value *Explicit, mlir::Value Anchor) {
    if constexpr (detail::HasAbstract<Op>::value) {
      if (!Explicit && Anchor)
        if (auto Node = Anchor.getDefiningOp<mpir_index::NodeOp>())
          return Op::abstract(AbstractCall{Operands, Call.getResult(), Features,
                                           int64_t(Node.getNode())});
    }
    return unknown();
  }

private:
  static std::optional<SmallVector<ConstraintValue, 2>>
  allKnown(ArrayRef<Value> Operands) {
    SmallVector<ConstraintValue, 2> Known;
    for (const Value &Operand : Operands) {
      if (!Operand.isConcrete())
        return std::nullopt;
      Known.push_back(Operand.getConcrete());
    }
    return Known;
  }

  const FunctionFeatures &Features;
  ArrayRef<Binding> Types;
};
} // namespace

Expected<AbstractValue> AbstractEvaluator::evaluate(mlir::Value E) const {
  AbstractDomain Domain(Features, Types);
  return ExprEvaluator<AbstractDomain>(Domain).evaluate(E);
}

} // namespace metaphir
} // namespace llvm
