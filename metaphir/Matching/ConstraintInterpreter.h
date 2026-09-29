#ifndef METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H
#define METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H

#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/Support/Error.h"
#include <functional>
#include <memory>

namespace llvm {
class Value;
namespace metaphir {

class ConcreteDomain;
class Constraint;
class Instantiation;
class MIRContext;
template <class Domain> class ConstraintEvaluator;

/// Evaluates constraints on the IR, for the instantiations of a match.
class ConstraintInterpreter {
public:
  /// Context holds the 'constraint' definitions that calls refer to; without
  /// one, only built-in operations can be evaluated.
  explicit ConstraintInterpreter(MIRContext *Context = nullptr);
  ~ConstraintInterpreter();

  Expected<ConstraintValue> evaluate(const Constraint &Expression,
                                     const Instantiation &State);

  /// Drops the analyses cached for value-tracking operators. Call it before
  /// the functions they were built for are freed.
  void resetAnalyses();

  /// Sets what makes the use lists of constants complete, for a module whose
  /// functions are not all materialized: uses of a global or constant
  /// expression can be in any function.
  void setUseListCompleter(std::function<void()> Completer);

private:
  std::unique_ptr<ConcreteDomain> Domain;
  std::unique_ptr<ConstraintEvaluator<ConcreteDomain>> Evaluator;
};

} // namespace metaphir
} // namespace llvm

#endif
