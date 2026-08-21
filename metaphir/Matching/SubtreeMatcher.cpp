#include "metaphir/Matching/SubtreeMatcher.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Values.h"
#include "metaphir/Matching/InstructionMatcher.h"
#include "metaphir/Matching/MatchersDetail.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/ErrorHandling.h"
#include <optional>

namespace llvm {
namespace metaphir {

using detail::bind;
using detail::success;

namespace {

bool matches(const GlobalValue &Matcher, const llvm::Value &Target) {
  const auto *Global = dyn_cast<llvm::GlobalValue>(&Target);
  if (!Global)
    return false;
  StringRef MatcherName = Matcher.getName();
  // llvm.* names denote intrinsic function calls (e.g. llvm.ctlz). Match on
  // the intrinsic base name so an overloaded callee (llvm.ctlz.i32) matches
  // the pattern's llvm.ctlz.
  if (MatcherName.starts_with("llvm.")) {
    const auto *Function = dyn_cast<llvm::Function>(Global);
    if (!Function || !Function->isIntrinsic())
      return false;
    return Intrinsic::getBaseName(Function->getIntrinsicID()) == MatcherName;
  }
  return MatcherName == Global->getName();
}

bool matches(const IntegerConstant &Matcher, const llvm::Value &Target) {
  const auto *Integer = dyn_cast<ConstantInt>(&Target);
  if (!Integer)
    return false;
  APSInt TargetValue(Integer->getValue(), Matcher.getValue().isUnsigned());
  return APSInt::isSameValue(Matcher.getValue(), TargetValue);
}

bool matches(const FloatingConstant &Matcher, const llvm::Value &Target) {
  const auto *Floating = dyn_cast<ConstantFP>(&Target);
  if (!Floating)
    return false;
  APFloat Converted = Matcher.getValue();
  bool LosesInfo;
  Converted.convert(Floating->getValueAPF().getSemantics(),
                    APFloat::rmNearestTiesToEven, &LosesInfo);
  return Converted.bitwiseIsEqual(Floating->getValueAPF());
}

bool matches(const KeywordConstant &Matcher, const llvm::Value &Target) {
  switch (Matcher.getKeywordID()) {
#define MIR_MATCHABLE_CONSTANT_KEYWORD(ID, Spelling, LLVMClass)                \
  case KeywordConstant::K_##ID:                                                \
    return isa<LLVMClass>(Target);
#include "metaphir/IR/KeywordConstants.def"
  default:
    llvm_unreachable("invalid keyword constant ID");
  }
}

} // namespace

std::optional<Instantiation::Binding>
SubtreeMatcher::getMetaVariableBinding(const MetaVariable &Matcher) {
  switch (Matcher.getType()) {
  case MetaType::Value:
    return &Target;
  case MetaType::Nat: {
    if (const auto *Integer = dyn_cast<ConstantInt>(&Target))
      return Integer->getValue();
    // A vector splat constant binds its scalar element value.
    if (const auto *Constant = dyn_cast<llvm::Constant>(&Target))
      if (Constant->getType()->isVectorTy())
        if (const auto *Splat = Constant->getSplatValue())
          if (const auto *Integer = dyn_cast<ConstantInt>(Splat))
            return Integer->getValue();
    return std::nullopt;
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

std::optional<Instantiation::Binding> SubtreeMatcher::getTargetBinding() {
  if (const auto *Variable = dyn_cast<MetaVariable>(&Matcher))
    return getMetaVariableBinding(*Variable);
  return &Target;
}

MatchResults SubtreeMatcher::matchAggregate(const AggregateConstant &Matcher) {
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
      MatchResults Matches = SubtreeMatcher(*Matcher.getElements()[Index],
                                            *Element, std::move(Candidate))
                                 .match();
      Next.append(std::make_move_iterator(Matches.begin()),
                  std::make_move_iterator(Matches.end()));
    }
    States = std::move(Next);
  }
  return States;
}

MatchResults SubtreeMatcher::match() {
  std::optional<Instantiation::Binding> TargetBinding = getTargetBinding();
  if (!TargetBinding)
    return {};
  if (const Instantiation::Binding *Existing = State.lookup(Matcher))
    return *Existing == *TargetBinding ? success(std::move(State))
                                       : MatchResults();

  switch (Matcher.getValueID()) {
  case Value::InstructionVal:
    return InstructionMatcher(cast<Instruction>(Matcher), Target,
                              std::move(State))
        .match();
  case Value::AggregateConstantVal:
    return matchAggregate(cast<AggregateConstant>(Matcher));
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

} // namespace metaphir
} // namespace llvm
