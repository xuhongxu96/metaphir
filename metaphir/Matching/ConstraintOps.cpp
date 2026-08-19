#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/IR/Constraints.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

namespace detail {

char ConstraintEvaluationError::ID = 0;

void ConstraintEvaluationError::log(raw_ostream &OS) const {
  OS << "cannot evaluate constraint '" << *Expression << "': " << Message;
}

Error evaluationError(const Constraint &Expression, const Twine &Message) {
  return make_error<ConstraintEvaluationError>(Expression, Message.str());
}

Expected<APSInt> requireInteger(Expected<ConstraintValue> Result,
                                const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::Integer)
    return Result->getInteger();
  if (Result->getKind() == ConstraintValue::Boolean)
    return APSInt(APInt(1, Result->getBoolean()), true);
  // A value binding that is a constant integer can be coerced to an integer
  // so shift amounts / constants captured as Value metas can be used in
  // arithmetic constraints.
  if (Result->getKind() == ConstraintValue::Value) {
    if (const auto *Integer = dyn_cast<ConstantInt>(Result->getValue()))
      return APSInt(Integer->getValue(), true);
    return evaluationError(Expression,
                           "expected an integer-valued constant operand");
  }
  return evaluationError(Expression, "expected an integer-coercible operand");
}

static std::string printValue(const llvm::Value &Value) {
  std::string Text;
  raw_string_ostream OS(Text);
  if (const auto *Instruction = dyn_cast<llvm::Instruction>(&Value))
    Instruction->print(OS);
  else
    Value.printAsOperand(OS, false);
  return OS.str();
}

Expected<std::string> requireString(Expected<ConstraintValue> Result,
                                    const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() == ConstraintValue::String)
    return Result->getString().str();
  std::string Text;
  raw_string_ostream OS(Text);
  if (Result->getKind() == ConstraintValue::Type)
    Result->getType()->print(OS);
  else if (Result->getKind() == ConstraintValue::Value)
    return printValue(*Result->getValue());
  else
    return evaluationError(Expression, "expected a string-coercible operand");
  return OS.str();
}

Expected<const llvm::Value *> requireValue(Expected<ConstraintValue> Result,
                                           const Constraint &Expression) {
  if (!Result)
    return Result.takeError();
  if (Result->getKind() != ConstraintValue::Value)
    return evaluationError(Expression, "expected an LLVM value operand");
  return Result->getValue();
}

ConstraintValue integerResult(APInt Value, bool IsUnsigned) {
  return ConstraintValue::getInteger(APSInt(std::move(Value), IsUnsigned));
}

} // namespace detail

static std::optional<bool> matchesLLVMValueClass(StringRef ClassName,
                                                 const llvm::Value &Value) {
#define MIR_LLVM_VALUE_CLASS(Class)                                            \
  if (ClassName == #Class)                                                     \
    return isa<llvm::Class>(Value);
#include "metaphir/Matching/LLVMValueClasses.def"
  return std::nullopt;
}

static Expected<SmallVector<ConstraintValue, 2>>
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

Expected<ConstraintValue> evaluateIsa(const ConstraintInterpreter &Interpreter,
                                      ArrayRef<Constraint *> Arguments,
                                      const Instantiation &State,
                                      const Constraint &Expression) {
  auto Values = evaluateArguments(Interpreter, Arguments, State);
  if (!Values)
    return Values.takeError();
  auto Value = detail::requireValue(std::move((*Values)[0]), Expression);
  if (!Value)
    return Value.takeError();
  auto ClassName = detail::requireString(std::move((*Values)[1]), Expression);
  if (!ClassName)
    return ClassName.takeError();
  auto Result = matchesLLVMValueClass(*ClassName, **Value);
  if (!Result)
    return detail::evaluationError(
        Expression, Twine("unknown LLVM value class '") + *ClassName + "'");
  return ConstraintValue::getBoolean(*Result);
}

} // namespace metaphir
} // namespace llvm
