#include "metaphir/IR/Constraints.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

IntegerConstraint *IntegerConstraint::get(MIRContext &Context, int64_t Number,
                                          SourceRange Range) {
  return new (Context.pImpl->Alloc) IntegerConstraint(Number, Range);
}

BooleanConstraint *BooleanConstraint::get(MIRContext &Context, bool State,
                                          SourceRange Range) {
  return new (Context.pImpl->Alloc) BooleanConstraint(State, Range);
}

StringConstraint *StringConstraint::get(MIRContext &Context, StringRef Value,
                                        SourceRange Range) {
  return new (Context.pImpl->Alloc)
      StringConstraint(Context.pImpl->Saver.save(Value), Range);
}

ArrayConstraint *ArrayConstraint::get(MIRContext &Context, ResultType Type,
                                      ArrayRef<Constraint *> Elements,
                                      SourceRange Range) {
  return new (Context.pImpl->Alloc)
      ArrayConstraint(Type, Context.pImpl->copyArray(Elements), Range);
}

VariableConstraint *VariableConstraint::get(MIRContext &Context,
                                            Value *Variable, ResultType Type,
                                            SourceRange Range) {
  return new (Context.pImpl->Alloc) VariableConstraint(Variable, Type, Range);
}

ArrayAccessConstraint *ArrayAccessConstraint::get(MIRContext &Context,
                                                  ResultType Type,
                                                  Constraint *Array,
                                                  Constraint *Index,
                                                  SourceRange Range) {
  return new (Context.pImpl->Alloc)
      ArrayAccessConstraint(Type, Array, Index, Range);
}

OperatorConstraint *OperatorConstraint::getBuiltin(
    MIRContext &Context, ConstraintID ID, ResultType Type, OperatorID OpID,
    ArrayRef<Constraint *> Arguments, SourceRange Range) {
  assert(OpID != UnknownOperator &&
         "built-in OperatorConstraint::getBuiltin requires a known OperatorID");
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, OpID, Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

OperatorConstraint *OperatorConstraint::getUserDefined(
    MIRContext &Context, ConstraintID ID, ResultType Type, StringRef Operator,
    ArrayRef<Constraint *> Arguments, SourceRange Range) {
  assert(Constraint::getOperatorID(Operator, ID) == UnknownOperator &&
         "custom OperatorConstraint::getUserDefined cannot be called with a "
         "built-in operator name");
  StringRef SavedOperator = Context.pImpl->Saver.save(Operator);
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, SavedOperator,
      Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

Constraint::OperatorID OperatorConstraint::getOperatorID() const {
  if (const auto *ID = std::get_if<OperatorID>(&Op))
    return *ID;
  return UnknownOperator;
}

StringRef OperatorConstraint::getOperator() const {
  if (const auto *ID = std::get_if<OperatorID>(&Op))
    return Constraint::getOperatorName(*ID);
  return std::get<StringRef>(Op);
}

std::optional<Constraint::OperatorSchema>
Constraint::getOperatorSchema(OperatorID ID) {
  switch (ID) {
#define MIR_CONSTRAINT_OPERATOR_SCHEMA(OperatorID, Name, Kind, Result,         \
                                       MinArity, MaxArity)                     \
  case O_##OperatorID:                                                         \
    return OperatorSchema{Result, MinArity, MaxArity};
#include "metaphir/IR/ConstraintOperators.def"
  case UnknownOperator:
    break;
  }
  return std::nullopt;
}

Constraint::OperatorID Constraint::getOperatorID(StringRef Name,
                                                 ConstraintID Kind) {
  static const auto OperatorMaps = [] {
    struct Maps {
      StringMap<OperatorID> Unary;
      StringMap<OperatorID> Binary;
      StringMap<OperatorID> Call;
    } M;
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, OperatorName, OperatorKind)     \
  if (OperatorKind == Constraint::Unary)                                       \
    M.Unary[OperatorName] = Constraint::O_##OperatorID;                        \
  else if (OperatorKind == Constraint::Binary)                                 \
    M.Binary[OperatorName] = Constraint::O_##OperatorID;                       \
  else if (OperatorKind == Constraint::Call)                                   \
    M.Call[OperatorName] = Constraint::O_##OperatorID;
#define MIR_CONSTRAINT_OPERATOR_ALIAS(OperatorID, OperatorName, OperatorKind)  \
  if (OperatorKind == Constraint::Unary)                                       \
    M.Unary[OperatorName] = Constraint::O_##OperatorID;                        \
  else if (OperatorKind == Constraint::Binary)                                 \
    M.Binary[OperatorName] = Constraint::O_##OperatorID;                       \
  else if (OperatorKind == Constraint::Call)                                   \
    M.Call[OperatorName] = Constraint::O_##OperatorID;
#include "metaphir/IR/ConstraintOperators.def"
#undef MIR_CONSTRAINT_OPERATOR_ALIAS
    return M;
  }();

  const StringMap<OperatorID> *Map = nullptr;
  switch (Kind) {
  case Unary:
    Map = &OperatorMaps.Unary;
    break;
  case Binary:
    Map = &OperatorMaps.Binary;
    break;
  case Call:
    Map = &OperatorMaps.Call;
    break;
  default:
    return UnknownOperator;
  }

  auto It = Map->find(Name);
  return It != Map->end() ? It->second : UnknownOperator;
}

