#include "metaphir/Matching/Operators/CmpPredicates.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/IR/Instructions.h"

namespace llvm {
namespace metaphir {

using namespace detail;

/// The predicate named by the operand, as CmpInst::getPredicateName names it.
static Expected<CmpInst::Predicate> requirePredicate(const ConcreteCall &Call) {
  Expected<std::string> Name = requireString(Call.Operands[0], Call.Expression);
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
  return make_error<ConstraintEvaluationError>(
      Call.Expression, Twine("unknown comparison predicate '") + *Name + "'");
}

/// Applies Test to the operand's predicate.
template <typename PredicateTest>
static Expected<ConstraintValue> testPredicate(const ConcreteCall &Call,
                                               PredicateTest Test) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  return ConstraintValue::getBoolean(Test(*P));
}

/// Maps the operand's predicate with Map, naming the result.
template <typename PredicateMap>
static Expected<ConstraintValue> mapPredicate(const ConcreteCall &Call,
                                              PredicateMap Map) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  return ConstraintValue::getString(CmpInst::getPredicateName(Map(*P)));
}

Expected<ConstraintValue> OpIsEquality::concrete(const ConcreteCall &Call) {
  return testPredicate(
      Call, [](CmpInst::Predicate P) { return CmpInst::isEquality(P); });
}

Expected<ConstraintValue> OpIsSigned::concrete(const ConcreteCall &Call) {
  return testPredicate(
      Call, [](CmpInst::Predicate P) { return CmpInst::isSigned(P); });
}

Expected<ConstraintValue> OpIsUnsigned::concrete(const ConcreteCall &Call) {
  return testPredicate(
      Call, [](CmpInst::Predicate P) { return CmpInst::isUnsigned(P); });
}

// isLT and the like are ICmpInst's, so they are false for FP predicates.

Expected<ConstraintValue> OpIsLT::concrete(const ConcreteCall &Call) {
  return testPredicate(Call,
                       [](CmpInst::Predicate P) { return ICmpInst::isLT(P); });
}

Expected<ConstraintValue> OpIsGT::concrete(const ConcreteCall &Call) {
  return testPredicate(Call,
                       [](CmpInst::Predicate P) { return ICmpInst::isGT(P); });
}

Expected<ConstraintValue> OpIsLE::concrete(const ConcreteCall &Call) {
  return testPredicate(Call,
                       [](CmpInst::Predicate P) { return ICmpInst::isLE(P); });
}

Expected<ConstraintValue> OpIsGE::concrete(const ConcreteCall &Call) {
  return testPredicate(Call,
                       [](CmpInst::Predicate P) { return ICmpInst::isGE(P); });
}

Expected<ConstraintValue>
OpSwappedPredicate::concrete(const ConcreteCall &Call) {
  return mapPredicate(Call, [](CmpInst::Predicate P) {
    return CmpInst::getSwappedPredicate(P);
  });
}

Expected<ConstraintValue>
OpInversePredicate::concrete(const ConcreteCall &Call) {
  return mapPredicate(Call, [](CmpInst::Predicate P) {
    return CmpInst::getInversePredicate(P);
  });
}

Expected<ConstraintValue>
OpStrictPredicate::concrete(const ConcreteCall &Call) {
  return mapPredicate(Call, [](CmpInst::Predicate P) {
    return CmpInst::getStrictPredicate(P);
  });
}

Expected<ConstraintValue>
OpNonStrictPredicate::concrete(const ConcreteCall &Call) {
  return mapPredicate(Call, [](CmpInst::Predicate P) {
    return CmpInst::getNonStrictPredicate(P);
  });
}

// ICmpInst::getFlippedSignednessPredicate takes an integer relational
// predicate; an equality has no signedness, so it is its own flip.
Expected<ConstraintValue>
OpFlippedSignednessPredicate::concrete(const ConcreteCall &Call) {
  Expected<CmpInst::Predicate> P = requirePredicate(Call);
  if (!P)
    return P.takeError();
  if (!CmpInst::isIntPredicate(*P))
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "expected an integer comparison predicate");
  CmpInst::Predicate Flipped =
      ICmpInst::isEquality(*P) ? *P
                               : ICmpInst::getFlippedSignednessPredicate(*P);
  return ConstraintValue::getString(CmpInst::getPredicateName(Flipped));
}

} // namespace metaphir
} // namespace llvm
