// Reimplementation of llvm/llvm-project PR #209322 as a pass plugin.
//
// Op0 / Y --> zext (Op0 u>= Y) when Y is known negative (sign bit set). The
// PR generalized the constant-only fold to any known-negative divisor via
// isKnownNegative. Anchor: the root `udiv`.

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

struct PR209322 : public PassInfoMixin<PR209322> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    SimplifyQuery SQ(F.getParent()->getDataLayout());
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *Op0, *Op1;
        if (!match(&I, m_UDiv(m_Value(Op0), m_Value(Op1))))
          continue;
        if (!I.getType()->isIntegerTy())
          continue;
        if (!isKnownNegative(Op1, SQ.getWithInstruction(&I)))
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
        if (Name == "pr209322") {
          FPM.addPass(PR209322());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr209322", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}