#include "metaphir/Matching/Operators/ValuePredicates.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/ErrorHandling.h"
#include <iterator>

namespace llvm {
namespace metaphir {

using namespace detail;

static constexpr StringLiteral ValueClassNames[] = {
#define MIR_LLVM_VALUE_CLASS(Class) #Class,
#include "metaphir/Matching/LLVMValueClasses.def"
};

bool OpIsa::holds(const llvm::Value &V, unsigned ClassIndex) {
  unsigned Index = 0;
#define MIR_LLVM_VALUE_CLASS(Class)                                            \
  if (Index++ == ClassIndex)                                                   \
    return isa<llvm::Class>(V);
#include "metaphir/Matching/LLVMValueClasses.def"
  llvm_unreachable("invalid LLVM value class index");
}

Expected<ConstraintValue> OpIsa::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  Expected<std::string> ClassName =
      requireString(Call.Operands[1], Call.Expression);
  if (!ClassName)
    return ClassName.takeError();
  const StringLiteral *Class = find(ValueClassNames, *ClassName);
  if (Class == std::end(ValueClassNames))
    return make_error<ConstraintEvaluationError>(
        Call.Expression,
        Twine("unknown LLVM value class '") + *ClassName + "'");
  return ConstraintValue::getBoolean(
      holds(**Value, Class - std::begin(ValueClassNames)));
}

bool OpIsa::isRecorded(unsigned ClassIndex) {
  StringRef Name = ValueClassNames[ClassIndex];
  return Name != "Value" && Name != "User" && Name != "Instruction";
}

void OpIsa::record(const RecordCall &Call) {
  for (unsigned Index = 0; Index != std::size(ValueClassNames); ++Index)
    if (isRecorded(Index) && holds(Call.Value, Index))
      Call.Sink.add(Atom::valueClass(Index));
}

AbstractValue OpIsa::abstract(const AbstractCall &Call) {
  const AbstractValue &ClassName = Call.Operands[1];
  if (!ClassName.isConcrete() ||
      ClassName.getConcrete().getKind() != ConstraintValue::String)
    return AbstractValue::unknown();
  const StringLiteral *Class =
      find(ValueClassNames, ClassName.getConcrete().getString());
  unsigned Index = Class - std::begin(ValueClassNames);
  if (Class == std::end(ValueClassNames) || !isRecorded(Index))
    return AbstractValue::unknown();
  return lacksFact(Call, 0, Atom::valueClass(Index));
}

Expected<ConstraintValue> OpOpcode::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
    return ConstraintValue::getString(Instruction->getOpcodeName());
  return make_error<ConstraintEvaluationError>(
      Call.Expression, "expected an instruction operand");
}

/// The operand as an LLVM value, if it is one.
static const llvm::Value *valueOperand(const ConcreteCall &Call) {
  const ConstraintValue &V = Call.Operands[0];
  return V.getKind() == ConstraintValue::Value ? V.getValue() : nullptr;
}

/// A predicate on an integer: an LLVM value is tested with Op::holds, which
/// accepts splats; anything else is coerced to an integer and tested with
/// MatchInteger. An operand that is not an integer does not satisfy it.
template <class Op, typename IntegerPredicate>
static ConstraintValue integerPredicate(const ConcreteCall &Call,
                                        IntegerPredicate MatchInteger) {
  if (const llvm::Value *V = valueOperand(Call))
    return ConstraintValue::getBoolean(Op::holds(*V));
  Expected<APSInt> Operand = requireInteger(Call.Operands[0], Call.Expression);
  if (!Operand) {
    consumeError(Operand.takeError());
    return ConstraintValue::getBoolean(false);
  }
  return ConstraintValue::getBoolean(MatchInteger(*Operand));
}

/// A predicate that holds only for LLVM values: Op::holds decides it.
template <class Op>
static ConstraintValue valuePredicate(const ConcreteCall &Call) {
  const llvm::Value *V = valueOperand(Call);
  return ConstraintValue::getBoolean(V && Op::holds(*V));
}

/// Records Op's fact for the value if Op::holds.
template <class Op> static void recordIfHolds(const RecordCall &Call) {
  if (Op::holds(Call.Value))
    Call.Sink.add(Op::Fact);
}

bool OpIsPower2::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Power2());
}

Expected<ConstraintValue> OpIsPower2::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsPower2>(
      Call, [](const APSInt &V) { return V.isPowerOf2(); });
}

void OpIsPower2::record(const RecordCall &Call) {
  recordIfHolds<OpIsPower2>(Call);
}

bool OpIsZero::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Zero());
}

Expected<ConstraintValue> OpIsZero::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsZero>(Call,
                                    [](const APSInt &V) { return V.isZero(); });
}

