#ifndef METAPHIR_IR_VALUE_H
#define METAPHIR_IR_VALUE_H

#include "metaphir/IR/SourceRange.h"

namespace llvm {
namespace metaphir {

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
