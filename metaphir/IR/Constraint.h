#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Sort.h"
#include "llvm/ADT/APSInt.h"
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

  struct OperatorSchema {
    Sort Result;
    unsigned MinArity;
    unsigned MaxArity;
  };

  virtual ~Constraint() = default;

  ConstraintID getConstraintID() const { return ID; }
  Sort getSort() const { return Ty; }
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

  /// Whether a value of sort From may be used where To is expected: From is
  /// a subsort of To, one of them is unknown until evaluation, or From's
  /// representation converts to To (see ConstraintCoercions.def).
  static bool canCoerce(Sort From, Sort To);
  /// The sort argument Index of a built-in operator must coerce to; Unknown
  /// when any value is accepted.
  static Sort getArgumentType(OperatorID ID, unsigned Index);
  /// A phrase naming a sort for diagnostics, e.g. "an integer".
  static StringRef describe(Sort Type);

protected:
  Constraint(ConstraintID ID, Sort Ty, SourceRange R)
      : ID(ID), Ty(Ty), Range(R) {}

private:
  ConstraintID ID;
  Sort Ty;
  SourceRange Range;
  const Instruction *Context = nullptr;
};

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C);

// Kinds of constraint expression nodes.

/// An integer literal, of any size. A non-negative literal is unsigned and a
/// negative one signed, each at least 64 bits wide.
class IntegerConstraint : public Constraint {
public:
  const APSInt &getValue() const { return Number; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Integer;
  }
  /// The literal with Number's value, read as its signedness says.
  static IntegerConstraint *create(MIRContext &Context, const APSInt &Number,
                                   SourceRange Range);
  static IntegerConstraint *create(MIRContext &Context, int64_t Number,
                                   SourceRange Range);

private:
  APSInt Number;

  IntegerConstraint(APSInt N, SourceRange R)
      : Constraint(Integer, Sort::Integer, R), Number(std::move(N)) {}
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
      : Constraint(Boolean, Sort::Boolean, R), State(S) {}
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
      : Constraint(String, Sort::String, Range), Value(Value) {}
};

/// An array literal of types, values or strings, '[a, b]'.
class ArrayConstraint : public Constraint {
public:
  ArrayRef<Constraint *> getElements() const { return Elements; }
  static bool classof(const Constraint *C) {
    return C->getConstraintID() == Array;
  }
  static ArrayConstraint *create(MIRContext &Context, Sort Type,
                                 ArrayRef<Constraint *> Elements,
                                 SourceRange Range);

private:
  ArrayRef<Constraint *> Elements;

  ArrayConstraint(Sort Type, ArrayRef<Constraint *> Elements, SourceRange Range)
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
                                    Sort Type, SourceRange Range);

private:
  Value *VariableValue;

  VariableConstraint(Value *V, Sort T, SourceRange R)
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
  static ArrayAccessConstraint *create(MIRContext &Context, Sort Type,
                                       Constraint *Array, Constraint *Index,
                                       SourceRange Range);

private:
  Constraint *Array;
  Constraint *Index;

  ArrayAccessConstraint(Sort Type, Constraint *Array, Constraint *Index,
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
                                           Sort Type, OperatorID OpID,
                                           ArrayRef<Constraint *> Arguments,
                                           SourceRange Range);
  static OperatorConstraint *createUserDefined(MIRContext &Context,
                                               ConstraintID ID, Sort Type,
                                               StringRef Operator,
                                               ArrayRef<Constraint *> Arguments,
                                               SourceRange Range);

private:
  std::variant<OperatorID, StringRef> Op;
  ArrayRef<Constraint *> Arguments;

  OperatorConstraint(ConstraintID ID, Sort T,
                     std::variant<OperatorID, StringRef> Op,
                     ArrayRef<Constraint *> A, SourceRange R)
      : Constraint(ID, T, R), Op(Op), Arguments(A) {}
};

} // namespace metaphir
} // namespace llvm
#endif
