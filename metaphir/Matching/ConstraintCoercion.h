#ifndef METAPHIR_MATCHING_CONSTRAINTCOERCION_H
#define METAPHIR_MATCHING_CONSTRAINTCOERCION_H

#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/IntegerSemantics.h"
#include "llvm/ADT/APSInt.h"

namespace llvm {
namespace metaphir {

namespace detail {

// Coercion-class predicates. A value belongs to a class when it can be coerced
// to the corresponding target kind (see IR/Constraint/ConstraintCoercions.td).
// isNumeric() is additionally gated on a Value actually being a constant
// integer, since a non-constant Value can never satisfy an integer demand.
bool isNumeric(const ConstraintValue &V);
bool isStringLike(const ConstraintValue &V);
bool isStringArrayLike(const ConstraintValue &V);

// Table-driven coercion dispatch. Converts V into the target kind when an
// admissible coercion exists, and returns a structured error otherwise. The
// admissible conversions are listed in IR/Constraint/ConstraintCoercions.td; each
// destination kind owns its acceptance policy in a dedicated converter.
bool canCoerceTo(const ConstraintValue &V, ConstraintValue::ValueKind Target);
Expected<ConstraintValue> coerce(ConstraintValue V,
                                 ConstraintValue::ValueKind Target,
                                 mlir::Value Expression);

// Coercion-aware accessors. They forward evaluation errors, coerce the value
// into the requested representation, and report a structured error when no
// coercion exists.
Expected<bool> requireBoolean(const ConstraintValue &Value,
                              mlir::Value Expression);
inline Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                                     mlir::Value Expression) {
  if (!Result)
    return Result.takeError();
  return requireBoolean(*Result, Expression);
}

Expected<APSInt> requireInteger(const ConstraintValue &Value,
                                mlir::Value Expression);
inline Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                       mlir::Value Expression) {
  if (!Result)
    return Result.takeError();
  return requireInteger(*Result, Expression);
}

Expected<std::string> requireString(const ConstraintValue &Value,
                                    mlir::Value Expression);
inline Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                           mlir::Value Expression) {
  if (!Result)
    return Result.takeError();
  return requireString(*Result, Expression);
}

Expected<ConstraintValue::StringArrayStorage>
requireStringArray(const ConstraintValue &Value, mlir::Value Expression);
inline Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result, mlir::Value Expression) {
  if (!Result)
    return Result.takeError();
  return requireStringArray(*Result, Expression);
}

Expected<const llvm::Value *> requireValue(const ConstraintValue &Value,
                                           mlir::Value Expression);
inline Expected<const llvm::Value *>
requireValue(Expected<ConstraintValue> Result, mlir::Value Expression) {
  if (!Result)
    return Result.takeError();
  return requireValue(*Result, Expression);
}

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                mlir::Value Expression);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTCOERCION_H
