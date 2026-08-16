#include "metaphir/IR/Values.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

MetaValue *MetaValue::get(MIRContext &Context, MetaVariable *Variable,
                          SourceRange Range) {
  return new (Context.pImpl->Alloc) MetaValue(Variable, Range);
}

LocalInstructionValue *LocalInstructionValue::get(MIRContext &Context,
                                                  StringRef Name,
                                                  Instruction *Definition,
                                                  SourceRange Range) {
  return new (Context.pImpl->Alloc)
      LocalInstructionValue(Context.pImpl->Saver.save(Name), Definition, Range);
}

BasicBlockValue *BasicBlockValue::get(MIRContext &Context, StringRef Name,
                                      MetaVariable *Variable,
                                      SourceRange Range) {
  return new (Context.pImpl->Alloc)
      BasicBlockValue(Context.pImpl->Saver.save(Name), Variable, Range);
}

GlobalValue *GlobalValue::get(MIRContext &Context, StringRef Name,
                              SourceRange Range) {
  return new (Context.pImpl->Alloc)
      GlobalValue(Context.pImpl->Saver.save(Name), Range);
}

IntrinsicValue *IntrinsicValue::get(MIRContext &Context, MetaVariable *ID,
                                    SourceRange Range) {
  return new (Context.pImpl->Alloc) IntrinsicValue(ID, Range);
}

IntegerConstant *IntegerConstant::get(MIRContext &Context, const APSInt &Number,
                                      SourceRange Range) {
  return new (Context.pImpl->Alloc) IntegerConstant(Number, Range);
}

FloatingConstant *FloatingConstant::get(MIRContext &Context,
                                        const APFloat &Number,
                                        SourceRange Range) {
  return new (Context.pImpl->Alloc) FloatingConstant(Number, Range);
}

KeywordConstant *KeywordConstant::get(MIRContext &Context, StringRef Keyword,
                                      SourceRange Range) {
  return new (Context.pImpl->Alloc)
      KeywordConstant(Context.pImpl->Saver.save(Keyword), Range);
}

AggregateConstant *AggregateConstant::get(MIRContext &Context,
                                          ArrayRef<Type *> ElementTypes,
                                          ArrayRef<Value *> Elements,
                                          Delimiter Delim, SourceRange Range) {
  return new (Context.pImpl->Alloc) AggregateConstant(
      Context.pImpl->copyArray<Type *>(ElementTypes),
      Context.pImpl->copyArray<Value *>(Elements), Delim, Range);
}

raw_ostream &operator<<(raw_ostream &OS, const Value &V) {
  switch (V.getValueID()) {
  case Value::MetaVal:
    OS << *cast<MetaValue>(V).getVariable();
    break;
  case Value::LocalInstructionVal:
    OS << '%' << cast<LocalInstructionValue>(V).getName();
    break;
  case Value::BasicBlockVal: {
    const auto &BB = cast<BasicBlockValue>(V);
    OS << '%' << BB.getName();
    break;
  }
  case Value::GlobalVal:
    OS << '@' << cast<GlobalValue>(V).getName();
    break;
  case Value::IntrinsicVal:
    OS << "@llvm." << *cast<IntrinsicValue>(V).getID();
    break;
  case Value::IntegerConstantVal:
    OS << cast<IntegerConstant>(V).getValue();
    break;
  case Value::FloatingConstantVal:
    cast<FloatingConstant>(V).getValue().print(OS);
    break;
  case Value::KeywordConstantVal:
    OS << cast<KeywordConstant>(V).getKeyword();
    break;
  case Value::AggregateConstantVal: {
    const auto &A = cast<AggregateConstant>(V);
    const char Open[] = {'[', '{', '<'};
    const char Close[] = {']', '}', '>'};
    OS << Open[A.getDelimiter()];
    for (unsigned I = 0; I != A.getElements().size(); ++I) {
      if (I)
        OS << ", ";
      OS << *A.getElementTypes()[I] << ' ' << *A.getElements()[I];
    }
    OS << Close[A.getDelimiter()];
    break;
  }
  }
  for (const MetaFlag *F : V.getMetaFlags())
    OS << *F;
  return OS;
}

} // namespace metaphir
} // namespace llvm
