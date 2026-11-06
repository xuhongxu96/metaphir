//===- MetaphIRFolds.cpp - Each evaluated fold, alone, as a pass ----------===//
//
// A pass plugin holding the InstCombine folds of the evaluated PRs, so that a
// fold's ground truth does not depend on any other fold:
//
//   opt -load-pass-plugin=MetaphIRFolds.so -passes=metaphir-folds -disable-output
//
// The PRs are enabled one by one, so the input is parsed once: with each alone,
// its fold is tried on every instruction of the input. A fold's firings are
// reported as "ANCHOR <function> <pr>", once per function, and counted as
// "FIRINGS <function> <pr> <n>", on stderr.
//
// The code between BEGIN and END is copied from the patched InstCombine source
// named after BEGIN. eval/scripts/check_fold_plugin.py checks that each of its
// lines is in that file, in the same order, except those marked "differs":
// those replace the visitor around a fold. Conditions on the path to a fold are
// kept; every other fold is left out, and so is what a fold rewrites after it
// fires, so the input stays as it is in the file.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/StringMap.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/DomConditionCache.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::PatternMatch;

namespace {

/// The PRs the plugin holds, enabled one by one.
const StringRef PRs[] = {
    "pr204089", "pr204927", "pr204928", "pr205383", "pr207462",
    "pr207564", "pr209322", "pr210499", "pr212132", "pr213313",
    "pr213709", "pr214376", "pr214381", "pr214517", "pr214541",
    "pr215122", "pr215130", "pr216046", "pr216436", "pr216470",
};

/// The names the copied folds use. Only the fold of the current PR is enabled;
/// reportAnchor counts a firing.
namespace metaphir_eval {
StringRef Enabled;
bool foldEnabled(StringRef PR) { return PR == Enabled; }
StringMap<unsigned> *Firings;
void reportAnchor(const Instruction *, StringRef PR) { ++(*Firings)[PR]; }
} // namespace metaphir_eval

// BEGIN pr207462 llvm/lib/Transforms/InstCombine/InstCombineAddSub.cpp
static bool MatchMul(Value *E, Value *&Op, APInt &C) {
  const APInt *AI;
  if (match(E, m_Mul(m_Value(Op), m_APInt(AI)))) {
    C = *AI;
    return true;
  }
  if (match(E, m_Shl(m_Value(Op), m_APInt(AI)))) {
    C = APInt(AI->getBitWidth(), 1);
    C <<= *AI;
    return true;
  }
  return false;
}
static bool MatchRem(Value *E, Value *&Op, APInt &C, bool &IsSigned) {
  const APInt *AI;
  IsSigned = false;
  if (match(E, m_SRem(m_Value(Op), m_APInt(AI)))) {
    IsSigned = true;
    C = *AI;
    return true;
  }
  if (match(E, m_URem(m_Value(Op), m_APInt(AI)))) {
    C = *AI;
    return true;
  }
  if (match(E, m_And(m_Value(Op), m_APInt(AI))) && (*AI + 1).isPowerOf2()) {
    C = *AI + 1;
    return true;
  }
  return false;
}
static bool MatchDiv(Value *E, Value *&Op, APInt &C, bool IsSigned) {
  const APInt *AI;
  if (IsSigned && match(E, m_SDiv(m_Value(Op), m_APInt(AI)))) {
    C = *AI;
    return true;
  }
  if (!IsSigned) {
    if (match(E, m_UDiv(m_Value(Op), m_APInt(AI)))) {
      C = *AI;
      return true;
    }
    if (match(E, m_LShr(m_Value(Op), m_APInt(AI)))) {
      C = APInt(AI->getBitWidth(), 1);
      C <<= *AI;
      return true;
    }
  }
  return false;
}
// END

// BEGIN pr205383 llvm/lib/Transforms/InstCombine/InstCombineSelect.cpp
static Instruction *foldSelectCtlzToCttz(ICmpInst *ICI, Value *TrueVal,
                                         Value *FalseVal) { // differs
  unsigned BitWidth = TrueVal->getType()->getScalarSizeInBits();
  if (!ICI->isEquality() || !match(ICI->getOperand(1), m_Zero()))
    return nullptr;

  if (ICI->getPredicate() == ICmpInst::ICMP_NE)
    std::swap(TrueVal, FalseVal);

  Value *Ctlz;
  if (match(FalseVal,
            m_Xor(m_Value(Ctlz), m_SpecificIntAllowPoison(BitWidth - 1)))) {
    if (!isPowerOf2_32(BitWidth))
      return nullptr;
  } else if (!match(FalseVal, m_Sub(m_SpecificIntAllowPoison(BitWidth - 1),
                                    m_Value(Ctlz)))) {
    return nullptr;
  }

  if (!match(Ctlz, m_Ctlz(m_Value(), m_Value())))
    return nullptr;

  if (!match(TrueVal, m_SpecificInt(BitWidth)))
    return nullptr;

  Value *X = ICI->getOperand(0);
  auto *II = cast<IntrinsicInst>(Ctlz);
  if (!match(II->getOperand(0), m_c_And(m_Specific(X), m_Neg(m_Specific(X)))))
    return nullptr;

  return II; // differs
}
// END

// BEGIN pr212132 llvm/lib/Transforms/InstCombine/InstCombineSelect.cpp
static Instruction *foldSelectAndOrPowerOfTwo(SelectInst &SI,
                                              const SimplifyQuery &SQ) {
  Value *Cond = SI.getCondition();

  if (!Cond->hasOneUse())
    return nullptr;

  Value *TrueVal = SI.getTrueValue();
  Value *FalseVal = SI.getFalseValue();

  Value *A, *B, *Shift;

  bool Case1 =
      match(TrueVal, m_Zero()) && match(FalseVal, m_Value(Shift)) &&
      match(Cond, m_Or(m_SpecificICmp(ICmpInst::ICMP_EQ,
                                      m_c_And(m_Specific(Shift), m_Value(A)),
                                      m_Zero()),
                       m_SpecificICmp(ICmpInst::ICMP_EQ,
                                      m_c_And(m_Specific(Shift), m_Value(B)),
                                      m_Zero())));

  bool Case2 =
      match(FalseVal, m_Zero()) && match(TrueVal, m_Value(Shift)) &&
      match(Cond, m_And(m_SpecificICmp(ICmpInst::ICMP_NE,
                                       m_c_And(m_Specific(Shift), m_Value(A)),
                                       m_Zero()),
                        m_SpecificICmp(ICmpInst::ICMP_NE,
                                       m_c_And(m_Specific(Shift), m_Value(B)),
                                       m_Zero())));

  if ((Case1 || Case2) && isKnownToBeAPowerOfTwo(Shift, /*OrZero=*/true,
                                                 SQ.getWithInstruction(&SI))) {
    return &SI; // differs
  }

  return nullptr;
}
// END

/// What the folds use of InstCombinerImpl, with the same names.
struct Folds {
  AssumptionCache &AC;
  DominatorTree &DT;
  SimplifyQuery SQ;

