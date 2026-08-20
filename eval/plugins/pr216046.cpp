// Reimplementation of llvm/llvm-project PR #216046 as a pass plugin.
//
// scmp(X, 0) --> sext_or_trunc(X) when X is a constant in [-1, 1] (the range
// version of the fold is approximated by the constant-only check, mirroring
// the pattern language).
// Anchor: the scmp call instruction.

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace PatternMatch;

namespace {

struct PR216046 : public PassInfoMixin<PR216046> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *II = dyn_cast<IntrinsicInst>(&I);
        if (!II || II->getIntrinsicID() != Intrinsic::scmp)
          continue;
        if (!match(II->getArgOperand(1), m_Zero()))
          continue;
        auto *C = dyn_cast<ConstantInt>(II->getArgOperand(0));
        if (!C)
          continue;
        const APInt &V = C->getValue();
        if (!V.isSignedIntN(V.getBitWidth()) || !V.sge(-1) || !V.sle(1))
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
        if (Name == "pr216046") {
          FPM.addPass(PR216046());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr216046", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}