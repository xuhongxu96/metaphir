#ifndef METAPHIR_IR_PATTERN_H
#define METAPHIR_IR_PATTERN_H

#include "metaphir/IR/Constraints.h"
#include "metaphir/IR/Instruction.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class raw_ostream;
namespace metaphir {

class Pattern {
public:
  ~Pattern();

  ArrayRef<Instruction *> getInstructions() const { return Instructions; }
  ArrayRef<Constraint *> getConstraints() const { return Constraints; }
  ArrayRef<MetaVariable *> getMetaVariables() const { return MetaVariables; }

  SmallVector<Instruction *, 4> getRoots() const;

  void addInstruction(Instruction *Instruction) {
    Instructions.push_back(Instruction);
  }
  void addConstraint(Constraint *Constraint) {
    Constraints.push_back(Constraint);
  }
  void addMetaVariable(MetaVariable *MetaVariable) {
    MetaVariables.push_back(MetaVariable);
  }

  static Pattern *get(MIRContext &Context);

private:
  MIRContext &Context;
  SmallVector<Instruction *, 16> Instructions;
  SmallVector<Constraint *, 8> Constraints;
  SmallVector<MetaVariable *, 16> MetaVariables;

  explicit Pattern(MIRContext &Context) : Context(Context) {}
};

raw_ostream &operator<<(raw_ostream &OS, const Pattern &P);

} // namespace metaphir
} // namespace llvm
#endif
