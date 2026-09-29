#ifndef METAPHIR_IR_CONSTANTS_H
#define METAPHIR_IR_CONSTANTS_H

#include "metaphir/IR/Type.h"
#include "metaphir/IR/Value.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APSInt.h"

namespace llvm {
namespace metaphir {

/// A named global ('@f'), or an intrinsic ('@llvm.ctlz').
class GlobalValue : public Value {
public:
  StringRef getName() const { return Name; }

  static bool classof(const Value *V) { return V->getValueID() == GlobalVal; }
  static GlobalValue *create(MIRContext &Context, StringRef Name,
                             SourceRange Range);

private:
  StringRef Name;

  GlobalValue(StringRef N, SourceRange R) : Value(GlobalVal, R), Name(N) {}
};

/// An integer literal. Its signedness is that of the literal as written.
class IntegerConstant : public Value {
public:
  const APSInt &getValue() const { return Number; }

  static bool classof(const Value *V) {
    return V->getValueID() == IntegerConstantVal;
  }
  static IntegerConstant *create(MIRContext &Context, const APSInt &Number,
                                 SourceRange Range);

private:
  APSInt Number;

  IntegerConstant(const APSInt &N, SourceRange R)
      : Value(IntegerConstantVal, R), Number(N) {}
};

/// A floating-point literal.
class FloatingConstant : public Value {
public:
  const APFloat &getValue() const { return Number; }

  static bool classof(const Value *V) {
    return V->getValueID() == FloatingConstantVal;
  }
  static FloatingConstant *create(MIRContext &Context, const APFloat &Number,
                                  SourceRange Range);

private:
  APFloat Number;

  FloatingConstant(const APFloat &N, SourceRange R)
      : Value(FloatingConstantVal, R), Number(N) {}
};

/// A keyword constant ('null', 'poison', ...) or comparison predicate.
class KeywordConstant : public Value {
public:
  enum KeywordID {
#define MIR_KEYWORD_CONSTANT(ID, Spelling) K_##ID,
#include "metaphir/IR/KeywordConstants.def"
  };

  KeywordID getKeywordID() const { return ID; }

  static bool classof(const Value *V) {
    return V->getValueID() == KeywordConstantVal;
  }
  static StringRef getKeywordName(KeywordID ID);
  static KeywordConstant *create(MIRContext &Context, KeywordID ID,
                                 SourceRange Range);

private:
  KeywordID ID;

  KeywordConstant(KeywordID ID, SourceRange R)
      : Value(KeywordConstantVal, R), ID(ID) {}
};

/// An array ('[...]'), struct ('{...}') or vector ('<...>') constant of typed
/// elements; getElementTypes() and getElements() are parallel.
class AggregateConstant : public Value {
public:
  enum Delimiter { Square, Brace, Angle };

  ArrayRef<Type *> getElementTypes() const { return Types; }
  ArrayRef<Value *> getElements() const { return Values; }
  Delimiter getDelimiter() const { return Delim; }

  static bool classof(const Value *V) {
    return V->getValueID() == AggregateConstantVal;
  }
  static AggregateConstant *create(MIRContext &Context,
                                   ArrayRef<Type *> ElementTypes,
                                   ArrayRef<Value *> Elements, Delimiter Delim,
                                   SourceRange Range);

private:
  ArrayRef<Type *> Types;
  ArrayRef<Value *> Values;
  Delimiter Delim;

  AggregateConstant(ArrayRef<Type *> T, ArrayRef<Value *> V, Delimiter D,
                    SourceRange R)
      : Value(AggregateConstantVal, R), Types(T), Values(V), Delim(D) {}
};

raw_ostream &operator<<(raw_ostream &OS, const Value &V);

} // namespace metaphir
} // namespace llvm

#endif
