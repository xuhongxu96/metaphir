#include "metaphir/Exec/ConcreteEvaluator.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Exec/ExprEvaluator.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

using namespace detail;
using mlir::Operation;

std::string detail::describeVariable(mlir::Value V, StringRef Msg) {
  std::string Str;
  raw_string_ostream OS(Str);
  if (Operation *Def = V.getDefiningOp())
    if (auto Name =
            Def->getAttrOfType<mlir::StringAttr>(mpir::ResultNameAttrName)) {
      OS << "variable '%" << Name.getValue() << "' " << Msg;
      return Str;
    }
  OS << "meta variable '?" << getMetaVariableName(V) << "' " << Msg;
  return Str;
}

/// What a variable bound to Binding is when read as Read reads it: as
/// detail::bindingValue reads it.
Expected<ConstraintValue> readBinding(mlir::Value ReadValue,
                                      const Binding &Binding) {
  auto Read = ReadValue.getDefiningOp<mpir_expr::ReadOp>();
  mlir::Value Expression = Read.getResult();
  auto Incompatible = [&] {
    return make_error<ConstraintEvaluationError>(
        Expression,
        describeVariable(Read.getValue(), "has an incompatible binding"));
  };
  switch (mpir::sortOf(Read)) {
  case Sort::Integer:
    if (const auto *Integer = std::get_if<APSInt>(&Binding.Data))
      return ConstraintValue::getInteger(*Integer);
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getInteger(
            APSInt(CI->getValue(), /*isUnsigned=*/false));
    break;
  case Sort::Boolean:
    if (const auto *Boolean = std::get_if<bool>(&Binding.Data))
      return ConstraintValue::getBoolean(*Boolean);
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      if (const auto *CI = dyn_cast<ConstantInt>(*Value))
        return ConstraintValue::getBoolean(CI->isOne());
    break;
  case Sort::String:
    if (const auto *Predicate = std::get_if<CmpInst::Predicate>(&Binding.Data))
      return ConstraintValue::getString(CmpInst::getPredicateName(*Predicate));
    if (const auto *ID = std::get_if<Intrinsic::ID>(&Binding.Data))
      return ConstraintValue::getString(Intrinsic::getBaseName(*ID));
    break;
  case Sort::Type:
    if (const auto *Type = std::get_if<const llvm::Type *>(&Binding.Data))
      return ConstraintValue::getType(*Type);
    break;
  case Sort::Value:
    if (const auto *Value = std::get_if<const llvm::Value *>(&Binding.Data))
      return ConstraintValue::getValue(*Value);
    break;
  case Sort::TypeArray:
    if (const auto *Types = std::get_if<Binding::TypeArray>(&Binding.Data))
      return ConstraintValue::getTypeArray(*Types);
    break;
  case Sort::ValueArray:
    if (const auto *Values = std::get_if<Binding::ValueArray>(&Binding.Data))
      return ConstraintValue::getValueArray(*Values);
    break;
  case Sort::Unknown:
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
          else if constexpr (std::is_same_v<T, Binding::TypeArray>)
            return ConstraintValue::getTypeArray(Val);
          else if constexpr (std::is_same_v<T, Binding::ValueArray>)
            return ConstraintValue::getValueArray(Val);
          else
            return Incompatible();
        },
        Binding.Data);
  default:
    llvm_unreachable("variable constraint has no runtime sort");
  }
  return Incompatible();
}

namespace {
/// The matcher's values: what a match binds, read from its slots, and the
/// operators' concrete() faces on the IR.
class ConcreteDomain {
public:
  using Value = ConstraintValue;
  using Argument = Binding;
  using GetModuleUsesFn =
      function_ref<std::optional<ModuleUses>(const llvm::Value &)>;

  ConcreteDomain(ConcreteEvaluator::SlotLookup Slots,
                 ValueTrackContext &Analysis, GetModuleUsesFn GetModuleUses)
      : Slots(Slots), Analysis(Analysis), GetModuleUses(GetModuleUses) {}

  Value lift(ConstraintValue V) const { return V; }
  const ConstraintValue *known(const Value &V) const { return &V; }
  Value unknown() const {
    llvm_unreachable("the matcher knows every value it evaluates");
  }

