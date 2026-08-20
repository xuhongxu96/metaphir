// Reimplementation of llvm/llvm-project PR #214541 as a pass plugin.
//
// (X /u Y) /u Z --> X /u (Y * Z) when Y*Z cannot overflow unsigned.
// Conditions: root is a one-use udiv whose LHS is another udiv; the product of
// the two divisors is unsigned-overflow-free. The constant-only overflow check
// mirrors the pattern language; non-constant divisors that InstCombine could
// prove non-overflowing are not matched (documented approximation).
// Anchor: the root `udiv`.

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

bool WillNotOverflowUnsignedMul(const Value *Y, const Value *Z) {
  const APInt *CY = nullptr, *CZ = nullptr;
  if (!match(Y, m_APInt(CY)) || !match(Z, m_APInt(CZ)))
    return false;
  unsigned BW = CY->getBitWidth();
  APInt Product = *CY * *CZ;
  if (CY->isZero() || CZ->isZero())
    return false;
  if (*CY != Product.udiv(*CZ))
    return false;
  return true;
}

struct PR214541 : public PassInfoMixin<PR214541> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *X, *Y, *Z;
        if (!match(&I, m_UDiv(m_OneUse(m_UDiv(m_Value(X), m_Value(Y))),
                              m_Value(Z))))
          continue;
        if (!I.getType()->isIntegerTy() || !WillNotOverflowUnsignedMul(Y, Z))
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