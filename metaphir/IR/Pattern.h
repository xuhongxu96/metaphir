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

  ArrayRef<std::pair<const MetaVariable *, bool>> getFixedFlags() const {
    return FixedFlags;
  }

  SmallVector<Instruction *, 4> getRoots() const;

  void addInstruction(Instruction *Instruction) {
    Instructions.push_back(Instruction);
  }
  void addConstraint(Constraint *Constraint) {
    Constraints.push_back(Constraint);
  }
  void addFixedFlag(const MetaVariable *Var, bool Value) {
    FixedFlags.push_back({Var, Value});
  }
  void addMetaVariable(MetaVariable *MetaVariable) {
    assert(llvm::none_of(MetaVariables,
                         [&](const auto *M) {
                           return M == MetaVariable ||
                                  M->getName() == MetaVariable->getName();
                         }) &&
           "meta variable already added to pattern");
    MetaVariables.push_back(MetaVariable);
  }

  /// Creates an empty pattern owned by Context.
  static Pattern *get(MIRContext &Context);

  /// Creates a pattern owned by the context with the same contents as this
  /// one. Instructions and constraints are shared, not copied.
  Pattern *copy() const;

  Pattern(const Pattern &) = delete;
  Pattern &operator=(const Pattern &) = delete;

private:
  MIRContext &Context;
  SmallVector<Instruction *, 16> Instructions;
  SmallVector<Constraint *, 8> Constraints;
  SmallVector<MetaVariable *, 16> MetaVariables;
  SmallVector<std::pair<const MetaVariable *, bool>, 4> FixedFlags;

  explicit Pattern(MIRContext &Context) : Context(Context) {}
};

raw_ostream &operator<<(raw_ostream &OS, const Pattern &P);

} // namespace metaphir
} // namespace llvm
#endif
