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

VariableConstraint *VariableConstraint::get(MIRContext &Context,
                                            MetaVariable *Variable,
                                            ResultType Type,
                                            SourceRange Range) {
  return new (Context.pImpl->Alloc) VariableConstraint(Variable, Type, Range);
}

OperatorConstraint *OperatorConstraint::get(MIRContext &Context,
                                            ConstraintID ID, ResultType Type,
                                            StringRef Operator,
                                            ArrayRef<Constraint *> Arguments,
                                            SourceRange Range) {
  OperatorID OperatorID = Constraint::getOperatorID(Operator, ID);
  StringRef SavedOperator;
  if (OperatorID == UnknownOperator)
    SavedOperator = Context.pImpl->Saver.save(Operator);
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, OperatorID, SavedOperator,
      Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

StringRef OperatorConstraint::getOperator() const {
  if (Operator != UnknownOperator)
    return Constraint::getOperatorName(Operator);
  return OperatorName;
}

std::optional<Constraint::OperatorSchema>
Constraint::getOperatorSchema(OperatorID ID) {
  switch (ID) {
#define MIR_CONSTRAINT_OPERATOR_SCHEMA(OperatorID, Name, Kind, Result, Arity)  \
  case O_##OperatorID:                                                         \
    return OperatorSchema{Result, Arity};
#include "metaphir/IR/ConstraintOperators.def"
  case UnknownOperator:
    break;
  }
  return std::nullopt;
}

Constraint::OperatorID Constraint::getOperatorID(StringRef Name,
                                                 ConstraintID Kind) {
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, OperatorName, OperatorKind)     \
  if (Name == OperatorName && Kind == OperatorKind)                            \
    return O_##OperatorID;
#include "metaphir/IR/ConstraintOperators.def"
  return UnknownOperator;
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

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C) {
  switch (C.getConstraintID()) {
  case Constraint::Integer:
    return OS << cast<IntegerConstraint>(C).getValue();
  case Constraint::Boolean:
    return OS << (cast<BooleanConstraint>(C).getValue() ? "true" : "false");
  case Constraint::Variable:
    return OS << *cast<VariableConstraint>(C).getVariable();
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
