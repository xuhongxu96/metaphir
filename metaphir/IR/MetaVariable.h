#ifndef METAPHIR_IR_META_VARIABLE_H
#define METAPHIR_IR_META_VARIABLE_H

#include "metaphir/IR/Value.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {

class raw_ostream;

namespace metaphir {

class MIRContext;

enum class MetaType {
  Unknown,
  Nat,
  Bool,
  Type,
  CmpPredicate,
  Value,
  Instruction,
  Function,
  IntrinsicID,
  BasicBlock,
  TypeArray,
  ValueArray,
};

raw_ostream &operator<<(raw_ostream &OS, MetaType Type);

class MetaVariable : public Value {
public:
  StringRef getName() const { return Name; }
  MetaType getType() const { return Ty; }
  void setType(MetaType T) { Ty = T; }
  static bool classof(const Value *V) {
    return V->getValueID() == MetaVariableVal;
  }

  static MetaVariable *get(MIRContext &Context, StringRef Name, MetaType Ty,
                           SourceRange Range);

private:
  StringRef Name;
  MetaType Ty;
  MetaVariable(StringRef Name, MetaType Ty, SourceRange Range)
      : Value(MetaVariableVal, Range), Name(Name), Ty(Ty) {}
};

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M);

} // namespace metaphir
} // namespace llvm
#endif
