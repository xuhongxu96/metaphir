#include "metaphir/Matching/Operators/ValueTracking.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Analysis/WithCache.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/DerivedTypes.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

using namespace detail;

/// Value with an integer (or vector-of-integer) type, as required by the
/// integer value-tracking queries.
static Expected<const llvm::Value *>
requireIntegerValue(const ConstraintValue &Value,
                    const Constraint &Expression) {
  Expected<const llvm::Value *> Val = requireValue(Value, Expression);
  if (!Val)
    return Val.takeError();
  if ((*Val)->getType()->getScalarType()->isIntegerTy())
    return Val;
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-typed value operand");
}

/// Value with a floating-point (or vector-of-FP) type, as required by the
/// floating-point value-tracking queries.
static Expected<const llvm::Value *>
requireFPValue(const ConstraintValue &Value, const Constraint &Expression) {
  Expected<const llvm::Value *> Val = requireValue(Value, Expression);
  if (!Val)
    return Val.takeError();
  if ((*Val)->getType()->isFPOrFPVectorTy())
    return Val;
  return make_error<ConstraintEvaluationError>(
      Expression, "expected a floating-point value operand");
}

static unsigned integerElementWidth(const llvm::Value &Value) {
  return Value.getType()->getScalarSizeInBits();
}

static const SimplifyQuery &query(const ConcreteCall &Call) {
  assert(Call.Query && "value-tracking operator without a query");
  return *Call.Query;
}

static const SimplifyQuery &query(const RecordCall &Call) {
  assert(Call.Query && "recording value tracking without a query");
  return *Call.Query;
}

Expected<ConstraintValue> OpNoOverflow::concrete(const ConcreteCall &Call) {
  Expected<std::string> Kind = requireString(Call.Operands[0], Call.Expression);
  if (!Kind)
    return Kind.takeError();
  Expected<const llvm::Value *> LHS =
      requireIntegerValue(Call.Operands[1], Call.Expression);
  if (!LHS)
    return LHS.takeError();
  Expected<const llvm::Value *> RHS =
      requireIntegerValue(Call.Operands[2], Call.Expression);
  if (!RHS)
    return RHS.takeError();

  const SimplifyQuery &Query = query(Call);
  OverflowResult Result;
  if (*Kind == "umul")
    Result = computeOverflowForUnsignedMul(*LHS, *RHS, Query);
  else if (*Kind == "smul")
    Result = computeOverflowForSignedMul(*LHS, *RHS, Query);
  else if (*Kind == "uadd")
    Result = computeOverflowForUnsignedAdd(WithCache<const llvm::Value *>(*LHS),
                                           WithCache<const llvm::Value *>(*RHS),
                                           Query);
  else if (*Kind == "sadd")
    Result = computeOverflowForSignedAdd(WithCache<const llvm::Value *>(*LHS),
                                         WithCache<const llvm::Value *>(*RHS),
                                         Query);
  else if (*Kind == "usub")
    Result = computeOverflowForUnsignedSub(*LHS, *RHS, Query);
  else if (*Kind == "ssub")
    Result = computeOverflowForSignedSub(*LHS, *RHS, Query);
  else
    return make_error<ConstraintEvaluationError>(
        Call.Expression, Twine("unknown overflow kind '") + *Kind + "'");
  return ConstraintValue::getBoolean(Result == OverflowResult::NeverOverflows);
}

Expected<ConstraintValue> OpKnownBits::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getKnownBits(computeKnownBits(*Value, query(Call)));
}

/// The known zero (or one) bits of a knownBits(...) result, as an integer.
static Expected<ConstraintValue> knownBitsMask(const ConcreteCall &Call,
                                               bool Ones) {
  if (Call.Operands[0].getKind() != ConstraintValue::BitVector)
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "expected a bit-vector operand");
  const KnownBits &Known = Call.Operands[0].getKnownBits();
  return integerResult(Ones ? Known.One : Known.Zero, true);
}

Expected<ConstraintValue> OpKnownZeros::concrete(const ConcreteCall &Call) {
  return knownBitsMask(Call, /*Ones=*/false);
}

Expected<ConstraintValue> OpKnownOnes::concrete(const ConcreteCall &Call) {
  return knownBitsMask(Call, /*Ones=*/true);
}

Expected<ConstraintValue> OpIsKnownNonZero::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNonZero(*Value, query(Call)));
}

void OpIsKnownNonZero::record(const RecordCall &Call) {
  if (isKnownNonZero(&Call.Value, query(Call)))
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpIsKnownNegative::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNegative(*Value, query(Call)));
}

