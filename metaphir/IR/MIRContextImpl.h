#ifndef METAPHIR_IR_MIRCONTEXTIMPL_H
#define METAPHIR_IR_MIRCONTEXTIMPL_H

#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Type.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/StringSaver.h"

namespace llvm {
namespace metaphir {

class MIRContextImpl {
public:
  explicit MIRContextImpl(MIRContext &C) : Context(C) {}

  MIRContext &Context;

  BumpPtrAllocator Alloc;
  UniqueStringSaver Saver{Alloc};

  DenseMap<unsigned, IntegerType *> IntegerTypes;
  DenseMap<unsigned, ByteType *> ByteTypes;
};

} // namespace metaphir
} // namespace llvm

#endif