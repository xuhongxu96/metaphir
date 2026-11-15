#include "metaphir/Exec/ExprEvaluator.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SurfacePrinter.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/Operators/Arithmetic.h"
#include "metaphir/Matching/Operators/CmpPredicates.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "metaphir/Matching/Operators/ValuePredicates.h"
#include "metaphir/Matching/Operators/ValueTracking.h"
#include "metaphir/Matching/ValueTrackContext.h"
#include "mlir/IR/SymbolTable.h"
#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

using namespace detail;
using mlir::Operation;

static Sort sortOf(mlir::Value V) {
  return cast<mpir::SortType>(V.getType()).getSort();
}

/// The name a variable is read under, in a diagnostic.
static std::string describeVariable(mlir::Value V, StringRef Msg) {
  std::string Str;
  raw_string_ostream OS(Str);
  if (Operation *Def = V.getDefiningOp())
    if (auto Name = Def->getAttrOfType<mlir::StringAttr>("result_name")) {
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
  switch (sortOf(Read)) {
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

/// A constraint definition's call: the definition's parameters, bound to its
/// arguments.
struct ExprEvaluator::Frame {
  SlotLookup Slots;
  DenseMap<mlir::Value, Binding> Parameters;
};

ExprEvaluator::ExprEvaluator()
    : Analysis(std::make_unique<ValueTrackContext>()) {}
ExprEvaluator::~ExprEvaluator() = default;

void ExprEvaluator::resetAnalyses() { Analysis->reset(); }

std::optional<ModuleUses> ExprEvaluator::getModuleUses(const llvm::Value &V) {
  if (!Uses || !isUsedAcrossFunctions(V))
    return std::nullopt;
  return Uses->getModuleUses(V);
}

Expected<ConstraintValue> ExprEvaluator::evaluate(mlir::Value E,
                                                  SlotLookup Slots) {
  Frame F{Slots, {}};
  return eval(E, F);
}

const Binding *ExprEvaluator::lookup(mlir::Value V, Frame &F) {
  if (auto Slot = V.getDefiningOp<mpir_plan::SlotOp>())
    return F.Slots(Slot.getSlot());
  auto It = F.Parameters.find(V);
  return It == F.Parameters.end() ? nullptr : &It->second;
}

Expected<SmallVector<ConstraintValue, 2>>
ExprEvaluator::evalAll(mlir::ValueRange Values, Frame &F) {
  SmallVector<ConstraintValue, 2> Result;
  for (mlir::Value V : Values) {
    Expected<ConstraintValue> Value = eval(V, F);
    if (!Value)
      return Value.takeError();
    Result.push_back(std::move(*Value));
  }
  return Result;
}

Expected<ConstraintValue> ExprEvaluator::eval(mlir::Value E, Frame &F) {
  Operation *Def = E.getDefiningOp();
  mlir::Value Expression = E;
  if (auto Int = dyn_cast<mpir_expr::IntOp>(Def))
    return ConstraintValue::getInteger(Int.getAPSInt());
  if (auto Bool = dyn_cast<mpir_expr::BoolOp>(Def))
    return ConstraintValue::getBoolean(Bool.getValue());
  if (auto Str = dyn_cast<mpir_expr::StrOp>(Def))
    return ConstraintValue::getString(Str.getValue());
  if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def)) {
    const Binding *Binding = lookup(Read.getValue(), F);
    if (!Binding)
      return make_error<ConstraintEvaluationError>(
          Expression, describeVariable(Read.getValue(), "is not instantiated"));
    return readBinding(Read.getResult(), *Binding);
  }
  if (auto Array = dyn_cast<mpir_expr::ArrayOp>(Def)) {
    Expected<SmallVector<ConstraintValue, 2>> Elements =
        evalAll(Array.getElements(), F);
    if (!Elements)
      return Elements.takeError();
    switch (sortOf(Array)) {
    case Sort::TypeArray: {
      Binding::TypeArray Types;
      for (const ConstraintValue &Element : *Elements)
        Types.push_back(Element.getType());
      return ConstraintValue::getTypeArray(std::move(Types));
    }
    case Sort::ValueArray: {
      Binding::ValueArray Values;
      for (const ConstraintValue &Element : *Elements)
        Values.push_back(Element.getValue());
      return ConstraintValue::getValueArray(std::move(Values));
    }
    default: {
      ConstraintValue::StringArrayStorage Strings;
      for (const ConstraintValue &Element : *Elements) {
        Expected<std::string> String = requireString(Element, Expression);
        if (!String)
          return String.takeError();
        Strings.push_back(std::move(*String));
      }
      return ConstraintValue::getStringArray(std::move(Strings));
    }
    }
  }
  if (auto Access = dyn_cast<mpir_expr::IndexOp>(Def)) {
    Expected<ConstraintValue> Array = eval(Access.getArray(), F);
    if (!Array)
      return Array.takeError();
    Expected<ConstraintValue> IndexValue = eval(Access.getIndex(), F);
    if (!IndexValue)
      return IndexValue.takeError();
    Expected<APSInt> Index = requireInteger(*IndexValue, Expression);
    if (!Index)
      return Index.takeError();
    if (Index->isSigned() && Index->isNegative())
      return make_error<ConstraintEvaluationError>(Expression,
                                                   "array index is negative");
    uint64_t Position = Index->getLimitedValue();
    auto OutOfBounds = [&] {
      return make_error<ConstraintEvaluationError>(
          Expression, "array index is out of bounds");
    };
    switch (Array->getKind()) {
    case ConstraintValue::TypeArray:
      if (Position >= Array->getTypeArray().size())
        return OutOfBounds();
      return ConstraintValue::getType(Array->getTypeArray()[Position]);
    case ConstraintValue::ValueArray:
      if (Position >= Array->getValueArray().size())
        return OutOfBounds();
      return ConstraintValue::getValue(Array->getValueArray()[Position]);
    case ConstraintValue::StringArray:
      if (Position >= Array->getStringArray().size())
        return OutOfBounds();
      return ConstraintValue::getString(Array->getStringArray()[Position]);
    default:
      llvm_unreachable("array access constraint has a non-array operand");
    }
  }
  if (isa<mpir_expr::CallOp>(Def))
    return evalCall(Def, F);
  if (isa<mpir_expr::ApplyOp>(Def))
    return evalApply(Def, F);
  return make_error<ConstraintEvaluationError>(Expression,
                                               "not a constraint expression");
}

Expected<ConstraintValue> ExprEvaluator::evalApply(Operation *Op, Frame &F) {
  auto Apply = cast<mpir_expr::ApplyOp>(Op);
  mlir::Value Expression = Apply.getResult();
  auto Def = mlir::SymbolTable::lookupNearestSymbolFrom<mpir::ConstraintDefOp>(
      Op, Apply.getCalleeAttr());
  if (!Def)
    return make_error<ConstraintEvaluationError>(
        Expression, Twine("unknown operator '") + Apply.getCallee() + "'");
  if (CallDepth == MaxCallDepth)
    return make_error<ConstraintEvaluationError>(
        Expression, "user-defined constraints are nested too deeply");
  mlir::Block &Body = Def.getBody().front();
  Frame Callee{F.Slots, {}};
  for (auto [Index, Arg] : enumerate(Apply.getArgs())) {
    Expected<ConstraintValue> Value = eval(Arg, F);
    if (!Value)
      return Value.takeError();
    std::optional<Binding> Parameter;
    switch (Value->getKind()) {
    case ConstraintValue::Integer:
      Parameter = Binding(Value->getInteger());
      break;
    case ConstraintValue::Boolean:
      Parameter = Binding(Value->getBoolean());
      break;
    case ConstraintValue::Type:
      Parameter = Binding(Value->getType());
      break;
    case ConstraintValue::Value:
      Parameter = Binding(Value->getValue());
      break;
    case ConstraintValue::TypeArray:
      Parameter = Binding(Value->getTypeArray());
      break;
    case ConstraintValue::ValueArray:
      Parameter = Binding(Value->getValueArray());
      break;
    default:
      break;
    }
    if (!Parameter)
      return make_error<ConstraintEvaluationError>(
          Expression, "unsupported argument type for user-defined constraint");
    Callee.Parameters[Body.getArgument(Index)] = std::move(*Parameter);
  }
  mlir::Value Result = (*Body.getOps<mpir::YieldOp>().begin()).getValue();
  ++CallDepth;
  Expected<ConstraintValue> Value = eval(Result, Callee);
  --CallDepth;
  return Value;
}

Expected<ConstraintValue> ExprEvaluator::evalCall(Operation *Op, Frame &F) {
  auto Call = cast<mpir_expr::CallOp>(Op);
  mlir::Value Expression = Call.getResult();
  mlir::OperandRange Arguments = Call.getArgs();
  auto GetModuleUses = [this](const llvm::Value &V) {
    return getModuleUses(V);
  };

  // '&&' and '||': the right side only if the left does not decide.
  auto Logical = [&](bool IsOr) -> Expected<ConstraintValue> {
    Expected<ConstraintValue> Left = eval(Arguments[0], F);
    if (!Left)
      return Left.takeError();
    Expected<bool> LeftValue = requireBoolean(*Left, Expression);
    if (!LeftValue)
      return LeftValue.takeError();
    if (*LeftValue == IsOr)
      return ConstraintValue::getBoolean(*LeftValue);
    Expected<ConstraintValue> Right = eval(Arguments[1], F);
    if (!Right)
      return Right.takeError();
    Expected<bool> RightValue = requireBoolean(*Right, Expression);
    if (!RightValue)
      return RightValue.takeError();
    return ConstraintValue::getBoolean(*RightValue);
  };

  auto Builtin = [&](auto Descriptor) -> Expected<ConstraintValue> {
    using Op = decltype(Descriptor);
    if constexpr (Op::ShortCircuits) {
      return Logical(Call.getOperatorID() == constraint::O_LogicalOr);
    } else {
      Expected<SmallVector<ConstraintValue, 2>> Operands =
          evalAll(Arguments, F);
      if (!Operands)
        return Operands.takeError();
      return Op::concrete(ConcreteCall{*Operands, Expression, GetModuleUses});
    }
  };

  // A value-tracking operator: its first BaseArity arguments are operands,
  // and an optional last one is the context instruction; without it, the
  // instruction the constraint is anchored at.
  auto ValueTrack = [&](auto Descriptor,
                        unsigned BaseArity) -> Expected<ConstraintValue> {
    using Op = decltype(Descriptor);
    Expected<SmallVector<ConstraintValue, 2>> Operands =
        evalAll(Arguments.take_front(BaseArity), F);
    if (!Operands)
      return Operands.takeError();
    const llvm::Instruction *Context = nullptr;
    if (Arguments.size() > BaseArity) {
      Expected<ConstraintValue> Explicit = eval(Arguments[BaseArity], F);
      if (!Explicit)
        return Explicit.takeError();
      Expected<const llvm::Value *> Value = requireValue(*Explicit, Expression);
      if (!Value)
        return Value.takeError();
      Context = dyn_cast<llvm::Instruction>(*Value);
      if (!Context)
        return make_error<ConstraintEvaluationError>(
            Expression, "expected an instruction context operand");
    } else {
      if (mlir::Value Anchor = Call.getAnchor())
        if (const Binding *Binding = lookup(Anchor, F))
          if (const auto *Value =
                  std::get_if<const llvm::Value *>(&Binding->Data))
            Context = dyn_cast<llvm::Instruction>(*Value);
      if (!Context)
        return make_error<ConstraintEvaluationError>(
            Expression,
            "no context instruction for value-tracking operator "
            "(place the constraint after an instruction or pass ?ctx "
            "explicitly)");
    }
    SimplifyQuery Query = Analysis->getQuery(Context);
    return Op::concrete(
        ConcreteCall{*Operands, Expression, GetModuleUses, &Query});
  };

  switch (Call.getOperatorID()) {
#define MIR_CONSTRAINT_OPERATOR_ID(ID, Name, Kind)                             \
  case constraint::O_##ID:                                                     \
    return Builtin(Op##ID());
#define MIR_CONSTRAINT_VALUE_TRACK_OPERATOR(ID, Name, Kind, Result, BaseArity) \
  case constraint::O_##ID:                                                     \
    return ValueTrack(Op##ID(), BaseArity);
#include "metaphir/IR/ConstraintOperators.def"
  default:
    break;
  }
  return make_error<ConstraintEvaluationError>(
      Expression, "constraint operator without a descriptor");
}

} // namespace metaphir
} // namespace llvm
