// Reimplementation of llvm/llvm-project PR #204089 as a pass plugin.
//
// zext/sext of a value-preserving trunc folds back to the source value:
//   zext(trunc nuw X) with SrcType == DestType -> X
//   sext(trunc nsw X) with SrcType == DestType -> X
// Anchor: the root `zext`/`sext`.

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

struct PR204089 : public PassInfoMixin<PR204089> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Cast = dyn_cast<CastInst>(&I);
        if (!Cast || (Cast->getOpcode() != Instruction::ZExt &&
                      Cast->getOpcode() != Instruction::SExt))
          continue;
        auto *Trunc = dyn_cast<TruncInst>(Cast->getOperand(0));
        if (!Trunc)
          continue;
        Value *Src = Trunc->getOperand(0);
        bool NoWrap = Cast->getOpcode() == Instruction::ZExt
                          ? Trunc->hasNoUnsignedWrap()
                          : Trunc->hasNoSignedWrap();
        if (Src->getType() != Cast->getType() || !NoWrap)
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
        if (Name == "pr204089") {
          FPM.addPass(PR204089());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr204089", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}