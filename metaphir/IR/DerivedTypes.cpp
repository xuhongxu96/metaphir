#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

IntegerType *IntegerType::get(MIRContext &C, unsigned NumBits) {
  assert(NumBits >= MIN_INT_BITS && "bitwidth too small");
  assert(NumBits <= MAX_INT_BITS && "bitwidth too large");

  IntegerType *&Entry = C.pImpl->IntegerTypes[NumBits];

  if (!Entry)
    Entry = new (C.pImpl->Alloc) IntegerType(C, NumBits);

  return Entry;
}

ByteType *ByteType::get(MIRContext &C, unsigned NumBits) {
  assert(NumBits >= MIN_INT_BITS && "bitwidth too small");
  assert(NumBits <= MAX_INT_BITS && "bitwidth too large");

  ByteType *&Entry = C.pImpl->ByteTypes[NumBits];

  if (!Entry)
    Entry = new (C.pImpl->Alloc) ByteType(C, NumBits);

  return Entry;
}

} // namespace metaphir
} // namespace llvm