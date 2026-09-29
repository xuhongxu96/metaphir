#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

GlobalValue *GlobalValue::create(MIRContext &Context, StringRef Name,
                                 SourceRange Range) {
  return new (Context.pImpl->Alloc)
      GlobalValue(Context.pImpl->Saver.save(Name), Range);
}

IntegerConstant *IntegerConstant::create(MIRContext &Context,
                                         const APSInt &Number,
                                         SourceRange Range) {
  auto *Result = new (Context.pImpl->Alloc) IntegerConstant(Number, Range);
  if (Number.needsCleanup())
    Context.pImpl->ValuesToDestroy.push_back(Result);
  return Result;
}

FloatingConstant *FloatingConstant::create(MIRContext &Context,
                                           const APFloat &Number,
                                           SourceRange Range) {
  auto *Result = new (Context.pImpl->Alloc) FloatingConstant(Number, Range);
  if (Number.needsCleanup())
    Context.pImpl->ValuesToDestroy.push_back(Result);
  return Result;
}

StringRef KeywordConstant::getKeywordName(KeywordID ID) {
  switch (ID) {
#define MIR_KEYWORD_CONSTANT(ID, Spelling)                                     \
  case K_##ID:                                                                 \
    return #Spelling;
#include "metaphir/IR/KeywordConstants.def"
  }
  llvm_unreachable("invalid keyword constant ID");
}

KeywordConstant *KeywordConstant::create(MIRContext &Context, KeywordID ID,
                                         SourceRange Range) {
  return new (Context.pImpl->Alloc) KeywordConstant(ID, Range);
}

AggregateConstant *AggregateConstant::create(MIRContext &Context,
                                             ArrayRef<Type *> ElementTypes,
                                             ArrayRef<Value *> Elements,
                                             Delimiter Delim,
                                             SourceRange Range) {
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
    OS << KeywordConstant::getKeywordName(
        cast<KeywordConstant>(V).getKeywordID());
    break;
  case Value::AggregateConstantVal: {
    const auto &A = cast<AggregateConstant>(V);
    const char Open[] = {'[', '{', '<'};
    const char Close[] = {']', '}', '>'};
    OS << Open[A.getDelimiter()];
    interleaveComma(
        zip(A.getElementTypes(), A.getElements()), OS, [&OS](auto Element) {
          OS << *std::get<0>(Element) << ' ' << *std::get<1>(Element);
        });
    OS << Close[A.getDelimiter()];
    break;
  }
  }
  return OS;
}

} // namespace metaphir
} // namespace llvm
