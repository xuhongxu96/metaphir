#include "metaphir/Exec/TypePattern.h"
#include "metaphir/Exec/PrimitiveTypeMatch.h"
#include "llvm/IR/DerivedTypes.h"

namespace llvm {
namespace metaphir {

unsigned TypePatterns::add(mlir::ArrayAttr Pattern) {
  auto Int = [&](unsigned I) {
    return cast<mlir::IntegerAttr>(Pattern[I]).getInt();
  };
  Node N;
  N.Kind = mpir::TypePatternKind(Int(0));
  unsigned First = 1;
  switch (N.Kind) {
  case mpir::TypePatternKind::Primitive:
  case mpir::TypePatternKind::Variable:
    N.A = Int(1);
    First = 2;
    break;
  case mpir::TypePatternKind::Integer:
  case mpir::TypePatternKind::MetaInteger:
  case mpir::TypePatternKind::Pointer:
  case mpir::TypePatternKind::Struct:
  case mpir::TypePatternKind::Function:
    N.A = Int(1);
    if (N.Kind != mpir::TypePatternKind::Struct &&
        N.Kind != mpir::TypePatternKind::Function)
      N.B = Int(2);
    First = N.Kind == mpir::TypePatternKind::Struct ||
                    N.Kind == mpir::TypePatternKind::Function
                ? 2
                : 3;
    break;
  case mpir::TypePatternKind::Sequence:
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
  case mpir::TypePatternKind::Primitive:
    return primitive_type::matches(primitive_type::TypeID(Node.A), Target);
  case mpir::TypePatternKind::Integer: {
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
  case mpir::TypePatternKind::MetaInteger: {
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
  case mpir::TypePatternKind::Variable:
    return Unify(Node.A, Binding(&Target));
  case mpir::TypePatternKind::Pointer: {
    const auto *Pointer = dyn_cast<llvm::PointerType>(&Target);
    return Node.B && Pointer &&
           (Node.A < 0 || unsigned(Node.A) == Pointer->getAddressSpace());
  }
  case mpir::TypePatternKind::Sequence:
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
  case mpir::TypePatternKind::Struct: {
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
  case mpir::TypePatternKind::Function:
    // Targets are the types of values, and no value has a function type.
    return false;
  }
  llvm_unreachable("invalid type pattern");
}

} // namespace metaphir
} // namespace llvm
