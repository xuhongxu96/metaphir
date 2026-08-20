// Reimplementation of llvm/llvm-project PR #215130 as a pass plugin.
//
// uadd.sat(X, C) + -C --> umin(X, ~C)
// Conditions: add RHS constant C; LHS is a one-use uadd.sat whose constant is
// -C. Anchor: the root `add`.

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

struct PR215130 : public PassInfoMixin<PR215130> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X;
        const APInt *SatC, *NegC;
        if (!match(&I, m_Add(m_OneUse(m_Intrinsic<Intrinsic::uadd_sat>(
                                 m_Value(X), m_APInt(SatC))),
                             m_APInt(NegC))))
          continue;
        if (!I.getType()->isIntegerTy() || *SatC != -*NegC)
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
        if (Name == "pr215130") {
          FPM.addPass(PR215130());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr215130", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}