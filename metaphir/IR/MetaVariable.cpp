#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

MetaVariable *MetaVariable::get(MIRContext &Context, StringRef Name,
                                MetaType Ty, SourceRange Range) {
  return new (Context.pImpl->Alloc)
      MetaVariable(Context.pImpl->Saver.save(Name), Ty, Range);
}

StringRef getMetaTypeName(MetaType Type) {
  switch (Type) {
  case MetaType::Unknown:
    return "Unknown";
  case MetaType::Nat:
    return "Nat";
  case MetaType::Bool:
    return "i1";
  case MetaType::Type:
    return "Type";
  case MetaType::CmpPredicate:
    return "CmpPredicate";
  case MetaType::Value:
    return "Value";
  case MetaType::Instruction:
    return "Instruction";
  case MetaType::Function:
    return "Function";
  case MetaType::IntrinsicID:
    return "Intrinsic::ID";
  case MetaType::BasicBlock:
    return "BasicBlock";
  case MetaType::TypeArray:
    return "Type[]";
  case MetaType::ValueArray:
    return "Value[]";
  }
  llvm_unreachable("invalid meta type");
}

raw_ostream &operator<<(raw_ostream &OS, MetaType Type) {
  return OS << getMetaTypeName(Type);
}

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M) {
  return OS << '?' << M.getName();
}

} // namespace metaphir
} // namespace llvm
