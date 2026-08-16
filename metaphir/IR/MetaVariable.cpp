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

raw_ostream &operator<<(raw_ostream &OS, MetaType Type) {
  switch (Type) {
  case MetaType::Unknown:
    return OS << "Unknown";
  case MetaType::Nat:
    return OS << "Nat";
  case MetaType::Bool:
    return OS << "i1";
  case MetaType::Type:
    return OS << "Type";
  case MetaType::CmpPredicate:
    return OS << "CmpPredicate";
  case MetaType::Value:
    return OS << "Value";
  case MetaType::Instruction:
    return OS << "Instruction";
  case MetaType::Function:
    return OS << "Function";
  case MetaType::IntrinsicID:
    return OS << "Intrinsic::ID";
  case MetaType::BasicBlock:
    return OS << "BasicBlock";
  case MetaType::TypeArray:
    return OS << "Type[]";
  case MetaType::ValueArray:
    return OS << "Value[]";
  }
  llvm_unreachable("invalid meta type");
}

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M) {
  return OS << '?' << M.getName();
}

} // namespace metaphir
} // namespace llvm
