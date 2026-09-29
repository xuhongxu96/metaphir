#ifndef METAPHIR_IR_MIRCONTEXTIMPL_H
#define METAPHIR_IR_MIRCONTEXTIMPL_H

#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Type.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/Hashing.h"
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

class Pattern;

struct MetaIntegerTypeKeyInfo {
  struct KeyTy {
    MetaVariable *BitWidth;
    bool IsByte;

    KeyTy(MetaVariable *BitWidth, bool IsByte)
        : BitWidth(BitWidth), IsByte(IsByte) {}
    explicit KeyTy(const MetaIntegerType *Ty)
        : BitWidth(Ty->getBitWidthVariable()), IsByte(Ty->isByte()) {}
    bool operator==(const KeyTy &Other) const {
      return BitWidth == Other.BitWidth && IsByte == Other.IsByte;
    }
  };

  static unsigned getHashValue(const KeyTy &Key) {
    return hash_combine(Key.BitWidth, Key.IsByte);
  }
  static unsigned getHashValue(const MetaIntegerType *Ty) {
    return getHashValue(KeyTy(Ty));
  }
  static bool isEqual(const KeyTy &LHS, const MetaIntegerType *RHS) {
    return LHS == KeyTy(RHS);
  }
  static bool isEqual(const MetaIntegerType *LHS, const MetaIntegerType *RHS) {
    return LHS == RHS;
  }
};

struct ArrayTypeKeyInfo {
  struct KeyTy {
    Type *ElementType;
    uint64_t Count;
    MetaVariable *CountVariable;

    KeyTy(Type *ElementType, uint64_t Count, MetaVariable *CountVariable)
        : ElementType(ElementType), Count(Count), CountVariable(CountVariable) {
    }
    explicit KeyTy(const ArrayType *Ty)
        : ElementType(Ty->getElementType()), Count(Ty->getCount()),
          CountVariable(Ty->getCountVariable()) {}
    bool operator==(const KeyTy &Other) const {
      return ElementType == Other.ElementType && Count == Other.Count &&
             CountVariable == Other.CountVariable;
    }
  };

  static unsigned getHashValue(const KeyTy &Key) {
    return hash_combine(Key.ElementType, Key.Count, Key.CountVariable);
  }
  static unsigned getHashValue(const ArrayType *Ty) {
    return getHashValue(KeyTy(Ty));
  }
  static bool isEqual(const KeyTy &LHS, const ArrayType *RHS) {
    return LHS == KeyTy(RHS);
  }
  static bool isEqual(const ArrayType *LHS, const ArrayType *RHS) {
    return LHS == RHS;
  }
};

struct VectorTypeKeyInfo {
  struct KeyTy {
    Type *ElementType;
    uint64_t Count;
    MetaVariable *CountVariable;
    bool IsScalable;

    KeyTy(Type *ElementType, uint64_t Count, MetaVariable *CountVariable,
          bool IsScalable)
        : ElementType(ElementType), Count(Count), CountVariable(CountVariable),
          IsScalable(IsScalable) {}
    explicit KeyTy(const VectorType *Ty)
        : ElementType(Ty->getElementType()), Count(Ty->getCount()),
          CountVariable(Ty->getCountVariable()), IsScalable(Ty->isScalable()) {}
    bool operator==(const KeyTy &Other) const {
      return ElementType == Other.ElementType && Count == Other.Count &&
             CountVariable == Other.CountVariable &&
             IsScalable == Other.IsScalable;
    }
  };

  static unsigned getHashValue(const KeyTy &Key) {
    return hash_combine(Key.ElementType, Key.Count, Key.CountVariable,
                        Key.IsScalable);
  }
  static unsigned getHashValue(const VectorType *Ty) {
    return getHashValue(KeyTy(Ty));
  }
  static bool isEqual(const KeyTy &LHS, const VectorType *RHS) {
    return LHS == KeyTy(RHS);
  }
  static bool isEqual(const VectorType *LHS, const VectorType *RHS) {
    return LHS == RHS;
  }
};

struct StructTypeKeyInfo {
  struct KeyTy {
    ArrayRef<Type *> ElementTypes;
    bool IsPacked;

