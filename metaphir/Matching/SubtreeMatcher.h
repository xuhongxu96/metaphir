#ifndef METAPHIR_MATCHING_SUBTREE_MATCHER_H
#define METAPHIR_MATCHING_SUBTREE_MATCHER_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/TypeMatcher.h"

namespace llvm {
class Value;
namespace metaphir {

class AggregateConstant;
class Value;

// Matches a MetaphIR value matcher (constants, meta variables, and
// instructions) against a single concrete LLVM value, recursively producing the
// set of valid instantiations.
class SubtreeMatcher {
public:
  SubtreeMatcher(const Value &Matcher, const llvm::Value &Target,
                 Instantiation State)
      : Matcher(Matcher), Target(Target), State(std::move(State)) {}

  SubtreeMatcher(const SubtreeMatcher &) = delete;
  SubtreeMatcher(SubtreeMatcher &&) = delete;

  MatchResults match();

private:
  std::optional<Instantiation::Binding>
  getMetaVariableBinding(const MetaVariable &Matcher);

  std::optional<Instantiation::Binding> getTargetBinding();

  MatchResults matchAggregate(const AggregateConstant &Matcher);

  const Value &Matcher;
  const llvm::Value &Target;
  Instantiation State;
};

} // namespace metaphir
} // namespace llvm

#endif
