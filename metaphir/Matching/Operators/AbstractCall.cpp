#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Features.h"
#include "llvm/ADT/bit.h"

namespace llvm {
namespace metaphir {

/// Whether some position of the site satisfies Holds.
template <typename Predicate>
static bool anyPosition(const Site &S, Predicate Holds) {
  for (unsigned Positions = S.Positions; Positions; Positions &= Positions - 1)
    if (Holds(S.ID, unsigned(llvm::countr_zero(Positions))))
      return true;
  return false;
}

AbstractValue lacksFact(const AbstractCall &Call, unsigned OperandIndex,
                        Atom A) {
  const AbstractValue &V = Call.Operands[OperandIndex];
  if (!V.isSites())
    return AbstractValue::unknown();
  for (const Site &S : V.getSites())
    if (!anyPosition(S, [&](instruction::InstructionID ID, unsigned Position) {
          return Call.Features.hasFact(ID, Position, A);
        }))
      return AbstractValue::concrete(ConstraintValue::getBoolean(false));
  return AbstractValue::unknown();
}

/// The sites of Operands[OperandIndex] that value tracking was anchored at
/// for the call's context, if its facts were recorded.
static std::optional<SmallVector<Site, 2>>
contextSites(const AbstractCall &Call, unsigned OperandIndex) {
  const AbstractValue &V = Call.Operands[OperandIndex];
  if (!V.isSites() || Call.Context < 0 || !Call.Features.HasValueFacts)
    return std::nullopt;
  SmallVector<Site, 2> Anchored;
  for (const Site &S : V.getSites())
    if (S.Node == Call.Context)
      Anchored.push_back(S);
  return Anchored;
}

/// Whether value tracking was skipped for some value at the position.
static bool skipped(const AbstractCall &Call, instruction::InstructionID ID,
                    unsigned Position) {
  return Call.Features.hasFact(ID, Position, fact::ValueTrackingSkipped);
}

AbstractValue lacksValueFact(const AbstractCall &Call, unsigned OperandIndex,
                             Atom A) {
  std::optional<SmallVector<Site, 2>> Anchored =
      contextSites(Call, OperandIndex);
  if (!Anchored)
    return AbstractValue::unknown();
  for (const Site &S : *Anchored)
    if (!anyPosition(S, [&](instruction::InstructionID ID, unsigned Position) {
          return skipped(Call, ID, Position) ||
                 Call.Features.hasFact(ID, Position, A);
        }))
      return AbstractValue::concrete(ConstraintValue::getBoolean(false));
  return AbstractValue::unknown();
}

AbstractValue exceedsMeasure(const AbstractCall &Call, unsigned OperandIndex,
                             Measure M, unsigned Bound) {
  std::optional<SmallVector<Site, 2>> Anchored =
      contextSites(Call, OperandIndex);
  if (!Anchored)
    return AbstractValue::unknown();
  // Recorded measures are capped at MaxMeasure, so a most measure at the cap
  // may reach any bound, and a least one never falls below its value.
  auto Within = [&](unsigned Recorded) {
    switch (getMeasureOrder(M)) {
    case MeasureOrder::Most:
      return Recorded >= std::min(Bound, MaxMeasure);
    case MeasureOrder::Least:
      return Recorded <= Bound;
    }
    llvm_unreachable("invalid measure order");
  };
  for (const Site &S : *Anchored)
    if (!anyPosition(S, [&](instruction::InstructionID ID, unsigned Position) {
          if (skipped(Call, ID, Position))
            return true;
          std::optional<unsigned> Recorded =
              Call.Features.getMeasure(ID, Position, M);
          return Recorded && Within(*Recorded);
        }))
      return AbstractValue::concrete(ConstraintValue::getBoolean(false));
  return AbstractValue::unknown();
}

} // namespace metaphir
} // namespace llvm
