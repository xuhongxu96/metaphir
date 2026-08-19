#include "metaphir/Matching/Matchers.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Values.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"
#include <optional>

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

static std::optional<Instantiation::Binding>
getMetaVariableBinding(const MetaVariable &Matcher, const llvm::Value &Target) {
  switch (Matcher.getType()) {
  case MetaType::Value:
    return &Target;
  case MetaType::Nat: {
    const auto *Integer = dyn_cast<ConstantInt>(&Target);
    if (!Integer)
      return std::nullopt;
    return Integer->getValue();
  }
  case MetaType::Bool:
    if (!Target.getType()->isIntegerTy(1))
      return std::nullopt;
    return &Target;
  case MetaType::Instruction:
    if (!isa<llvm::Instruction>(Target))
      return std::nullopt;
    return &Target;
  case MetaType::Function:
    if (!isa<llvm::Function>(Target))
      return std::nullopt;
    return &Target;
  case MetaType::IntrinsicID: {
    const auto *Function = dyn_cast<llvm::Function>(&Target);
    if (!Function || !Function->isIntrinsic())
      return std::nullopt;
    return Function->getIntrinsicID();
  }
  case MetaType::BasicBlock:
    if (!isa<llvm::BasicBlock>(Target))
      return std::nullopt;
    return &Target;
  case MetaType::Type:
  case MetaType::CmpPredicate:
  case MetaType::TypeArray:
  case MetaType::ValueArray:
    return std::nullopt;
  case MetaType::Unknown:
    report_fatal_error(Twine("unexpected meta type '") +
                       getMetaTypeName(Matcher.getType()) + "'");
  }
  llvm_unreachable("invalid meta type");
}

static std::optional<Instantiation::Binding>
getTargetBinding(const metaphir::Value &Matcher, const llvm::Value &Target) {
  if (const auto *Variable = dyn_cast<MetaVariable>(&Matcher))
    return getMetaVariableBinding(*Variable, Target);
  return &Target;
}

static bool matches(const GlobalValue &Matcher, const llvm::Value &Target) {
  const auto *Global = dyn_cast<llvm::GlobalValue>(&Target);
  return Global && Matcher.getName() == Global->getName();
}

static bool matches(const IntegerConstant &Matcher, const llvm::Value &Target) {
  const auto *Integer = dyn_cast<ConstantInt>(&Target);
  if (!Integer)
    return false;
  APSInt TargetValue(Integer->getValue(), Matcher.getValue().isUnsigned());
  return APSInt::isSameValue(Matcher.getValue(), TargetValue);
}

static bool matches(const FloatingConstant &Matcher,
                    const llvm::Value &Target) {
  const auto *Floating = dyn_cast<ConstantFP>(&Target);
  if (!Floating)
    return false;
  APFloat Converted = Matcher.getValue();
  bool LosesInfo;
  Converted.convert(Floating->getValueAPF().getSemantics(),
                    APFloat::rmNearestTiesToEven, &LosesInfo);
  return Converted.bitwiseIsEqual(Floating->getValueAPF());
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
  std::optional<Instantiation::Binding> TargetBinding =
      getTargetBinding(Matcher, Target);
  if (!TargetBinding)
    return {};
  if (const Instantiation::Binding *Existing = State.lookup(Matcher))
    return *Existing == *TargetBinding ? success(std::move(State))
                                       : MatchResults();

  switch (Matcher.getValueID()) {
  case Value::InstructionVal:
    return detail::matchInstruction(cast<Instruction>(Matcher), Target,
                                    std::move(State), Driver);
  case Value::AggregateConstantVal:
    return matchAggregate(cast<AggregateConstant>(Matcher), Target,
                          std::move(State), Driver);
  case Value::MetaVariableVal:
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
  State.bind(Matcher, std::move(*TargetBinding));
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
