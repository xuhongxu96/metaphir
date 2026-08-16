#ifndef METAPHIR_IR_VALUES_H
#define METAPHIR_IR_VALUES_H

#include "metaphir/IR/Type.h"
#include "metaphir/IR/Value.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APSInt.h"

namespace llvm {
namespace metaphir {

class Instruction;

class MetaValue : public Value {
public:
  MetaVariable *getVariable() const { return Variable; }

  static bool classof(const Value *V) { return V->getValueID() == MetaVal; }
  static MetaValue *get(MIRContext &Context, MetaVariable *Variable,
                        SourceRange Range);

private:
  MetaVariable *Variable;

  MetaValue(MetaVariable *V, SourceRange R) : Value(MetaVal, R), Variable(V) {}
};

class LocalInstructionValue : public Value {
public:
  StringRef getName() const { return Name; }
  Instruction *getDefinition() const { return Definition; }

  static bool classof(const Value *V) {
    return V->getValueID() == LocalInstructionVal;
  }
  static LocalInstructionValue *get(MIRContext &Context, StringRef Name,
                                    Instruction *Definition, SourceRange Range);

private:
  StringRef Name;
  Instruction *Definition;

  LocalInstructionValue(StringRef N, Instruction *D, SourceRange R)
      : Value(LocalInstructionVal, R), Name(N), Definition(D) {}
};

class BasicBlockValue : public Value {
public:
  StringRef getName() const { return Name; }
  MetaVariable *getVariable() const { return Variable; }

  static bool classof(const Value *V) {
    return V->getValueID() == BasicBlockVal;
  }
  static BasicBlockValue *get(MIRContext &Context, StringRef Name,
                              MetaVariable *Variable, SourceRange Range);

private:
  StringRef Name;
  MetaVariable *Variable;

  BasicBlockValue(StringRef N, MetaVariable *V, SourceRange R)
      : Value(BasicBlockVal, R), Name(N), Variable(V) {}
};

class GlobalValue : public Value {
public:
  StringRef getName() const { return Name; }

  static bool classof(const Value *V) { return V->getValueID() == GlobalVal; }
  static GlobalValue *get(MIRContext &Context, StringRef Name,
                          SourceRange Range);

private:
  StringRef Name;

  GlobalValue(StringRef N, SourceRange R) : Value(GlobalVal, R), Name(N) {}
};

class IntrinsicValue : public Value {
public:
  MetaVariable *getID() const { return ID; }

  static bool classof(const Value *V) {
    return V->getValueID() == IntrinsicVal;
  }
  static IntrinsicValue *get(MIRContext &Context, MetaVariable *ID,
                             SourceRange Range);

private:
  MetaVariable *ID;

  IntrinsicValue(MetaVariable *ID, SourceRange R)
      : Value(IntrinsicVal, R), ID(ID) {}
};

class IntegerConstant : public Value {
public:
  const APSInt &getValue() const { return Number; }

  static bool classof(const Value *V) {
    return V->getValueID() == IntegerConstantVal;
  }
  static IntegerConstant *get(MIRContext &Context, const APSInt &Number,
                              SourceRange Range);

private:
  APSInt Number;

  IntegerConstant(const APSInt &N, SourceRange R)
      : Value(IntegerConstantVal, R), Number(N) {}
};

class FloatingConstant : public Value {
public:
  const APFloat &getValue() const { return Number; }

  static bool classof(const Value *V) {
    return V->getValueID() == FloatingConstantVal;
  }
  static FloatingConstant *get(MIRContext &Context, const APFloat &Number,
                               SourceRange Range);

private:
  APFloat Number;

  FloatingConstant(const APFloat &N, SourceRange R)
      : Value(FloatingConstantVal, R), Number(N) {}
};

class KeywordConstant : public Value {
public:
  StringRef getKeyword() const { return Keyword; }

  static bool classof(const Value *V) {
    return V->getValueID() == KeywordConstantVal;
  }
  static KeywordConstant *get(MIRContext &Context, StringRef Keyword,
                              SourceRange Range);

private:
  StringRef Keyword;

  KeywordConstant(StringRef K, SourceRange R)
      : Value(KeywordConstantVal, R), Keyword(K) {}
};

class AggregateConstant : public Value {
public:
  enum Delimiter { Square, Brace, Angle };

  ArrayRef<Type *> getElementTypes() const { return Types; }
  ArrayRef<Value *> getElements() const { return Values; }
  Delimiter getDelimiter() const { return Delim; }

  static bool classof(const Value *V) {
    return V->getValueID() == AggregateConstantVal;
  }
  static AggregateConstant *get(MIRContext &Context,
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
