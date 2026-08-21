#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Analysis/WithCache.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include <optional>

namespace llvm {
namespace metaphir {

using namespace detail;

namespace {

// Evaluates every argument in order, collecting the results into a vector so
// that an interpreted built-in can coerce them with the shared require*
// helpers.
Expected<SmallVector<ConstraintValue, 2>>
evaluateArguments(ConstraintInterpreter &Interpreter,
                  ArrayRef<Constraint *> Arguments,
                  const Instantiation &State) {
  SmallVector<ConstraintValue, 2> Values;
  Values.reserve(Arguments.size());
  for (const Constraint *Argument : Arguments) {
    Expected<ConstraintValue> Value = Interpreter.evaluate(*Argument, State);
    if (!Value)
      return Value.takeError();
    Values.push_back(std::move(*Value));
  }
  return Values;
}

std::optional<bool> matchesLLVMValueClass(StringRef ClassName,
                                          const llvm::Value &Value) {
#define MIR_LLVM_VALUE_CLASS(Class)                                            \
  if (ClassName == #Class)                                                     \
    return isa<llvm::Class>(Value);
#include "metaphir/Matching/LLVMValueClasses.def"
  return std::nullopt;
}

// Value with an integer (or vector-of-integer) type, as required by the
// integer value-tracking queries.
Expected<const llvm::Value *>
requireIntegerValue(Expected<ConstraintValue> Result,
                    const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireValue(std::move(Result), Expression);
  if (!Value)
    return Value.takeError();
  const llvm::Type *Type = (*Value)->getType();
  if (const auto *Vector = dyn_cast<llvm::VectorType>(Type))
    Type = Vector->getElementType();
  if (Type->isIntegerTy())
    return Value;
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an integer-typed value operand");
}

unsigned integerElementWidth(const llvm::Value &Value) {
  const llvm::Type *Type = Value.getType();
  if (const auto *Vector = dyn_cast<llvm::VectorType>(Type))
    Type = Vector->getElementType();
  return cast<llvm::IntegerType>(Type)->getBitWidth();
}

// Copies a constraint value into an Expected so a require* helper can consume
// it (the operand list passed to a value-tracking operator is read-only).
Expected<ConstraintValue> copyValue(const ConstraintValue &Value) {
  return Expected<ConstraintValue>(Value);
}

} // namespace

Expected<ConstraintValue> evaluateIsa(ConstraintInterpreter &Interpreter,
                                      ArrayRef<Constraint *> Arguments,
                                      const Instantiation &State,
                                      const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  auto Value = requireValue(std::move((*Values)[0]), Expression);
  if (!Value)
    return Value.takeError();
  auto ClassName = requireString(std::move((*Values)[1]), Expression);
  if (!ClassName)
    return ClassName.takeError();
  auto Result = matchesLLVMValueClass(*ClassName, **Value);
  if (!Result)
    return make_error<ConstraintEvaluationError>(
        Expression, Twine("unknown LLVM value class '") + *ClassName + "'");
  return ConstraintValue::getBoolean(*Result);
}

Expected<ConstraintValue> evaluateOpcode(ConstraintInterpreter &Interpreter,
                                         ArrayRef<Constraint *> Arguments,
                                         const Instantiation &State,
                                         const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  auto Value = requireValue(std::move((*Values)[0]), Expression);
  if (!Value)
    return Value.takeError();
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(*Value))
    return ConstraintValue::getString(Instruction->getOpcodeName());
  return make_error<ConstraintEvaluationError>(
      Expression, "expected an instruction operand");
}

Expected<ConstraintValue> evaluateLog2(ConstraintInterpreter &Interpreter,
                                       ArrayRef<Constraint *> Arguments,
                                       const Instantiation &State,
                                       const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  auto Operand = requireInteger(std::move((*Values)[0]), Expression);
  if (!Operand)
    return Operand.takeError();
  if (Operand->isNegative() || Operand->isZero())
    return make_error<ConstraintEvaluationError>(
        Expression, "log2 requires a positive operand");
  return integerResult(APInt(Operand->getBitWidth(), Operand->logBase2(), true),
                       true);
}

Expected<ConstraintValue> evaluatePopcount(ConstraintInterpreter &Interpreter,
                                           ArrayRef<Constraint *> Arguments,
                                           const Instantiation &State,
                                           const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  auto Operand = requireInteger(std::move((*Values)[0]), Expression);
  if (!Operand)
    return Operand.takeError();
  return integerResult(APInt(Operand->getBitWidth(), Operand->popcount(), true),
                       true);
}

Expected<ConstraintValue> evaluateNoOverflow(ArrayRef<ConstraintValue> Values,
                                             const SimplifyQuery &Query,
                                             const Constraint &Expression) {
  Expected<std::string> Kind = requireString(copyValue(Values[0]), Expression);
  if (!Kind)
    return Kind.takeError();
  Expected<const llvm::Value *> LHS =
      requireIntegerValue(copyValue(Values[1]), Expression);
  if (!LHS)
    return LHS.takeError();
  Expected<const llvm::Value *> RHS =
      requireIntegerValue(copyValue(Values[2]), Expression);
  if (!RHS)
    return RHS.takeError();

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
        Expression, Twine("unknown overflow kind '") + *Kind + "'");
  return ConstraintValue::getBoolean(Result == OverflowResult::NeverOverflows);
}

Expected<ConstraintValue> evaluateKnownBits(ArrayRef<ConstraintValue> Values,
                                            const SimplifyQuery &Query,
                                            const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getKnownBits(computeKnownBits(*Value, Query));
}

Expected<ConstraintValue> evaluateKnownZeros(ConstraintInterpreter &Interpreter,
                                             ArrayRef<Constraint *> Arguments,
                                             const Instantiation &State,
                                             const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  if ((*Values)[0].getKind() != ConstraintValue::BitVector)
    return make_error<ConstraintEvaluationError>(
        Expression, "expected a bit-vector operand");
  return integerResult((*Values)[0].getKnownBits().Zero, true);
}

Expected<ConstraintValue> evaluateKnownOnes(ConstraintInterpreter &Interpreter,
                                            ArrayRef<Constraint *> Arguments,
                                            const Instantiation &State,
                                            const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  if ((*Values)[0].getKind() != ConstraintValue::BitVector)
    return make_error<ConstraintEvaluationError>(
        Expression, "expected a bit-vector operand");
  return integerResult((*Values)[0].getKnownBits().One, true);
}

Expected<ConstraintValue>
evaluateIsKnownNonZero(ArrayRef<ConstraintValue> Values,
                       const SimplifyQuery &Query,
                       const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNonZero(*Value, Query));
}