  bool willNotOverflowUnsignedAdd(const WithCache<const Value *> &LHS,
                                  const WithCache<const Value *> &RHS,
                                  const Instruction &CtxI) const {
    return llvm::computeOverflowForUnsignedAdd(
               LHS, RHS, SQ.getWithInstruction(&CtxI)) ==
           OverflowResult::NeverOverflows;
  }
  bool willNotOverflowUnsignedMul(const Value *LHS, const Value *RHS,
                                  const Instruction &CtxI,
                                  bool IsNSW = false) const {
    return llvm::computeOverflowForUnsignedMul(
               LHS, RHS, SQ.getWithInstruction(&CtxI), IsNSW) ==
           OverflowResult::NeverOverflows;
  }

  // BEGIN pr204089 llvm/lib/Analysis/InstructionSimplify.cpp
  Value *pr204089(unsigned CastOpc, Value *Op, Type *Ty) { // differs
  // [MetaphIR eval] PR 204089: Fold a value-preserving zext/sext of a trunc back to the original value.
  if (metaphir_eval::foldEnabled("pr204089")) {
    if (CastOpc == Instruction::ZExt || CastOpc == Instruction::SExt) {
      if (auto *Trunc = dyn_cast<TruncInst>(Op)) {
        Value *Src = Trunc->getOperand(0);
        bool NoWrap = CastOpc == Instruction::ZExt ? Trunc->hasNoUnsignedWrap()
                                                   : Trunc->hasNoSignedWrap();
        if (Src->getType() == Ty && NoWrap) {
          metaphir_eval::reportAnchor(Trunc, "pr204089");
          return Src;
        }
      }
    }
  }

  return nullptr;
  } // differs
  // END

