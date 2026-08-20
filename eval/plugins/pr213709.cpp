// Reimplementation of llvm/llvm-project PR #213709 as a pass plugin.
//
// icmp {eq,ne} (X & -X), C with C a constant of width > 1 and C in {0, 1}.
// The !=1 case additionally requires the `and` to have a single use (mirrors
// the fold's conservative guard against dropping a sign-extended bit).
// Anchor: the root `icmp`.

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

struct PR213709 : public PassInfoMixin<PR213709> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Cmp = dyn_cast<ICmpInst>(&I);
        if (!Cmp || !Cmp->isEquality())
          continue;
        Value *X;
        const APInt *C;
        if (!match(Cmp->getOperand(0),
                   m_c_And(m_Neg(m_Value(X)), m_Deferred(X))) ||
            !match(Cmp->getOperand(1), m_APInt(C)))
          continue;
        if (C->getBitWidth() <= 1 || (!C->isZero() && !C->isOne()))
          continue;
        if (C->isOne() && Cmp->getPredicate() == ICmpInst::ICMP_NE) {
          auto *And = dyn_cast<BinaryOperator>(Cmp->getOperand(0));
          if (!And || !And->hasOneUse())
            continue;
        }

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
        if (Name == "pr213709") {
          FPM.addPass(PR213709());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr213709", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}