#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/SubtreeMatcher.h"
#include "llvm/IR/Instruction.h"

namespace llvm {
namespace metaphir {

MatchResults PatternMatcher::matchStructure(const Pattern &Pattern,
                                            const Target &Program) {
  MatchResults Instantiations(1);
  for (const Instruction *Root : Pattern.getRoots()) {
    MatchResults NewInstantiations;
    for (const Instantiation &Candidate : Instantiations)
      for (const llvm::Instruction *Instruction : Program.getInstructions())
        for (Instantiation &Matched :
             SubtreeMatcher(*Root, *Instruction, Candidate).match())
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

MatchResults PatternMatcher::applyConstraints(
    const Pattern &Pattern, MatchResults Matches,
    SmallVectorImpl<UnsatisfiedConstraint> &Failed) {
  auto Record = [&Failed](const Constraint *Expression, std::string Reason) {
    if (none_of(Failed, [&](const UnsatisfiedConstraint &U) {
          return U.Expression == Expression;
        }))
      Failed.push_back({Expression, std::move(Reason)});
  };

  MatchResults Filtered;
  for (Instantiation &Match : Matches) {
    bool Satisfies = true;
    for (const Constraint *Expression : Pattern.getConstraints()) {
      Expected<ConstraintValue> Result =
          Interpreter.evaluate(*Expression, Match);
      Expected<bool> Holds = Result
                                 ? detail::requireBoolean(*Result, *Expression)
                                 : Expected<bool>(Result.takeError());
      if (!Holds) {
        // A constraint that cannot be evaluated for this binding (e.g.
        // arithmetic on a non-constant value) rejects it, and the remaining
        // constraints are not evaluated.
        std::string Reason = "constraint could not be evaluated";
        handleAllErrors(
            Holds.takeError(),
            [&](const detail::ConstraintEvaluationError &E) {
              Reason = E.Message;
            },
            [&](const ErrorInfoBase &E) { Reason = E.message(); });
        Record(Expression, std::move(Reason));
        Satisfies = false;
        break;
      }
      if (!*Holds) {
        Record(Expression, "");
        Satisfies = false;
      }
    }
    if (Satisfies)
      Filtered.push_back(std::move(Match));
  }
  return Filtered;
}

MatchResults
PatternMatcher::match(const Pattern &Pattern, const Target &Program,
                      SmallVectorImpl<UnsatisfiedConstraint> *Unsatisfied) {
  // Analyses cached for an earlier target may belong to a freed function.
  Interpreter.resetAnalyses();
  SmallVector<UnsatisfiedConstraint, 4> Failed;
  MatchResults Matches =
      applyConstraints(Pattern, matchStructure(Pattern, Program), Failed);
  if (Unsatisfied)
    Unsatisfied->append(Failed.begin(), Failed.end());
  return Matches;
}

MatchResults
PatternMatcher::match(const PatternVariants &Variants, const Target &Program,
                      SmallVectorImpl<UnsatisfiedConstraint> *Unsatisfied,
                      bool *HadStructuralMatch) {
  // Analyses cached for an earlier target may belong to a freed function.
  Interpreter.resetAnalyses();
  MatchResults Combined;
  for (const Pattern *Variant : Variants) {
    MatchResults Structural = matchStructure(*Variant, Program);
    if (!Structural.empty() && HadStructuralMatch)
      *HadStructuralMatch = true;
    SmallVector<UnsatisfiedConstraint, 4> Failed;
    MatchResults Matches =
        applyConstraints(*Variant, std::move(Structural), Failed);
    // Variants for the operand orders of a ':c' use can find the same match.
    appendUnique(Combined, std::move(Matches));
    if (Combined.empty() && Unsatisfied)
      Unsatisfied->append(Failed.begin(), Failed.end());
  }
  return Combined;
}

} // namespace metaphir
} // namespace llvm
