// Reimplementation of llvm/llvm-project PR #216470 as a pass plugin.
//
// ceil(X / 2^ShiftAmt):
//   zext(X & Mask != 0) + zext(X >> ShiftAmt)  (Mask = 2^ShiftAmt - 1)
// folds by merging into a single shift when the mask equals 2^ShiftAmt - 1
// (i.e. Mask->popcount() == ShiftAmt).
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

struct PR216470 : public PassInfoMixin<PR216470> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X;
        const APInt *Mask, *ShiftAmt;
        if (!match(&I, m_c_Add(m_ZExt(m_SpecificICmp(
                                   ICmpInst::ICMP_NE,
                                   m_And(m_Value(X), m_LowBitMask(Mask)),
                                   m_ZeroInt())),
                               m_OneUse(m_ZExt(m_OneUse(m_LShr(
                                   m_Deferred(X), m_APInt(ShiftAmt))))))))
          continue;
        if (!I.getType()->isIntegerTy() || Mask->popcount() != *ShiftAmt)
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
        if (Name == "pr216470") {
          FPM.addPass(PR216470());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr216470", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}