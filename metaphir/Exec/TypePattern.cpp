#include "metaphir/Exec/TypePattern.h"
#include "metaphir/IR/Type.h"
#include "llvm/IR/DerivedTypes.h"

namespace llvm {
namespace metaphir {

using Binding = Instantiation::Binding;
namespace plan = mpir_plan;

unsigned TypePatterns::add(mlir::ArrayAttr Pattern) {
  auto Int = [&](unsigned I) {
    return cast<mlir::IntegerAttr>(Pattern[I]).getInt();
  };
  Node N;
  N.Kind = plan::TypePatternKind(Int(0));
  unsigned First = 1;
  switch (N.Kind) {
  case plan::TypePatternKind::Primitive:
  case plan::TypePatternKind::Variable:
    N.A = Int(1);
    First = 2;
    break;
  case plan::TypePatternKind::Integer:
  case plan::TypePatternKind::MetaInteger:
  case plan::TypePatternKind::Pointer:
  case plan::TypePatternKind::Struct:
  case plan::TypePatternKind::Function:
    N.A = Int(1);
    if (N.Kind != plan::TypePatternKind::Struct &&
        N.Kind != plan::TypePatternKind::Function)
      N.B = Int(2);
    First = N.Kind == plan::TypePatternKind::Struct ||
                    N.Kind == plan::TypePatternKind::Function
                ? 2
                : 3;
    break;
  case plan::TypePatternKind::Sequence:
    N.A = Int(1);
    N.B = Int(2);
    N.C = Int(3);
    First = 4;
    break;
  }
  for (unsigned I = First; I < Pattern.size(); ++I)
    N.Children.push_back(add(cast<mlir::ArrayAttr>(Pattern[I])));
  Nodes.push_back(std::move(N));
  return Nodes.size() - 1;
}

bool TypePatterns::match(unsigned Index, const llvm::Type &Target,
                         bool TreatIntAsVec, UnifyFn Unify) const {
  const Node &Node = Nodes[Index];
  auto Sequence = [&](const llvm::Type &Element, uint64_t Count) {
    if (Node.C >= 0) {
      if (!Unify(Node.C, Binding(APInt(64, Count))))
        return false;
    } else if (uint64_t(Node.B) != Count) {
      return false;
    }
    return match(Node.Children[0], Element, TreatIntAsVec, Unify);
  };
  switch (Node.Kind) {
  case plan::TypePatternKind::Primitive:
    switch (Type::TypeID(Node.A)) {
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
    default:
      return false;
    }
  case plan::TypePatternKind::Integer: {
    unsigned Bits = Node.A;
    bool Byte = Node.B;
    auto Is = [&](const llvm::Type &T) {
      return Byte ? T.isByteTy(Bits) : T.isIntegerTy(Bits);
    };
    if (Is(Target))
      return true;
    if (TreatIntAsVec)
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        return Is(*Vector->getElementType());
    return false;
  }
  case plan::TypePatternKind::MetaInteger: {
    const llvm::Type *Element = &Target;
    if (TreatIntAsVec)
      if (const auto *Vector = dyn_cast<llvm::VectorType>(&Target))
        Element = Vector->getElementType();
    uint64_t Width;
    if (Node.B) {
      if (!Element->isByteTy())
        return false;
      Width = Element->getByteBitWidth();
    } else {
      if (!Element->isIntegerTy())
        return false;
      Width = Element->getIntegerBitWidth();
    }
    return Unify(Node.A, Binding(APInt(64, Width)));
  }
  case plan::TypePatternKind::Variable:
    return Unify(Node.A, Binding(&Target));
  case plan::TypePatternKind::Pointer: {
    const auto *Pointer = dyn_cast<llvm::PointerType>(&Target);
    return Node.B && Pointer &&
           (Node.A < 0 || unsigned(Node.A) == Pointer->getAddressSpace());
  }
  case plan::TypePatternKind::Sequence:
    if (Node.A == 0) {
      const auto *Array = dyn_cast<llvm::ArrayType>(&Target);
      return Array &&
             Sequence(*Array->getElementType(), Array->getNumElements());
    } else {
      const auto *Vector = dyn_cast<llvm::VectorType>(&Target);
      if (!Vector || (Node.A == 2) != Vector->getElementCount().isScalable())
        return false;
      return Sequence(*Vector->getElementType(),
                      Vector->getElementCount().getKnownMinValue());
    }
  case plan::TypePatternKind::Struct: {
    const auto *Struct = dyn_cast<llvm::StructType>(&Target);
    if (!Struct || Struct->isOpaque() || bool(Node.A) != Struct->isPacked() ||
        Node.Children.size() != Struct->getNumElements())
      return false;
    for (unsigned I = 0; I != Struct->getNumElements(); ++I)
      if (!match(Node.Children[I], *Struct->getElementType(I), TreatIntAsVec,
                 Unify))
        return false;
    return true;
  }
  case plan::TypePatternKind::Function: {
    const auto *Function = dyn_cast<llvm::FunctionType>(&Target);
    if (!Function || bool(Node.A) != Function->isVarArg() ||
        Node.Children.size() - 1 != Function->getNumParams() ||
        !match(Node.Children[0], *Function->getReturnType(), TreatIntAsVec,
               Unify))
      return false;
    for (unsigned I = 0; I != Function->getNumParams(); ++I)
      if (!match(Node.Children[I + 1], *Function->getParamType(I),
                 TreatIntAsVec, Unify))
        return false;
    return true;
  }
  }
  llvm_unreachable("invalid type pattern");
}

} // namespace metaphir
} // namespace llvm
