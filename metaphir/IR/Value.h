#ifndef METAPHIR_IR_VALUE_H
#define METAPHIR_IR_VALUE_H

#include "llvm/Support/SMLoc.h"

namespace llvm {
namespace metaphir {

struct SourceRange {
  SMLoc Begin;
  SMLoc End;
};

class Value {
public:
  enum ValueID {
    MetaVariableVal,
    InstructionVal,
    GlobalVal,
    IntegerConstantVal,
    FloatingConstantVal,
    KeywordConstantVal,
    AggregateConstantVal
  };

  virtual ~Value() = default;

  ValueID getValueID() const { return ID; }
  SourceRange getSourceRange() const { return Range; }

protected:
  Value(ValueID ID, SourceRange Range) : ID(ID), Range(Range) {}

private:
  ValueID ID;
  SourceRange Range;
};

} // namespace metaphir
} // namespace llvm

#endif
