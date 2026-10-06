#include "metaphir/Matching/Operators/Arithmetic.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstantInteger.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/ErrorHandling.h"
#include <optional>

namespace llvm {
namespace metaphir {

using namespace detail;

/// The optional bit width operand at Index.
static Expected<std::optional<unsigned>>
optionalBitWidth(const ConcreteCall &Call, unsigned Index) {
  if (Call.Operands.size() <= Index)
    return std::nullopt;
  Expected<APSInt> Width =
      requireInteger(Call.Operands[Index], Call.Expression);
  if (!Width)
    return Width.takeError();
  if (Width->isNegative() || Width->isZero() ||
      Width->ugt(llvm::IntegerType::MAX_INT_BITS))
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "bitwidth must be between 1 and " +
                             Twine(llvm::IntegerType::MAX_INT_BITS));
  return static_cast<unsigned>(Width->getZExtValue());
}

static Expected<ConstraintValue> evaluateEqual(const ConcreteCall &Call,
                                               bool Negated) {
  Expected<bool> Equal =
      evaluateEquality(Call.Operands[0], Call.Operands[1], Call.Expression);
  if (!Equal)
    return Equal.takeError();
  return ConstraintValue::getBoolean(Negated ? !*Equal : *Equal);
}

Expected<ConstraintValue> OpEqual::concrete(const ConcreteCall &Call) {
  return evaluateEqual(Call, /*Negated=*/false);
}

void OpEqual::record(const RecordCall &Call) {
  // An operand compared with a literal is coerced as getConstantInteger
  // reads it (ConstraintCoercion) and compared by value, read signed; a Nat
  // binding reads it unsigned. Both readings are recorded.
  std::optional<APInt> Integer = getConstantInteger(Call.Value);
  if (!Integer)
    return;
  auto Add = [&](int64_t V) {
    if (std::optional<Atom> Literal = Atom::literal(V))
      Call.Sink.add(*Literal);
  };
  if (Integer->isSignedIntN(64))
    Add(Integer->getSExtValue());
  if (Integer->isIntN(63))
    Add(int64_t(Integer->getZExtValue()));
}

AbstractValue OpEqual::abstract(const AbstractCall &Call) {
  // A value compared with a literal the index records must have it at each
  // of its sites; anything else is unknown.
  for (unsigned SitesIndex : {0u, 1u}) {
    const AbstractValue &Other = Call.Operands[1 - SitesIndex];
    if (!Call.Operands[SitesIndex].isSites() || !Other.isConcrete())
      continue;
    Expected<APSInt> Literal =
        requireInteger(Other.getConcrete(), Call.Expression);
    if (!Literal) {
      consumeError(Literal.takeError());
      return AbstractValue::unknown();
    }
    // The comparison is by value, so the literal is read as its signedness
    // says.
    if (std::optional<int64_t> V = Literal->tryExtValue())
      if (std::optional<Atom> A = Atom::literal(*V))
        return lacksFact(Call, SitesIndex, *A);
  }
  return AbstractValue::unknown();
}

Expected<ConstraintValue> OpNotEqual::concrete(const ConcreteCall &Call) {
  return evaluateEqual(Call, /*Negated=*/true);
}

Expected<ConstraintValue> OpNot::concrete(const ConcreteCall &Call) {
  Expected<bool> Operand = requireBoolean(Call.Operands[0], Call.Expression);
  if (!Operand)
    return Operand.takeError();
  return ConstraintValue::getBoolean(!*Operand);
}

Expected<ConstraintValue> OpNegate::concrete(const ConcreteCall &Call) {
  Expected<std::optional<unsigned>> BitWidth = optionalBitWidth(Call, 1);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<APSInt> Operand = requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand)
    return Operand.takeError();
  if (*BitWidth) {
    *Operand = castToBitWidth(*Operand, **BitWidth);
    return integerResult(-static_cast<const APInt &>(*Operand),
                         Operand->isUnsigned());
  }
  APSInt Extended = extend(*Operand, Operand->getBitWidth() + 1, false);
  return integerResult(-static_cast<const APInt &>(Extended), false);
}

