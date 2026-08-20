// Reimplementation of llvm/llvm-project PR #212132 as a pass plugin.
//
// select(cond, 0, Shift) and select(cond, Shift, 0) where cond is a power-of-
// two test on Shift:
//   Case 1: select(or(icmp eq (Shift & A), 0, icmp eq (Shift & B), 0),
//                  0, Shift)  ->  select(cond, 0, pow2) ...
//   Case 2: select(and(icmp ne (Shift & A), 0, icmp ne (Shift & B), 0),
//                  Shift, 0)
// Conditions: Shift is a known power of two; the condition has a single use.
// Anchor: the root `select`.

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

struct PR212132 : public PassInfoMixin<PR212132> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    const DataLayout &DL = F.getParent()->getDataLayout();
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<SelectInst>(&I);
        if (!SI)
          continue;
        Value *A = nullptr, *B = nullptr, *Shift = nullptr;
        bool Case1 = false, Case2 = false;

        if (match(SI->getTrueValue(), m_Zero()) &&
            match(SI->getFalseValue(), m_Value(Shift))) {
          Case1 =
              match(SI->getCondition(),
                    m_Or(m_SpecificICmp(ICmpInst::ICMP_EQ,
                                        m_c_And(m_Specific(Shift), m_Value(A)),
                                        m_Zero()),
                         m_SpecificICmp(ICmpInst::ICMP_EQ,
                                        m_c_And(m_Specific(Shift), m_Value(B)),
                                        m_Zero())));
        } else if (match(SI->getFalseValue(), m_Zero()) &&
                   match(SI->getTrueValue(), m_Value(Shift))) {
          Case2 =
              match(SI->getCondition(),
                    m_And(m_SpecificICmp(ICmpInst::ICMP_NE,
                                         m_c_And(m_Specific(Shift), m_Value(A)),
                                         m_Zero()),
                          m_SpecificICmp(ICmpInst::ICMP_NE,
                                         m_c_And(m_Specific(Shift), m_Value(B)),
                                         m_Zero())));
        }
        if ((!Case1 && !Case2) || !SI->getCondition()->hasOneUse())
          continue;
        if (!isKnownToBeAPowerOfTwo(Shift, DL, /*OrZero=*/false))
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
        if (Name == "pr212132") {
          FPM.addPass(PR212132());
          return true;
        }
        return false;
      });
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "pr212132", LLVM_VERSION_STRING,
          registerPassBuilderCallbacks};
}