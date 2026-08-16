#ifndef METAPHIR_IR_VALUE_H
#define METAPHIR_IR_VALUE_H

#include "metaphir/IR/MetaFlag.h"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

class MIRContext;

class Value {
public:
  enum ValueID {
    MetaVal,
    LocalInstructionVal,
    BasicBlockVal,
    GlobalVal,
    IntrinsicVal,
    IntegerConstantVal,
    FloatingConstantVal,
    KeywordConstantVal,
    AggregateConstantVal
  };

  virtual ~Value() = default;

  ValueID getValueID() const { return ID; }
  ArrayRef<MetaFlag *> getMetaFlags() const { return Flags; }
  SourceRange getSourceRange() const { return Range; }

  void setMetaFlags(MIRContext &Context, ArrayRef<MetaFlag *> NewFlags);

protected:
  Value(ValueID ID, SourceRange Range) : ID(ID), Range(Range) {}

private:
  ValueID ID;
  ArrayRef<MetaFlag *> Flags;
  SourceRange Range;
};

} // namespace metaphir
} // namespace llvm

#endif
