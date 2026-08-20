// Reimplementation of llvm/llvm-project PR #213313 as a pass plugin.
//
// and(zext(X), sext(X)) and or(zext(X), sext(X)) folds that drop a
// zero-extended bit when X is non-negative and the result sign-extends.
// Matches the structural form: a bitwise and/or of a zext(X) with a sext(X).
// Anchor: the root `and`/`or`.

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

struct PR213313 : public PassInfoMixin<PR213313> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (I.getOpcode() != Instruction::And &&
            I.getOpcode() != Instruction::Or)
          continue;
        if (!I.getType()->isIntegerTy())
          continue;
        Value *X;
        if (!match(&I,
                   m_c_BitwiseLogic(m_ZExt(m_Value(X)), m_SExt(m_Deferred(X)))))
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
        if (Name == "pr213313") {
          FPM.addPass(PR213313());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr213313", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}