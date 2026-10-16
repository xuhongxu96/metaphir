#ifndef METAPHIR_IR_MIRCONTEXTIMPL_H
#define METAPHIR_IR_MIRCONTEXTIMPL_H

#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Type.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/StringSaver.h"
#include <new>
#include <utility>

namespace llvm {
namespace metaphir {

class Constraint;

class Pattern;

class MIRContextImpl {
public:
  BumpPtrAllocator Alloc;
  UniqueStringSaver Saver{Alloc};

  DenseMap<unsigned, IntegerType *> IntegerTypes;
  DenseMap<unsigned, ByteType *> ByteTypes;
  DenseMap<unsigned, Type *> PrimitiveTypes;
  DenseMap<MetaVariable *, MetaIRType *> MetaIRTypes;
  DenseMap<std::pair<MetaVariable *, unsigned>, MetaIntegerType *>
      MetaIntegerTypes;
  DenseMap<std::pair<Type *, unsigned>, PointerType *> PointerTypes;
  DenseMap<std::tuple<Type *, uint64_t, MetaVariable *>, ArrayType *>
      ArrayTypes;
  DenseMap<std::tuple<Type *, uint64_t, MetaVariable *, unsigned>, VectorType *>
      VectorTypes;
  // DenseMapInfo has no bool specialization, so flags are keyed as unsigned.
  /// Keys of aggregate types refer to the element arrays the types own.
  DenseMap<std::pair<ArrayRef<Type *>, unsigned>, StructType *> StructTypes;
  DenseMap<std::tuple<Type *, ArrayRef<Type *>, unsigned>, FunctionType *>
      FunctionTypes;

  SmallPtrSet<Pattern *, 4> OwnedPatterns;
  /// Arena-allocated values that own heap memory (wide APInt/APFloat
  /// storage). The arena releases memory without running destructors, so
  /// these are destroyed explicitly with the context.
  SmallVector<Value *, 0> ValuesToDestroy;
  /// Constraints owning heap memory, such as integer literals wider than 64
  /// bits, destroyed with the context.
  SmallVector<Constraint *, 0> ConstraintsToDestroy;

  StringMap<CompositeMatcher *> CompositeMatchers;
  StringMap<ConstraintDef *> ConstraintDefs;
  StringMap<MetaFlagDef *> MetaFlagDefs;
  /// Names of the libraries whose definitions have been loaded into this
  /// context, so each is parsed at most once.
  StringSet<> LoadedLibraries;
  /// Buffers of the loaded libraries; see MIRContext::getLibrarySourceMgr.
  SourceMgr LibrarySources;

  MIRContextImpl() = default;
  ~MIRContextImpl();

  template <typename T> ArrayRef<T> copyArray(ArrayRef<T> Values) {
    if (Values.empty())
      return {};
    auto *Storage =
        static_cast<T *>(Alloc.Allocate(sizeof(T) * Values.size(), alignof(T)));
    for (size_t I = 0; I != Values.size(); ++I)
      new (&Storage[I]) T(Values[I]);
    return {Storage, Values.size()};
  }
};

} // namespace metaphir
} // namespace llvm

#endif
