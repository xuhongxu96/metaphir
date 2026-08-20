// Reimplementation of llvm/llvm-project PR #204928 as a pass plugin.
//
// sext(and/or/xor(trunc nsw X, Y)) to <wide> folds by hoisting the logic ahead
// of the sext when the truncated value sign-extends losslessly.
// Conditions: the logic op has a single use; the truncated value has nsw and
// its source type is the sext result type.
// Anchor: the root `sext`.

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

struct PR204928 : public PassInfoMixin<PR204928> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Sext = dyn_cast<SExtInst>(&I);
        if (!Sext)
          continue;
        Value *X, *Y;
        if (!match(Sext->getOperand(0),
                   m_OneUse(m_c_BitwiseLogic(
                       m_NSWTrunc(m_SpecificType(Sext->getType(), X)),
                       m_Value(Y)))))
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
        if (Name == "pr204928") {
          FPM.addPass(PR204928());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr204928", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}