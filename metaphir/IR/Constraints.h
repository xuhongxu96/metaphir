#ifndef METAPHIR_IR_CONSTRAINTS_H
#define METAPHIR_IR_CONSTRAINTS_H

#include "metaphir/IR/Constraint.h"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

class IntegerConstraint : public Constraint {
public:
  int64_t getValue() const { return Number; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Integer;
  }
  static IntegerConstraint *get(MIRContext &Context, int64_t Number,
                                SourceRange Range);

private:
  int64_t Number;

  IntegerConstraint(int64_t N, SourceRange R)
      : Constraint(Integer, IntegerResult, R), Number(N) {}
};

class BooleanConstraint : public Constraint {
public:
  bool getValue() const { return State; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Boolean;
  }
  static BooleanConstraint *get(MIRContext &Context, bool State,
                                SourceRange Range);

private:
  bool State;

  BooleanConstraint(bool S, SourceRange R)
      : Constraint(Boolean, BooleanResult, R), State(S) {}
};

class VariableConstraint : public Constraint {
public:
  MetaVariable *getVariable() const { return VariableValue; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Variable;
  }
  static VariableConstraint *get(MIRContext &Context, MetaVariable *Variable,
                                 ResultType Type, SourceRange Range);

private:
  MetaVariable *VariableValue;

  VariableConstraint(MetaVariable *V, ResultType T, SourceRange R)
      : Constraint(Variable, T, R), VariableValue(V) {}
};

class OperatorConstraint : public Constraint {
public:
  StringRef getOperator() const { return Operator; }
  ArrayRef<Constraint *> getArguments() const { return Arguments; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Unary || C->getConstraintID() == Binary ||
           C->getConstraintID() == Call;
  }
  static OperatorConstraint *get(MIRContext &Context, ConstraintID ID,
                                 ResultType Type, StringRef Operator,
                                 ArrayRef<Constraint *> Arguments,
                                 SourceRange Range);

private:
  StringRef Operator;
  ArrayRef<Constraint *> Arguments;

  OperatorConstraint(ConstraintID ID, ResultType T, StringRef Op,
                     ArrayRef<Constraint *> A, SourceRange R)
      : Constraint(ID, T, R), Operator(Op), Arguments(A) {}
};

} // namespace metaphir
} // namespace llvm

#endif
