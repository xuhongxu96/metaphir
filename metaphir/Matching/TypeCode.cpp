#include "metaphir/Matching/TypeCode.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"

namespace llvm {
namespace metaphir {

// Layout: the low 4 bits are the kind. A scalar kind keeps its payload (a
// bit width, address space or LLVM TypeID) in bits 4-35; a vector keeps its
// element's kind in bits 4-7, its payload in bits 8-39, and its element count
// in bits 40-63.
namespace {
enum Kind : uint64_t {
  None = 0,
  Opaque = 1,
  Void = 2,
  Label = 3,
  Integer = 4,
  Byte = 5,
  FloatingPoint = 6,
  Pointer = 7,
  FixedVector = 8,
  ScalableVector = 9,
};
} // namespace

static constexpr uint64_t MaxPayload = (uint64_t(1) << 32) - 1;
static constexpr uint64_t MaxCount = (uint64_t(1) << 24) - 1;

/// The kind and payload of a scalar type, if it has an encoding.
static bool encodeScalar(const Type &Ty, uint64_t &Kind, uint64_t &Payload) {
  if (Ty.isIntegerTy()) {
    Kind = Integer;
    Payload = Ty.getIntegerBitWidth();
  } else if (Ty.isByteTy()) {
    Kind = Byte;
    Payload = Ty.getByteBitWidth();
  } else if (Ty.isFloatingPointTy()) {
    Kind = FloatingPoint;
    Payload = Ty.getTypeID();
  } else if (Ty.isPointerTy()) {
    Kind = Pointer;
    Payload = Ty.getPointerAddressSpace();
  } else {
    return false;
  }
  return Payload <= MaxPayload;
}

TypeCode encodeType(const Type &Ty) {
  if (Ty.isVoidTy())
    return Void;
  if (Ty.isLabelTy())
    return Label;
  uint64_t Kind, Payload;
  if (encodeScalar(Ty, Kind, Payload))
    return Kind | Payload << 4;
  if (const auto *Vector = dyn_cast<VectorType>(&Ty)) {
    uint64_t Count = Vector->getElementCount().getKnownMinValue();
    if (Count <= MaxCount &&
        encodeScalar(*Vector->getElementType(), Kind, Payload))
      return (isa<ScalableVectorType>(Vector) ? ScalableVector : FixedVector) |
             Kind << 4 | Payload << 8 | Count << 40;
  }
  return Opaque;
}

static Type *decodeScalar(uint64_t Kind, uint64_t Payload,
                          LLVMContext &Context) {
  // Codes come from index files, so they are checked before LLVM asserts.
  switch (Kind) {
  case Integer:
    if (Payload < IntegerType::MIN_INT_BITS ||
        Payload > IntegerType::MAX_INT_BITS)
      return nullptr;
    return IntegerType::get(Context, Payload);
  case Byte:
    if (Payload < ByteType::MIN_BYTE_BITS || Payload > ByteType::MAX_BYTE_BITS)
      return nullptr;
    return ByteType::get(Context, Payload);
  case FloatingPoint:
    for (Type::TypeID ID :
         {Type::HalfTyID, Type::BFloatTyID, Type::FloatTyID, Type::DoubleTyID,
          Type::X86_FP80TyID, Type::FP128TyID, Type::PPC_FP128TyID})
      if (Payload == ID)
        return Type::getPrimitiveType(Context, ID);
    return nullptr;
  case Pointer:
    return PointerType::get(Context, Payload);
  default:
    return nullptr;
  }
}

unsigned getIntegerElementWidth(TypeCode Code) {
  uint64_t Kind = Code & 0xf;
  if (Kind == Integer)
    return Code >> 4 & MaxPayload;
  if ((Kind == FixedVector || Kind == ScalableVector) &&
      (Code >> 4 & 0xf) == Integer)
    return Code >> 8 & MaxPayload;
  return 0;
}

Type *decodeType(TypeCode Code, LLVMContext &Context) {
  uint64_t Kind = Code & 0xf;
  switch (Kind) {
  case Void:
    return Type::getVoidTy(Context);
  case Label:
    return Type::getLabelTy(Context);
  case FixedVector:
  case ScalableVector: {
    Type *Element =
        decodeScalar(Code >> 4 & 0xf, Code >> 8 & MaxPayload, Context);
    uint64_t Count = Code >> 40;
    if (!Element || !Count || !VectorType::isValidElementType(Element))
      return nullptr;
    return VectorType::get(Element, Count, Kind == ScalableVector);
  }
  default:
    return decodeScalar(Kind, Code >> 4 & MaxPayload, Context);
  }
}

} // namespace metaphir
} // namespace llvm
