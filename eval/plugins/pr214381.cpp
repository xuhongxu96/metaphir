// Reimplementation of llvm/llvm-project PR #214381 as a pass plugin.
//
//   icmp ugt (sub X, (urem X, D)), C --> icmp ugt X, D-1   (C u< D, D != 0)
//   icmp ult (sub X, (urem X, D)), C --> icmp ult X, D     (0 u< C u<= D, D !=
//   0)
// Anchor: the root `icmp`.

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace PatternMatch;

namespace {

struct PR214381 : public PassInfoMixin<PR214381> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Cmp = dyn_cast<ICmpInst>(&I);
        if (!Cmp)
          continue;
        ICmpInst::Predicate Pred = Cmp->getPredicate();
        if (Pred != ICmpInst::ICMP_UGT && Pred != ICmpInst::ICMP_ULT)
          continue;
        Value *X;
        const APInt *D, *C;
        if (!match(Cmp->getOperand(0),
                   m_Sub(m_Value(X), m_URem(m_Deferred(X), m_APInt(D)))) ||
            !match(Cmp->getOperand(1), m_APInt(C)))
          continue;
        if (D->isZero())
          continue;
        bool Fired = (Pred == ICmpInst::ICMP_UGT && C->ult(*D)) ||
                     (Pred == ICmpInst::ICMP_ULT && !C->isZero() && C->ule(*D));
        if (!Fired)
          continue;

        std::string Name;
        raw_string_ostream OS(Name);
        I.printAsOperand(OS, /*PrintType=*/false);
        errs() << "ANCHOR " << F.getName() << " " << OS.str().substr(1) << "\n";
      }
    }
    return PreservedAnalyses::all();
  }
};

} // namespace

static void registerPassBuilderCallbacks(PassBuilder &PB) {
  PB.registerPipelineParsingCallback(
      [](StringRef Name, FunctionPassManager &FPM,
         ArrayRef<PassBuilder::PipelineElement>) {
        if (Name == "pr214381") {
          FPM.addPass(PR214381());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr214381", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}