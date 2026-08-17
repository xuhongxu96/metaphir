#include "metaphir/IR/Values.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

GlobalValue *GlobalValue::get(MIRContext &Context, StringRef Name,
                              SourceRange Range) {
  return new (Context.pImpl->Alloc)
      GlobalValue(Context.pImpl->Saver.save(Name), Range);
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
  case Value::MetaVariableVal: {
    const auto &Variable = cast<MetaVariable>(V);
    if (Variable.getType() == MetaType::IntrinsicID)
      OS << "@llvm.";
    OS << Variable;
    break;
  }
  case Value::InstructionVal:
    OS << '%' << cast<Instruction>(V).getResultName();
    break;
  case Value::GlobalVal:
    OS << '@' << cast<GlobalValue>(V).getName();
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
  return OS;
}

} // namespace metaphir
} // namespace llvm