StringRef Constraint::getOperatorName(OperatorID ID) {
  switch (ID) {
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, Name, Kind)                     \
  case O_##OperatorID:                                                         \
    return Name;
#include "metaphir/IR/ConstraintOperators.def"
  case UnknownOperator:
    return {};
  }
  llvm_unreachable("invalid constraint function ID");
}

Constraint::ResultType Constraint::getResultType(MetaType Type) {
  switch (Type) {
#define MIR_META_TYPE_CONSTRAINT_RESULT(ID, Result)                            \
  case MetaType::ID:                                                           \
    return Result;
#include "metaphir/IR/MetaTypes.def"
  }
  llvm_unreachable("invalid meta type");
}

void Constraint::setDefaultContextInstruction(const Instruction *CxtI) {
  if (!Context)
    Context = CxtI;
  switch (ID) {
  case Array:
    for (Constraint *Element : cast<ArrayConstraint>(this)->getElements())
      Element->setDefaultContextInstruction(CxtI);
    break;
  case ArrayAccess: {
    auto *Access = cast<ArrayAccessConstraint>(this);
    Access->getArray()->setDefaultContextInstruction(CxtI);
    Access->getIndex()->setDefaultContextInstruction(CxtI);
    break;
  }
  case Unary:
  case Binary:
  case Call:
    for (Constraint *Argument : cast<OperatorConstraint>(this)->getArguments())
      Argument->setDefaultContextInstruction(CxtI);
    break;
  case Integer:
  case Boolean:
  case String:
  case Variable:
    break;
  }
}

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C) {
  switch (C.getConstraintID()) {
  case Constraint::Integer:
    return OS << cast<IntegerConstraint>(C).getValue();
  case Constraint::Boolean:
    return OS << (cast<BooleanConstraint>(C).getValue() ? "true" : "false");
  case Constraint::String:
    return OS << '"' << cast<StringConstraint>(C).getValue() << '"';
  case Constraint::Array: {
    const auto &Array = cast<ArrayConstraint>(C);
    OS << '[';
    for (unsigned Index = 0; Index != Array.getElements().size(); ++Index) {
      if (Index)
        OS << ',';
      OS << *Array.getElements()[Index];
    }
    return OS << ']';
  }
  case Constraint::Variable: {
    const Value *V = cast<VariableConstraint>(C).getVariable();
    if (const auto *MV = dyn_cast<MetaVariable>(V))
      return OS << *MV;
    return OS << *V;
  }
  case Constraint::ArrayAccess: {
    const auto &Access = cast<ArrayAccessConstraint>(C);
    return OS << *Access.getArray() << '[' << *Access.getIndex() << ']';
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call: {
    const auto &Operator = cast<OperatorConstraint>(C);
    OS << '(' << Operator.getOperator();
    for (const Constraint *Argument : Operator.getArguments())
      OS << ' ' << *Argument;
    return OS << ')';
  }
  }
  llvm_unreachable("invalid constraint kind");
}

} // namespace metaphir
} // namespace llvm
