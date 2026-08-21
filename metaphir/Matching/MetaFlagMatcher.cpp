#include "metaphir/Matching/MetaFlagMatcher.h"
#include "llvm/IR/PatternMatch.h"

namespace llvm {
namespace metaphir {

bool MetaFlagMatcher::matchOperandFlag(const MetaFlag &Flag,
                                       const llvm::Value &Target) {
  using namespace PatternMatch;

  switch (Flag.getMetaFlagID()) {
  case MetaFlag::MF_s:
    return Target.hasOneUse();
  case MetaFlag::MF_su:
    return Target.hasOneUser();
  case MetaFlag::MF_allones:
    return PatternMatch::match(&Target, m_AllOnes());
  case MetaFlag::MF_zero:
    return PatternMatch::match(&Target, m_Zero());
  case MetaFlag::MF_lowbitmask:
    return PatternMatch::match(&Target, m_LowBitMask());
  case MetaFlag::MF_forbidpoison:
    if (const auto *Constant = dyn_cast<llvm::Constant>(&Target))
      return !isa<PoisonValue>(Constant) && !Constant->containsPoisonElement();
    return false;
  case MetaFlag::MF_integralconstant:
    return PatternMatch::match(&Target, m_AnyIntegralConstant());
  case MetaFlag::MF_zerofp:
    return PatternMatch::match(&Target, m_AnyZeroFP());
  case MetaFlag::MF_poison:
    return PatternMatch::match(&Target, m_Poison());
  case MetaFlag::MF_apint: {
    const APInt *Value = nullptr;
    return PatternMatch::match(&Target, m_APInt(Value));
  }
  case MetaFlag::MF_constantint:
    return isa<llvm::ConstantInt>(Target);
  case MetaFlag::MF_constantsplat: {
    if (const auto &CI = dyn_cast<ConstantInt>(&Target))
      return true;
    if (const auto *Constant = dyn_cast<llvm::Constant>(&Target))
      if (Constant->getType()->isVectorTy())
        return Constant->getSplatValue();
    return false;
  }
  case MetaFlag::MF_poweroftwo:
    return PatternMatch::match(&Target, m_Power2());
  case MetaFlag::MF_or: {
    assert(!Flag.getArguments().empty() &&
           "':or' requires at least one argument");
    return any_of(Flag.getArguments(), [&](const MetaFlag::Argument &Argument) {
      return matchOperandFlag(getNestedMetaFlag(Argument), Target);
    });
  }
  case MetaFlag::MF_not:
    assert(Flag.getArguments().size() == 1 &&
           "':not' requires exactly one argument");
    return !matchOperandFlag(getNestedMetaFlag(Flag.getArguments().front()),
                             Target);
  case MetaFlag::MF_c:
  case MetaFlag::MF_o:
    llvm_unreachable("instruction meta flag used on an operand");
  case MetaFlag::UnknownMetaFlag:
    llvm_unreachable("invalid meta flag ID");
  }
}

const MetaFlag &
MetaFlagMatcher::getNestedMetaFlag(const MetaFlag::Argument &Argument) {
  assert(Argument.K == MetaFlag::Argument::Flag && Argument.FlagValue &&
         "expected a nested meta flag argument");
  return *Argument.FlagValue;
}

bool MetaFlagMatcher::matchOperandFlags(const llvm::Value &Target) {
  return all_of(Flags, [&](const MetaFlag *Flag) {
    assert(Flag && "null operand meta flag");
    return matchOperandFlag(*Flag, Target);
  });
}

bool MetaFlagMatcher::matchUseFlags(const llvm::Value &Target) {
  for (const MetaFlag *Flag : Flags) {
    switch (Flag->getMetaFlagID()) {
    case MetaFlag::MF_s:
      if (!Target.hasOneUse())
        return false;
      break;
    case MetaFlag::MF_su:
      if (!Target.hasOneUser())
        return false;
      break;
    default:
      break;
    }
  }
  return true;
}

} // namespace metaphir
} // namespace llvm