  Expected<Value> read(mpir_expr::ReadOp Read) {
    if (const Binding *Bound = lookup(Read.getValue()))
      return readBinding(Read.getResult(), *Bound);
    return make_error<ConstraintEvaluationError>(
        Read.getResult(),
        describeVariable(Read.getValue(), "is not instantiated"));
  }

  Expected<Argument> pass(const Value &V, mlir::Value Apply) {
    switch (V.getKind()) {
    case ConstraintValue::Integer:
      return Binding(V.getInteger());
    case ConstraintValue::Boolean:
      return Binding(V.getBoolean());
    case ConstraintValue::Type:
      return Binding(V.getType());
    case ConstraintValue::Value:
      return Binding(V.getValue());
    case ConstraintValue::TypeArray:
      return Binding(V.getTypeArray());
    case ConstraintValue::ValueArray:
      return Binding(V.getValueArray());
    default:
      return make_error<ConstraintEvaluationError>(
          Apply, "unsupported argument type for user-defined constraint");
    }
  }

  Expected<Value> readArgument(mpir_expr::ReadOp Read, const Argument &A) {
    return readBinding(Read.getResult(), A);
  }

  template <class Op>
  Expected<Value> apply(ArrayRef<Value> Operands, mpir_expr::CallOp Call) {
    return Op::concrete(
        ConcreteCall{Operands, Call.getResult(), GetModuleUses});
  }

  template <class Op>
  Expected<Value>
  applyValueTracking(ArrayRef<Value> Operands, mpir_expr::CallOp Call,
                     const Value *Explicit, mlir::Value Anchor) {
    mlir::Value Expression = Call.getResult();
    const llvm::Instruction *Context = nullptr;
    if (Explicit) {
      Expected<const llvm::Value *> V = requireValue(*Explicit, Expression);
      if (!V)
        return V.takeError();
      Context = dyn_cast<llvm::Instruction>(*V);
      if (!Context)
        return make_error<ConstraintEvaluationError>(
            Expression, "expected an instruction context operand");
    } else {
      if (Anchor)
        if (const Binding *Bound = lookup(Anchor))
          if (const auto *V = std::get_if<const llvm::Value *>(&Bound->Data))
            Context = dyn_cast<llvm::Instruction>(*V);
      if (!Context)
        return make_error<ConstraintEvaluationError>(
            Expression,
            "no context instruction for value-tracking operator "
            "(place the constraint after an instruction or pass ?ctx "
            "explicitly)");
    }
    SimplifyQuery Query = Analysis.getQuery(Context);
    return Op::concrete(
        ConcreteCall{Operands, Expression, GetModuleUses, &Query});
  }

private:
  /// What the slot V is bound to; null if V is no slot or is unbound.
  const Binding *lookup(mlir::Value V) {
    if (auto Slot = V.getDefiningOp<mpir_plan::SlotOp>())
      return Slots(Slot.getSlot());
    return nullptr;
  }

  ConcreteEvaluator::SlotLookup Slots;
  ValueTrackContext &Analysis;
  GetModuleUsesFn GetModuleUses;
};
} // namespace

ConcreteEvaluator::ConcreteEvaluator()
    : Analysis(std::make_unique<ValueTrackContext>()) {}
ConcreteEvaluator::~ConcreteEvaluator() = default;

void ConcreteEvaluator::resetAnalyses() { Analysis->reset(); }

std::optional<ModuleUses>
ConcreteEvaluator::getModuleUses(const llvm::Value &V) {
  if (!Uses || !isUsedAcrossFunctions(V))
    return std::nullopt;
  return Uses->getModuleUses(V);
}

Expected<ConstraintValue> ConcreteEvaluator::evaluate(mlir::Value E,
                                                      SlotLookup Slots) {
  auto GetModuleUses = [this](const llvm::Value &V) {
    return getModuleUses(V);
  };
  ConcreteDomain Domain(Slots, *Analysis, GetModuleUses);
  return ExprEvaluator<ConcreteDomain>(Domain).evaluate(E);
}

} // namespace metaphir
} // namespace llvm