  // BEGIN pr213313 llvm/lib/Analysis/InstructionSimplify.cpp
  Value *pr213313And(Value *Op0, Value *Op1, const SimplifyQuery &Q) { // differs
  // [MetaphIR eval] PR 213313: zext(X) & sext(X) --> zext(X).
  if (metaphir_eval::foldEnabled("pr213313")) {
    Value *X = nullptr;
    if (match(Op0, m_ZExt(m_Value(X))) && match(Op1, m_SExt(m_Specific(X)))) {
      metaphir_eval::reportAnchor(Q.CtxI, "pr213313");
      return Op0;
    }
    if (match(Op1, m_ZExt(m_Value(X))) && match(Op0, m_SExt(m_Specific(X)))) {
      metaphir_eval::reportAnchor(Q.CtxI, "pr213313");
      return Op1;
    }
  }
  return nullptr; // differs
  } // differs

  Value *pr213313Or(Value *Op0, Value *Op1, const SimplifyQuery &Q) { // differs
  // [MetaphIR eval] PR 213313: zext(X) | sext(X) --> sext(X).
  if (metaphir_eval::foldEnabled("pr213313")) {
    Value *X = nullptr;
    if (match(Op0, m_ZExt(m_Value(X))) && match(Op1, m_SExt(m_Specific(X)))) {
      metaphir_eval::reportAnchor(Q.CtxI, "pr213313");
      return Op1;
    }
    if (match(Op1, m_ZExt(m_Value(X))) && match(Op0, m_SExt(m_Specific(X)))) {
      metaphir_eval::reportAnchor(Q.CtxI, "pr213313");
      return Op0;
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr204927,pr207564 llvm/lib/Transforms/InstCombine/InstCombineCasts.cpp
  Instruction *visitZExt(ZExtInst &Zext) { // differs
  // If this zero extend is only used by a truncate, let the truncate be
  // eliminated before we try to optimize this zext.
  if (Zext.hasOneUse() && isa<TruncInst>(Zext.user_back()) &&
      !isa<Constant>(Zext.getOperand(0)))
    return nullptr;

  Value *Src = Zext.getOperand(0);
  Type *SrcTy = Src->getType(), *DestTy = Zext.getType();
  Value *X; // differs

  // [MetaphIR eval] PR 207564: zext(sub(0, trunc(X))) -> and(sub(0, X), mask).
  if (metaphir_eval::foldEnabled("pr207564") &&
      match(Src, m_Sub(m_Zero(), m_Trunc(m_SpecificType(DestTy, X))))) {
    metaphir_eval::reportAnchor(&Zext, "pr207564");
    return nullptr; // differs
  }

  Value *Y;
  // [MetaphIR eval] PR 204927: zext(and/or/xor(trunc nuw x), y) ->
  // and/or/xor(zext(y), x).
  if (metaphir_eval::foldEnabled("pr204927") &&
      match(Src, m_OneUse(m_c_BitwiseLogic(
                     m_NUWTrunc(m_SpecificType(DestTy, X)), m_Value(Y))))) {
    metaphir_eval::reportAnchor(&Zext, "pr204927");
    return nullptr; // differs
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr204928 llvm/lib/Transforms/InstCombine/InstCombineCasts.cpp
  Instruction *visitSExt(SExtInst &Sext) { // differs
  // If this sign extend is only used by a truncate, let the truncate be
  // eliminated before we try to optimize this sext.
  if (Sext.hasOneUse() && isa<TruncInst>(Sext.user_back()))
    return nullptr;

  Value *Src = Sext.getOperand(0);
  Type *DestTy = Sext.getType(); // differs
  Value *X; // differs
  Value *Y;
  // [MetaphIR eval] PR 204928: sext(and/or/xor(trunc nsw x), y) ->
  // and/or/xor(sext(y), x).
  if (metaphir_eval::foldEnabled("pr204928") &&
      match(Src, m_OneUse(m_c_BitwiseLogic(
                     m_NSWTrunc(m_SpecificType(DestTy, X)), m_Value(Y))))) {
    metaphir_eval::reportAnchor(&Sext, "pr204928");
    return nullptr; // differs
  }

  return nullptr;
  } // differs
  // END

  // BEGIN pr210499 llvm/lib/Transforms/InstCombine/InstCombineCasts.cpp
  Instruction *visitTrunc(TruncInst &Trunc) { // differs
  Value *Src = Trunc.getOperand(0);
  Type *DestTy = Trunc.getType(), *SrcTy = Src->getType();
  unsigned DestWidth = DestTy->getScalarSizeInBits();
  Value *X;
  // [MetaphIR eval] PR 210499: trunc(shr exact X, Y) to i1 --> icmp ne X, 0.
  if (metaphir_eval::foldEnabled("pr210499") && DestWidth == 1 &&
      (Trunc.hasNoUnsignedWrap() || Trunc.hasNoSignedWrap()) &&
      match(Src, m_Exact(m_Shr(m_Value(X), m_Value())))) {
    metaphir_eval::reportAnchor(&Trunc, "pr210499");
    return nullptr; // differs
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr205383 llvm/lib/Transforms/InstCombine/InstCombineSelect.cpp
  Instruction *foldSelectInstWithICmp(SelectInst &SI, ICmpInst *ICI) { // differs
  Value *TrueVal = SI.getTrueValue();
  Value *FalseVal = SI.getFalseValue();
  // [MetaphIR eval] PR 205383: (bw-1) - ctlz(x & -x) -> cttz (sub and xor forms).
  if (metaphir_eval::foldEnabled("pr205383")) {
    if (Instruction *V =
            foldSelectCtlzToCttz(ICI, TrueVal, FalseVal)) { // differs
      metaphir_eval::reportAnchor(&SI, "pr205383");
      return V;
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr212132 llvm/lib/Transforms/InstCombine/InstCombineSelect.cpp
  Instruction *visitSelectInst(SelectInst &SI) { // differs
  // [MetaphIR eval] PR 212132: select((A&S)==0||(B&S)==0, 0, S) -> S & A & B.
  if (metaphir_eval::foldEnabled("pr212132")) {
    if (Instruction *I = foldSelectAndOrPowerOfTwo(SI, SQ)) { // differs
      metaphir_eval::reportAnchor(&SI, "pr212132");
      return I;
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr214541,pr209322 llvm/lib/Transforms/InstCombine/InstCombineMulDivRem.cpp
  Instruction *visitUDiv(BinaryOperator &I) { // differs
  Value *Op0 = I.getOperand(0), *Op1 = I.getOperand(1);
  Value *X;
  // [MetaphIR eval] PR 214541:
  // (X udiv Y) udiv Z --> X udiv (Y * Z), if Y * Z does not overflow.
  // This is the variable-operand version of the (X / C1) / C2 fold in
  // commonIDivTransforms().
  Value *Y;
  if (metaphir_eval::foldEnabled("pr214541") &&
      match(Op0, m_OneUse(m_UDiv(m_Value(X), m_Value(Y)))) &&
      willNotOverflowUnsignedMul(Y, Op1, I)) {
    metaphir_eval::reportAnchor(&I, "pr214541");
    return nullptr; // differs
  }

  // Op0 / C where C is large (negative) --> zext (Op0 >= C)
  // This also handles non-constant values where the sign bit is known to be
  // set.
  // [MetaphIR eval] PR 209322: generalize the udiv-by-negative-constant fold to
  // known-negative non-constants via isKnownNegative().
  if (metaphir_eval::foldEnabled("pr209322") &&
      isKnownNegative(Op1, SQ.getWithInstruction(&I))) {
    metaphir_eval::reportAnchor(&I, "pr209322");
    return nullptr; // differs
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr213709 llvm/lib/Transforms/InstCombine/InstCombineCompares.cpp
  Instruction *foldICmpAndConstant(ICmpInst &Cmp, BinaryOperator *And, const APInt &C) { // differs
  ICmpInst::Predicate Pred = Cmp.getPredicate(); // differs
  if (!Cmp.isEquality())
    return nullptr;

  // [MetaphIR eval] PR 213709:
  // (X & -X) == 0 --> X == 0
  // (X & -X) != 0 --> X != 0
  // (X & -X) == 1 --> trunc X to i1
  // (X & -X) != 1 --> !(trunc X to i1)
  // Cmp is == or != by the check above.
  Value *MatchedX;
  // Match X & -X in either operand order.
  if (metaphir_eval::foldEnabled("pr213709") &&
      C.getBitWidth() > 1 && (C.isZero() || C.isOne()) &&
      match(And, m_c_And(m_Neg(m_Value(MatchedX)), m_Deferred(MatchedX)))) {
    // Preserve the predicate: (X & -X) ==/!= 0 --> X ==/!= 0.
    if (C.isZero()) {
      metaphir_eval::reportAnchor(&Cmp, "pr213709");
      return nullptr; // differs
    }

    // (X & -X) == 1 iff the low bit of X is set.
    if (Pred == CmpInst::ICMP_EQ) {
      metaphir_eval::reportAnchor(&Cmp, "pr213709");
      return nullptr; // differs
    }

    // The remaining case needs a trunc and not. Require the original and
    // to become dead to avoid increasing the instruction count.
    if (And->hasOneUse()) {
      metaphir_eval::reportAnchor(&Cmp, "pr213709");
      return nullptr; // differs
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr214381 llvm/lib/Transforms/InstCombine/InstCombineCompares.cpp
  Instruction *foldICmpSubConstant(ICmpInst &Cmp, BinaryOperator *Sub, const APInt &C) { // differs
  Value *X = Sub->getOperand(0), *Y = Sub->getOperand(1);
  ICmpInst::Predicate Pred = Cmp.getPredicate();

  // [MetaphIR eval] PR 214381:
  // (X - (X urem D)) is D*(X/D), a multiple of D, so it is u> C exactly when
  // X u>= D (for C u< D), and u< C exactly when X u< D (for 0 u< C u<= D):
  //   icmp ugt (sub X, (urem X, D)), C --> icmp ugt X, D-1
  //   icmp ult (sub X, (urem X, D)), C --> icmp ult X, D
  const APInt *D;
  if (metaphir_eval::foldEnabled("pr214381") &&
      match(Y, m_URem(m_Specific(X), m_APInt(D))) && !D->isZero()) {
    if (Pred == ICmpInst::ICMP_UGT && C.ult(*D)) {
      metaphir_eval::reportAnchor(&Cmp, "pr214381");
      return nullptr; // differs
    }
    if (Pred == ICmpInst::ICMP_ULT && !C.isZero() && C.ule(*D)) {
      metaphir_eval::reportAnchor(&Cmp, "pr214381");
      return nullptr; // differs
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr214376 llvm/lib/Transforms/InstCombine/InstCombineCalls.cpp
  Instruction *foldCttzCtlz(IntrinsicInst &II) { // differs
  bool IsTZ = II.getIntrinsicID() == Intrinsic::cttz;
  Value *Op0 = II.getArgOperand(0);
  Value *X;
  if (IsTZ) {
    // [MetaphIR eval] PR 214376: cttz(mul(X, OddC)) -> cttz(X).
    if (metaphir_eval::foldEnabled("pr214376")) {
      if (match(Op0, m_Mul(m_Value(X),
                           m_CheckedInt([](const APInt &C) { return C[0]; })))) {
        metaphir_eval::reportAnchor(&II, "pr214376");
        return nullptr; // differs
      }
    }
  } // differs
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr216046 llvm/lib/Transforms/InstCombine/InstCombineCalls.cpp
  Instruction *visitSCmp(CallInst &CI, IntrinsicInst *II) { // differs
    Value *I0 = II->getArgOperand(0), *I1 = II->getArgOperand(1);

    // [MetaphIR eval] PR 216046: scmp(X, 0) -> sext_or_trunc(X) if X is known
    // to be one of -1, 0, 1.
    if (metaphir_eval::foldEnabled("pr216046")) {
      if (match(I1, m_Zero())) {
        ConstantRange Range = computeConstantRange(
            I0, /*ForSigned=*/true, SQ.getWithInstruction(II));
        if (Range.getSignedMin().sge(-1) && Range.getSignedMax().sle(1)) {
          metaphir_eval::reportAnchor(&CI, "pr216046");
          return nullptr; // differs
        }
      }
    }
    return nullptr; // differs
  } // differs
  // END

  // BEGIN pr214517 llvm/lib/Transforms/InstCombine/InstCombineShifts.cpp
  Instruction *visitShl(BinaryOperator &I) { // differs
  Value *Op0 = I.getOperand(0), *Op1 = I.getOperand(1);
  Value *X; // differs
  if (match(Op0, m_One())) {
    // [MetaphIR eval] PR 214517:
    // Canonicalize "extract lowest set bit" using cttz to and-with-negate:
    // 1 << (cttz X) --> -X & X
    if (metaphir_eval::foldEnabled("pr214517")) {
      if (match(Op1, m_OneUse(m_Cttz(m_Value(X), m_Value())))) {
        metaphir_eval::reportAnchor(&I, "pr214517");
        return nullptr; // differs
      }
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr215130 llvm/lib/Transforms/InstCombine/InstCombineAddSub.cpp
  Instruction *foldAddWithConstant(BinaryOperator &Add) { // differs
  Value *Op0 = Add.getOperand(0), *Op1 = Add.getOperand(1);
  Constant *Op1C;
  if (!match(Op1, m_ImmConstant(Op1C)))
    return nullptr;

  Value *X; // differs
  const APInt *C;
  if (!match(Op1, m_APInt(C))) // differs
    return nullptr; // differs
  // [MetaphIR eval] PR 215130: uadd.sat(X, C) + -C --> umin(X, ~C)
  // The saturating add gives X + C or UMAX, so subtracting C leaves X or
  // UMAX - C. Note UMAX - C == ~C.
  if (metaphir_eval::foldEnabled("pr215130")) {
    APInt SatC = -*C;
    if (match(Op0, m_OneUse(m_Intrinsic<Intrinsic::uadd_sat>(
                       m_Value(X), m_SpecificInt(SatC))))) {
      metaphir_eval::reportAnchor(&Add, "pr215130");
      return nullptr; // differs
    }
  }
  return nullptr; // differs
  } // differs
  // END

  // BEGIN pr207462 llvm/lib/Transforms/InstCombine/InstCombineAddSub.cpp
  Value *SimplifyAddWithRemainder(BinaryOperator &I) { // differs
  Value *LHS = I.getOperand(0), *RHS = I.getOperand(1);
  Value *X; // differs
  APInt C0; // differs
  bool IsSigned;
  // Match I = (X / C0) * C1 + (X % C0) * C2.
  auto FoldDivRem = [&](Value *DivSide, Value *RemSide) -> Value * {
    Value *Div, *Rem;
    APInt C1, C2;
    if (!DivSide->hasOneUse() || !MatchMul(DivSide, Div, C1))
      Div = DivSide, C1 = APInt(I.getType()->getScalarSizeInBits(), 1);
    if (!RemSide->hasOneUse() || !MatchMul(RemSide, Rem, C2))
      Rem = RemSide, C2 = APInt(I.getType()->getScalarSizeInBits(), 1);
    Value *DivOpV;
    APInt DivOpC;
    if (MatchRem(Rem, X, C0, IsSigned) &&
        MatchDiv(Div, DivOpV, DivOpC, IsSigned) && X == DivOpV &&
        C0 == DivOpC &&
        // Avoid unprofitable replacement of and with mul.
        !(C1.isOne() && !IsSigned && DivOpC.isPowerOf2() && DivOpC != 2)) {
      APInt NewC = C1 - C2 * C0;
      if (!NewC.isZero() && !Rem->hasOneUse())
        return nullptr;
      if (!isGuaranteedNotToBeUndef(X, &AC, &I, &DT))
        return nullptr;
      return X; // differs
    }
    return nullptr;
  };
  // [MetaphIR eval] PR 207462: commuted add of udiv/urem by 2.
  if (metaphir_eval::foldEnabled("pr207462"))
    if (Value *V = FoldDivRem(RHS, LHS)) {
      metaphir_eval::reportAnchor(&I, "pr207462");
      return V;
    }

  return nullptr;
  } // differs
  // END

  // BEGIN pr215122,pr216436,pr216470 llvm/lib/Transforms/InstCombine/InstCombineAddSub.cpp
  Instruction *visitAdd(BinaryOperator &I) { // differs
  Type *Ty = I.getType(); // differs
  Value *A; // differs
  // Align-up idiom:
  // [MetaphIR eval] PR 215122: X + ((-X) & (C - 1)) --> (X + C - 1) & -C, for a power-of-two C.
  // Note -C == ~(C - 1), so the mask is simply the inverted low-bit mask.
  {
    const APInt *LowMask;
    if (metaphir_eval::foldEnabled("pr215122") &&
        match(&I,
              m_c_Add(m_OneUse(m_And(m_Neg(m_Value(A)), m_LowBitMask(LowMask))),
                      m_Deferred(A)))) {
      metaphir_eval::reportAnchor(&I, "pr215122");
      return nullptr; // differs
    }
    // [MetaphIR eval] PR 216436: ((X - 1) | (C - 1)) + 1 -> (X + C - 1) & -C, for a power-of-two C.
    if (metaphir_eval::foldEnabled("pr216436") &&
        match(&I, m_Add(m_OneUse(m_Or(m_Add(m_Value(A), m_AllOnes()),
                                      m_LowBitMask(LowMask))),
                        m_One()))) {
      metaphir_eval::reportAnchor(&I, "pr216436");
      return nullptr; // differs
    }
  }

  // Ceiling division by power-of-2:
  // (X >> log2(N)) + zext(X & (N-1) != 0) --> (X + (N-1)) >> log2(N)
  // This is valid when adding (N-1) to X doesn't overflow.
  {
    Value *X;
    const APInt *ShiftAmt, *Mask;
    // Match: (X >> C) + zext((X & Mask) != 0)
    // or:    zext((X & Mask) != 0) + (X >> C)
    // [MetaphIR eval] PR 216470: also handle the case where the add's result
    // type is wider than X (the shift/icmp operands are zext'ed to it).
    if (metaphir_eval::foldEnabled("pr216470") &&
        match(&I,
              m_c_Add(m_ZExt(m_SpecificICmp(
                          ICmpInst::ICMP_NE,
                          m_And(m_Value(X), m_LowBitMask(Mask)), m_ZeroInt())),
                      m_OneUse(m_ZExtOrSelf(m_OneUse(
                          m_LShr(m_Deferred(X), m_APInt(ShiftAmt))))))) &&
        Mask->popcount() == *ShiftAmt) {

      // Check if X + Mask doesn't overflow
      unsigned Xbits = X->getType()->getScalarSizeInBits();
      unsigned Ibits = Ty->getScalarSizeInBits();
      bool NeedZext = Ibits > Xbits;
      Constant *MaskC = ConstantInt::get(Ty, Mask->zext(Ibits));
      if (NeedZext || willNotOverflowUnsignedAdd(X, MaskC, I)) {
        metaphir_eval::reportAnchor(&I, "pr216470");
        return nullptr; // differs
      }
    } // differs
    return nullptr; // differs
  } // differs
  } // differs
  // END
};

/// Tries the fold of each PR, alone, on the input instructions.
struct MetaphIRFoldsPass : OptionalPassInfoMixin<MetaphIRFoldsPass> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    auto &AC = FAM.getResult<AssumptionAnalysis>(F);
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    auto &TLI = FAM.getResult<TargetLibraryAnalysis>(F);
    // InstCombine registers each branch it visits, and it reaches a fixpoint
    // having visited them all.
    DomConditionCache DC;
    for (BasicBlock &BB : F)
      if (DT.isReachableFromEntry(&BB))
        if (auto *BI = dyn_cast<CondBrInst>(BB.getTerminator()))
          DC.registerBranch(BI);

    Folds Fold{AC, DT,
               SimplifyQuery(F.getDataLayout(), &TLI, &DT, &AC, nullptr,
                             /*UseInstrInfo*/ true, /*CanUseUndef*/ true, &DC)};
    StringMap<unsigned> Firings;
    metaphir_eval::Firings = &Firings;

    auto Visit = [&](Instruction &I) {
      if (auto *Zext = dyn_cast<ZExtInst>(&I)) {
        Fold.pr204089(Instruction::ZExt, Zext->getOperand(0), Zext->getType());
        Fold.visitZExt(*Zext);
      } else if (auto *Sext = dyn_cast<SExtInst>(&I)) {
        Fold.pr204089(Instruction::SExt, Sext->getOperand(0), Sext->getType());
        Fold.visitSExt(*Sext);
      } else if (auto *Trunc = dyn_cast<TruncInst>(&I)) {
        Fold.visitTrunc(*Trunc);
      } else if (auto *SI = dyn_cast<SelectInst>(&I)) {
        if (auto *ICI = dyn_cast<ICmpInst>(SI->getCondition()))
          Fold.foldSelectInstWithICmp(*SI, ICI);
        Fold.visitSelectInst(*SI);
      } else if (auto *Cmp = dyn_cast<ICmpInst>(&I)) {
        const APInt *C;
        if (match(Cmp->getOperand(1), m_APInt(C)))
          if (auto *BO = dyn_cast<BinaryOperator>(Cmp->getOperand(0))) {
            if (BO->getOpcode() == Instruction::And)
              Fold.foldICmpAndConstant(*Cmp, BO, *C);
            if (BO->getOpcode() == Instruction::Sub)
              Fold.foldICmpSubConstant(*Cmp, BO, *C);
          }
      } else if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
        if (II->getIntrinsicID() == Intrinsic::cttz)
          Fold.foldCttzCtlz(*II);
        if (II->getIntrinsicID() == Intrinsic::scmp)
          Fold.visitSCmp(*II, II);
      } else if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
        const SimplifyQuery Q = Fold.SQ.getWithInstruction(BO);
        switch (BO->getOpcode()) {
        case Instruction::Add:
          Fold.foldAddWithConstant(*BO);
          Fold.SimplifyAddWithRemainder(*BO);
          Fold.visitAdd(*BO);
          break;
        case Instruction::And:
          Fold.pr213313And(BO->getOperand(0), BO->getOperand(1), Q);
          break;
        case Instruction::Or:
          Fold.pr213313Or(BO->getOperand(0), BO->getOperand(1), Q);
          break;
        case Instruction::UDiv:
          Fold.visitUDiv(*BO);
          break;
        case Instruction::Shl:
          Fold.visitShl(*BO);
          break;
        default:
          break;
        }
      }
    };

    for (StringRef PR : PRs) {
      metaphir_eval::Enabled = PR;
      for (BasicBlock &BB : F)
        if (DT.isReachableFromEntry(&BB))
          for (Instruction &I : BB)
            Visit(I);
    }

    for (auto &E : Firings) {
      errs() << "ANCHOR " << F.getName() << " " << E.getKey() << "\n";
      errs() << "FIRINGS " << F.getName() << " " << E.getKey() << " "
             << E.getValue() << "\n";
    }
    return PreservedAnalyses::all();
  }
};

/// Removes the bodies of the optnone functions, which no pass optimizes, so a
/// corpus has none for a pattern to match; callers keep their declarations.
/// eval/scripts/prepare_corpus.py runs it on every module.
struct MetaphIRDropOptNonePass : RequiredPassInfoMixin<MetaphIRDropOptNonePass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    unsigned Dropped = 0;
    for (Function &F : M) {
      if (F.isDeclaration() || !F.hasOptNone())
        continue;
      F.deleteBody();
      F.setComdat(nullptr);
      ++Dropped;
    }
    if (!Dropped)
      return PreservedAnalyses::all();
    errs() << "DROPPED " << Dropped << "\n";
    return PreservedAnalyses::none();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "MetaphIRFolds", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "metaphir-folds") {
                    MPM.addPass(
                        createModuleToFunctionPassAdaptor(MetaphIRFoldsPass()));
                    return true;
                  }
                  if (Name == "metaphir-drop-optnone") {
                    MPM.addPass(MetaphIRDropOptNonePass());
                    return true;
                  }
                  return false;
                });
          }};
}
