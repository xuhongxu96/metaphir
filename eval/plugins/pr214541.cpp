// Reimplementation of llvm/llvm-project PR #214541 as a pass plugin.
//
// (X /u Y) /u Z --> X /u (Y * Z) when Y*Z cannot overflow unsigned.
// Conditions: root is a one-use udiv whose LHS is another udiv; the product of
// the two divisors is unsigned-overflow-free (reuses LLVM's
// computeOverflowForUnsignedMul, the same computation the InstCombine fold's
// willNotOverflowUnsignedMul is built on).
// Anchor: the root `udiv`.

#include "llvm/Analysis/SimplifyQuery.h"
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

struct PR214541 : public PassInfoMixin<PR214541> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    const DataLayout &DL = F.getParent()->getDataLayout();
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X, *Y, *Z;
        if (!match(&I, m_UDiv(m_OneUse(m_UDiv(m_Value(X), m_Value(Y))),
                              m_Value(Z))))
          continue;
        if (!I.getType()->isIntegerTy())
          continue;
        SimplifyQuery SQ(DL, &I);
        if (computeOverflowForUnsignedMul(Y, Z, SQ) !=
            OverflowResult::NeverOverflows)
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
        if (Name == "pr214541") {
          FPM.addPass(PR214541());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr214541", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}
