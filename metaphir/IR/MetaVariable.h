#ifndef METAPHIR_IR_META_VARIABLE_H
#define METAPHIR_IR_META_VARIABLE_H

#include "metaphir/IR/Sort.h"
#include "metaphir/IR/Value.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {

class raw_ostream;

namespace metaphir {

class MIRContext;

/// A meta variable ('?x'): a name bound when a pattern matches. Its sort is
/// the meet of the sorts its occurrences require (see Sorts.def). Not uniqued:
/// each create() makes a new variable, and matching binds variables by object,
/// not by name.
class MetaVariable : public Value {
public:
  StringRef getName() const { return Name; }
  /// The sort the variable denotes: an operand-only variable is a Value.
  Sort getSort() const { return resolveSort(Ty); }
  /// The sort inferred so far, which may still be Operand.
  Sort getInferredSort() const { return Ty; }
  void setSort(Sort S) { Ty = S; }
  static bool classof(const Value *V) {
    return V->getValueID() == MetaVariableVal;
  }

  // The range is required rather than defaulted, so a caller cannot leave a
  // meta variable without a source location by omission.
  static MetaVariable *create(MIRContext &Context, StringRef Name, Sort Ty,
                              SourceRange Range);

private:
  StringRef Name;
  Sort Ty;
  MetaVariable(StringRef Name, Sort Ty, SourceRange Range)
      : Value(MetaVariableVal, Range), Name(Name), Ty(Ty) {}
};

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M);

} // namespace metaphir
} // namespace llvm
#endif
