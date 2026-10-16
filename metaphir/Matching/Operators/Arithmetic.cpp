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

/// Whether Left and Right have the same low BitWidth bits: 'icmp eq' on
/// iBitWidth, both operands cast to that width.
static Expected<bool> evaluateBitEquality(const ConcreteCall &Call,
                                          unsigned BitWidth) {
  Expected<APSInt> Left = requireInteger(Call.Operands[0], Call.Expression);
  if (!Left)
    return Left.takeError();
  Expected<APSInt> Right = requireInteger(Call.Operands[1], Call.Expression);
  if (!Right)
    return Right.takeError();
  return static_cast<const APInt &>(castToBitWidth(*Left, BitWidth)) ==
         static_cast<const APInt &>(castToBitWidth(*Right, BitWidth));
}

/// '==' or '!=': by value, or with a bit width by bit pattern.
static Expected<ConstraintValue> evaluateEqual(const ConcreteCall &Call,
                                               bool Negated) {
  Expected<std::optional<unsigned>> BitWidth = optionalBitWidth(Call, 2);
  if (!BitWidth)
    return BitWidth.takeError();
  Expected<bool> Equal =
      *BitWidth ? evaluateBitEquality(Call, **BitWidth)
                : evaluateEquality(Call.Operands[0], Call.Operands[1],
                                   Call.Expression);
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
  // of its sites; anything else is unknown, as is a comparison of bit
  // patterns.
  if (Call.Operands.size() > 2)
    return AbstractValue::unknown();
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
  if (*BitWidth)
    return ConstraintValue::getModularInteger(
        -static_cast<const APInt &>(castToBitWidth(*Operand, **BitWidth)));
  APSInt Extended = extend(*Operand, Operand->getBitWidth() + 1, false);
  return integerResult(-static_cast<const APInt &>(Extended), false);
}

/// A binary integer operator or comparison: both operands are coerced to
/// integers and widened so that the result is exact, unless an explicit bit
/// width W asks for the LLVM instruction on iW: then the operands are cast to
/// W bits and the result is a W-bit pattern.
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

  // A comparison reads a bit pattern as its signedness says.
  switch (ID) {
  case Constraint::O_SLT:
  case Constraint::O_SLE:
  case Constraint::O_SGT:
  case Constraint::O_SGE:
  case Constraint::O_ULT:
  case Constraint::O_ULE:
  case Constraint::O_UGT:
  case Constraint::O_UGE: {
    bool UnsignedComparison =
        ID == Constraint::O_ULT || ID == Constraint::O_ULE ||
        ID == Constraint::O_UGT || ID == Constraint::O_UGE;
    *Left = readForComparison(*Left, Call.Operands[0].isModular(),
                              UnsignedComparison);
    *Right = readForComparison(*Right, Call.Operands[1].isModular(),
                               UnsignedComparison);
    break;
  }
  default:
    break;
  }

  bool Unsigned = Left->isUnsigned() && Right->isUnsigned();
  unsigned ExtraBits = 0;
  APInt L, R;
  if (*BitWidth) {
    L = castToBitWidth(*Left, **BitWidth);
    R = castToBitWidth(*Right, **BitWidth);
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
    auto [LHS, RHS] = widen(*Left, *Right, ExtraBits);
    L = LHS;
    R = RHS;
  }
  // The result, a number or with a bit width a bit pattern.
  auto Result = [&](APInt Value, bool IsUnsigned) {
    return *BitWidth ? ConstraintValue::getModularInteger(std::move(Value))
                     : integerResult(std::move(Value), IsUnsigned);
  };

  switch (ID) {
  case Constraint::O_Add:
    return Result(L + R, Unsigned);
  case Constraint::O_Subtract:
    return Result(L - R, false);
  case Constraint::O_Multiply:
    return Result(L * R, Unsigned);
  case Constraint::O_And:
    return Result(L & R, Unsigned);
  case Constraint::O_Or:
    return Result(L | R, Unsigned);
  case Constraint::O_Xor:
    return Result(L ^ R, Unsigned);
  case Constraint::O_SDiv:
  case Constraint::O_UDiv:
  case Constraint::O_SRem:
  case Constraint::O_URem:
    if (R.isZero())
      return make_error<ConstraintEvaluationError>(Call.Expression,
                                                   "division by zero");
    if (ID == Constraint::O_SDiv)
      return Result(L.sdiv(R), false);
    if (ID == Constraint::O_UDiv)
      return Result(L.udiv(R), true);
    if (ID == Constraint::O_SRem)
      return Result(L.srem(R), false);
    return Result(L.urem(R), true);
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
  if (Amount->isSigned() && Amount->isNegative())
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "shift amount is out of range");
  // With a bit width, a shift by the width or more is poison in LLVM.
  if (*BitWidth && Amount->uge(**BitWidth))
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "shift amount is out of range");
  // Without one, integers are mathematical: shl keeps every bit, and a right
  // shift past the operand's bits leaves only its sign.
  uint64_t Shift = Amount->getLimitedValue();
  if (!*BitWidth && ID == Constraint::O_Shl) {
    if (Shift > llvm::IntegerType::MAX_INT_BITS)
      return make_error<ConstraintEvaluationError>(
          Call.Expression, "shift amount is out of range");
    *Value = extend(*Value, Value->getBitWidth() + unsigned(Shift),
                    Value->isUnsigned());
  }
  const APInt &Integer = *Value;
  unsigned Width = Integer.getBitWidth();
  APInt Result;
  switch (ID) {
  case Constraint::O_Lshr:
    Result = Shift >= Width ? APInt::getZero(Width) : Integer.lshr(Shift);
    break;
  case Constraint::O_Ashr:
    Result = Integer.ashr(std::min<uint64_t>(Shift, Width - 1));
    break;
  case Constraint::O_Shl:
    Result = Integer.shl(Shift);
    break;
  default:
    llvm_unreachable("invalid shift operator");
  }
  if (*BitWidth)
    return ConstraintValue::getModularInteger(std::move(Result));
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
