#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

IntegerType *IntegerType::get(MIRContext &C, unsigned NumBits) {
  assert(NumBits >= 1 && "bitwidth too small");

  IntegerType *&Entry = C.pImpl->IntegerTypes[NumBits];

  if (!Entry)
    Entry = new (C.pImpl->Alloc) IntegerType(C, NumBits);

  return Entry;
}

ByteType *ByteType::get(MIRContext &C, unsigned NumBits) {
  assert(NumBits >= 1 && "bitwidth too small");

  ByteType *&Entry = C.pImpl->ByteTypes[NumBits];

  if (!Entry)
    Entry = new (C.pImpl->Alloc) ByteType(C, NumBits);

  return Entry;
}

MetaIRType *MetaIRType::get(MIRContext &C, MetaVariable *Variable) {
  MetaIRType *&Entry = C.pImpl->MetaIRTypes[Variable];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) MetaIRType(C, Variable);
  return Entry;
}

MetaIntegerType *MetaIntegerType::get(MIRContext &C, MetaVariable *BitWidth,
                                      bool Byte) {
  const MetaIntegerTypeKeyInfo::KeyTy Key(BitWidth, Byte);
  auto Insertion = C.pImpl->MetaIntegerTypes.insert_as(nullptr, Key);
  if (Insertion.second)
    *Insertion.first = new (C.pImpl->Alloc) MetaIntegerType(C, BitWidth, Byte);
  return *Insertion.first;
}

PointerType *PointerType::get(MIRContext &C, Type *Element) {
  PointerType *&Entry = C.pImpl->PointerTypes[Element];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) PointerType(C, Element);
  return Entry;
}

ArrayType *ArrayType::get(MIRContext &C, Type *Element, uint64_t Count,
                          MetaVariable *CountVar) {
  const ArrayTypeKeyInfo::KeyTy Key(Element, Count, CountVar);
  auto Insertion = C.pImpl->ArrayTypes.insert_as(nullptr, Key);
  if (Insertion.second)
    *Insertion.first =
        new (C.pImpl->Alloc) ArrayType(C, Element, Count, CountVar);
  return *Insertion.first;
}

VectorType *VectorType::get(MIRContext &C, bool Scalable, Type *Element,
                            uint64_t Count, MetaVariable *CountVar) {
  const VectorTypeKeyInfo::KeyTy Key(Element, Count, CountVar, Scalable);
  auto Insertion = C.pImpl->VectorTypes.insert_as(nullptr, Key);
  if (Insertion.second)
    *Insertion.first =
        new (C.pImpl->Alloc) VectorType(C, Scalable, Element, Count, CountVar);
  return *Insertion.first;
}

StructType *StructType::get(MIRContext &C, ArrayRef<Type *> Elements,
                            bool Packed) {
  const StructTypeKeyInfo::KeyTy Key(Elements, Packed);
  auto Insertion = C.pImpl->StructTypes.insert_as(nullptr, Key);
  if (Insertion.second)
    *Insertion.first = new (C.pImpl->Alloc)
        StructType(C, C.pImpl->copyArray<Type *>(Elements), Packed);
  return *Insertion.first;
}

FunctionType *FunctionType::get(MIRContext &C, Type *ReturnType,
                                ArrayRef<Type *> Parameters, bool VarArg) {
  const FunctionTypeKeyInfo::KeyTy Key(ReturnType, Parameters, VarArg);
  auto Insertion = C.pImpl->FunctionTypes.insert_as(nullptr, Key);
  if (Insertion.second)
    *Insertion.first = new (C.pImpl->Alloc) FunctionType(
        C, ReturnType, C.pImpl->copyArray<Type *>(Parameters), VarArg);
  return *Insertion.first;
}

} // namespace metaphir
} // namespace llvm
