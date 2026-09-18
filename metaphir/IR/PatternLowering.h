#ifndef METAPHIR_IR_PATTERN_LOWERING_H
#define METAPHIR_IR_PATTERN_LOWERING_H

#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

class MIRContext;

class PatternLowering {
public:
  PatternLowering(MIRContext &Context) : Context(Context) {}

  Expected<PatternVariants> lower(Pattern *P);

private:
  /// Meta variables are named values, so substitutions use their spelling.
  using MetaValueMap = StringMap<Value *>;
  /// Local instruction values are identified by their IR object, not by the
  /// spelling of their result (which may coincide with a meta variable name).
  using InstrValueMap = DenseMap<const Instruction *, Instruction *>;

  MIRContext &Context;

  Error desugarMetaFlags(Pattern *P);
  Expected<SmallVector<Pattern *, 2>> expandCompositeMatchers(Pattern *P);

  Error inlineBranch(SmallVectorImpl<Instruction *> &BranchInsts,
                     Instruction *&RootInst, Pattern *TargetPattern,
                     Instruction *CompInst, CompositeMatcher *CM,
                     const CompositeMatcher::Branch &Branch,
                     ArrayRef<MatcherOperand> CallerOps);

  Value *substituteValue(Value *V, const MetaValueMap &MetaValues,
                         const InstrValueMap &InstrValues);
  Type *substituteType(Type *Ty, const StringMap<Type *> &TypeMap);
  Constraint *substituteConstraint(Constraint *C,
                                   const MetaValueMap &MetaValues,
                                   const StringMap<Type *> &TypeMap);
  Error lowerMetaFlags(Pattern *TargetPattern, ArrayRef<const MetaFlag *> Flags,
                       Value *Subject,
                       SmallVectorImpl<MetaFlag *> &RemainingFlags);
  Expected<Constraint *> buildMetaFlagConstraint(const MetaFlag *MF,
                                                 Value *OperandVal);

  /// While a branch is being inlined, maps each instruction of the 'match' body
  /// to the copy made for the current expansion. A constraint records the
  /// instruction it follows as the default context for value-tracking
  /// operators, and that context has to name an instruction of the expanded
  /// pattern to be resolvable.
  DenseMap<const Instruction *, Instruction *> InlinedInstructions;

  /// The expansion's copy of Context, or Context itself when it is not an
  /// instruction of the branch being inlined.
  const Instruction *remapContextInstruction(const Instruction *Context) const;
};

} // namespace metaphir
} // namespace llvm

#endif
