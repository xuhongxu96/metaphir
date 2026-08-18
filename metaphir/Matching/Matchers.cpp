#include "metaphir/Matching/Matchers.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Values.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {
namespace detail {

MatchResults success(Instantiation State) {
  MatchResults Results;
  Results.push_back(std::move(State));
  return Results;
}

bool bind(Instantiation &State, const Value &Matcher,
          Instantiation::Binding Target) {
  if (const Instantiation::Binding *Existing = State.lookup(Matcher))
    return *Existing == Target;
  State.bind(Matcher, std::move(Target));
  return true;
}

} // namespace detail

using detail::bind;
using detail::success;

static bool matches(const MetaVariable &Matcher, const llvm::Value &Target) {
  switch (Matcher.getType()) {
  case MetaType::Value:
    return true;
  case MetaType::Nat:
    return isa<ConstantInt>(Target);
  case MetaType::Bool:
    return Target.getType()->isIntegerTy(1);
  case MetaType::Instruction:
    return isa<llvm::Instruction>(Target);
  case MetaType::Function:
    return isa<llvm::Function>(Target);
  case MetaType::IntrinsicID:
    if (const auto *Function = dyn_cast<llvm::Function>(&Target))
      return Function->isIntrinsic();
    return false;
  case MetaType::BasicBlock:
    return isa<llvm::BasicBlock>(Target);
  case MetaType::Type:
  case MetaType::CmpPredicate:
  case MetaType::TypeArray:
  case MetaType::ValueArray:
    return false;
  case MetaType::Unknown:
    report_fatal_error(Twine("unexpected meta type '") +
                       getMetaTypeName(Matcher.getType()) + "'");
  }
}

static bool matches(const GlobalValue &Matcher, const llvm::Value &Target) {
  const auto *Global = dyn_cast<llvm::GlobalValue>(&Target);
  return Global && Matcher.getName() == Global->getName();
}

static bool matches(const IntegerConstant &Matcher, const llvm::Value &Target) {
  const auto *Integer = dyn_cast<ConstantInt>(&Target);
  return Integer &&
         static_cast<const APInt &>(Matcher.getValue()) == Integer->getValue();
}

static bool matches(const FloatingConstant &Matcher,
                    const llvm::Value &Target) {
  const auto *Floating = dyn_cast<ConstantFP>(&Target);
  return Floating && Matcher.getValue().bitwiseIsEqual(Floating->getValueAPF());
}

static bool matches(const KeywordConstant &Matcher, const llvm::Value &Target) {
  switch (Matcher.getKeywordID()) {
#define MIR_MATCHABLE_CONSTANT_KEYWORD(ID, Spelling, LLVMClass)                \
  case KeywordConstant::K_##ID:                                                \
    return isa<LLVMClass>(Target);
#include "metaphir/IR/KeywordConstants.def"
  default:
    llvm_unreachable("invalid keyword constant ID");
  }
}

static MatchResults matchAggregate(const AggregateConstant &Matcher,
                                   const llvm::Value &Target,
                                   Instantiation State,
                                   const MatchDriver &Driver) {
  const auto *Constant = dyn_cast<llvm::Constant>(&Target);
  if (!Constant)
    return {};

  const llvm::Type *Type = Constant->getType();
  unsigned NumElements = 0;
  switch (Matcher.getDelimiter()) {
  case AggregateConstant::Square:
    if (const auto *Array = dyn_cast<llvm::ArrayType>(Type))
      NumElements = Array->getNumElements();
    else
      return {};
    break;
  case AggregateConstant::Brace:
    if (const auto *Struct = dyn_cast<llvm::StructType>(Type))
      NumElements = Struct->getNumElements();
    else
      return {};
    break;
  case AggregateConstant::Angle:
    if (const auto *Vector = dyn_cast<FixedVectorType>(Type))
      NumElements = Vector->getNumElements();
    else
      return {};
    break;
  }
  if (NumElements != Matcher.getElements().size() ||
      !bind(State, Matcher, Constant))
    return {};

  MatchResults States = success(std::move(State));
  for (unsigned Index = 0; Index != NumElements; ++Index) {
    const llvm::Constant *Element = Constant->getAggregateElement(Index);
    if (!Element)
      return {};
    MatchResults Next;
    for (Instantiation &Candidate : States) {
      MatchResults Matches = Driver.match(*Matcher.getElements()[Index],
                                          *Element, std::move(Candidate));
      Next.append(std::make_move_iterator(Matches.begin()),
                  std::make_move_iterator(Matches.end()));
    }
    States = std::move(Next);
  }
  return States;
}

MatchResults matchValue(const metaphir::Value &Matcher,
                        const llvm::Value &Target, Instantiation State,
                        const MatchDriver &Driver) {
  if (const Instantiation::Binding *Existing = State.lookup(Matcher))
    return *Existing == Instantiation::Binding(&Target)
               ? success(std::move(State))
               : MatchResults();

  switch (Matcher.getValueID()) {
  case Value::InstructionVal:
    return detail::matchInstruction(cast<Instruction>(Matcher), Target,
                                    std::move(State), Driver);
  case Value::AggregateConstantVal:
    return matchAggregate(cast<AggregateConstant>(Matcher), Target,
                          std::move(State), Driver);
  case Value::MetaVariableVal:
    if (!matches(cast<MetaVariable>(Matcher), Target))
      return {};
    break;
  case Value::GlobalVal:
    if (!matches(cast<GlobalValue>(Matcher), Target))
      return {};
    break;
  case Value::IntegerConstantVal:
    if (!matches(cast<IntegerConstant>(Matcher), Target))
      return {};
    break;
  case Value::FloatingConstantVal:
    if (!matches(cast<FloatingConstant>(Matcher), Target))
      return {};
    break;
  case Value::KeywordConstantVal:
    if (!matches(cast<KeywordConstant>(Matcher), Target))
      return {};
    break;
  }
  State.bind(Matcher, &Target);
  return success(std::move(State));
}

bool matchValue(const metaphir::Value &Matcher, const llvm::Value &Target,
                Instantiation &State) {
  auto RecursiveMatch =
      [](const metaphir::Value &Pattern, const llvm::Value &Candidate,
         Instantiation CandidateState, const MatchDriver &Self) {
        return matchValue(Pattern, Candidate, std::move(CandidateState), Self);
      };
  MatchDriver Driver(RecursiveMatch);
  MatchResults Results = Driver.match(Matcher, Target, State);
  if (Results.empty())
    return false;
  State = std::move(Results.front());
  return true;
}

} // namespace metaphir
} // namespace llvm
