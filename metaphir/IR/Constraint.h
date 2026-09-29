#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/MetaVariable.h"
#include <optional>

namespace llvm {
namespace metaphir {

class Instruction;

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

} // namespace metaphir
} // namespace llvm
#endif