Expected<ConstraintValue>
evaluateIsKnownNegative(ArrayRef<ConstraintValue> Values,
                        const SimplifyQuery &Query,
                        const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNegative(*Value, Query));
}

Expected<ConstraintValue>
evaluateIsKnownNonNegative(ArrayRef<ConstraintValue> Values,
                           const SimplifyQuery &Query,
                           const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownNonNegative(*Value, Query));
}

Expected<ConstraintValue>
evaluateIsKnownPositive(ArrayRef<ConstraintValue> Values,
                        const SimplifyQuery &Query,
                        const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(isKnownPositive(*Value, Query));
}

Expected<ConstraintValue>
evaluateIsKnownPowerOfTwo(ArrayRef<ConstraintValue> Values,
                          const SimplifyQuery &Query,
                          const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  return ConstraintValue::getBoolean(
      isKnownToBeAPowerOfTwo(*Value, /*OrZero=*/false, Query));
}

Expected<ConstraintValue>
evaluateMaskedValueIsZero(ArrayRef<ConstraintValue> Values,
                          const SimplifyQuery &Query,
                          const Constraint &Expression) {
  Expected<const llvm::Value *> Value =
      requireIntegerValue(copyValue(Values[0]), Expression);
  if (!Value)
    return Value.takeError();
  Expected<APSInt> Mask = requireInteger(copyValue(Values[1]), Expression);
  if (!Mask)
    return Mask.takeError();
  APInt MaskValue = Mask->zextOrTrunc(integerElementWidth(**Value));
  return ConstraintValue::getBoolean(
      MaskedValueIsZero(*Value, MaskValue, Query));
}

} // namespace metaphir
} // namespace llvm
