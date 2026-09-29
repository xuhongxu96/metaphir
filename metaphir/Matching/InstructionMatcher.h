#ifndef METAPHIR_MATCHING_INSTRUCTION_MATCHER_H
#define METAPHIR_MATCHING_INSTRUCTION_MATCHER_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/TypeMatcher.h"

namespace llvm {
class Value;
namespace metaphir {

// Matches a single MetaphIR instruction matcher against a concrete LLVM value.
class InstructionMatcher {
public:
  InstructionMatcher(const Instruction &Matcher, const llvm::Value &Target,
                     Instantiation State)
      : Matcher(Matcher), Target(Target), State(std::move(State)),
        Settings(Matcher.getSettings()) {}

  InstructionMatcher(const InstructionMatcher &) = delete;
  InstructionMatcher(InstructionMatcher &&) = delete;

  MatchResults match();

private:
  MatchResults matchOrSelf(unsigned OperandIndex);

  bool matchInstructionTarget();

  const llvm::Type &getTypeOnlyOperandTarget();

  bool matchTypeOnlyOperands();
  bool matchSemanticFlags();
  bool matchKeyedOperands();
  bool matchPredicate();

  std::optional<APSInt>
  getKeyedIntegerTarget(MatcherOperand::KeyedOperandKind Kind);

  bool matchIntegerKeyedOperand(const MatcherOperand &Matcher,
                                const APSInt &Target);

  MatchResults matchValueOperand(const MatcherOperand &Operand,
                                 const llvm::Value &Target,
                                 Instantiation State);
  MatchResults matchOperandOrder(ArrayRef<unsigned> Order, Instantiation State);

  const Instruction &Matcher;
  const llvm::Value &Target;
  Instantiation State;
  PatternSettings Settings;

  SmallVector<MatcherOperand, 4> PatternOperands;

  const llvm::Instruction *TargetInstruction = nullptr;

  SmallVector<const llvm::Value *, 4> TargetOperands;
};

} // namespace metaphir
} // namespace llvm

#endif
