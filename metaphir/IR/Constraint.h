#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/MetaVariable.h"
#include "llvm/ADT/ArrayRef.h"
#include <optional>
#include <variant>

namespace llvm {
namespace metaphir {

class Instruction;

/// A node of a constraint expression ('?x == 1 && isZero(?y)'). Nodes are
/// created by the factories of the subclasses, are owned by the MIRContext,
/// and are not uniqued.
class Constraint {
public:
  enum ConstraintID {
    Integer,
    Boolean,
    String,
    Array,
    Variable,
    ArrayAccess,
    Unary,
    Binary,
    Call
  };
  enum OperatorID {
    UnknownOperator,
#define MIR_CONSTRAINT_OPERATOR_ID(ID, Name, Kind) O_##ID,
#include "metaphir/IR/ConstraintOperators.def"
  };
  enum ResultType {
    Unknown,
    IntegerResult,
    BooleanResult,
    StringResult,
    TypeResult,
    ValueResult,
    TypeArrayResult,
    ValueArrayResult,
    StringArrayResult,
    BitVectorResult
  };

  struct OperatorSchema {
    ResultType Result;
    unsigned MinArity;
    unsigned MaxArity;
  };

  virtual ~Constraint() = default;

  ConstraintID getConstraintID() const { return ID; }
  ResultType getResultType() const { return Ty; }
  SourceRange getSourceRange() const { return Range; }

  // The pattern instruction that lexically precedes this constraint, used as
  // the default context (use-point) for value-tracking operators that omit an
  // explicit ?ctx argument. Null when the constraint precedes every
  // instruction.
  const Instruction *getContextInstruction() const { return Context; }
  void setContextInstruction(const Instruction *Context) {
    this->Context = Context;
  }
  /// Sets the context instruction of this node and of every node below it
  /// that has none yet.
  void setDefaultContextInstruction(const Instruction *Context);

  static std::optional<OperatorSchema> getOperatorSchema(OperatorID ID);
  static StringRef getOperatorName(OperatorID ID);
  static OperatorID getOperatorID(StringRef Name, ConstraintID Kind);
  static ResultType getResultType(MetaType Type);

  /// Whether a value of type From may be used where To is expected: the
  /// types agree, one of them is unknown until evaluation, or From converts
  /// to To (see ConstraintCoercions.def).
  static bool canCoerce(ResultType From, ResultType To);
  /// The type argument Index of a built-in operator must coerce to; Unknown
  /// when any value is accepted.
  static ResultType getArgumentType(OperatorID ID, unsigned Index);
  /// A phrase naming a type for diagnostics, e.g. "an integer".
  static StringRef describe(ResultType Type);

protected:
  Constraint(ConstraintID ID, ResultType Ty, SourceRange R)
      : ID(ID), Ty(Ty), Range(R) {}

private:
  ConstraintID ID;
  ResultType Ty;
  SourceRange Range;
  const Instruction *Context = nullptr;
};

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C);

// Kinds of constraint expression nodes.

/// An integer literal.
class IntegerConstraint : public Constraint {
public:
  int64_t getValue() const { return Number; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Integer;
  }
  static IntegerConstraint *create(MIRContext &Context, int64_t Number,
                                   SourceRange Range);

private:
  int64_t Number;

  IntegerConstraint(int64_t N, SourceRange R)
      : Constraint(Integer, IntegerResult, R), Number(N) {}
};

/// 'true' or 'false'.
class BooleanConstraint : public Constraint {
public:
  bool getValue() const { return State; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Boolean;
  }
  static BooleanConstraint *create(MIRContext &Context, bool State,
                                   SourceRange Range);

private:
  bool State;

  BooleanConstraint(bool S, SourceRange R)
      : Constraint(Boolean, BooleanResult, R), State(S) {}
};

/// A string literal.
class StringConstraint : public Constraint {
public:
  StringRef getValue() const { return Value; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == String;
  }
  static StringConstraint *create(MIRContext &Context, StringRef Value,
                                  SourceRange Range);

private:
  StringRef Value;

  StringConstraint(StringRef Value, SourceRange Range)
      : Constraint(String, StringResult, Range), Value(Value) {}
};

/// An array literal of types, values or strings, '[a, b]'.
class ArrayConstraint : public Constraint {
public:
  ArrayRef<Constraint *> getElements() const { return Elements; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Array;
  }
  static ArrayConstraint *create(MIRContext &Context, ResultType Type,
                                 ArrayRef<Constraint *> Elements,
                                 SourceRange Range);

private:
  ArrayRef<Constraint *> Elements;

  ArrayConstraint(ResultType Type, ArrayRef<Constraint *> Elements,
                  SourceRange Range)
      : Constraint(Array, Type, Range), Elements(Elements) {}
};

/// A reference to a meta variable, or to a pattern instruction once lowered.
class VariableConstraint : public Constraint {
public:
  Value *getVariable() const { return VariableValue; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Variable;
  }
  static VariableConstraint *create(MIRContext &Context, Value *Variable,
                                    ResultType Type, SourceRange Range);

private:
  Value *VariableValue;

  VariableConstraint(Value *V, ResultType T, SourceRange R)
      : Constraint(Variable, T, R), VariableValue(V) {}
};

/// An element of an array, 'a[i]'.
class ArrayAccessConstraint : public Constraint {
public:
  Constraint *getArray() const { return Array; }
  Constraint *getIndex() const { return Index; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == ArrayAccess;
  }
  static ArrayAccessConstraint *create(MIRContext &Context, ResultType Type,
                                       Constraint *Array, Constraint *Index,
                                       SourceRange Range);

private:
  Constraint *Array;
  Constraint *Index;

  ArrayAccessConstraint(ResultType Type, Constraint *Array, Constraint *Index,
                        SourceRange Range)
      : Constraint(ArrayAccess, Type, Range), Array(Array), Index(Index) {}
};

/// A unary or binary operator, or a call of a built-in operation or of a
/// 'constraint' definition.
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
  static OperatorConstraint *createBuiltin(MIRContext &Context, ConstraintID ID,
                                           ResultType Type, OperatorID OpID,
                                           ArrayRef<Constraint *> Arguments,
                                           SourceRange Range);
  static OperatorConstraint *createUserDefined(MIRContext &Context,
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
