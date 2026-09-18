#ifndef METAPHIR_MATCHING_CONSTRAINTCOERCION_H
#define METAPHIR_MATCHING_CONSTRAINTCOERCION_H

#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/ADT/APSInt.h"

namespace llvm {
namespace metaphir {

class Constraint;

namespace detail {

// Integer promotion helpers (the numeric coercion lattice). widen() extends
// both operands to a common bitwidth so that binary arithmetic never overflows
// (the analog of C's usual arithmetic conversions).
APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned);
std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits = 0);
APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth);

// Coercion-class predicates. A value belongs to a class when it can be coerced
// to the corresponding target kind (see Coercions.def). isNumeric() is
// additionally gated on a Value actually being a constant integer, since a
// non-constant Value can never satisfy an integer demand.
bool isNumeric(const ConstraintValue &V);
bool isStringLike(const ConstraintValue &V);
bool isStringArrayLike(const ConstraintValue &V);

// Table-driven coercion dispatch. Converts V into the target kind when an
// admissible coercion exists, and returns a structured error otherwise. The
// admissible conversions are listed in Coercions.def; each destination kind
// owns its acceptance policy in a dedicated converter.
bool canCoerceTo(const ConstraintValue &V, ConstraintValue::ValueKind Target);
Expected<ConstraintValue> coerce(ConstraintValue V,
                                 ConstraintValue::ValueKind Target,
                                 const Constraint &Expression);

// Coercion-aware accessors. They forward evaluation errors, coerce the value
// into the requested representation, and report a structured error when no
// coercion exists.
Expected<bool> requireBoolean(const ConstraintValue &Value,
                              const Constraint &Expression);
inline Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                                     const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  return requireBoolean(*Result, Expression);
}

Expected<APSInt> requireInteger(const ConstraintValue &Value,
                                const Constraint &Expression);
inline Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                       const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  return requireInteger(*Result, Expression);
}

Expected<std::string> requireString(const ConstraintValue &Value,
                                    const Constraint &Expression);
inline Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                           const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  return requireString(*Result, Expression);
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(const ConstraintValue &Value,
                   const Constraint &Expression);
inline Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result,
                   const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  return requireStringArray(*Result, Expression);
}

Expected<const llvm::Value *> requireValue(const ConstraintValue &Value,
                                           const Constraint &Expression);
inline Expected<const llvm::Value *> requireValue(Expected<ConstraintValue> Result,
                                                  const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  return requireValue(*Result, Expression);
}

ConstraintValue integerResult(APInt Value, bool IsUnsigned);

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                const Constraint &Expression);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTCOERCION_H
