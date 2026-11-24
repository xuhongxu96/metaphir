#include "metaphir/Exec/TypePattern.h"
#include "metaphir/Exec/PrimitiveTypeMatch.h"
#include "llvm/ADT/TypeSwitch.h"
#include "llvm/IR/DerivedTypes.h"

namespace llvm {
namespace metaphir {

/// Whether Pattern matches Target, binding its variables with Unify.
static bool matchPattern(mpir::TypePatternAttr Pattern,
                         const llvm::Type &Target, bool TreatIntAsVec,
                         TypePatterns::UnifyFn Unify) {
  // With TreatIntAsVec, an integer pattern also matches a vector's element.
  auto Scalar = [&]() -> const llvm::Type & {
    if (TreatIntAsVec)
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        return *Vector->getElementType();
    return Target;
  };
  return TypeSwitch<mpir::TypePatternAttr, bool>(Pattern)
      .Case([&](mpir::VarTypePatternAttr Var) {
        return Unify(Var.getSlot(), Binding(&Target));
      })
      .Case([&](mpir::PrimTypePatternAttr Prim) {
        return primitive_type::matches(Prim.getKind(), Target);
      })
      .Case([&](mpir::IntTypePatternAttr Int) {
        return Target.isIntegerTy(Int.getWidth()) ||
               Scalar().isIntegerTy(Int.getWidth());
      })
      .Case([&](mpir::ByteTypePatternAttr Byte) {
        return Target.isByteTy(Byte.getWidth()) ||
               Scalar().isByteTy(Byte.getWidth());
      })
      .Case([&](mpir::IntWidthTypePatternAttr Int) {
        const llvm::Type &Element = Scalar();
        return Element.isIntegerTy() &&
               Unify(Int.getWidthSlot(),
                     Binding(APInt(64, Element.getIntegerBitWidth())));
      })
      .Case([&](mpir::ByteWidthTypePatternAttr Byte) {
        const llvm::Type &Element = Scalar();
        return Element.isByteTy() &&
               Unify(Byte.getWidthSlot(),
                     Binding(APInt(64, Element.getByteBitWidth())));
      })
      .Case([&](mpir::PtrTypePatternAttr Ptr) {
        // No LLVM type is a typed pointer.
        const auto *Pointer = dyn_cast<llvm::PointerType>(&Target);
        return !Ptr.getElement() && Pointer &&
               (!Ptr.getAddressSpace() ||
                *Ptr.getAddressSpace() == Pointer->getAddressSpace());
      })
      .Case([&](mpir::SeqTypePatternAttr Seq) {
        const llvm::Type *Element;
        uint64_t Count;
        if (Seq.getKind() == mpir::SeqKind::Array) {
          const auto *Array = dyn_cast<llvm::ArrayType>(&Target);
          if (!Array)
            return false;
          Element = Array->getElementType();
          Count = Array->getNumElements();
        } else {
          const auto *Vector = dyn_cast<llvm::VectorType>(&Target);
          if (!Vector || (Seq.getKind() == mpir::SeqKind::ScalableVector) !=
                             Vector->getElementCount().isScalable())
            return false;
          Element = Vector->getElementType();
          Count = Vector->getElementCount().getKnownMinValue();
        }
        if (std::optional<unsigned> Slot = Seq.getCountSlot()) {
          if (!Unify(*Slot, Binding(APInt(64, Count))))
            return false;
        } else if (*Seq.getCount() != Count) {
          return false;
        }
        return matchPattern(Seq.getElement(), *Element, TreatIntAsVec, Unify);
      })
      .Case([&](mpir::StructTypePatternAttr Struct) {
        const auto *Literal = dyn_cast<llvm::StructType>(&Target);
        if (!Literal || Literal->isOpaque() ||
            Struct.getPacked() != Literal->isPacked() ||
            Struct.getElements().size() != Literal->getNumElements())
          return false;
        for (auto [Element, Of] :
             zip(Struct.getElements(), Literal->elements()))
          if (!matchPattern(Element, *Of, TreatIntAsVec, Unify))
            return false;
        return true;
      })
      .Case([&](mpir::FuncTypePatternAttr) {
        // Targets are the types of values, and no value has a function type.
        return false;
      });
}

bool TypePatterns::match(unsigned Index, const llvm::Type &Target,
                         bool TreatIntAsVec, UnifyFn Unify) const {
  return matchPattern(Patterns[Index], Target, TreatIntAsVec, Unify);
}

} // namespace metaphir
} // namespace llvm
