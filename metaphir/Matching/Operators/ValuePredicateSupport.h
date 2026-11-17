#ifndef METAPHIR_MATCHING_OPERATORS_VALUEPREDICATESUPPORT_H
#define METAPHIR_MATCHING_OPERATORS_VALUEPREDICATESUPPORT_H

#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/IR/Value.h"
#include <optional>

namespace llvm {
namespace metaphir {

// What the operators of the constant classes (ConstantClassOps.inc) and the
// hand-written value predicates share.

/// The operand as an LLVM value, if it is one.
inline const llvm::Value *valueOperand(const ConcreteCall &Call) {
  const ConstraintValue &V = Call.Operands[0];
  return V.getKind() == ConstraintValue::Value ? V.getValue() : nullptr;
}

/// A predicate on an integer: an LLVM value is tested with Op::holds, which
/// accepts splats; anything else is coerced to an integer and tested with
/// MatchInteger, which may not apply (std::nullopt). An operand that is not an
/// integer does not satisfy it.
template <class Op, typename IntegerPredicate>
inline ConstraintValue integerPredicate(const ConcreteCall &Call,
                                        IntegerPredicate MatchInteger) {
  if (const llvm::Value *V = valueOperand(Call))
    return ConstraintValue::getBoolean(Op::holds(*V));
  Expected<APSInt> Operand =
      detail::requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand) {
    consumeError(Operand.takeError());
    return ConstraintValue::getBoolean(false);
  }
  std::optional<bool> Matches = MatchInteger(*Operand);
  return ConstraintValue::getBoolean(Matches.value_or(false));
}

/// A predicate that holds only for LLVM values: Op::holds decides it.
template <class Op>
inline ConstraintValue valuePredicate(const ConcreteCall &Call) {
  const llvm::Value *V = valueOperand(Call);
  return ConstraintValue::getBoolean(V && Op::holds(*V));
}

/// Records Op's fact for the value if Op::holds.
template <class Op> inline void recordIfHolds(const RecordCall &Call) {
  if (Op::holds(Call.Value))
    Call.Sink.add(Op::Fact);
}

} // namespace metaphir
} // namespace llvm

#endif