/// A binary integer operator or comparison: both operands are coerced to
/// integers and widened so that the result is exact, unless an explicit bit
/// width asks for modular arithmetic.
static Expected<ConstraintValue> evaluateBinary(Constraint::OperatorID ID,
                                                const ConcreteCall &Call) {
  Expected<APSInt> Left = requireInteger(Call.Operands[0], Call.Expression);
  if (!Left)
    return Left.takeError();
  Expected<APSInt> Right = requireInteger(Call.Operands[1], Call.Expression);
  if (!Right)
    return Right.takeError();
  Expected<std::optional<unsigned>> BitWidth = optionalBitWidth(Call, 2);
  if (!BitWidth)
    return BitWidth.takeError();

  bool Unsigned = Left->isUnsigned() && Right->isUnsigned();
  unsigned ExtraBits = 0;
  if (*BitWidth) {
    *Left = castToBitWidth(*Left, **BitWidth);
    *Right = castToBitWidth(*Right, **BitWidth);
  } else {
    switch (ID) {
    case Constraint::O_Multiply:
      ExtraBits = std::min(Left->getBitWidth(), Right->getBitWidth());
      break;
    case Constraint::O_Add:
    case Constraint::O_Subtract:
    // The most negative value divided by -1 needs one more bit.
    case Constraint::O_SDiv:
      ExtraBits = 1;
      break;
    default:
      break;
    }
  }
  auto [LHS, RHS] = widen(*Left, *Right, ExtraBits);
  const APInt &L = LHS;
  const APInt &R = RHS;

  switch (ID) {
  case Constraint::O_Add:
    return integerResult(L + R, Unsigned);
  case Constraint::O_Subtract:
    return integerResult(L - R, false);
  case Constraint::O_Multiply:
    return integerResult(L * R, Unsigned);
  case Constraint::O_And:
    return integerResult(L & R, Unsigned);
  case Constraint::O_Or:
    return integerResult(L | R, Unsigned);
  case Constraint::O_Xor:
    return integerResult(L ^ R, Unsigned);
  case Constraint::O_SDiv:
  case Constraint::O_UDiv:
  case Constraint::O_SRem:
  case Constraint::O_URem:
    if (R.isZero())
      return make_error<ConstraintEvaluationError>(Call.Expression,
                                                   "division by zero");
    if (ID == Constraint::O_SDiv)
      return integerResult(L.sdiv(R), false);
    if (ID == Constraint::O_UDiv)
      return integerResult(L.udiv(R), true);
    if (ID == Constraint::O_SRem)
      return integerResult(L.srem(R), false);
    return integerResult(L.urem(R), true);
  case Constraint::O_SLT:
    return ConstraintValue::getBoolean(L.slt(R));
  case Constraint::O_ULT:
    return ConstraintValue::getBoolean(L.ult(R));
  case Constraint::O_SLE:
    return ConstraintValue::getBoolean(L.sle(R));
  case Constraint::O_ULE:
    return ConstraintValue::getBoolean(L.ule(R));
  case Constraint::O_SGT:
    return ConstraintValue::getBoolean(L.sgt(R));
  case Constraint::O_UGT:
    return ConstraintValue::getBoolean(L.ugt(R));
  case Constraint::O_SGE:
    return ConstraintValue::getBoolean(L.sge(R));
  case Constraint::O_UGE:
    return ConstraintValue::getBoolean(L.uge(R));
  default:
    llvm_unreachable("not a binary integer operator");
  }
}

#define MIR_BINARY_OPERATOR(ID)                                                \
  Expected<ConstraintValue> Op##ID::concrete(const ConcreteCall &Call) {       \
    return evaluateBinary(Constraint::O_##ID, Call);                           \
  }
MIR_BINARY_OPERATOR(Add)
MIR_BINARY_OPERATOR(Subtract)
MIR_BINARY_OPERATOR(Multiply)
MIR_BINARY_OPERATOR(SDiv)
MIR_BINARY_OPERATOR(UDiv)
MIR_BINARY_OPERATOR(SRem)
MIR_BINARY_OPERATOR(URem)
MIR_BINARY_OPERATOR(And)
MIR_BINARY_OPERATOR(Or)
MIR_BINARY_OPERATOR(Xor)
MIR_BINARY_OPERATOR(SLT)
MIR_BINARY_OPERATOR(ULT)
MIR_BINARY_OPERATOR(SLE)
MIR_BINARY_OPERATOR(ULE)
MIR_BINARY_OPERATOR(SGT)
MIR_BINARY_OPERATOR(UGT)
MIR_BINARY_OPERATOR(SGE)
MIR_BINARY_OPERATOR(UGE)
#undef MIR_BINARY_OPERATOR

