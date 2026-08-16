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
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, Context.pImpl->Saver.save(Operator),
      Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

std::optional<Constraint::FunctionSchema>
Constraint::getFunctionSchema(StringRef Name) {
#define MIR_CONSTRAINT_FUNCTION_SCHEMA(FunctionName, Result, Arity)            \
  if (Name == #FunctionName)                                                   \
    return FunctionSchema{Result, Arity};
#include "metaphir/IR/ConstraintFunctions.def"
  return std::nullopt;
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
