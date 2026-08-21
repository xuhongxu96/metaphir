#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
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
evaluateArguments(const ConstraintInterpreter &Interpreter,
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

} // namespace

Expected<ConstraintValue> evaluateIsa(const ConstraintInterpreter &Interpreter,
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

Expected<ConstraintValue>
evaluateOpcode(const ConstraintInterpreter &Interpreter,
               ArrayRef<Constraint *> Arguments, const Instantiation &State,
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

Expected<ConstraintValue> evaluateLog2(const ConstraintInterpreter &Interpreter,
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

Expected<ConstraintValue>
evaluatePopcount(const ConstraintInterpreter &Interpreter,
                 ArrayRef<Constraint *> Arguments, const Instantiation &State,
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

} // namespace metaphir
} // namespace llvm
