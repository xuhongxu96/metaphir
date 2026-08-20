// Reimplementation of llvm/llvm-project PR #204927 as a pass plugin.
//
// zext(and/or/xor(trunc nuw X, Y)) to <wide> folds by hoisting the logic ahead
// of the zext when the truncated value zero-extends losslessly.
// Conditions: the logic op has a single use; the truncated value has nuw and
// its source type is the zext result type.
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

struct PR204927 : public PassInfoMixin<PR204927> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Zext = dyn_cast<ZExtInst>(&I);
        if (!Zext)
          continue;
        Value *X, *Y;
        if (!match(Zext->getOperand(0),
                   m_OneUse(m_c_BitwiseLogic(
                       m_NUWTrunc(m_SpecificType(Zext->getType(), X)),
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
        if (Name == "pr204927") {
          FPM.addPass(PR204927());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr204927", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}