void OpIsZero::record(const RecordCall &Call) { recordIfHolds<OpIsZero>(Call); }

bool OpIsAllOnes::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_AllOnes());
}

Expected<ConstraintValue> OpIsAllOnes::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsAllOnes>(
      Call, [](const APSInt &V) { return V.isAllOnes(); });
}

void OpIsAllOnes::record(const RecordCall &Call) {
  recordIfHolds<OpIsAllOnes>(Call);
}

bool OpIsLowBitMask::holds(const llvm::Value &V) {
  // A low bit mask is a non-empty run of ones starting at bit 0.
  return PatternMatch::match(&V, PatternMatch::m_LowBitMask());
}

Expected<ConstraintValue> OpIsLowBitMask::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsLowBitMask>(
      Call, [](const APSInt &V) { return V.isMask(); });
}

void OpIsLowBitMask::record(const RecordCall &Call) {
  recordIfHolds<OpIsLowBitMask>(Call);
}

bool OpIsAnyZeroFP::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_AnyZeroFP());
}

Expected<ConstraintValue> OpIsAnyZeroFP::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsAnyZeroFP>(Call);
}

void OpIsAnyZeroFP::record(const RecordCall &Call) {
  recordIfHolds<OpIsAnyZeroFP>(Call);
}

bool OpIsAnyIntegralConstant::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_AnyIntegralConstant());
}

Expected<ConstraintValue>
OpIsAnyIntegralConstant::concrete(const ConcreteCall &Call) {
  if (valueOperand(Call))
    return valuePredicate<OpIsAnyIntegralConstant>(Call);
  return ConstraintValue::getBoolean(Call.Operands[0].getKind() ==
                                     ConstraintValue::Integer);
}

void OpIsAnyIntegralConstant::record(const RecordCall &Call) {
  recordIfHolds<OpIsAnyIntegralConstant>(Call);
}

bool OpIsPoison::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Poison());
}

Expected<ConstraintValue> OpIsPoison::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsPoison>(Call);
}

void OpIsPoison::record(const RecordCall &Call) {
  recordIfHolds<OpIsPoison>(Call);
}

bool OpIsForbidPoison::holds(const llvm::Value &V) {
  const auto *Constant = dyn_cast<llvm::Constant>(&V);
  return Constant && !isa<PoisonValue>(Constant) &&
         !Constant->containsPoisonElement();
}

Expected<ConstraintValue> OpIsForbidPoison::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsForbidPoison>(Call);
}

void OpIsForbidPoison::record(const RecordCall &Call) {
  recordIfHolds<OpIsForbidPoison>(Call);
}

bool OpIsConstantSplat::holds(const llvm::Value &V) {
  const auto *Constant = dyn_cast<llvm::Constant>(&V);
  return Constant && Constant->getType()->isVectorTy() &&
         Constant->getSplatValue(/*AllowPoison=*/true);
}

Expected<ConstraintValue>
OpIsConstantSplat::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsConstantSplat>(Call);
}

void OpIsConstantSplat::record(const RecordCall &Call) {
  recordIfHolds<OpIsConstantSplat>(Call);
}

bool OpIsScalar::holds(const llvm::Value &V) {
  return !V.getType()->isVectorTy();
}

Expected<ConstraintValue> OpIsScalar::concrete(const ConcreteCall &Call) {
  if (valueOperand(Call))
    return valuePredicate<OpIsScalar>(Call);
  ConstraintValue::ValueKind Kind = Call.Operands[0].getKind();
  return ConstraintValue::getBoolean(Kind == ConstraintValue::Integer ||
                                     Kind == ConstraintValue::Boolean);
}

bool OpHasOneUse::holds(const llvm::Value &V) { return V.hasOneUse(); }

Expected<ConstraintValue> OpHasOneUse::concrete(const ConcreteCall &Call) {
  if (const llvm::Value *V = valueOperand(Call))
    if (std::optional<ModuleUses> Uses = Call.GetModuleUses(*V))
      return ConstraintValue::getBoolean(Uses->OneUse);
  return valuePredicate<OpHasOneUse>(Call);
}

// Uses in other functions may be missing from the IR at hand, so the counts
// the index saw can differ from the matcher's: the index records the fact
// regardless.
void OpHasOneUse::record(const RecordCall &Call) {
  if (isUsedAcrossFunctions(Call.Value) || holds(Call.Value))
    Call.Sink.add(Fact);
}

bool OpHasOneUser::holds(const llvm::Value &V) { return V.hasOneUser(); }

