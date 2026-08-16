#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/MetaVariable.h"
#include <optional>

namespace llvm {
namespace metaphir {

class Constraint {
public:
  enum ConstraintID { Integer, Boolean, Variable, Unary, Binary, Call };
  enum ResultType { Unknown, IntegerResult, BooleanResult };

  struct FunctionSchema {
    ResultType Result;
    unsigned Arity;
  };

  virtual ~Constraint() = default;

  ConstraintID getConstraintID() const { return ID; }
  ResultType getResultType() const { return Ty; }
  SourceRange getSourceRange() const { return Range; }

  static std::optional<FunctionSchema> getFunctionSchema(StringRef Name);

protected:
  Constraint(ConstraintID ID, ResultType Ty, SourceRange R)
      : ID(ID), Ty(Ty), Range(R) {}

private:
  ConstraintID ID;
  ResultType Ty;
  SourceRange Range;
};

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C);

} // namespace metaphir
} // namespace llvm
#endif
