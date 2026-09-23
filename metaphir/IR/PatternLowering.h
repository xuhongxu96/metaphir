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
class Type;
class Value;

class PatternLowering {
public:
  PatternLowering(MIRContext &Context) : Context(Context) {}

  Expected<PatternVariants> lower(Pattern *P);

  /// Meta variables are named values, so substitutions use their spelling.
  using MetaValueMap = StringMap<Value *>;
  /// Local instruction values are identified by their IR object pointer, not by
  /// the spelling of their result (which may coincide with a meta variable
  /// name).
  using InstrValueMap = DenseMap<const Instruction *, Instruction *>;
  using TypeMap = StringMap<Type *>;

  /// Pure substitution mapping context.
  struct SubstitutionContext {
    const MetaValueMap &MetaValues;
    const TypeMap &Types;
    const InstrValueMap &InstrValues;

    SubstitutionContext(const MetaValueMap &MetaValues, const TypeMap &Types,
                        const InstrValueMap &InstrValues)
        : MetaValues(MetaValues), Types(Types), InstrValues(InstrValues) {}
  };

  /// Context encapsulating the state of inlining a specific branch of a
  /// composite matcher.
  struct InliningContext {
    Pattern *Cur;
    size_t CompIdx;
    Instruction *CompInst;
    CompositeMatcher *CM;
    const CompositeMatcher::Branch &Branch;
    ArrayRef<MatcherOperand> CallerOps;

    Pattern *Variant;
    MetaValueMap MetaValues;
    TypeMap Types;
    InstrValueMap InlinedInstructions;
    SmallVector<InstructionFlag::FlagID, 4> OmittedFlags;

    InliningContext(Pattern *Cur, size_t CompIdx, CompositeMatcher *CM,
                    const CompositeMatcher::Branch &Branch,
                    ArrayRef<MatcherOperand> CallerOps, Pattern *Variant)
        : Cur(Cur), CompIdx(CompIdx), CompInst(Cur->getInstructions()[CompIdx]),
          CM(CM), Branch(Branch), CallerOps(CallerOps), Variant(Variant) {}

    SubstitutionContext getSubstCtx() const {
      return SubstitutionContext(MetaValues, Types, InlinedInstructions);
    }
  };

  /// Context for desugaring metaflags on instructions and operands.
  struct DesugarContext {
    Pattern *TargetPattern;
    const Instruction *CxtI = nullptr;

    DesugarContext(Pattern *TargetPattern, const Instruction *CxtI = nullptr)
        : TargetPattern(TargetPattern), CxtI(CxtI) {}
  };

private:
  MIRContext &Context;

  // Phase 1: Expand composite matchers into flattened pattern variants.
  Expected<SmallVector<Pattern *, 2>> expandComposites(Pattern *P);
  Error expandPattern(Pattern *Cur, SmallVectorImpl<Pattern *> &Results);
  Expected<Pattern *> inlineBranch(Pattern *Cur, size_t CompIdx,
                                   CompositeMatcher *CM,
                                   const CompositeMatcher::Branch &Branch,
                                   ArrayRef<MatcherOperand> CallerOps);

  bool bindParameters(InliningContext &Ctx);
  bool bindFlags(InliningContext &Ctx);

  Error inlineBranchInstructions(InliningContext &Ctx);
  void rewriteDownstreamInstructions(InliningContext &Ctx);
  void transferConstraints(InliningContext &Ctx);

  // Phase 2: Desugar metaflags into AST constraints on leaf patterns.
  Error desugarMetaFlags(Pattern *P);
  Error lowerMetaFlags(ArrayRef<const MetaFlag *> Flags, Value *Subject,
                       const DesugarContext &Ctx);
  Expected<Constraint *> buildMetaFlagConstraint(const MetaFlag *MF,
                                                 Value *OperandVal,
                                                 const DesugarContext &Ctx);
  Expected<Constraint *> lowerBuiltinLogicalFlag(const MetaFlag *MF,
                                                 Value *Subject,
                                                 const DesugarContext &Ctx);
  Expected<Constraint *> lowerUserDefinedFlag(const MetaFlag *MF,
                                              Value *Subject,
                                              const DesugarContext &Ctx);

  // Phase 3: Pure AST substitution utilities.
  Value *substituteValue(Value *V, const SubstitutionContext &Ctx);
  Type *substituteType(Type *Ty, const SubstitutionContext &Ctx);
  Constraint *substituteConstraint(Constraint *C,
                                   const SubstitutionContext &Ctx);
  const Instruction *
  remapContextInstruction(const Instruction *CxtI,
                          const SubstitutionContext &Ctx) const;
};

} // namespace metaphir
} // namespace llvm

#endif
