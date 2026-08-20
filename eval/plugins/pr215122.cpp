// Reimplementation of llvm/llvm-project PR #215122 as a pass plugin.
//
// (X & -(X)) + X --> X & ~(X) ... no:
// PR fold: (X + (X & -X)) no... actual fold:
//   (X & -X) + X  ->  X & ~X ... no.
// The PR fold (visitAdd, non-speculative path):
//   add(oneuse(and(neg(X), LowMask)), X)  is rewritten.
// Anchor: the root `add`.

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

struct PR215122 : public PassInfoMixin<PR215122> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // I = add(oneuse(and(neg(X), LowMask)), X)
        Value *A;
        const APInt *LowMask;
        if (!match(&I, m_c_Add(m_OneUse(m_And(m_Neg(m_Value(A)),
                                              m_LowBitMask(LowMask))),
                               m_Deferred(A))))
          continue;
        if (!I.getType()->isIntegerTy())
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
        if (Name == "pr215122") {
          FPM.addPass(PR215122());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr215122", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}