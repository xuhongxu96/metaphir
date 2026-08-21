#include "metaphir/Matching/ValueTrackContext.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

namespace llvm {
namespace metaphir {
namespace detail {

const DataLayout &ValueTrackContext::ensure(const llvm::Instruction *CtxI) {
  // The module outlives the match, so the const-qualified function view is
  // safe to use for the (non-mutating) DominatorTree/AssumptionCache builders.
  auto *Fn = const_cast<llvm::Function *>(CtxI->getFunction());
  if (Fn != F) {
    F = Fn;
    DT.reset();
    AC.reset();
    TLII.reset();
    TLI.reset();
  }

  const DataLayout &DL = Fn->getParent()->getDataLayout();
  if (!TLII)
    TLII.emplace(Triple(Fn->getParent()->getTargetTriple()));
  if (!TLI)
    TLI.emplace(*TLII);
  if (!AC)
    AC.emplace(*Fn);
  if (!DT)
    DT.emplace(*Fn);
  return DL;
}

SimplifyQuery ValueTrackContext::getQuery(const llvm::Instruction *CtxI) {
  const DataLayout &DL = ensure(CtxI);
  return SimplifyQuery(DL, &*TLI, &*DT, &*AC, CtxI);
}

} // namespace detail
} // namespace metaphir
} // namespace llvm