#ifndef METAPHIR_MATCHING_CONSTRAINTCOERCION_H
#define METAPHIR_MATCHING_CONSTRAINTCOERCION_H

#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/ADT/APSInt.h"

namespace llvm {
namespace metaphir {

class Constraint;

namespace detail {

APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned);
std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits = 0);
APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth);

bool isNumeric(const ConstraintValue &V);
bool isStringLike(const ConstraintValue &V);
bool isStringArrayLike(const ConstraintValue &V);

Expected<bool> requireBoolean(Expected<ConstraintValue> Result,
                              const Constraint &Expression);
Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression);
Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression);
Expected<ConstraintValue::StringArrayStorage>
requireStringArray(Expected<ConstraintValue> Result,
                   const Constraint &Expression);
Expected<const llvm::Value *> requireValue(Expected<ConstraintValue> Result,
                                           const Constraint &Expression);
ConstraintValue integerResult(APInt Value, bool IsUnsigned);

Expected<bool> evaluateEquality(ConstraintValue Left, ConstraintValue Right,
                                const Constraint &Expression);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTCOERCION_H
