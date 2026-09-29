#include "metaphir/IR/Type.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/MetaVariable.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

Type *Type::get(MIRContext &C, TypeID ID) {
  assert(ID < IntegerTyID &&
         "not a primitive type; use the derived type's get");
  Type *&Entry = C.pImpl->PrimitiveTypes[static_cast<unsigned>(ID)];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) Type(C, ID);
  return Entry;
}

raw_ostream &operator<<(raw_ostream &OS, const Type &T) {
  switch (T.getTypeID()) {
  case Type::HalfTyID:
    OS << "half";
    break;
  case Type::BFloatTyID:
    OS << "bfloat";
    break;
  case Type::FloatTyID:
    OS << "float";
    break;
  case Type::DoubleTyID:
    OS << "double";
    break;
  case Type::FP128TyID:
    OS << "fp128";
    break;
  case Type::VoidTyID:
    OS << "void";
    break;
  case Type::LabelTyID:
    OS << "label";
    break;
  case Type::IntegerTyID:
    OS << "i" << cast<IntegerType>(T).getNumBits();
    break;
  case Type::ByteTyID:
    OS << "b" << cast<ByteType>(T).getNumBits();
    break;
  case Type::FunctionTyID: {
    const auto &F = cast<FunctionType>(T);
    OS << *F.getReturnType() << " (";
    interleaveComma(F.getParameterTypes(), OS,
                    [&OS](const Type *P) { OS << *P; });
    if (F.isVarArg())
      OS << (F.getParameterTypes().empty() ? "..." : ", ...");
    OS << ')';
    break;
  }
  case Type::PointerTyID: {
    const auto &P = cast<PointerType>(T);
    if (P.isOpaque())
      OS << "ptr";
    else
      OS << *P.getElementType() << '*';
    if (P.getAddressSpace() != PointerType::AnyAddressSpace)
      OS << " addrspace(" << P.getAddressSpace() << ')';
    break;
  }
  case Type::StructTyID: {
    const auto &S = cast<StructType>(T);
    if (S.isPacked())
      OS << '<';
    OS << '{';
    for (unsigned I = 0; I != S.getElementTypes().size(); ++I) {
      if (I)
        OS << ", ";
      OS << *S.getElementTypes()[I];
    }
    OS << '}';
    if (S.isPacked())
      OS << '>';
    break;
  }
  case Type::ArrayTyID:
  case Type::FixedVectorTyID:
  case Type::ScalableVectorTyID: {
    const auto &S = cast<SequenceType>(T);
    char Open = T.getTypeID() == Type::ArrayTyID ? '[' : '<';
    char Close = T.getTypeID() == Type::ArrayTyID ? ']' : '>';
    OS << Open;
    if (T.getTypeID() == Type::ScalableVectorTyID)
      OS << "vscale x ";
    if (S.getCountVariable())
      OS << '?' << S.getCountVariable()->getName();
    else
      OS << S.getCount();
    OS << " x " << *S.getElementType() << Close;
    break;
  }
  case Type::MetaTyID:
    OS << '?' << cast<MetaIRType>(T).getVariable()->getName();
    break;
  case Type::MetaIntegerTyID: {
    const auto &M = cast<MetaIntegerType>(T);
    OS << (M.isByte() ? 'b' : 'i') << '?' << M.getBitWidthVariable()->getName();
    break;
  }
  }
  return OS;
}

} // namespace metaphir
} // namespace llvm
