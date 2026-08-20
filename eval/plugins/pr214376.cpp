// Reimplementation of llvm/llvm-project PR #214376 as a pass plugin.
//
// cttz(X * C, is_zero_undef) --> cttz(X, is_zero_undef) when C is odd.
// Anchor: the cttz call instruction.

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

struct PR214376 : public PassInfoMixin<PR214376> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X;
        const APInt *Odd;
        if (!match(&I, m_Intrinsic<Intrinsic::cttz>(
                           m_Mul(m_Value(X), m_APInt(Odd)), m_Value())))
          continue;
        if ((*Odd)[0] == 0)
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
        if (Name == "pr214376") {
          FPM.addPass(PR214376());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr214376", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}