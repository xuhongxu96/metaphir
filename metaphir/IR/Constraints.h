#ifndef METAPHIR_IR_CONSTRAINTS_H
#define METAPHIR_IR_CONSTRAINTS_H

#include "metaphir/IR/Constraint.h"
#include "llvm/ADT/ArrayRef.h"

#include <variant>

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

class StringConstraint : public Constraint {
public:
  StringRef getValue() const { return Value; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == String;
  }
  static StringConstraint *get(MIRContext &Context, StringRef Value,
                               SourceRange Range);

private:
  StringRef Value;

  StringConstraint(StringRef Value, SourceRange Range)
      : Constraint(String, StringResult, Range), Value(Value) {}
};

class ArrayConstraint : public Constraint {
public:
  ArrayRef<Constraint *> getElements() const { return Elements; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Array;
  }
  static ArrayConstraint *get(MIRContext &Context, ResultType Type,
                              ArrayRef<Constraint *> Elements,
                              SourceRange Range);

private:
  ArrayRef<Constraint *> Elements;

  ArrayConstraint(ResultType Type, ArrayRef<Constraint *> Elements,
                  SourceRange Range)
      : Constraint(Array, Type, Range), Elements(Elements) {}
};

class VariableConstraint : public Constraint {
public:
  Value *getVariable() const { return VariableValue; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Variable;
  }
  static VariableConstraint *get(MIRContext &Context, Value *Variable,
                                 ResultType Type, SourceRange Range);

private:
  Value *VariableValue;

  VariableConstraint(Value *V, ResultType T, SourceRange R)
      : Constraint(Variable, T, R), VariableValue(V) {}
};

class ArrayAccessConstraint : public Constraint {
public:
  Constraint *getArray() const { return Array; }
  Constraint *getIndex() const { return Index; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == ArrayAccess;
  }
  static ArrayAccessConstraint *get(MIRContext &Context, ResultType Type,
                                    Constraint *Array, Constraint *Index,
                                    SourceRange Range);

private:
  Constraint *Array;
  Constraint *Index;

  ArrayAccessConstraint(ResultType Type, Constraint *Array, Constraint *Index,
                        SourceRange Range)
      : Constraint(ArrayAccess, Type, Range), Array(Array), Index(Index) {}
};

class OperatorConstraint : public Constraint {
public:
  OperatorID getOperatorID() const;
  StringRef getOperator() const;
  bool isUserDefined() const { return std::holds_alternative<StringRef>(Op); }
  ArrayRef<Constraint *> getArguments() const { return Arguments; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Unary || C->getConstraintID() == Binary ||
           C->getConstraintID() == Call;
  }
  static OperatorConstraint *getBuiltin(MIRContext &Context, ConstraintID ID,
                                        ResultType Type, OperatorID OpID,
                                        ArrayRef<Constraint *> Arguments,
                                        SourceRange Range);
  static OperatorConstraint *getUserDefined(MIRContext &Context,
                                            ConstraintID ID, ResultType Type,
                                            StringRef Operator,
                                            ArrayRef<Constraint *> Arguments,
                                            SourceRange Range);

private:
  std::variant<OperatorID, StringRef> Op;
  ArrayRef<Constraint *> Arguments;

  OperatorConstraint(ConstraintID ID, ResultType T,
                     std::variant<OperatorID, StringRef> Op,
                     ArrayRef<Constraint *> A, SourceRange R)
      : Constraint(ID, T, R), Op(Op), Arguments(A) {}
};

} // namespace metaphir
} // namespace llvm

#endif
