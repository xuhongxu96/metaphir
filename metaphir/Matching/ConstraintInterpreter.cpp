#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/ConcreteDomain.h"
#include "metaphir/Matching/ConstraintEvaluator.h"

namespace llvm {
namespace metaphir {

template class ConstraintEvaluator<ConcreteDomain>;

ConstraintInterpreter::ConstraintInterpreter(MIRContext *Context)
    : Domain(std::make_unique<ConcreteDomain>()),
      Evaluator(std::make_unique<ConstraintEvaluator<ConcreteDomain>>(
          *Domain, Context)) {}

ConstraintInterpreter::~ConstraintInterpreter() = default;

Expected<ConstraintValue>
ConstraintInterpreter::evaluate(const Constraint &Expression,
                                const Instantiation &State) {
  return Evaluator->evaluate(Expression, State);
}

void ConstraintInterpreter::resetAnalyses() { Domain->resetAnalyses(); }

void ConstraintInterpreter::setUseListCompleter(
    std::function<void()> Completer) {
  Domain->setUseListCompleter(std::move(Completer));
}

} // namespace metaphir
} // namespace llvm
