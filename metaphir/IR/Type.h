#ifndef METAPHIR_IR_TYPE_H
#define METAPHIR_IR_TYPE_H

#include "llvm/Support/Casting.h"

namespace llvm {

class raw_ostream;

namespace metaphir {

class MIRContext;

/// A MetaphIR type, mirroring LLVM's type system plus meta types. Types are
/// uniqued and owned by the MIRContext. This class represents the primitive
/// types; see DerivedTypes.h for the others.
class Type {
public:
  enum TypeID {
// PrimitiveTypes
#define MIR_TYPE_ID(TypeID) TypeID,
#include "metaphir/IR/Types.def"

    // Derived types... see DerivedTypes.h file.
    IntegerTyID,        ///< Arbitrary bit width integers
    ByteTyID,           ///< Arbitrary bit width bytes
    FunctionTyID,       ///< Functions
    PointerTyID,        ///< Pointers
    StructTyID,         ///< Structures
    ArrayTyID,          ///< Arrays
    FixedVectorTyID,    ///< Fixed width SIMD vector type
    ScalableVectorTyID, ///< Scalable SIMD vector type
    MetaTyID,           ///< A captured MetaphIR type
    MetaIntegerTyID,    ///< Integer/byte type with captured bit width
  };

  virtual ~Type() = default;

  TypeID getTypeID() const { return ID; }
  MIRContext &getContext() const { return Context; }

  static Type *get(MIRContext &C, TypeID ID);

protected:
  explicit Type(MIRContext &C, TypeID id) : Context(C), ID(id) {}

private:
  MIRContext &Context;
  TypeID ID;
};

raw_ostream &operator<<(raw_ostream &OS, const Type &T);

} // namespace metaphir
} // namespace llvm

#endif
