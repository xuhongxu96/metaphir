#include "metaphir/Matching/Matchers.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MetaVariable.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {

static bool matchSequenceType(const SequenceType &Matcher,
                              const llvm::Type &TargetElement,
                              uint64_t TargetCount, Instantiation &State) {
  if (MetaVariable *Count = Matcher.getCountVariable()) {
    if (!detail::bind(State, *Count, APInt(64, TargetCount)))
      return false;
  } else if (Matcher.getCount() != TargetCount) {
    return false;
  }
  return matchType(*Matcher.getElementType(), TargetElement, State);
}

bool matchType(const metaphir::Type &Matcher, const llvm::Type &Target,
               Instantiation &State) {
  switch (Matcher.getTypeID()) {
  case metaphir::Type::HalfTyID:
    return Target.isHalfTy();
  case metaphir::Type::BFloatTyID:
    return Target.isBFloatTy();
  case metaphir::Type::FloatTyID:
    return Target.isFloatTy();
  case metaphir::Type::DoubleTyID:
    return Target.isDoubleTy();
  case metaphir::Type::FP128TyID:
    return Target.isFP128Ty();
  case metaphir::Type::VoidTyID:
    return Target.isVoidTy();
  case metaphir::Type::LabelTyID:
    return Target.isLabelTy();
  case metaphir::Type::IntegerTyID:
    return Target.isIntegerTy(cast<IntegerType>(Matcher).getNumBits());
  case metaphir::Type::ByteTyID:
    return Target.isByteTy(cast<ByteType>(Matcher).getNumBits());
  case metaphir::Type::FunctionTyID: {
    const auto *TargetFunction = dyn_cast<llvm::FunctionType>(&Target);
    if (!TargetFunction)
      return false;
    const auto &MatcherFunction = cast<FunctionType>(Matcher);
    if (MatcherFunction.isVarArg() != TargetFunction->isVarArg() ||
        MatcherFunction.getParameterTypes().size() !=
            TargetFunction->getNumParams() ||
        !matchType(*MatcherFunction.getReturnType(),
                   *TargetFunction->getReturnType(), State))
      return false;
    for (unsigned Index = 0; Index != TargetFunction->getNumParams(); ++Index)
      if (!matchType(*MatcherFunction.getParameterTypes()[Index],
                     *TargetFunction->getParamType(Index), State))
        return false;
    return true;
  }
  case metaphir::Type::PointerTyID:
    // LLVM opaque pointers do not retain a pointee type to match recursively.
    return cast<PointerType>(Matcher).isOpaque() &&
           isa<llvm::PointerType>(Target);
  case metaphir::Type::StructTyID: {
    const auto *TargetStruct = dyn_cast<llvm::StructType>(&Target);
    if (!TargetStruct || TargetStruct->isOpaque())
      return false;
    const auto &MatcherStruct = cast<StructType>(Matcher);
    if (MatcherStruct.isPacked() != TargetStruct->isPacked() ||
        MatcherStruct.getElementTypes().size() !=
            TargetStruct->getNumElements())
      return false;
    for (unsigned Index = 0; Index != TargetStruct->getNumElements(); ++Index)
      if (!matchType(*MatcherStruct.getElementTypes()[Index],
                     *TargetStruct->getElementType(Index), State))
        return false;
    return true;
  }
  case metaphir::Type::ArrayTyID: {
    const auto *TargetArray = dyn_cast<llvm::ArrayType>(&Target);
    return TargetArray &&
           matchSequenceType(cast<ArrayType>(Matcher),
                             *TargetArray->getElementType(),
                             TargetArray->getNumElements(), State);
  }
  case metaphir::Type::FixedVectorTyID:
  case metaphir::Type::ScalableVectorTyID: {
    const auto *TargetVector = dyn_cast<llvm::VectorType>(&Target);
    const auto &MatcherVector = cast<VectorType>(Matcher);
    if (!TargetVector || MatcherVector.isScalable() !=
                             TargetVector->getElementCount().isScalable())
      return false;
    return matchSequenceType(MatcherVector, *TargetVector->getElementType(),
                             TargetVector->getElementCount().getKnownMinValue(),
                             State);
  }
  case metaphir::Type::MetaTyID:
    return detail::bind(State, *cast<MetaIRType>(Matcher).getVariable(),
                        &Target);
  case metaphir::Type::MetaIntegerTyID: {
    const auto &MetaInteger = cast<MetaIntegerType>(Matcher);
    uint64_t BitWidth;
    if (MetaInteger.isByte()) {
      if (!Target.isByteTy())
        return false;
      BitWidth = Target.getByteBitWidth();
    } else {
      if (!Target.isIntegerTy())
        return false;
      BitWidth = Target.getIntegerBitWidth();
    }
    return detail::bind(State, *MetaInteger.getBitWidthVariable(),
                        APInt(64, BitWidth));
  }
  }
  llvm_unreachable("invalid MetaphIR type ID");
}

} // namespace metaphir
} // namespace llvm
