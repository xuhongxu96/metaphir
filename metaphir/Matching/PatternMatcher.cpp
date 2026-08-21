#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Matching/SubtreeMatcher.h"
#include "llvm/IR/Instruction.h"

namespace llvm {
namespace metaphir {

MatchResults PatternMatcher::match(const Pattern &Pattern,
                                   const Target &Program) {
  MatchResults Instantiations(1);

  for (const Instruction *Root : Pattern.getRoots()) {
    MatchResults NewInstantiations;
    for (const Instantiation &Candidate : Instantiations)
      for (const llvm::Instruction *Instruction : Program.getInstructions())
        for (Instantiation &Matched :
             matchSubgraph(*Root, *Instruction, Candidate))
          NewInstantiations.push_back(std::move(Matched));
    Instantiations = std::move(NewInstantiations);
    if (Instantiations.empty())
      return {};
  }
  for (const Instantiation &Candidate : Instantiations)
    Candidate.requireComplete(Pattern);
  return Instantiations;
}

MatchResults PatternMatcher::matchSubgraph(const Value &PatternNode,
                                           const llvm::Value &TargetNode,
                                           Instantiation Bindings) {
  return SubtreeMatcher(PatternNode, TargetNode, std::move(Bindings)).match();
}

} // namespace metaphir
} // namespace llvm
