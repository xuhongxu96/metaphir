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
  MetaIntegerType *&Entry = C.pImpl->MetaIntegerTypes[{BitWidth, Byte}];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) MetaIntegerType(C, BitWidth, Byte);
  return Entry;
}

PointerType *PointerType::get(MIRContext &C, Type *Element,
                              unsigned AddressSpace) {
  PointerType *&Entry = C.pImpl->PointerTypes[{Element, AddressSpace}];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) PointerType(C, Element, AddressSpace);
  return Entry;
}

ArrayType *ArrayType::get(MIRContext &C, Type *Element, uint64_t Count,
                          MetaVariable *CountVar) {
  ArrayType *&Entry = C.pImpl->ArrayTypes[{Element, Count, CountVar}];
  if (!Entry)
    Entry = new (C.pImpl->Alloc) ArrayType(C, Element, Count, CountVar);
  return Entry;
}

VectorType *VectorType::get(MIRContext &C, bool Scalable, Type *Element,
                            uint64_t Count, MetaVariable *CountVar) {
  VectorType *&Entry =
      C.pImpl->VectorTypes[{Element, Count, CountVar, Scalable}];
  if (!Entry)
    Entry =
        new (C.pImpl->Alloc) VectorType(C, Scalable, Element, Count, CountVar);
  return Entry;
}

// Aggregate types own a copy of their element array, and their map key refers
// to that copy rather than to the caller's array.
StructType *StructType::get(MIRContext &C, ArrayRef<Type *> Elements,
                            bool Packed) {
  if (StructType *Existing = C.pImpl->StructTypes.lookup({Elements, Packed}))
    return Existing;
  auto *New =
      new (C.pImpl->Alloc) StructType(C, C.pImpl->copyArray(Elements), Packed);
  C.pImpl->StructTypes[{New->getElementTypes(), Packed}] = New;
  return New;
}

FunctionType *FunctionType::get(MIRContext &C, Type *ReturnType,
                                ArrayRef<Type *> Parameters, bool VarArg) {
  if (FunctionType *Existing =
          C.pImpl->FunctionTypes.lookup({ReturnType, Parameters, VarArg}))
    return Existing;
  auto *New = new (C.pImpl->Alloc)
      FunctionType(C, ReturnType, C.pImpl->copyArray(Parameters), VarArg);
  C.pImpl->FunctionTypes[{ReturnType, New->getParameterTypes(), VarArg}] = New;
  return New;
}

} // namespace metaphir
} // namespace llvm
