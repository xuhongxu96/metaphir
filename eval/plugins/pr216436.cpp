// Reimplementation of llvm/llvm-project PR #216436 as a pass plugin.
//
// Align-up idiom (new fold added by the PR):
//   ((X - 1) | (C - 1)) + 1  ->  (X + C - 1) & -C
// for a power-of-two C (so C - 1 is a low-bit mask).
//
// Structural conditions (mirroring visitAdd):
//   * root is `add` with RHS constant 1
//   * LHS is `or` (single use) of `sub(X, 1)` and a low-bit-mask constant
// The anchor recorded is the root `add` instruction.

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace PatternMatch;

namespace {

struct PR216436 : public PassInfoMixin<PR216436> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    bool Changed = false;
    SmallVector<Instruction *, 8> Worklist;
    SmallVector<Value *, 8> Values;
    SmallVector<const APInt *, 8> Masks;
    SmallVector<std::string, 8> Names;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // I = add(or(sub(X, 1), LowMask), 1)
        Value *A;
        const APInt *LowMask;
        if (!match(&I, m_Add(m_OneUse(m_Or(m_Add(m_Value(A), m_AllOnes()),
                                            m_LowBitMask(LowMask))),
                             m_One())))
          continue;
        if (!I.getType()->isIntegerTy())
          continue;

        // Record the SSA name (%ID) so anchors match the pattern tool output
        // (?anch = %N). Must happen before any mutation to keep numbering
        // consistent with the pristine module.
        std::string Name;
        raw_string_ostream OS(Name);
        I.printAsOperand(OS, /*PrintType=*/false);
        Names.push_back(OS.str().substr(1));
        Worklist.push_back(&I);
        Values.push_back(A);
        Masks.push_back(LowMask);
      }
    }

    for (size_t i = 0; i != Worklist.size(); ++i) {
      Instruction *I = Worklist[i];
      errs() << "ANCHOR " << F.getName() << " " << Names[i] << "\n";

      IRBuilder<> Builder(I);
      Value *NewAdd =
          Builder.CreateAdd(Values[i], ConstantInt::get(I->getType(), *Masks[i]));
      Value *NewAnd =
          Builder.CreateAnd(NewAdd, ConstantInt::get(I->getType(), ~*Masks[i]));
      I->replaceAllUsesWith(NewAnd);
      I->eraseFromParent();
      Changed = true;
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

static void registerPassBuilderCallbacks(PassBuilder &PB) {
  PB.registerPipelineParsingCallback(
      [](StringRef Name, FunctionPassManager &FPM,
         ArrayRef<PassBuilder::PipelineElement>) {
        if (Name == "pr216436") {
          FPM.addPass(PR216436());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr216436", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}
