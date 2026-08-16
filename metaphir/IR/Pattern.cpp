#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

Pattern::~Pattern() { Context.pImpl->OwnedPatterns.erase(this); }

Pattern *Pattern::get(MIRContext &Context) {
  auto *Result = new Pattern(Context);
  Context.pImpl->OwnedPatterns.insert(Result);
  return Result;
}

raw_ostream &operator<<(raw_ostream &OS, const Pattern &P) {
  OS << "pattern instructions=" << P.getInstructions().size()
     << " constraints=" << P.getConstraints().size() << '\n';
  for (const Instruction *I : P.getInstructions()) {
    OS << *I << '\n';
  }
  for (const Constraint *C : P.getConstraints()) {
    OS << "constraint " << *C << '\n';
  }
  for (const MetaVariable *M : P.getMetaVariables())
    OS << "meta " << *M << " type=" << M->getType() << '\n';
  return OS;
}

} // namespace metaphir
} // namespace llvm
