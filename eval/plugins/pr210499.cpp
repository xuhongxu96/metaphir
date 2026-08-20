// Reimplementation of llvm/llvm-project PR #210499 as a pass plugin.
//
// trunc(nuw|nsw shr X, Y) to i1 --> icmp {ugt, sgt} X, 0 when the shift is
// exact and the trunc has a no-wrap flag matching the compare's signedness.
// Anchor: the root `trunc`.

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

struct PR210499 : public PassInfoMixin<PR210499> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Trunc = dyn_cast<TruncInst>(&I);
        if (!Trunc || !Trunc->getType()->isIntegerTy(1))
          continue;
        if (!Trunc->hasNoUnsignedWrap() && !Trunc->hasNoSignedWrap())
          continue;
        if (!match(Trunc->getOperand(0), m_Exact(m_Shr(m_Value(), m_Value()))))
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
        if (Name == "pr210499") {
          FPM.addPass(PR210499());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr210499", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}