Expected<ConstraintValue> OpHasOneUser::concrete(const ConcreteCall &Call) {
  if (const llvm::Value *V = valueOperand(Call))
    if (std::optional<ModuleUses> Uses = Call.GetModuleUses(*V))
      return ConstraintValue::getBoolean(Uses->OneUser);
  return valuePredicate<OpHasOneUser>(Call);
}

void OpHasOneUser::record(const RecordCall &Call) {
  if (isUsedAcrossFunctions(Call.Value) || holds(Call.Value))
    Call.Sink.add(Fact);
}

bool OpIsImmConstant::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_ImmConstant());
}

// A plain integer is an immediate, as it is an integral constant.
Expected<ConstraintValue> OpIsImmConstant::concrete(const ConcreteCall &Call) {
  if (valueOperand(Call))
    return valuePredicate<OpIsImmConstant>(Call);
  return ConstraintValue::getBoolean(Call.Operands[0].getKind() ==
                                     ConstraintValue::Integer);
}

void OpIsImmConstant::record(const RecordCall &Call) {
  recordIfHolds<OpIsImmConstant>(Call);
}

// The classes below that depend on the bit width (the sign bit, negated
// powers of two, shifted masks) hold only for LLVM constants; a plain integer
// has no width of its own.

bool OpIsSignMask::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_SignMask());
}

Expected<ConstraintValue> OpIsSignMask::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsSignMask>(Call);
}

void OpIsSignMask::record(const RecordCall &Call) {
  recordIfHolds<OpIsSignMask>(Call);
}

bool OpIsMaxSignedValue::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_MaxSignedValue());
}

Expected<ConstraintValue>
OpIsMaxSignedValue::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsMaxSignedValue>(Call);
}

void OpIsMaxSignedValue::record(const RecordCall &Call) {
  recordIfHolds<OpIsMaxSignedValue>(Call);
}

bool OpIsNegatedPower2::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_NegatedPower2());
}

Expected<ConstraintValue>
OpIsNegatedPower2::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsNegatedPower2>(Call);
}

void OpIsNegatedPower2::record(const RecordCall &Call) {
  recordIfHolds<OpIsNegatedPower2>(Call);
}

bool OpIsNegatedPower2OrZero::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_NegatedPower2OrZero());
}

Expected<ConstraintValue>
OpIsNegatedPower2OrZero::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsNegatedPower2OrZero>(Call);
}

bool OpIsPower2OrZero::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Power2OrZero());
}

Expected<ConstraintValue> OpIsPower2OrZero::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsPower2OrZero>(
      Call, [](const APSInt &V) { return V.isZero() || V.isPowerOf2(); });
}

bool OpIsLowBitMaskOrZero::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_LowBitMaskOrZero());
}

Expected<ConstraintValue>
OpIsLowBitMaskOrZero::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsLowBitMaskOrZero>(
      Call, [](const APSInt &V) { return V.isZero() || V.isMask(); });
}

bool OpIsShiftedMask::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_ShiftedMask());
}

Expected<ConstraintValue> OpIsShiftedMask::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsShiftedMask>(Call);
}

void OpIsShiftedMask::record(const RecordCall &Call) {
  recordIfHolds<OpIsShiftedMask>(Call);
}

// The sign classes read a plain integer by its signedness, as APSInt does.

bool OpIsNegative::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Negative());
}

Expected<ConstraintValue> OpIsNegative::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsNegative>(
      Call, [](const APSInt &V) { return V.isNegative(); });
}

void OpIsNegative::record(const RecordCall &Call) {
  recordIfHolds<OpIsNegative>(Call);
}

bool OpIsNonNegative::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_NonNegative());
}

Expected<ConstraintValue> OpIsNonNegative::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsNonNegative>(
      Call, [](const APSInt &V) { return V.isNonNegative(); });
}

void OpIsNonNegative::record(const RecordCall &Call) {
  recordIfHolds<OpIsNonNegative>(Call);
}

bool OpIsStrictlyPositive::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_StrictlyPositive());
}

Expected<ConstraintValue>
OpIsStrictlyPositive::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsStrictlyPositive>(
      Call, [](const APSInt &V) { return V.isStrictlyPositive(); });
}

void OpIsStrictlyPositive::record(const RecordCall &Call) {
  recordIfHolds<OpIsStrictlyPositive>(Call);
}

bool OpIsNonPositive::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_NonPositive());
}

Expected<ConstraintValue> OpIsNonPositive::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsNonPositive>(
      Call, [](const APSInt &V) { return !V.isStrictlyPositive(); });
}

bool OpIsNonZeroInt::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_NonZeroInt());
}

Expected<ConstraintValue> OpIsNonZeroInt::concrete(const ConcreteCall &Call) {
  return integerPredicate<OpIsNonZeroInt>(
      Call, [](const APSInt &V) { return !V.isZero(); });
}

