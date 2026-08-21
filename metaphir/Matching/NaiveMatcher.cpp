#include "metaphir/Matching/NaiveMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Pattern.h"
#include "llvm/IR/Instruction.h"

namespace llvm {
namespace metaphir {

// SmallVector<const Target *, 4>
// NaiveMatcher::match(const Pattern &Pattern, ArrayRef<const Target *>
// Programs) {
//   SmallVector<const Target *, 4> Results;
//   for (const Target *Program : Programs)
//     if (matchProgram(Pattern, *Program))
//       Results.push_back(Program);
//   return Results;
// }

// bool NaiveMatcher::matchProgram(const Pattern &Pattern, const Target
// &Program) {
//   return !matchInstantiations(Pattern, Program).empty();
// }

MatchResults NaiveMatcher::match(const Pattern &Pattern,
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

MatchResults NaiveMatcher::matchSubgraph(const Value &PatternNode,
                                         const llvm::Value &TargetNode,
                                         Instantiation Bindings) {
  auto RecursiveMatch = [](const Value &Pattern, const llvm::Value &Target,
                           Instantiation State, const MatchDriver &Self) {
    return matchValue(Pattern, Target, std::move(State), Self);
  };
  MatchDriver Driver(RecursiveMatch);
  return Driver.match(PatternNode, TargetNode, std::move(Bindings));
}

} // namespace metaphir
} // namespace llvm