    KeyTy(ArrayRef<Type *> ElementTypes, bool IsPacked)
        : ElementTypes(ElementTypes), IsPacked(IsPacked) {}
    explicit KeyTy(const StructType *Ty)
        : ElementTypes(Ty->getElementTypes()), IsPacked(Ty->isPacked()) {}
    bool operator==(const KeyTy &Other) const {
      return ElementTypes == Other.ElementTypes && IsPacked == Other.IsPacked;
    }
  };

  static unsigned getHashValue(const KeyTy &Key) {
    return hash_combine(hash_combine_range(Key.ElementTypes), Key.IsPacked);
  }
  static unsigned getHashValue(const StructType *Ty) {
    return getHashValue(KeyTy(Ty));
  }
  static bool isEqual(const KeyTy &LHS, const StructType *RHS) {
    return LHS == KeyTy(RHS);
  }
  static bool isEqual(const StructType *LHS, const StructType *RHS) {
    return LHS == RHS;
  }
};

struct FunctionTypeKeyInfo {
  struct KeyTy {
    Type *ReturnType;
    ArrayRef<Type *> ParameterTypes;
    bool IsVarArg;

    KeyTy(Type *ReturnType, ArrayRef<Type *> ParameterTypes, bool IsVarArg)
        : ReturnType(ReturnType), ParameterTypes(ParameterTypes),
          IsVarArg(IsVarArg) {}
    explicit KeyTy(const FunctionType *Ty)
        : ReturnType(Ty->getReturnType()),
          ParameterTypes(Ty->getParameterTypes()), IsVarArg(Ty->isVarArg()) {}
    bool operator==(const KeyTy &Other) const {
      return ReturnType == Other.ReturnType &&
             ParameterTypes == Other.ParameterTypes &&
             IsVarArg == Other.IsVarArg;
    }
  };

  static unsigned getHashValue(const KeyTy &Key) {
    return hash_combine(Key.ReturnType, hash_combine_range(Key.ParameterTypes),
                        Key.IsVarArg);
  }
  static unsigned getHashValue(const FunctionType *Ty) {
    return getHashValue(KeyTy(Ty));
  }
  static bool isEqual(const KeyTy &LHS, const FunctionType *RHS) {
    return LHS == KeyTy(RHS);
  }
  static bool isEqual(const FunctionType *LHS, const FunctionType *RHS) {
    return LHS == RHS;
  }
};

class MIRContextImpl {
public:
  using MetaIntegerTypeSet =
      DenseSet<MetaIntegerType *, MetaIntegerTypeKeyInfo>;
  using ArrayTypeSet = DenseSet<ArrayType *, ArrayTypeKeyInfo>;
  using VectorTypeSet = DenseSet<VectorType *, VectorTypeKeyInfo>;
  using StructTypeSet = DenseSet<StructType *, StructTypeKeyInfo>;
  using FunctionTypeSet = DenseSet<FunctionType *, FunctionTypeKeyInfo>;

  MIRContext &Context;

  BumpPtrAllocator Alloc;
  UniqueStringSaver Saver{Alloc};

  DenseMap<unsigned, IntegerType *> IntegerTypes;
  DenseMap<unsigned, ByteType *> ByteTypes;
  DenseMap<unsigned, Type *> PrimitiveTypes;
  DenseMap<MetaVariable *, MetaIRType *> MetaIRTypes;
  MetaIntegerTypeSet MetaIntegerTypes;
  DenseMap<std::pair<Type *, unsigned>, PointerType *> PointerTypes;
  ArrayTypeSet ArrayTypes;
  VectorTypeSet VectorTypes;
  StructTypeSet StructTypes;
  FunctionTypeSet FunctionTypes;

  SmallPtrSet<Pattern *, 4> OwnedPatterns;
  /// Arena-allocated values that own heap memory (wide APInt/APFloat
  /// storage). The arena releases memory without running destructors, so
  /// these are destroyed explicitly with the context.
  SmallVector<Value *, 0> ValuesToDestroy;

  StringMap<CompositeMatcher *> CompositeMatchers;
  StringMap<ConstraintDef *> ConstraintDefs;
  StringMap<MetaFlagDef *> MetaFlagDefs;
  /// Names of the libraries whose definitions have been loaded into this
  /// context, so each is parsed at most once.
  StringSet<> LoadedLibraries;
  /// Buffers of the loaded libraries; see MIRContext::getLibrarySourceMgr.
  SourceMgr LibrarySources;

  explicit MIRContextImpl(MIRContext &C) : Context(C) {}
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
