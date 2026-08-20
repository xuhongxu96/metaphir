// Reimplementation of llvm/llvm-project PR #214517 as a pass plugin.
//
// (1 << cttz(X, is_zero_undef)) --> ctlz(X & -X, is_zero_undef) when the shift
// operand is a one-use cttz call.
// Anchor: the root `shl`.

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

struct PR214517 : public PassInfoMixin<PR214517> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // I = shl(1, oneuse(cttz(X, isz)))
        if (!match(&I, m_Shl(m_One(), m_OneUse(m_Cttz(m_Value(), m_Value())))))
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
        if (Name == "pr214517") {
          FPM.addPass(PR214517());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr214517", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}