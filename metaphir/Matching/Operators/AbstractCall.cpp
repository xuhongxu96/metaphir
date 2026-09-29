#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Features.h"
#include "llvm/ADT/bit.h"

namespace llvm {
namespace metaphir {

/// Whether some slot of the site satisfies Holds.
template <typename Predicate>
static bool anySlot(const Site &S, Predicate Holds) {
  for (unsigned Slots = S.Slots; Slots; Slots &= Slots - 1)
    if (Holds(S.Parent->getInstructionID(), unsigned(llvm::countr_zero(Slots))))
      return true;
  return false;
}

AbstractValue lacksFact(const AbstractCall &Call, unsigned OperandIndex,
                        Atom A) {
  const AbstractValue &V = Call.Operands[OperandIndex];
  if (!V.isSites())
    return AbstractValue::unknown();
  for (const Site &S : V.getSites())
    if (!anySlot(S, [&](Instruction::InstructionID ID, unsigned Slot) {
          return Call.Features.hasFact(ID, Slot, A);
        }))
      return AbstractValue::concrete(ConstraintValue::getBoolean(false));
  return AbstractValue::unknown();
}

/// The sites of Operands[OperandIndex] that value tracking was anchored at
/// for the call's context, if its facts were recorded.
static std::optional<SmallVector<Site, 2>>
contextSites(const AbstractCall &Call, unsigned OperandIndex) {
  const AbstractValue &V = Call.Operands[OperandIndex];
  if (!V.isSites() || !Call.Context || !Call.Features.HasValueFacts)
    return std::nullopt;
  SmallVector<Site, 2> Anchored;
  for (const Site &S : V.getSites())
    if (S.Parent == Call.Context)
      Anchored.push_back(S);
  return Anchored;
}

/// Whether value tracking was skipped for some value in the slot.
static bool skipped(const AbstractCall &Call, Instruction::InstructionID ID,
                    unsigned Slot) {
  return Call.Features.hasFact(ID, Slot, Atom::ValueTrackingSkipped);
}

AbstractValue lacksValueFact(const AbstractCall &Call, unsigned OperandIndex,
                             Atom A) {
  std::optional<SmallVector<Site, 2>> Anchored =
      contextSites(Call, OperandIndex);
  if (!Anchored)
    return AbstractValue::unknown();
  for (const Site &S : *Anchored)
    if (!anySlot(S, [&](Instruction::InstructionID ID, unsigned Slot) {
          return skipped(Call, ID, Slot) || Call.Features.hasFact(ID, Slot, A);
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
    return isMaximum(M) ? Recorded >= std::min(Bound, MaxMeasure)
                        : Recorded <= Bound;
  };
  for (const Site &S : *Anchored)
    if (!anySlot(S, [&](Instruction::InstructionID ID, unsigned Slot) {
          if (skipped(Call, ID, Slot))
            return true;
          std::optional<unsigned> Recorded =
              Call.Features.getMeasure(ID, Slot, M);
          return Recorded && Within(*Recorded);
        }))
      return AbstractValue::concrete(ConstraintValue::getBoolean(false));
  return AbstractValue::unknown();
}

} // namespace metaphir
} // namespace llvm
