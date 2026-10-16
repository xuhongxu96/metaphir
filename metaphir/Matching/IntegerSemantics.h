//===- IntegerSemantics.h - Integers in constraint evaluation ---*- C++ -*-===//
//
// Constraint integers are APSInts that denote mathematical numbers (see
// ConstraintValue). These helpers bring operands to a common width without
// changing their values, and cast to an explicit width.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_MATCHING_INTEGERSEMANTICS_H
#define METAPHIR_MATCHING_INTEGERSEMANTICS_H

#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/ADT/APSInt.h"
#include <utility>

namespace llvm {
namespace metaphir {
namespace detail {

/// Value extended by its own signedness to Width bits, then read as signed
/// or unsigned as IsUnsigned says.
APSInt extend(const APSInt &Value, unsigned Width, bool IsUnsigned);

/// Extends both operands to a common width at which both values fit, plus
/// ExtraBits (so that e.g. an addition cannot overflow). The result is
/// unsigned only if both operands are.
std::pair<APSInt, APSInt> widen(const APSInt &Left, const APSInt &Right,
                                unsigned ExtraBits = 0);

/// Value truncated, or extended by its own signedness, to BitWidth bits:
/// the modular arithmetic an explicit bitwidth argument asks for.
APSInt castToBitWidth(const APSInt &Value, unsigned BitWidth);

/// An integer constraint value.
ConstraintValue integerResult(APInt Value, bool IsUnsigned);

/// Value read as a comparison with the signedness of IsUnsigned reads it: a
/// bit pattern (Modular) as signed or unsigned, a number as itself.
APSInt readForComparison(const APSInt &Value, bool Modular, bool IsUnsigned);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_INTEGERSEMANTICS_H
