#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
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
  for (Instantiation &Candidate : Instantiations) {
    for (const auto &[Var, Val] : Pattern.getFixedFlags())
      Candidate.bind(*Var, Val);
    Candidate.requireComplete(Pattern);
  }
  return Instantiations;
}

MatchResults PatternMatcher::match(const PatternVariants &Variants,
                                   const Target &Program) {
  MatchResults Combined;
  for (const Pattern *Variant : Variants) {
    MatchResults Res = match(*Variant, Program);
    Combined.append(Res.begin(), Res.end());
  }
  return Combined;
}

MatchResults PatternMatcher::matchSubgraph(const Value &PatternNode,
                                           const llvm::Value &TargetNode,
                                           Instantiation Bindings) {
  return SubtreeMatcher(PatternNode, TargetNode, std::move(Bindings)).match();
}

} // namespace metaphir
} // namespace llvm
