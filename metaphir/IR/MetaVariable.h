#ifndef METAPHIR_IR_META_VARIABLE_H
#define METAPHIR_IR_META_VARIABLE_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/SMLoc.h"

namespace llvm {

class raw_ostream;

namespace metaphir {

class MIRContext;

struct SourceRange {
  SMLoc Begin;
  SMLoc End;
};

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

class MetaVariable {
public:
  StringRef getName() const { return Name; }
  MetaType getType() const { return Ty; }
  void setType(MetaType T) { Ty = T; }
  SourceRange getSourceRange() const { return Range; }

  static MetaVariable *get(MIRContext &Context, StringRef Name, MetaType Ty,
                           SourceRange Range);

private:
  StringRef Name;
  MetaType Ty;
  SourceRange Range;

  MetaVariable(StringRef Name, MetaType Ty, SourceRange Range)
      : Name(Name), Ty(Ty), Range(Range) {}
};

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M);

} // namespace metaphir
} // namespace llvm
#endif