static Expected<ConstraintValue> evaluateShift(Constraint::OperatorID ID,
                                               const ConcreteCall &Call) {
  Expected<std::optional<unsigned>> BitWidth = optionalBitWidth(Call, 2);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<APSInt> Value = requireInteger(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  if (*BitWidth)
    *Value = castToBitWidth(*Value, **BitWidth);
  Expected<APSInt> Amount = requireInteger(Call.Operands[1], Call.Expression);
  if (!Amount)
    return Amount.takeError();
  if ((Amount->isSigned() && Amount->isNegative()) ||
      Amount->uge(Value->getBitWidth()))
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "shift amount is out of range");
  // Without an explicit width, shl keeps the bits shifted out of the
  // operand's width, like the other arithmetic operators.
  if (!*BitWidth && ID == Constraint::O_Shl)
    *Value = extend(*Value, Value->getBitWidth() + Amount->getZExtValue(),
                    Value->isUnsigned());
  const APInt &Integer = *Value;
  APInt Result;
  switch (ID) {
  case Constraint::O_Lshr:
    Result = Integer.lshr(Amount->getLimitedValue());
    break;
  case Constraint::O_Ashr:
    Result = Integer.ashr(Amount->getLimitedValue());
    break;
  case Constraint::O_Shl:
    Result = Integer.shl(Amount->getLimitedValue());
    break;
  default:
    llvm_unreachable("invalid shift operator");
  }
  return integerResult(std::move(Result),
                       ID != Constraint::O_Ashr && Value->isUnsigned());
}

Expected<ConstraintValue> OpLshr::concrete(const ConcreteCall &Call) {
  return evaluateShift(Constraint::O_Lshr, Call);
}

Expected<ConstraintValue> OpAshr::concrete(const ConcreteCall &Call) {
  return evaluateShift(Constraint::O_Ashr, Call);
}

Expected<ConstraintValue> OpShl::concrete(const ConcreteCall &Call) {
  return evaluateShift(Constraint::O_Shl, Call);
}

Expected<ConstraintValue> OpLog2::concrete(const ConcreteCall &Call) {
  Expected<APSInt> Operand = requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand)
    return Operand.takeError();
  if (Operand->isNegative() || Operand->isZero())
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "log2 requires a positive operand");
  return integerResult(APInt(Operand->getBitWidth(), Operand->logBase2(), true),
                       true);
}

Expected<ConstraintValue> OpPopcount::concrete(const ConcreteCall &Call) {
  Expected<APSInt> Operand = requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand)
    return Operand.takeError();
  return integerResult(APInt(Operand->getBitWidth(), Operand->popcount(), true),
                       true);
}

/// A count of the operand's bits by Count, at the operand's own width or the
/// optional one: a constant's is its type's, and knownZeros' and knownOnes'
/// are the value's.
template <typename BitCount>
static Expected<ConstraintValue> evaluateCount(const ConcreteCall &Call,
                                               BitCount Count) {
  Expected<std::optional<unsigned>> BitWidth = optionalBitWidth(Call, 1);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<APSInt> Operand = requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand)
    return Operand.takeError();
  if (*BitWidth)
    *Operand = castToBitWidth(*Operand, **BitWidth);
  return integerResult(APInt(32, Count(*Operand)), /*IsUnsigned=*/true);
}

Expected<ConstraintValue> OpCountlZero::concrete(const ConcreteCall &Call) {
  return evaluateCount(Call, [](const APInt &V) { return V.countl_zero(); });
}

Expected<ConstraintValue> OpCountrZero::concrete(const ConcreteCall &Call) {
  return evaluateCount(Call, [](const APInt &V) { return V.countr_zero(); });
}

Expected<ConstraintValue> OpCountlOne::concrete(const ConcreteCall &Call) {
  return evaluateCount(Call, [](const APInt &V) { return V.countl_one(); });
}

Expected<ConstraintValue> OpCountrOne::concrete(const ConcreteCall &Call) {
  return evaluateCount(Call, [](const APInt &V) { return V.countr_one(); });
}

} // namespace metaphir
} // namespace llvm
