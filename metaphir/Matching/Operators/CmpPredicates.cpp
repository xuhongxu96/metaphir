#include "metaphir/Matching/Operators/CmpPredicates.h"
#include "metaphir/Matching/Operators/CmpPredicateSupport.h"

namespace llvm {
namespace metaphir {

// ICmpInst::getFlippedSignednessPredicate takes an integer relational
// predicate; an equality has no signedness, so it is its own flip.
Expected<ConstraintValue>
OpFlippedSignednessPredicate::concrete(const ConcreteCall &Call) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  if (!CmpInst::isIntPredicate(*P))
    return make_error<detail::ConstraintEvaluationError>(
        Call.Expression, "expected an integer comparison predicate");
  CmpInst::Predicate Flipped =
      ICmpInst::isEquality(*P) ? *P
                               : ICmpInst::getFlippedSignednessPredicate(*P);
  return ConstraintValue::getString(CmpInst::getPredicateName(Flipped));
}

} // namespace metaphir
} // namespace llvm
