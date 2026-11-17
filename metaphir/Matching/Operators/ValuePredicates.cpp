#include "metaphir/Matching/Operators/ValuePredicates.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/LLVMValueClasses.h"
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

bool OpIsa::holds(const llvm::Value &V, unsigned ClassIndex) {
  return isValueClass(V, ClassIndex);
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
  std::optional<unsigned> Class = findValueClass(*ClassName);
  if (!Class)
    return make_error<ConstraintEvaluationError>(
        Call.Expression,
        Twine("unknown LLVM value class '") + *ClassName + "'");
  return ConstraintValue::getBoolean(holds(**Value, *Class));
}

bool OpIsa::isRecorded(unsigned ClassIndex) {
  return isRecordedValueClass(ClassIndex);
}

void OpIsa::record(const RecordCall &Call) {
  for (unsigned Index = 0; Index != NumValueClasses; ++Index)
    if (isRecorded(Index) && holds(Call.Value, Index))
      Call.Sink.add(Atom::valueClass(Index));
}

AbstractValue OpIsa::abstract(const AbstractCall &Call) {
  const AbstractValue &ClassName = Call.Operands[1];
  if (!ClassName.isConcrete() ||
      ClassName.getConcrete().getKind() != ConstraintValue::String)
    return AbstractValue::unknown();
  std::optional<unsigned> Class =
      findValueClass(ClassName.getConcrete().getString());
  if (!Class || !isRecorded(*Class))
    return AbstractValue::unknown();
  return lacksFact(Call, 0, Atom::valueClass(*Class));
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
      return ConstraintValue::getBoolean(Uses->NumUses == 1);
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

/// The value and the count of a use-count operator.
static Expected<std::pair<const llvm::Value *, APSInt>>
useCountOperands(const ConcreteCall &Call) {
  Expected<const llvm::Value *> Value =
      requireValue(Call.Operands[0], Call.Expression);
  if (!Value)
    return Value.takeError();
  Expected<APSInt> Count = requireInteger(Call.Operands[1], Call.Expression);
  if (!Count)
    return Count.takeError();
  if (Count->isNegative() || !Count->isIntN(32))
    return make_error<ConstraintEvaluationError>(
        Call.Expression, "expected a use count between 0 and 2^32 - 1");
  return std::make_pair(*Value, *Count);
}

// A value used across functions counts its uses in its whole module.
Expected<ConstraintValue> OpHasNUses::concrete(const ConcreteCall &Call) {
  auto Operands = useCountOperands(Call);
  if (!Operands)
    return Operands.takeError();
  auto [Value, Count] = *Operands;
  if (std::optional<ModuleUses> Uses = Call.GetModuleUses(*Value))
    return ConstraintValue::getBoolean(Count == Uses->NumUses);
  return ConstraintValue::getBoolean(Value->hasNUses(Count.getZExtValue()));
}

Expected<ConstraintValue> OpHasNUsesOrMore::concrete(const ConcreteCall &Call) {
  auto Operands = useCountOperands(Call);
  if (!Operands)
    return Operands.takeError();
  auto [Value, Count] = *Operands;
  if (std::optional<ModuleUses> Uses = Call.GetModuleUses(*Value))
    return ConstraintValue::getBoolean(Count.ule(Uses->NumUses));
  return ConstraintValue::getBoolean(
      Value->hasNUsesOrMore(Count.getZExtValue()));
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
MIR_ABSTRACT_PREDICATE(IsAnyIntegralConstant)
MIR_ABSTRACT_PREDICATE(IsForbidPoison)
MIR_ABSTRACT_PREDICATE(IsConstantSplat)
MIR_ABSTRACT_PREDICATE(HasOneUse)
MIR_ABSTRACT_PREDICATE(HasOneUser)
MIR_ABSTRACT_PREDICATE(IsImmConstant)
#undef MIR_ABSTRACT_PREDICATE

void recordValuePredicates(const RecordCall &Call) {
  OpIsa::record(Call);
  recordConstantClasses(Call);
  OpIsAnyIntegralConstant::record(Call);
  OpIsForbidPoison::record(Call);
  OpIsConstantSplat::record(Call);
  OpHasOneUse::record(Call);
  OpHasOneUser::record(Call);
  OpIsImmConstant::record(Call);
}

} // namespace metaphir
} // namespace llvm
