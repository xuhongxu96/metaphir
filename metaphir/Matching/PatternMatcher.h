#ifndef METAPHIR_MATCHING_PATTERN_MATCHER_H
#define METAPHIR_MATCHING_PATTERN_MATCHER_H

#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/Target.h"

namespace llvm {
class Value;
namespace metaphir {

class Pattern;
class PatternVariants;
class Value;

// Searches a whole target (program) for all instantiations of a MetaphIR
// pattern: iterates the pattern's roots against every instruction in the
// program, threads candidate instantiations across roots, and enforces that
// every root is instantiated (completeness).
class PatternMatcher {
public:
  MatchResults match(const Pattern &Pattern, const Target &Program);
  MatchResults match(const PatternVariants &Variants, const Target &Program);

private:
  MatchResults matchSubgraph(const Value &PatternNode,
                             const llvm::Value &TargetNode,
                             Instantiation Bindings);
};

} // namespace metaphir
} // namespace llvm

#endif
