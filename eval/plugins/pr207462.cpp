// Reimplementation of llvm/llvm-project PR #207462 as a pass plugin.
//
// (X /u 2) * C1 + (X %u 2) * C2  (both mul forms, C1 - 2*C2 != 0) is
// rewritten. Only the canonical two-mul form is matched (documented
// approximation: the direct-div/rem C==1 variants are not covered).
// Anchor: the root `add`.

#include "llvm/Analysis/ValueTracking.h"
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

struct PR207462 : public PassInfoMixin<PR207462> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X;
        const APInt *C1, *C2;
        if (!match(
                &I,
                m_c_Add(m_OneUse(m_Mul(m_UDiv(m_Value(X), m_SpecificInt(2)),
                                       m_APInt(C1))),
                        m_OneUse(m_Mul(m_URem(m_Deferred(X), m_SpecificInt(2)),
                                       m_APInt(C2))))))
          continue;
        if (!I.getType()->isIntegerTy())
          continue;
        APInt NewC = *C1 - *C2 * 2;
        if (NewC.isZero())
          continue;
        if (!isGuaranteedNotToBeUndef(X, /*AC=*/nullptr, &I,
                                      /*DT=*/nullptr))
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
        if (Name == "pr207462") {
          FPM.addPass(PR207462());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr207462", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}