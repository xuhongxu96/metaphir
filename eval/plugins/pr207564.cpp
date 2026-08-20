// Reimplementation of llvm/llvm-project PR #207564 as a pass plugin.
//
// zext(sub(0, trunc(X))) --> sub(0, sext(X)) when the trunc's source type is
// the zext's result type.
// Anchor: the root `zext`.

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

struct PR207564 : public PassInfoMixin<PR207564> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Zext = dyn_cast<ZExtInst>(&I);
        if (!Zext)
          continue;
        Value *X;
        if (!match(
                Zext->getOperand(0),
                m_Sub(m_Zero(), m_Trunc(m_SpecificType(Zext->getType(), X)))))
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
        if (Name == "pr207564") {
          FPM.addPass(PR207564());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr207564", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}