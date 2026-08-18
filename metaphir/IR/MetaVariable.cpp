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
#define MIR_META_TYPE_NAME(ID, Name)                                           \
  case MetaType::ID:                                                           \
    return Name;
#include "metaphir/IR/MetaTypes.def"
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