bool OpIsUndef::holds(const llvm::Value &V) {
  return PatternMatch::match(&V, PatternMatch::m_Undef());
}

Expected<ConstraintValue> OpIsUndef::concrete(const ConcreteCall &Call) {
  return valuePredicate<OpIsUndef>(Call);
}

void OpIsUndef::record(const RecordCall &Call) {
  recordIfHolds<OpIsUndef>(Call);
}

Expected<ConstraintValue> OpIntrinsic::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  if (const auto *CB = dyn_cast<CallBase>(*Value))
    if (const Function *Callee = CB->getCalledFunction();
        Callee && Callee->isIntrinsic())
      return ConstraintValue::getString(
          Intrinsic::getBaseName(Callee->getIntrinsicID()));
  return make_error<ConstraintEvaluationError>(
      Call.Expression, "expected a call to an intrinsic");
}

Expected<ConstraintValue> OpPredicate::concrete(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  if (const auto *Compare = dyn_cast<CmpInst>(*Value))
    return ConstraintValue::getString(
        CmpInst::getPredicateName(Compare->getPredicate()));
  return make_error<ConstraintEvaluationError>(Call.Expression,
                                               "expected a compare");
}

Expected<ConstraintValue> OpBitWidth::concrete(const ConcreteCall &Call) {
  const ConstraintValue &Operand = Call.Operands[0];
  const llvm::Type *Type = nullptr;
  if (Operand.getKind() == ConstraintValue::Value)
    Type = Operand.getValue()->getType();
  else if (Operand.getKind() == ConstraintValue::Type)
    Type = Operand.getType();
  else
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "expected a value or a type operand");
  unsigned Width = Type->getScalarSizeInBits();
  if (!Width)
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "operand type has no bit width");
  return integerResult(APInt(32, Width), /*IsUnsigned=*/true);
}

// A recorded predicate is false where the index lacks its fact.
#define MIR_ABSTRACT_PREDICATE(ID)                                             \
  AbstractValue Op##ID::abstract(const AbstractCall &Call) {                   \
    return lacksFact(Call, 0, Fact);                                           \
  }
MIR_ABSTRACT_PREDICATE(IsPower2)
MIR_ABSTRACT_PREDICATE(IsZero)
MIR_ABSTRACT_PREDICATE(IsAllOnes)
MIR_ABSTRACT_PREDICATE(IsLowBitMask)
MIR_ABSTRACT_PREDICATE(IsAnyZeroFP)
MIR_ABSTRACT_PREDICATE(IsAnyIntegralConstant)
MIR_ABSTRACT_PREDICATE(IsPoison)
MIR_ABSTRACT_PREDICATE(IsForbidPoison)
MIR_ABSTRACT_PREDICATE(IsConstantSplat)
MIR_ABSTRACT_PREDICATE(HasOneUse)
MIR_ABSTRACT_PREDICATE(HasOneUser)
MIR_ABSTRACT_PREDICATE(IsImmConstant)
MIR_ABSTRACT_PREDICATE(IsSignMask)
MIR_ABSTRACT_PREDICATE(IsMaxSignedValue)
MIR_ABSTRACT_PREDICATE(IsNegatedPower2)
MIR_ABSTRACT_PREDICATE(IsShiftedMask)
MIR_ABSTRACT_PREDICATE(IsNegative)
MIR_ABSTRACT_PREDICATE(IsNonNegative)
MIR_ABSTRACT_PREDICATE(IsStrictlyPositive)
MIR_ABSTRACT_PREDICATE(IsUndef)
#undef MIR_ABSTRACT_PREDICATE

void recordValuePredicates(const RecordCall &Call) {
  OpIsa::record(Call);
  OpIsPower2::record(Call);
  OpIsZero::record(Call);
  OpIsAllOnes::record(Call);
  OpIsLowBitMask::record(Call);
  OpIsAnyZeroFP::record(Call);
  OpIsAnyIntegralConstant::record(Call);
  OpIsPoison::record(Call);
  OpIsForbidPoison::record(Call);
  OpIsConstantSplat::record(Call);
  OpHasOneUse::record(Call);
  OpHasOneUser::record(Call);
  OpIsImmConstant::record(Call);
  OpIsSignMask::record(Call);
  OpIsMaxSignedValue::record(Call);
  OpIsNegatedPower2::record(Call);
  OpIsShiftedMask::record(Call);
  OpIsNegative::record(Call);
  OpIsNonNegative::record(Call);
  OpIsStrictlyPositive::record(Call);
  OpIsUndef::record(Call);
}

} // namespace metaphir
} // namespace llvm
