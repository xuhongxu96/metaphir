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

  static std::optional<OperatorSchema> getOperatorSchema(OperatorID ID);
  static StringRef getOperatorName(OperatorID ID);
  static OperatorID getOperatorID(StringRef Name, ConstraintID Kind);
  static ResultType getResultType(MetaType Type);

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
