#include "metaphir/Matching/TypeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/Matching/MatchersDetail.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {

bool TypeMatcher::matchSequenceType(const SequenceType &Matcher,
                                    const llvm::Type &TargetElement,
                                    uint64_t TargetCount) const {
  if (MetaVariable *Count = Matcher.getCountVariable()) {
    if (!detail::bind(State, *Count, APInt(64, TargetCount)))
      return false;
  } else if (Matcher.getCount() != TargetCount) {
    return false;
  }
  return TypeMatcher(*Matcher.getElementType(), TargetElement, State,
                     TreatIntAsVec)
      .match();
}

bool TypeMatcher::match() const {
  switch (Matcher.getTypeID()) {
  case Type::HalfTyID:
    return Target.isHalfTy();
  case Type::BFloatTyID:
    return Target.isBFloatTy();
  case Type::FloatTyID:
    return Target.isFloatTy();
  case Type::DoubleTyID:
    return Target.isDoubleTy();
  case Type::FP128TyID:
    return Target.isFP128Ty();
  case Type::VoidTyID:
    return Target.isVoidTy();
  case Type::LabelTyID:
    return Target.isLabelTy();
  case Type::IntegerTyID: {
    unsigned Bits = cast<IntegerType>(Matcher).getNumBits();
    if (Target.isIntegerTy(Bits))
      return true;
    if (TreatIntAsVec) {
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        return Vector->getElementType()->isIntegerTy(Bits);
    }
    return false;
  }
  case Type::ByteTyID: {
    unsigned Bits = cast<ByteType>(Matcher).getNumBits();
    if (Target.isByteTy(Bits))
      return true;
    if (TreatIntAsVec) {
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        return Vector->getElementType()->isByteTy(Bits);
    }
    return false;
  }
  case Type::FunctionTyID: {
    const auto *TargetFunction = dyn_cast<llvm::FunctionType>(&Target);
    if (!TargetFunction)
      return false;
    const auto &MatcherFunction = cast<FunctionType>(Matcher);
    if (MatcherFunction.isVarArg() != TargetFunction->isVarArg() ||
        MatcherFunction.getParameterTypes().size() !=
            TargetFunction->getNumParams() ||
        !TypeMatcher(*MatcherFunction.getReturnType(),
                     *TargetFunction->getReturnType(), State, TreatIntAsVec)
             .match())
      return false;
    for (unsigned Index = 0; Index != TargetFunction->getNumParams(); ++Index)
      if (!TypeMatcher(*MatcherFunction.getParameterTypes()[Index],
                       *TargetFunction->getParamType(Index), State,
                       TreatIntAsVec)
               .match())
        return false;
    return true;
  }
  case Type::PointerTyID:
    // LLVM opaque pointers do not retain a pointee type to match recursively.
    return cast<PointerType>(Matcher).isOpaque() &&
           isa<llvm::PointerType>(Target);
  case Type::StructTyID: {
    const auto *TargetStruct = dyn_cast<llvm::StructType>(&Target);
    if (!TargetStruct || TargetStruct->isOpaque())
      return false;
    const auto &MatcherStruct = cast<StructType>(Matcher);
    if (MatcherStruct.isPacked() != TargetStruct->isPacked() ||
        MatcherStruct.getElementTypes().size() !=
            TargetStruct->getNumElements())
      return false;
    for (unsigned Index = 0; Index != TargetStruct->getNumElements(); ++Index)
      if (!TypeMatcher(*MatcherStruct.getElementTypes()[Index],
                       *TargetStruct->getElementType(Index), State,
                       TreatIntAsVec)
               .match())
        return false;
    return true;
  }
  case Type::ArrayTyID: {
    const auto *TargetArray = dyn_cast<llvm::ArrayType>(&Target);
    return TargetArray && matchSequenceType(cast<ArrayType>(Matcher),
                                            *TargetArray->getElementType(),
                                            TargetArray->getNumElements());
  }
  case Type::FixedVectorTyID:
  case Type::ScalableVectorTyID: {
    const auto *TargetVector = dyn_cast<llvm::VectorType>(&Target);
    const auto &MatcherVector = cast<VectorType>(Matcher);
    if (!TargetVector || MatcherVector.isScalable() !=
                             TargetVector->getElementCount().isScalable())
      return false;
    return matchSequenceType(
        MatcherVector, *TargetVector->getElementType(),
        TargetVector->getElementCount().getKnownMinValue());
  }
  case Type::MetaTyID:
    return detail::bind(State, *cast<MetaIRType>(Matcher).getVariable(),
                        &Target);
  case Type::MetaIntegerTyID: {
    const auto &MetaInteger = cast<MetaIntegerType>(Matcher);
    const llvm::Type *Element = &Target;
    if (TreatIntAsVec) {
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        Element = Vector->getElementType();
    }
    uint64_t BitWidth;
    if (MetaInteger.isByte()) {
      if (!Element->isByteTy())
        return false;
      BitWidth = Element->getByteBitWidth();
    } else {
      if (!Element->isIntegerTy())
        return false;
      BitWidth = Element->getIntegerBitWidth();
    }
    return detail::bind(State, *MetaInteger.getBitWidthVariable(),
                        APInt(64, BitWidth));
  }
  }
  llvm_unreachable("invalid MetaphIR type ID");
}

} // namespace metaphir
} // namespace llvm