void OpIsKnownNegative::record(const RecordCall &Call) {
  // isKnownNegative is computeKnownBits(...).isNegative().
  if (Call.Value.getType()->isIntOrIntVectorTy() &&
      Call.knownBits().isNegative())
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpIsGuaranteedNotToBeUndef::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  const SimplifyQuery &Query = query(Call);
  return ConstraintValue::getBoolean(
      isGuaranteedNotToBeUndef(*Value, Query.AC, Query.CxtI, Query.DT));
}

Expected<ConstraintValue>
OpIsGuaranteedNotToBePoison::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  const SimplifyQuery &Query = query(Call);
  return ConstraintValue::getBoolean(
      isGuaranteedNotToBePoison(*Value, Query.AC, Query.CxtI, Query.DT));
}

Expected<ConstraintValue>
OpIsGuaranteedNotToBeUndefOrPoison::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  const SimplifyQuery &Query = query(Call);
  return ConstraintValue::getBoolean(
      isGuaranteedNotToBeUndefOrPoison(*Value, Query.AC, Query.CxtI, Query.DT));
}

Expected<ConstraintValue>
OpIsKnownNonNegative::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNonNegative(*Value, query(Call)));
}

void OpIsKnownNonNegative::record(const RecordCall &Call) {
  // isKnownNonNegative is computeKnownBits(...).isNonNegative().
  if (Call.Value.getType()->isIntOrIntVectorTy() &&
      Call.knownBits().isNonNegative())
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpIsKnownPositive::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownPositive(*Value, query(Call)));
}

void OpIsKnownPositive::record(const RecordCall &Call) {
  if (Call.Value.getType()->isIntOrIntVectorTy() &&
      isKnownPositive(&Call.Value, query(Call)))
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpIsKnownPowerOfTwo::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(
      isKnownToBeAPowerOfTwo(*Value, /*OrZero=*/false, query(Call)));
}

void OpIsKnownPowerOfTwo::record(const RecordCall &Call) {
  if (Call.Value.getType()->isIntOrIntVectorTy() &&
      isKnownToBeAPowerOfTwo(&Call.Value, /*OrZero=*/false, query(Call)))
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpIsKnownPowerOfTwoOrZero::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(
      isKnownToBeAPowerOfTwo(*Value, /*OrZero=*/true, query(Call)));
}

void OpIsKnownPowerOfTwoOrZero::record(const RecordCall &Call) {
  if (Call.Value.getType()->isIntOrIntVectorTy() &&
      isKnownToBeAPowerOfTwo(&Call.Value, /*OrZero=*/true, query(Call)))
    Call.Sink.add(Fact);
}

Expected<ConstraintValue>
OpMaskedValueIsZero::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  Expected<APSInt> Mask = requireInteger(Call.Operands[1], Call.Expression);
  if (!Mask)
    return Mask.takeError();
  // A negative mask sign-extends, so -256 covers every bit above bit 7.
  APInt MaskValue = Mask->extOrTrunc(integerElementWidth(**Value));
  return ConstraintValue::getBoolean(
      MaskedValueIsZero(*Value, MaskValue, query(Call)));
}

void OpMaskedValueIsZero::record(const RecordCall &Call) {
  // MaskedValueIsZero(V, M) is M.isSubsetOf(computeKnownBits(V).Zero): a mask
  // needs as many known trailing zeros as its low run of ones, and a mask of
  // the bits from T up leaves at most T active bits.
  if (!Call.Value.getType()->isIntOrIntVectorTy())
    return;
  const KnownBits &Known = Call.knownBits();
  // A mask wider than the value is truncated to it, so a value known to be
  // zero has as many trailing zeros as any mask needs.
  Call.Sink.measure(Measure::TrailingZeros,
                    Known.isZero() ? MaxMeasure
                                   : Known.countMinTrailingZeros());
  Call.Sink.measure(Measure::ActiveBits, Known.countMaxActiveBits());
}

/// The range computeConstantRange finds for the operand, and the bounds it
/// must lie within, extended to a width that holds them all exactly: bounds
/// outside the value's range must not wrap into it.
struct RangeQuery {
  ConstantRange Range;
  APInt Lower, Upper;
  unsigned Width;
};

