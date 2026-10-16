#ifndef METAPHIR_MATCHING_PATTERN_MATCHER_H
#define METAPHIR_MATCHING_PATTERN_MATCHER_H

#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/Target.h"
#include <string>

namespace llvm {
namespace metaphir {

class Constraint;
class FeatureQuery;
class MIRContext;
class Pattern;
class PatternVariants;

/// A constraint that rejected a structural match.
struct UnsatisfiedConstraint {
  const Constraint *Expression;
  /// Why the constraint could not be evaluated; empty if it was false.
  std::string Reason;
  /// The first structural match it rejected.
  Instantiation Rejected;
};

/// Searches a function for the instantiations of a lowered pattern: matches
/// the pattern's roots against every instruction, threads candidate
/// instantiations across roots, and keeps those satisfying the constraints.
class PatternMatcher {
public:
  /// Context holds the 'constraint' definitions the patterns call.
  explicit PatternMatcher(MIRContext *Context = nullptr)
      : Interpreter(Context) {}

  /// See ConstraintInterpreter::setUseOracle.
  void setUseOracle(UseOracle *Oracle) { Interpreter.setUseOracle(Oracle); }

  /// The instantiations of Pattern's instructions in Program, before its
  /// constraints are checked.
  MatchResults matchStructure(const Pattern &Pattern, const Target &Program);

  /// The instantiations of Pattern that satisfy its constraints. Constraints
  /// that rejected a structural match are added to Unsatisfied.
  MatchResults
  match(const Pattern &Pattern, const Target &Program,
        SmallVectorImpl<UnsatisfiedConstraint> *Unsatisfied = nullptr);

  /// The matches of any of Variants, each reported once. If there are none,
  /// the constraints that rejected structural matches are added to
  /// Unsatisfied; HadStructuralMatch tells whether there were any.
  /// Filter, computed from Variants, skips the variants Program lacks the
  /// features for; the results are the same without it. When Unsatisfied or
  /// HadStructuralMatch is asked for, only the variants' instructions are
  /// checked, so structural matches are still found.
  MatchResults
  match(const PatternVariants &Variants, const Target &Program,
        SmallVectorImpl<UnsatisfiedConstraint> *Unsatisfied = nullptr,
        bool *HadStructuralMatch = nullptr,
        const FeatureQuery *Filter = nullptr);

private:
  /// Keeps the matches that satisfy Pattern's constraints.
  MatchResults applyConstraints(const Pattern &Pattern, MatchResults Matches,
                                SmallVectorImpl<UnsatisfiedConstraint> &Failed);

  ConstraintInterpreter Interpreter;
};

} // namespace metaphir
} // namespace llvm

#endif
