#include "metaphir/IR/Type.h"
#include "metaphir/IR/DerivedTypes.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

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
  case Type::FunctionTyID:
  case Type::PointerTyID:
  case Type::StructTyID:
  case Type::ArrayTyID:
  case Type::FixedVectorTyID:
  case Type::ScalableVectorTyID:
    break;
  }
  return OS;
}

} // namespace metaphir
} // namespace llvm