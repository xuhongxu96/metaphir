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
  /// This enum is just used to hold constants we need for IntegerType.
  enum {
    MIN_INT_BITS = 1, ///< Minimum number of bits that can be specified
    MAX_INT_BITS =
        (1 << 23) ///< Maximum number of bits that can be specified
                  ///< Note that bit width is stored in the Type classes
                  ///< SubclassData field which has 24 bits. SelectionDAG type
                  ///< legalization can require a power of 2 IntegerType, so
                  ///< limit to the largest representable power of 2, 8388608.
  };

  /// This static method is the primary way of constructing an IntegerType.
  /// If an IntegerType with the same NumBits value was previously instantiated,
  /// that instance will be returned. Otherwise a new one will be created. Only
  /// one instance with a given NumBits value is ever created.
  /// Get or create an IntegerType instance.
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
  /// This enum is just used to hold constants we need for ByteType.
  enum {
    MIN_INT_BITS = 1, ///< Minimum number of bits that can be specified
    MAX_INT_BITS =
        (1 << 23) ///< Maximum number of bits that can be specified
                  ///< Note that bit width is stored in the Type classes
                  ///< SubclassData field which has 24 bits. SelectionDAG type
                  ///< legalization can require a power of 2 ByteType, so
                  ///< limit to the largest representable power of 2, 8388608.
  };

  /// This static method is the primary way of constructing an ByteType.
  /// If an ByteType with the same NumBits value was previously instantiated,
  /// that instance will be returned. Otherwise a new one will be created. Only
  /// one instance with a given NumBits value is ever created.
  /// Get or create an ByteType instance.
  static ByteType *get(MIRContext &C, unsigned NumBits);

  static bool classof(const Type *T) { return T->getTypeID() == ByteTyID; }
};

} // namespace metaphir
} // namespace llvm

#endif