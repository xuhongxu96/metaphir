// Reimplementation of llvm/llvm-project PR #205383 as a pass plugin.
//
// select(icmp {eq,ne} X, 0, BW, (BW-1) {xor,sub} ctlz(X & -X)) folds to
// cttz(X, false). The PR generalized the power-of-two-only xor form to any
// bitwidth and added the sub form.
// Anchor: the root `select`.

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

struct PR205383 : public PassInfoMixin<PR205383> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<SelectInst>(&I);
        if (!SI)
          continue;
        auto *Cmp = dyn_cast<ICmpInst>(SI->getCondition());
        if (!Cmp || !Cmp->isEquality() || !match(Cmp->getOperand(1), m_Zero()))
          continue;

        Value *TrueVal = SI->getTrueValue();
        Value *FalseVal = SI->getFalseValue();
        if (Cmp->getPredicate() == ICmpInst::ICMP_NE)
          std::swap(TrueVal, FalseVal);
        unsigned BitWidth = TrueVal->getType()->getScalarSizeInBits();

        Value *Ctlz;
        if (!match(FalseVal,
                   m_c_Xor(m_Value(Ctlz), m_SpecificInt(BitWidth - 1))) &&
            !match(FalseVal, m_Sub(m_SpecificInt(BitWidth - 1), m_Value(Ctlz))))
          continue;
        if (!match(Ctlz, m_Ctlz(m_Value(), m_Value())))
          continue;
        if (!match(TrueVal, m_SpecificInt(BitWidth)))
          continue;

        Value *X = Cmp->getOperand(0);
        auto *II = cast<IntrinsicInst>(Ctlz);
        if (!match(II->getOperand(0),
                   m_c_And(m_Specific(X), m_Neg(m_Specific(X)))))
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
        if (Name == "pr205383") {
          FPM.addPass(PR205383());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr205383", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}