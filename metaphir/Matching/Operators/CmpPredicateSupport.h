#ifndef METAPHIR_MATCHING_OPERATORS_CMPPREDICATESUPPORT_H
#define METAPHIR_MATCHING_OPERATORS_CMPPREDICATESUPPORT_H

#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// What the operators on comparison predicates share.

/// The predicate named by the operand, as CmpInst::getPredicateName names it.
inline Expected<CmpInst::Predicate> requirePredicate(const ConcreteCall &Call) {
  Expected<std::string> Name =
      detail::requireString(Call.Operands[0], Call.Expression);
  if (!Name)
    return Name.takeError();
  auto Named = [&](unsigned First,
                   unsigned Last) -> std::optional<CmpInst::Predicate> {
    for (unsigned P = First; P <= Last; ++P)
      if (CmpInst::getPredicateName(CmpInst::Predicate(P)) == *Name)
        return CmpInst::Predicate(P);
    return std::nullopt;
  };
  if (std::optional<CmpInst::Predicate> P =
          Named(CmpInst::FIRST_ICMP_PREDICATE, CmpInst::LAST_ICMP_PREDICATE))
    return *P;
  if (std::optional<CmpInst::Predicate> P =
          Named(CmpInst::FIRST_FCMP_PREDICATE, CmpInst::LAST_FCMP_PREDICATE))
    return *P;
  return make_error<detail::ConstraintEvaluationError>(
      Call.Expression, Twine("unknown comparison predicate '") + *Name + "'");
}

/// Applies Test to the operand's predicate.
template <typename PredicateTest>
inline Expected<ConstraintValue> testPredicate(const ConcreteCall &Call,
                                               PredicateTest Test) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  return ConstraintValue::getBoolean(Test(*P));
}

/// Maps the operand's predicate with Map, naming the result.
template <typename PredicateMap>
inline Expected<ConstraintValue> mapPredicate(const ConcreteCall &Call,
                                              PredicateMap Map) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  return ConstraintValue::getString(CmpInst::getPredicateName(Map(*P)));
}

} // namespace metaphir
} // namespace llvm

#endif
