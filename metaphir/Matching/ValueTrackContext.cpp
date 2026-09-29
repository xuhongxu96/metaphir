#include "metaphir/Matching/ValueTrackContext.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

namespace llvm {
namespace metaphir {
namespace detail {

const DataLayout &ValueTrackContext::ensure(const llvm::Instruction *CtxI) {
  // The module outlives the match, so the const-qualified function view is
  // safe to use for the (non-mutating) DominatorTree/AssumptionCache builders.
  auto *Fn = const_cast<llvm::Function *>(CtxI->getFunction());
  assert(Fn && "value tracking needs an instruction inside a function");
  if (Fn != F) {
    F = Fn;
    DT.reset();
    AC.reset();
    DC.reset();
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
  if (!DC) {
    // Register every conditional branch up front, so facts implied by a
    // dominating branch are visible like in InstCombine. Dominance is checked
    // at query time, so non-dominating branches are harmless.
    DC.emplace();
    for (BasicBlock &BB : *Fn)
      if (auto *BI = dyn_cast_or_null<CondBrInst>(BB.getTerminator()))
        DC->registerBranch(BI);
  }
  return DL;
}

SimplifyQuery ValueTrackContext::getQuery(const llvm::Instruction *CtxI) {
  const DataLayout &DL = ensure(CtxI);
  return SimplifyQuery(DL, &*TLI, &*DT, &*AC, CtxI, /*UseInstrInfo=*/true,
                       /*CanUseUndef=*/true, &*DC);
}

} // namespace detail
} // namespace metaphir
} // namespace llvm