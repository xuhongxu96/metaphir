#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/FeatureQuery.h"
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
  auto Record = [&Failed](const Constraint *Expression, std::string Reason,
                          const Instantiation &Rejected) {
    if (none_of(Failed, [&](const UnsatisfiedConstraint &U) {
          return U.Expression == Expression;
        }))
      Failed.push_back({Expression, std::move(Reason), Rejected});
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
      // A constraint that cannot be evaluated for this binding (e.g.
      // arithmetic on a non-constant value) rejects it, and the remaining
      // constraints are not evaluated. Once another constraint is false, it
      // is not reported: the binding it cannot handle was rejected already.
      if (!Holds) {
        std::string Reason = "constraint could not be evaluated";
        handleAllErrors(
            Holds.takeError(),
            [&](const detail::ConstraintEvaluationError &E) {
              Reason = E.Message;
            },
            [&](const ErrorInfoBase &E) { Reason = E.message(); });
        if (Satisfies)
          Record(Expression, std::move(Reason), Match);
        Satisfies = false;
        break;
      }
      if (!*Holds) {
        Record(Expression, "", Match);
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

/// Whether A and B are copies of one constraint of the pattern, as lowering
/// makes for its variants: they come from the same source text.
static bool isSameConstraint(const Constraint &A, const Constraint &B) {
  SourceRange RA = A.getSourceRange(), RB = B.getSourceRange();
  if (&A == &B)
    return true;
  return RA.Begin.isValid() && RA.Begin == RB.Begin && RA.End == RB.End;
}

MatchResults
PatternMatcher::match(const PatternVariants &Variants, const Target &Program,
                      SmallVectorImpl<UnsatisfiedConstraint> *Unsatisfied,
                      bool *HadStructuralMatch, const FeatureQuery *Filter) {
  assert((!Filter || Filter->size() == Variants.size()) &&
         "filter computed from other variants");
  // Analyses cached for an earlier target may belong to a freed function.
  Interpreter.resetAnalyses();
  MatchResults Combined;
  for (auto [Index, Variant] : enumerate(Variants)) {
    // Without the features, the variant has no structural match.
    // A variant whose constraints cannot hold has no matches, but its
    // structural matches are reported when asked for.
    if (Filter &&
        !(Unsatisfied || HadStructuralMatch
              ? Filter->mayMatchStructure(Index, Program.getFeatures())
              : Filter->mayMatchVariant(Index, Program.getFeatures())))
      continue;
    MatchResults Structural = matchStructure(*Variant, Program);
    if (!Structural.empty() && HadStructuralMatch)
      *HadStructuralMatch = true;
    SmallVector<UnsatisfiedConstraint, 4> Failed;
    MatchResults Matches =
        applyConstraints(*Variant, std::move(Structural), Failed);
    // Variants for the operand orders of a ':c' use can find the same match.
    appendUnique(Combined, std::move(Matches));
    // A constraint is copied into each variant (each ':c' order, each
    // branch of a composite matcher), and reported once.
    if (Combined.empty() && Unsatisfied)
      for (UnsatisfiedConstraint &U : Failed)
        if (none_of(*Unsatisfied, [&](const UnsatisfiedConstraint &Known) {
              return isSameConstraint(*Known.Expression, *U.Expression);
            }))
          Unsatisfied->push_back(std::move(U));
  }
  return Combined;
}

} // namespace metaphir
} // namespace llvm