static Expected<RangeQuery> rangeQuery(const ConcreteCall &Call,
                                       bool ForSigned) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  Expected<APSInt> Min = requireInteger(Call.Operands[1], Call.Expression);
  if (!Min)
    return Min.takeError();
  Expected<APSInt> Max = requireInteger(Call.Operands[2], Call.Expression);
  if (!Max)
    return Max.takeError();

  ConstantRange Range = computeConstantRange(const_cast<llvm::Value *>(*Value),
                                             ForSigned, query(Call));
  auto Needed = [](const APSInt &V) {
    return V.getBitWidth() + (V.isUnsigned() ? 1 : 0);
  };
  // One more bit than the value's, so its unsigned values read as signed.
  unsigned Width =
      std::max({Range.getBitWidth() + 1, Needed(*Min), Needed(*Max)});
  return RangeQuery{Range, Min->extend(Width), Max->extend(Width), Width};
}

Expected<ConstraintValue> OpInSignedRange::concrete(const ConcreteCall &Call) {
  Expected<RangeQuery> Q = rangeQuery(Call, /*ForSigned=*/true);
  if (!Q)
    return Q.takeError();
  return ConstraintValue::getBoolean(
      Q->Range.getSignedMin().sext(Q->Width).sge(Q->Lower) &&
      Q->Range.getSignedMax().sext(Q->Width).sle(Q->Upper));
}

Expected<ConstraintValue>
OpInUnsignedRange::concrete(const ConcreteCall &Call) {
  Expected<RangeQuery> Q = rangeQuery(Call, /*ForSigned=*/false);
  if (!Q)
    return Q.takeError();
  return ConstraintValue::getBoolean(
      Q->Range.getUnsignedMin().zext(Q->Width).sge(Q->Lower) &&
      Q->Range.getUnsignedMax().zext(Q->Width).sle(Q->Upper));
}

Expected<ConstraintValue> OpNumSignBits::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  const SimplifyQuery &Query = query(Call);
  return integerResult(APInt(32, ComputeNumSignBits(*Value, Query.DL, Query.AC,
                                                    Query.CxtI, Query.DT)),
                       /*IsUnsigned=*/true);
}

Expected<ConstraintValue>
OpMaxSignificantBits::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  const SimplifyQuery &Query = query(Call);
  return integerResult(
      APInt(32, ComputeMaxSignificantBits(*Value, Query.DL, Query.AC,
                                          Query.CxtI, Query.DT)),
      /*IsUnsigned=*/true);
}

/// A floating-point value-tracking query on the operand.
template <typename FPQuery>
static Expected<ConstraintValue> fpQuery(const ConcreteCall &Call,
                                         FPQuery Query) {
  Expected<const llvm::Value *> Value =
      requireFPValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(Query(*Value, query(Call)));
}

Expected<ConstraintValue>
OpIsKnownNeverNaN::concrete(const ConcreteCall &Call) {
  return fpQuery(Call, [](const llvm::Value *V, const SimplifyQuery &Q) {
    return isKnownNeverNaN(V, Q);
  });
}

Expected<ConstraintValue>
OpIsKnownNeverInfinity::concrete(const ConcreteCall &Call) {
  return fpQuery(Call, [](const llvm::Value *V, const SimplifyQuery &Q) {
    return isKnownNeverInfinity(V, Q);
  });
}

Expected<ConstraintValue>
OpIsKnownNeverInfOrNaN::concrete(const ConcreteCall &Call) {
  return fpQuery(Call, [](const llvm::Value *V, const SimplifyQuery &Q) {
    return isKnownNeverInfOrNaN(V, Q);
  });
}

Expected<ConstraintValue>
OpCannotBeNegativeZero::concrete(const ConcreteCall &Call) {
  return fpQuery(Call, [](const llvm::Value *V, const SimplifyQuery &Q) {
    return cannotBeNegativeZero(V, Q);
  });
}

Expected<ConstraintValue>
OpCannotBeOrderedLessThanZero::concrete(const ConcreteCall &Call) {
  return fpQuery(Call, [](const llvm::Value *V, const SimplifyQuery &Q) {
    return cannotBeOrderedLessThanZero(V, Q);
  });
}

void OpInSignedRange::record(const RecordCall &Call) {
  // Every value in [Min, Max] fits in as many signed bits as the wider bound,
  // so a range within the bounds does too.
  if (!Call.Value.getType()->isIntOrIntVectorTy())
    return;
  ConstantRange Range =
      computeConstantRange(const_cast<llvm::Value *>(&Call.Value),
                           /*ForSigned=*/true, query(Call));
  Call.Sink.measure(Measure::RangeSignedBits, Range.getMinSignedBits());
}

