#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

MetaVariable *MetaVariable::create(MIRContext &Context, StringRef Name, Sort Ty,
                                   SourceRange Range) {
  return new (Context.pImpl->Alloc)
      MetaVariable(Context.pImpl->Saver.save(Name), Ty, Range);
}

raw_ostream &operator<<(raw_ostream &OS, const MetaVariable &M) {
  return OS << '?' << M.getName();
}

} // namespace metaphir
} // namespace llvm
