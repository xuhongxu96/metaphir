#ifndef METAPHIR_MATCHING_NAIVE_MATCHER_H
#define METAPHIR_MATCHING_NAIVE_MATCHER_H

#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/Matchers.h"
#include "metaphir/Matching/Target.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Value;
namespace metaphir {

class Pattern;
class Value;

class NaiveMatcher {
public:
  MatchResults match(const Pattern &Pattern, const Target &Program);

private:
  MatchResults matchSubgraph(const metaphir::Value &PatternNode,
                             const llvm::Value &TargetNode,
                             Instantiation Bindings);
};

} // namespace metaphir
} // namespace llvm

#endif
