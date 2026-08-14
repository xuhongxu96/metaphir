#ifndef METAPHIR_IR_DERIVEDTYPES_H
#define METAPHIR_IR_DERIVEDTYPES_H

#include "metaphir/IR/Type.h"

namespace llvm {
namespace metaphir {

class MIRContext;

class IntegerType : public Type {
  explicit IntegerType(MIRContext &C, unsigned NumBits)
      : Type(C, IntegerTyID), NumBits(NumBits) {}

  unsigned NumBits;

public:
  unsigned getNumBits() const { return NumBits; }

public:
  static IntegerType *get(MIRContext &C, unsigned NumBits);

  static bool classof(const Type *T) { return T->getTypeID() == IntegerTyID; }
};

class ByteType : public Type {
  explicit ByteType(MIRContext &C, unsigned NumBits)
      : Type(C, ByteTyID), NumBits(NumBits) {}

  unsigned NumBits;

public:
  unsigned getNumBits() const { return NumBits; }

public:
  static ByteType *get(MIRContext &C, unsigned NumBits);

  static bool classof(const Type *T) { return T->getTypeID() == ByteTyID; }
};

} // namespace metaphir
} // namespace llvm

#endif