void OpInUnsignedRange::record(const RecordCall &Call) {
  // Every value up to Max fits in as many bits as Max, so a range within the
  // bounds does too.
  if (!Call.Value.getType()->isIntOrIntVectorTy())
    return;
  ConstantRange Range =
      computeConstantRange(const_cast<llvm::Value *>(&Call.Value),
                           /*ForSigned=*/false, query(Call));
  Call.Sink.measure(Measure::RangeUnsignedBits, Range.getActiveBits());
}

// A recorded predicate is false where the index lacks its fact.
#define MIR_ABSTRACT_PREDICATE(ID)                                             \
  AbstractValue Op##ID::abstract(const AbstractCall &Call) {                   \
    return lacksValueFact(Call, 0, Fact);                                      \
  }
MIR_ABSTRACT_PREDICATE(IsKnownNonZero)
MIR_ABSTRACT_PREDICATE(IsKnownNegative)
MIR_ABSTRACT_PREDICATE(IsKnownNonNegative)
MIR_ABSTRACT_PREDICATE(IsKnownPositive)
MIR_ABSTRACT_PREDICATE(IsKnownPowerOfTwo)
MIR_ABSTRACT_PREDICATE(IsKnownPowerOfTwoOrZero)
#undef MIR_ABSTRACT_PREDICATE

/// The integer Operands[Index] certainly is, if it is concrete and one.
static std::optional<APSInt> concreteInteger(const AbstractCall &Call,
                                             unsigned Index) {
  const AbstractValue &V = Call.Operands[Index];
  if (!V.isConcrete())
    return std::nullopt;
  Expected<APSInt> Integer = requireInteger(V.getConcrete(), Call.Expression);
  if (!Integer) {
    consumeError(Integer.takeError());
    return std::nullopt;
  }
  return *Integer;
}

AbstractValue OpMaskedValueIsZero::abstract(const AbstractCall &Call) {
  std::optional<APSInt> Mask = concreteInteger(Call, 1);
  if (!Mask)
    return AbstractValue::unknown();
  // The mask's low run of ones must be known trailing zeros.
  if (unsigned LowOnes = Mask->countr_one())
    if (AbstractValue V =
            exceedsMeasure(Call, 0, Measure::TrailingZeros, LowOnes);
        V.isFalse())
      return V;
  // A negative mask sign-extends, covering every bit from its leading ones
  // up, which must then be known leading zeros.
  if (Mask->isSigned() && Mask->isNegative())
    return exceedsMeasure(Call, 0, Measure::ActiveBits,
                          Mask->getBitWidth() - Mask->countl_one());
  return AbstractValue::unknown();
}

/// The fewest bits holding the integer as a signed number.
static unsigned signedBits(const APSInt &Integer) {
  return Integer.isSigned() ? Integer.getSignificantBits()
                            : Integer.getActiveBits() + 1;
}

AbstractValue OpInSignedRange::abstract(const AbstractCall &Call) {
  std::optional<APSInt> Min = concreteInteger(Call, 1);
  std::optional<APSInt> Max = concreteInteger(Call, 2);
  if (!Min || !Max)
    return AbstractValue::unknown();
  // Values within [Min, Max] fit in as many signed bits as the wider bound.
  return exceedsMeasure(Call, 0, Measure::RangeSignedBits,
                        std::max(signedBits(*Min), signedBits(*Max)));
}

AbstractValue OpInUnsignedRange::abstract(const AbstractCall &Call) {
  std::optional<APSInt> Max = concreteInteger(Call, 2);
  if (!Max)
    return AbstractValue::unknown();
  // A negative Max is left to the matcher.
  if (Max->isSigned() && Max->isNegative())
    return AbstractValue::unknown();
  // Values up to Max fit in as many bits as it.
  return exceedsMeasure(Call, 0, Measure::RangeUnsignedBits,
                        Max->getActiveBits());
}

void recordValueTracking(const RecordCall &Call) {
  // Value tracking is asked about integers and pointers only; other values'
  // facts are unknown.
  if (!Call.Value.getType()->isIntOrIntVectorTy() &&
      !Call.Value.getType()->isPtrOrPtrVectorTy()) {
    Call.Sink.add(Atom::ValueTrackingSkipped);
    return;
  }
  OpIsKnownNonZero::record(Call);
  OpIsKnownNegative::record(Call);
  OpIsKnownNonNegative::record(Call);
  OpIsKnownPositive::record(Call);
  OpIsKnownPowerOfTwo::record(Call);
  OpIsKnownPowerOfTwoOrZero::record(Call);
  OpMaskedValueIsZero::record(Call);
  OpInSignedRange::record(Call);
  OpInUnsignedRange::record(Call);
}

} // namespace metaphir
} // namespace llvm
