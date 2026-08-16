#ifndef METAPHIR_IR_DERIVEDTYPES_H
#define METAPHIR_IR_DERIVEDTYPES_H

#include "metaphir/IR/Type.h"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

class MIRContext;
class MetaVariable;

class IntegerType : public Type {
public:
  unsigned getNumBits() const { return NumBits; }
  static IntegerType *get(MIRContext &C, unsigned NumBits);
  static bool classof(const Type *T) { return T->getTypeID() == IntegerTyID; }

private:
  unsigned NumBits;

  explicit IntegerType(MIRContext &C, unsigned NumBits)
      : Type(C, IntegerTyID), NumBits(NumBits) {}
};

class ByteType : public Type {
public:
  unsigned getNumBits() const { return NumBits; }
  static ByteType *get(MIRContext &C, unsigned NumBits);
  static bool classof(const Type *T) { return T->getTypeID() == ByteTyID; }

private:
  unsigned NumBits;

  explicit ByteType(MIRContext &C, unsigned NumBits)
      : Type(C, ByteTyID), NumBits(NumBits) {}
};

class FunctionType : public Type {
public:
  Type *getReturnType() const { return ReturnType; }
  ArrayRef<Type *> getParameterTypes() const { return Parameters; }
  bool isVarArg() const { return VarArg; }

  static FunctionType *get(MIRContext &C, Type *ReturnType,
                           ArrayRef<Type *> Parameters, bool VarArg = false);

  static bool classof(const Type *T) { return T->getTypeID() == FunctionTyID; }

private:
  Type *ReturnType;
  ArrayRef<Type *> Parameters;
  bool VarArg;

  FunctionType(MIRContext &C, Type *ReturnType, ArrayRef<Type *> Parameters,
               bool VarArg)
      : Type(C, FunctionTyID), ReturnType(ReturnType), Parameters(Parameters),
        VarArg(VarArg) {}
};

class PointerType : public Type {
public:
  Type *getElementType() const { return Element; }
  bool isOpaque() const { return Element == nullptr; }

  static PointerType *get(MIRContext &C, Type *Element = nullptr);

  static bool classof(const Type *T) { return T->getTypeID() == PointerTyID; }

private:
  Type *Element;

  PointerType(MIRContext &C, Type *Element)
      : Type(C, PointerTyID), Element(Element) {}
};

class StructType : public Type {
public:
  ArrayRef<Type *> getElementTypes() const { return Elements; }
  bool isPacked() const { return Packed; }

  static StructType *get(MIRContext &C, ArrayRef<Type *> Elements,
                         bool Packed = false);

  static bool classof(const Type *T) { return T->getTypeID() == StructTyID; }

private:
  ArrayRef<Type *> Elements;
  bool Packed;

  StructType(MIRContext &C, ArrayRef<Type *> Elements, bool Packed)
      : Type(C, StructTyID), Elements(Elements), Packed(Packed) {}
};

class SequenceType : public Type {
public:
  Type *getElementType() const { return Element; }
  uint64_t getCount() const { return Count; }
  MetaVariable *getCountVariable() const { return CountVariable; }

  static bool classof(const Type *T) {
    return T->getTypeID() == ArrayTyID || T->getTypeID() == FixedVectorTyID ||
           T->getTypeID() == ScalableVectorTyID;
  }

protected:
  SequenceType(MIRContext &C, TypeID ID, Type *Element, uint64_t Count,
               MetaVariable *CountVariable)
      : Type(C, ID), Element(Element), Count(Count),
        CountVariable(CountVariable) {}

private:
  Type *Element;
  uint64_t Count;
  MetaVariable *CountVariable;
};

class ArrayType : public SequenceType {
public:
  static ArrayType *get(MIRContext &C, Type *Element, uint64_t Count,
                        MetaVariable *CountVar = nullptr);

  static bool classof(const Type *T) { return T->getTypeID() == ArrayTyID; }

private:
  ArrayType(MIRContext &C, Type *Element, uint64_t Count,
            MetaVariable *CountVar)
      : SequenceType(C, ArrayTyID, Element, Count, CountVar) {}
};

class VectorType : public SequenceType {
public:
  bool isScalable() const { return getTypeID() == ScalableVectorTyID; }

  static VectorType *get(MIRContext &C, bool Scalable, Type *Element,
                         uint64_t Count, MetaVariable *CountVar = nullptr);

  static bool classof(const Type *T) {
    return T->getTypeID() == FixedVectorTyID ||
           T->getTypeID() == ScalableVectorTyID;
  }

private:
  VectorType(MIRContext &C, bool Scalable, Type *Element, uint64_t Count,
             MetaVariable *CountVar)
      : SequenceType(C, Scalable ? ScalableVectorTyID : FixedVectorTyID,
                     Element, Count, CountVar) {}
};

class MetaIRType : public Type {
public:
  MetaVariable *getVariable() const { return Variable; }

  static MetaIRType *get(MIRContext &C, MetaVariable *Variable);
  static bool classof(const Type *T) { return T->getTypeID() == MetaTyID; }

private:
  MetaVariable *Variable;

  MetaIRType(MIRContext &C, MetaVariable *Variable)
      : Type(C, MetaTyID), Variable(Variable) {}
};

class MetaIntegerType : public Type {
public:
  MetaVariable *getBitWidthVariable() const { return BitWidth; }
  bool isByte() const { return Byte; }

  static MetaIntegerType *get(MIRContext &C, MetaVariable *BitWidth, bool Byte);

  static bool classof(const Type *T) {
    return T->getTypeID() == MetaIntegerTyID;
  }

private:
  MetaVariable *BitWidth;
  bool Byte;

  MetaIntegerType(MIRContext &C, MetaVariable *BitWidth, bool Byte)
      : Type(C, MetaIntegerTyID), BitWidth(BitWidth), Byte(Byte) {}
};

} // namespace metaphir
} // namespace llvm

#endif
