# Comprehensive MetaphIR Evaluation & Discrepancy Investigation Report

## Executive Summary

This report presents the current evaluation of MetaphIR against LLVM's `InstCombine` pass across all 20 pull requests on the evaluation corpus of **50,838 modules** (the preprocessed benchmark bitcode and the PRs' upstream test files).

10 of the 20 PRs match exactly. Every discrepancy in the other 10 is either expected (an earlier InstCombine transformation changes or removes the shape first) or accepted (see *Evaluation Setup Notes*).

For every pull request with non-100% F1 score, this report provides:
- The MetaphIR pattern code (`.mpir`).
- The instrumented LLVM C++ implementation with the `reportAnchor` site.
- The concrete Target LLVM IR from the corpus for each False Positive (FP) and False Negative (FN).
- A step-by-step root-cause analysis explaining the divergence between static pattern matching on input IR and dynamic InstCombine execution.
- A resolution: expected, accepted, or a concrete proposed fix.

Every FP/FN listed below was reproduced by running the instrumented `opt` (`METAPHIR_EVAL_ANCHOR=1 -passes='function(instcombine<no-verify-fixpoint>)'`) and `metaphir-match` on the corpus module, and the cause was confirmed either by tracing (debug output / gdb backtrace at `reportAnchor`) or by a minimal IR edit that removes the cause and makes the fold fire. Line numbers refer to the current `llvm-project` checkout.

---

## Evaluation Setup Notes

1. **Ground truth runs `instcombine<no-verify-fixpoint>`.** With fixpoint verification on (the `opt` default), InstCombine aborts on some modules with `LLVM ERROR: Instruction Combining on <fn> did not reach a fixpoint` (e.g. `velox__DecimalFunctions.bc`, `abc__giaSimBase.bc`, `harfbuzz__harfbuzz.bc`, `node__sqlite3.bc`), and every later function in the module loses its anchors. `run_llvm_anchors` (`eval/scripts/run_eval.py`) disables the check and `gt` lists any module where `opt` still exits non-zero; the current run has none.
2. **Each upstream test file is in the corpus once.** `add-mask-neg.ll` exercises both pr216436 and pr215122; it is included once (as `pr216436__add-mask-neg.ll`) and counted for both PRs.
3. **Accepted discrepancies.** These are kept as is and have no proposed fix:
   - **`optnone` functions**: the pass manager skips InstCombine on them, so no anchor can fire, but `metaphir-match` still matches them (all 16 FPs of pr204089).
   - **Anchors fired from simplify queries on operand combinations that are not in the IR**: `foldOpIntoPhi`/`FoldOpIntoSelect` translating a cast through a phi/select (pr204089 FNs), and `simplifyOrInst`'s internal reassociation/distribution attempts (pr213313 FNs).

---

## Overall Evaluation Metrics Table

| PR | \|G\| | \|P\| | TP | FP | FN | Anchor Recall | Anchor Precision | Anchor F1 | Function F1 | Status |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| **pr216436** | 42 | 42 | 42 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr213709** | 27 | 27 | 27 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr214376** | 5 | 5 | 5 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr216470** | 9 | 9 | 9 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr212132** | 5 | 5 | 5 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr210499** | 11 | 11 | 11 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr216046** | 2 | 2 | 2 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr214541** | 38 | 38 | 38 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr214517** | 17 | 17 | 17 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr207462** | 47 | 47 | 47 | 0 | 0 | 100.0% | 100.0% | **100.0%** | **100.0%** | Exact match |
| **pr215122** | 30 | 31 | 30 | 1 | 0 | 100.0% | 96.77% | **98.36%** | **100.0%** | Overlapping instances of the same fold |
| **pr207564** | 158 | 159 | 158 | 1 | 0 | 100.0% | 99.37% | **99.68%** | **100.0%** | Use count changes; `canEvaluateZExtd` wins |
| **pr204928** | 6949 | 6950 | 6949 | 1 | 0 | 100.0% | 99.99% | **99.99%** | **100.0%** | Reassociation by `reassociateForUses` |
| **pr204927** | 8300 | 8301 | 8300 | 1 | 0 | 100.0% | 99.99% | **99.99%** | **100.0%** | Phi-cycle narrowing |
| **pr209322** | 10 | 12 | 10 | 2 | 0 | 100.0% | 83.33% | **90.91%** | **95.24%** | Earlier `commonIDivTransforms` / `simplifyUDivInst` |
| **pr205383** | 5 | 4 | 4 | 0 | 1 | 80.00% | 100.0% | **88.89%** | **88.89%** | `foldSelectValueEquivalence` rewrites true arm |
| **pr214381** | 17 | 16 | 14 | 2 | 3 | 82.35% | 87.50% | **84.85%** | **83.87%** | Pow2 divisor; `uge`/`ule` canonicalization; `mul(udiv)` |
| **pr213313** | 15 | 10 | 10 | 0 | 5 | 66.67% | 100.0% | **80.00%** | **86.96%** | Speculative `simplifyOrInst` queries (accepted) |
| **pr215130** | 5 | 3 | 3 | 0 | 2 | 60.00% | 100.0% | **75.00%** | **75.00%** | `sub` input rewritten to `add` by Negator |
| **pr204089** | 4021 | 19 | 3 | 16 | 4018 | 0.07% | 15.79% | **0.15%** | **0.48%** | FN: via `foldOpIntoPhi`/`FoldOpIntoSelect` (ignored); FP: `optnone` (accepted) |

---

## Detailed PR Discrepancy Breakdown

---

### PR 215122: Align-Up Idiom `X + ((-X) & LowMask) --> (X + LowMask) & ~LowMask`

- **Pattern File (`eval/patterns/pr215122.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %neg = neg i?bits ?a
  %and = and:c:s i?bits %neg, ?cm:lowBitMask:or(:scalar, :constantSplat)
  %add = add:?anch:c nsw:?_ nuw:?_ i?bits ?a, %and
  ```

- **LLVM Implementation (`InstCombineAddSub.cpp:1834-1842`)**:
  ```cpp
  if (!metaphir_eval::foldsDisabled()) {
    const APInt *LowMask;
    if (match(&I,
              m_c_Add(m_OneUse(m_And(m_Neg(m_Value(A)), m_LowBitMask(LowMask))),
                      m_Deferred(A)))) {
      metaphir_eval::reportAnchor(&I, "pr215122");
      Value *NewAdd = Builder.CreateAdd(A, ConstantInt::get(Ty, *LowMask));
      return BinaryOperator::CreateAnd(NewAdd, ConstantInt::get(Ty, ~*LowMask));
    }
  ```

- **Metrics**: |G|=30, |P|=31, TP=30, FP=1, FN=0 (Anchor F1: **98.36%**, Function F1: **100.0%**, 27/27 functions)

#### False Positive (1/1): an earlier fold of the same PR destroys the second match
- **Target File & Function**: `wireshark__packet-lustre.bc` @ `@lustre_opcode_process`, anchor `%834`
- **Target LLVM IR**:
  ```llvm
  %827 = add i32 %791, %778
  %828 = sub i32 0, %827
  %829 = and i32 %828, 7
  %830 = add i32 %829, %827        ; match #1 (fires, TP)
  %831 = add i32 %804, %830
  %832 = sub i32 0, %831
  %833 = and i32 %832, 7
  %834 = add i32 %833, %831        ; match #2 (FP)
  ```
- **After InstCombine**:
  ```llvm
  %828 = add i32 %827, 7
  %829 = and i32 %828, -8          ; input %830
  %830 = add i32 %804, %829        ; input %831
  %831 = sub i32 0, %804           ; input %832: the "+ %829" term is gone
  %832 = and i32 %831, 7
  %833 = add i32 %832, %830        ; input %834: -X operand no longer matches X
  ```
- **Step-by-Step Explanation**:
  1. Both `%830` and `%834` match the pattern on the input IR.
  2. InstCombine folds `%830` first into `(%827 + 7) & -8`, whose low 3 bits are known zero.
  3. `%833 = and %832, 7` only demands the low 3 bits of `%832 = -(%804 + %830)`. Because `%830` contributes nothing to those bits, the negation is simplified to `sub 0, %804`.
  4. `%834` is now `((-%804) & 7) + (%804 + %829)`. The negated value and the added value are different, so `m_Deferred(A)` fails and the anchor never fires.
  5. Verified: if `%830` is changed so it cannot fold (e.g. `add %829, %791`), `%834` fires.
- **Resolution**: Expected. An earlier firing of the same fold changes the second instance; no fix.

---

### PR 215130: `uadd.sat(X, C) + -C --> umin(X, ~C)`

- **Pattern File (`eval/patterns/pr215130.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %sat = call:s i?bits @llvm.uadd.sat(i?bits ?x, i?bits ?c:or(:constantInt, :constantSplat))
  %res = add:?anch:c nsw:?_ nuw:?_ i?bits %sat, ?negc:or(:constantInt, :constantSplat)
  ;; add(?c, ?negc, ?bits) == 0
  ```

- **LLVM Implementation (`InstCombineAddSub.cpp:1007-1020`, inside `foldAddWithConstant`)**:
  ```cpp
  // [MetaphIR eval] PR 215130: uadd.sat(X, C) + -C --> umin(X, ~C)
  if (!metaphir_eval::foldsDisabled()) {
    APInt SatC = -*C;
    if (match(Op0, m_OneUse(m_Intrinsic<Intrinsic::uadd_sat>(
                       m_Value(X), m_SpecificInt(SatC))))) {
      metaphir_eval::reportAnchor(&Add, "pr215130");
      return replaceInstUsesWith(
          Add, Builder.CreateBinaryIntrinsic(Intrinsic::umin, X,
                                             ConstantInt::get(Ty, ~SatC)));
    }
  }
  ```

- **Metrics**: |G|=5, |P|=3, TP=3, FP=0, FN=2 (Anchor F1: **75.00%**, Function F1: **75.00%**)

All divergences have one cause: **the input is `sub X, C`, which InstCombine rewrites to `add X, -C` first** (2 FN: `test_scalar_uadd_sub_const` and `test_vector_uadd_sub_const` in `pr215130__saturating-add-sub.ll`).

#### False Negative Example
- **Target File & Function**: `pr215130__saturating-add-sub.ll` @ `@test_scalar_uadd_sub_const` (the vector twin `@test_vector_uadd_sub_const` uses `splat (i8 42)` and behaves the same way)
- **Target LLVM IR**:
  ```llvm
  %sat = call i8 @llvm.uadd.sat.i8(i8 %a, i8 42)
  %res = sub i8 %sat, 42
  ret i8 %res
  ```
- **Step-by-Step Explanation**:
  1. The input contains `sub %sat, 42`, and the pattern only matches `add`.
  2. `visitSub` tries to read `sub a, b` as `add a, (sub 0, b)`: `Negator::Negate` folds `-42` into the constant, and `visitSub` returns `BinaryOperator::CreateAdd(NegOp1, Op0)` (`InstCombineAddSub.cpp:2507-2516`). The new `add` takes over the name `%res`.
  3. `visitAdd` → `foldAddWithConstant` then sees `add %sat, -42` and fires the anchor on `%res`. The output is `%res = call i8 @llvm.umin.i8(i8 %a, i8 -43)`.
- **Resolution**: Expected. An earlier transformation (the Negator in `visitSub`) produces the shape the fold needs; no fix.

---

### PR 214381: `icmp (sub X, (urem X, D)), C`

- **Pattern File (`eval/patterns/pr214381.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %rem = urem i?bits ?x, ?d:constantInt
  %aligned = sub nuw:?_ nsw:?_ i?bits ?x, %rem
  %cmp = icmp:?anch samesign:?_ ?pred i?bits %aligned, ?c:constantInt
  ;; (?d != 0)
  ;; ((?pred == "ugt" && ult(?c, ?d)) || (?pred == "ult" && ?c != 0 && ule(?c, ?d)))
  ```

- **LLVM Implementation (`InstCombineCompares.cpp:3065-3076`, inside `foldICmpSubConstant`)**:
  ```cpp
  const APInt *D;
  if (!metaphir_eval::foldsDisabled() &&
      match(Y, m_URem(m_Specific(X), m_APInt(D))) && !D->isZero()) {
    if (Pred == ICmpInst::ICMP_UGT && C.ult(*D)) {
      metaphir_eval::reportAnchor(&Cmp, "pr214381");
      return new ICmpInst(ICmpInst::ICMP_UGT, X, ConstantInt::get(Ty, *D - 1));
    }
    if (Pred == ICmpInst::ICMP_ULT && !C.isZero() && C.ule(*D)) {
      metaphir_eval::reportAnchor(&Cmp, "pr214381");
      return new ICmpInst(ICmpInst::ICMP_ULT, X, ConstantInt::get(Ty, *D));
    }
  }
  ```

- **Metrics**: |G|=17, |P|=16, TP=14, FP=2, FN=3 (Anchor F1: **84.85%**, Function F1: **83.87%**)

All 5 divergences are in `pr214381__icmp-floor-align.ll`. They have three causes:

| Cause | Kind | Functions |
|:---|:---|:---|
| A. Power-of-two divisor: `urem` becomes `and` before the compare is visited | FP | `floor_ugt_16`, `floor_ult_16` |
| B. `uge`/`ule` predicate, canonicalized to `ugt`/`ult` before the fold | FN | `floor_uge_48`, `floor_ule_47_48` |
| C. `mul (udiv X, D), D` is rewritten into `sub X, (urem X, D)` (plus a `uge` predicate) | FN | `floor_mul_udiv_uge_48` |

#### False Positive Example (Cause A)
- **Target File & Function**: `pr214381__icmp-floor-align.ll` @ `@floor_ugt_16` (`@floor_ult_16` behaves the same way with `ult 16`)
- **Target LLVM IR**:
  ```llvm
  %r = urem i32 %x, 16
  %s = sub i32 %x, %r
  %c = icmp ugt i32 %s, 15
  ret i1 %c
  ```
- **Step-by-Step Explanation**:
  1. InstCombine visits operands before users. `visitURem` turns `urem %x, 16` into `and %x, 15` because the divisor is a power of two (`InstCombineMulDivRem.cpp:2573-2580`).
  2. `visitSub` then rewrites `sub %x, (and %x, 15)` into `and %x, -16` using `(X - (X & Y)) --> (X & ~Y)` (`InstCombineAddSub.cpp:2861-2865`).
  3. When `%c` is visited, its operand is no longer `sub X, (urem X, D)`, so the `pr214381` site never sees its shape. A different compare fold turns `icmp ugt (and %x, -16), 15` into the same result, `icmp ugt i32 %x, 15`, without reporting the anchor (checked on the intermediate IR).

#### False Negative Example (Cause B)
- **Target File & Function**: `pr214381__icmp-floor-align.ll` @ `@floor_uge_48` (`@floor_ule_47_48` is the `ule 47` → `ult 48` counterpart)
- **Target LLVM IR**:
  ```llvm
  %r = urem i64 %x, 48
  %s = sub i64 %x, %r
  %c = icmp uge i64 %s, 48
  ret i1 %c
  ```
- **Step-by-Step Explanation**:
  1. `visitICmpInst` calls `canonicalizeCmpWithConstant` (`InstCombineCompares.cpp:7949`, defined at `:7390`) before `foldICmpInstWithConstant` (`:8042`), so `icmp uge %s, 48` becomes `icmp ugt %s, 47`. The new compare keeps the name `%c`.
  2. When the new compare is revisited, `foldICmpSubConstant` sees `ugt` with `C = 47 < D = 48` and fires on `%c`, producing `icmp ugt i64 %x, 47`.
  3. The pattern only allows `ugt`/`ult`, so it rejects the input predicate `uge`.

#### False Negative Example (Cause C)
- **Target File & Function**: `pr214381__icmp-floor-align.ll` @ `@floor_mul_udiv_uge_48`
- **Target LLVM IR**:
  ```llvm
  %d = udiv i32 %x, 48
  %m = mul nuw i32 %d, 48
  %c = icmp uge i32 %m, 48
  ret i1 %c
  ```
- **Step-by-Step Explanation**:
  1. `visitMul` rewrites `(X / Y) * Y` into `X - (X % Y)` (`InstCombineMulDivRem.cpp:462-495`; it needs a one-use, non-`exact` udiv and freezes `X`), so `%m` becomes `sub %x.fr, (urem %x.fr, 48)`.
  2. Cause B then applies: `uge 48` is canonicalized to `ugt 47`, and the anchor fires on `%c`. The output is `icmp ugt i32 %x.fr, 47`.
  3. The input has no `urem`/`sub`, so the pattern can't match.

- **Resolution**: Expected. All three causes are earlier transformations (`urem` → `and`, predicate canonicalization, `mul (udiv)` → `sub`/`urem`) that change the shape before the fold is reached; no fix.

---

### PR 204928: `sext(logic(trunc nsw x, y)) --> logic(x, sext y)`

- **Pattern File (`eval/patterns/pr204928.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %trunc = trunc nsw nuw:?_ i?big ?x to i?small
  %logic = bitwiseLogic:c:s disjoint:?_ i?small %trunc, ?y
  %sext = sext:?anch i?small %logic to i?big
  ```

- **LLVM Implementation (`InstCombineCasts.cpp:2064-2071`, anchor at line 2067)**:
  ```cpp
  if (!metaphir_eval::foldsDisabled() &&
      match(Src, m_OneUse(m_c_BitwiseLogic(
                     m_NSWTrunc(m_SpecificType(DestTy, X)), m_Value(Y))))) {
    metaphir_eval::reportAnchor(&Sext, "pr204928");
    Value *SextY = Builder.CreateSExt(Y, DestTy);
    return BinaryOperator::Create(cast<BinaryOperator>(Src)->getOpcode(), X,
                                  SextY);
  }
  ```

- **Metrics**: |G|=6949, |P|=6950, TP=6949, FP=1, FN=0 (Anchor Recall: **100.0%**, Anchor Precision: **99.99%**, Anchor F1: **99.99%**, Function F1: **100.0%**)

#### False Positive (1/1): operand reassociated before the `sext` is visited
- **Target File & Function**: `abc__mpmPre.bc` @ `@Extra_Truth6AllConfigs2`
- **Target LLVM IR**:
  ```llvm
  %6 = shl nuw i32 1, %3
  ...
  %61 = shl i32 %60, %7
  %invariant.op = or i32 %61, %6
  ...
  %63 = trunc nuw nsw i64 %indvars.iv.1 to i32
  %.reass.reass = or i32 %63, %invariant.op
  %64 = sext i32 %.reass.reass to i64
  ```
- **Step-by-Step Explanation**:
  1. On the input IR, `%64 = sext(or(trunc nsw, %invariant.op))` matches the pattern.
  2. InstCombine visits `%.reass.reass` before `%64`. In `visitOr`, `reassociateForUses` (`InstCombineAndOrXor.cpp:2171`, called at line 4612) rewrites `(%61 | %6) | %63` into `(%61 | %63) | %6`, because `%6` has other uses (`(X op Y) op Z --> (X op Z) op Y`).
  3. When `%64` is visited, its source is `or(or(%61, %63), %6)`. Neither operand is a `trunc nsw`, so `m_NSWTrunc` fails and the anchor never fires.
  4. The static pattern sees the pre-reassociation shape and reports a match.
- **Resolution**: Expected. An earlier transformation (`reassociateForUses`) changes the shape; no fix.

---

### PR 204927: `zext(logic(trunc nuw x, y)) --> logic(x, zext y)`

- **Pattern File (`eval/patterns/pr204927.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %trunc = trunc nuw nsw:?_ i?big ?x to i?small
  %logic = bitwiseLogic:c:s disjoint:?_ i?small %trunc, ?y
  %zext = zext:?anch nneg:?_ i?small %logic to i?big
  ```

- **LLVM Implementation (`InstCombineCasts.cpp:1718-1727`)**:
  ```cpp
  // [MetaphIR eval] PR 204927: zext(and/or/xor(trunc nuw x), y) ->
  // and/or/xor(zext(y), x).
  if (!metaphir_eval::foldsDisabled() &&
      match(Src, m_OneUse(m_c_BitwiseLogic(
                     m_NUWTrunc(m_SpecificType(DestTy, X)), m_Value(Y))))) {
    metaphir_eval::reportAnchor(&Zext, "pr204927");
    Value *ZextY = Builder.CreateZExt(Y, DestTy);
    return BinaryOperator::Create(cast<BinaryOperator>(Src)->getOpcode(), X,
                                  ZextY);
  }
  ```

- **Metrics**: |G|=8300, |P|=8301, TP=8300, FP=1, FN=0 (Anchor F1: **99.99%**, Function F1: **100.0%**)

#### False Positive (1/1): loop phi narrowed by `visitTrunc` before the zext is visited
- **Target File & Function**: `rust-analyzer-rs__ide_assists-698f35cb73900ae6.ide_assists.dc31bb520690ed66-cgu.14.bc` @ `@_RNvMs9_NtCshzWfHUSfYae_4core3numj15overflowing_pow`, anchor `%20` (`%11` in the same function is a TP)
- **Target LLVM IR**:
  ```llvm
  .preheader45:
    %.sroa.020.0 = phi i8 [ %20, %13 ], [ 0, %2 ]
    ...
  5:
    %9  = trunc nuw i8 %.sroa.020.0 to i1
    %10 = or i1 %8, %9
    %11 = zext i1 %10 to i8                     ; fires (TP)
    ...
  13:
    %.sroa.020.1 = phi i8 [ %11, %5 ], [ %.sroa.020.0, %.preheader45 ]
    ...
    %18 = trunc nuw i8 %.sroa.020.1 to i1
    %19 = or i1 %17, %18
    %20 = zext i1 %19 to i8                     ; FP
    br label %.preheader45
  ```
- **Step-by-Step Explanation**:
  1. `%11` is visited first and folds (anchor reported).
  2. In block `%13`, `%18 = trunc nuw i8 %.sroa.020.1 to i1` is visited before `%20`. `visitTrunc` (`InstCombineCasts.cpp:1059-1070`) calls `canEvaluateTruncated`, which recurses through phis (`case Instruction::PHI`, line 630). The i8 loop-carried phi cycle `%.sroa.020.0`/`%.sroa.020.1` has only zext/trunc/constant/logic inputs, so `EvaluateInDifferentType` rewrites the whole cycle to `i1`.
  3. That removes `%20`'s only use (it was the phi's i8 incoming value), so `%20` is erased as dead and `visitZExt` is never called on it. The output keeps `phi i1` with `%16 = or i1 %15, %.sroa.020.1` and no zext.
  4. Verified: pinning the phi with an extra external use (`call void @use(i8 %.sroa.020.1)`) blocks the narrowing, and `%20` then fires.
- **Resolution**: Expected. An earlier transformation (phi-cycle narrowing) removes the instance; no fix.

---

### PR 207564: `zext (sub 0, (trunc X)) --> and (sub 0, X), LowMask`

- **Pattern File (`eval/patterns/pr207564.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %trunc = trunc nuw:?_ nsw:?_ i?big ?x to i?small
  %sub = neg i?small %trunc
  %zext = zext:?anch nneg:?_ i?small %sub to i?big
  ```

- **LLVM Implementation (`InstCombineCasts.cpp:1697-1705`)**:
  ```cpp
  // [MetaphIR eval] PR 207564: zext(sub(0, trunc(X))) -> and(sub(0, X), mask).
  if (!metaphir_eval::foldsDisabled() &&
      match(Src, m_Sub(m_Zero(), m_Trunc(m_SpecificType(DestTy, X))))) {
    metaphir_eval::reportAnchor(&Zext, "pr207564");
    APInt Mask = APInt::getLowBitsSet(DestTy->getScalarSizeInBits(),
                                      SrcTy->getScalarSizeInBits());
    Value *Neg = Builder.CreateSub(ConstantInt::get(DestTy, 0), X);
    return BinaryOperator::CreateAnd(Neg, ConstantInt::get(DestTy, Mask));
  }
  ```

- **Metrics**: |G|=158, |P|=159, TP=158, FP=1, FN=0 (Anchor F1: **99.68%**, Function F1: **100.0%**, 38/38 functions)

#### False Positive (1/1): second user taken by the earlier `canEvaluateZExtd` path
- **Target File & Function**: `qemu__multifd-nocomp.bc` @ `@multifd_ram_unfill_packet`, anchor `%45`
- **Target LLVM IR**:
  ```llvm
  %9 = trunc i64 %5 to i32
  %10 = sub i32 0, %9
  ...
  %40 = zext i32 %10 to i64        ; in %.lr.ph   (fires, TP)
  ...
  %45 = zext i32 %10 to i64        ; in %.lr.ph95 (FP)
  ```
- **After InstCombine**:
  ```llvm
  %9  = sub i64 0, %5              ; widened copy of %10, placed at %10
  %39 = sub i64 0, %5              ; from the pr207564 fold of %40
  %40 = and i64 %39, 4294967295
  %45 = and i64 %9, 4294967295
  ```
- **Step-by-Step Explanation**:
  1. `%10` initially has two users (`%40`, `%45`). The fold at line 1698 has no one-use requirement, so it fires on `%40`.
  2. After that, `%10` has a single user, `%45`.
  3. When `%45` is visited, `visitZExt` first tries `canEvaluateZExtd` (`InstCombineCasts.cpp:1611-1612`). That path requires one-use operands, which now holds, so `EvaluateInDifferentType` widens `sub 0, trunc %5` to `sub i64 0, %5` and masks the high bits. The visitor returns before line 1698.
  4. The result is the same as the PR fold, but produced by a different, pre-existing transform, so no anchor is reported.
  5. Verified: adding one more use of `%10` (so it stays multi-use) makes `%45` fire as well.
- **Resolution**: Expected. An earlier transformation handles the instance first; no fix.

---

### PR 205383: Select of CTLZ to CTTZ

- **Pattern Files**:
  - `eval/patterns/pr205383_sub.mpir`:
    ```mpir
    %neg = neg i?bits ?x
    %and = and:c i?bits %neg, ?x
    %ctlz = call i?bits @llvm.ctlz(i?bits %and, i1 ?_)
    %sub = sub nuw:?_ nsw:?_ i?bits ?bm1:constantInt, %ctlz
    %sel = selectEqZero:?anch i?bits ?x, i?bits ?bits, i?bits %sub
    ;; ?bm1 == ?bits - 1
    ```
  - `eval/patterns/pr205383_xor.mpir`:
    ```mpir
    %neg = neg i?bits ?x
    %and = and:c i?bits %neg, ?x
    %ctlz = call i?bits @llvm.ctlz(i?bits %and, i1 ?_)
    %xor = xor:c i?bits %ctlz, ?bm1:constantInt
    %sel = selectEqZero:?anch i?bits ?x, i?bits ?bits, i?bits %xor
    ;; ?bm1 == ?bits - 1
    ;; isPowerOfTwo(?bits)
    ```

- **LLVM Implementation (`InstCombineSelect.cpp:1494-1529`, anchor at `2458-2465`)**:
  ```cpp
  static Instruction *foldSelectCtlzToCttz(ICmpInst *ICI, Value *TrueVal,
                                           Value *FalseVal,
                                           InstCombiner::BuilderTy &Builder) {
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
    ...
  }

  // in foldSelectInstWithICmp:
  if (!metaphir_eval::foldsDisabled()) {
    if (Instruction *V =
            foldSelectCtlzToCttz(ICI, TrueVal, FalseVal, Builder)) {
      metaphir_eval::reportAnchor(&SI, "pr205383");
      return V;
    }
  }
  ```

- **Metrics** (both patterns combined): |G|=5, |P|=4, TP=4, FP=0, FN=1 (Anchor F1: **88.89%**, Function F1: **88.89%**)

#### False Negative Example (the only divergence)
- **Target File & Function**: `pr205383__select-ctlz-to-cttz.ll` @ `@select_clz_to_ctz_preserve_flag`
- **Target LLVM IR**:
  ```llvm
  %sub = sub i32 0, %a
  %and = and i32 %sub, %a
  %lz = tail call i32 @llvm.ctlz.i32(i32 %and, i1 false)
  %tobool = icmp eq i32 %a, 0
  %sub1 = xor i32 %lz, 31
  %cond = select i1 %tobool, i32 %lz, i32 %sub1
  ret i32 %cond
  ```
- **Step-by-Step Explanation**:
  1. In the input IR the true arm of `%cond` is `%lz`, not the constant `32`, so `pr205383_xor.mpir` fails on the select (`selectEqZero ?x, ?bits, %xor`).
  2. Before `foldSelectInstWithICmp` runs, `visitSelectInst` calls `foldSelectValueEquivalence` (`InstCombineSelect.cpp:1687`, called at `4917`). For `%a == 0 ? f(%a) : ...`, it evaluates `f(0)` with `simplifyWithOpReplaced`: `ctlz(and(sub 0, 0), 0), false) = ctlz(0, false) = 32`, and replaces the true arm with `32`.
  3. When the select is revisited, `foldSelectCtlzToCttz` sees `select %tobool, 32, %sub1` and fires the anchor on `%cond`.
  4. Verified: with the eval folds disabled (no `METAPHIR_EVAL_ANCHOR`), InstCombine's output for this function is `%cond = select i1 %tobool, i32 32, i32 %sub1`, which confirms that step 2 happens on its own.
- **Resolution**: Expected. An earlier transformation (`foldSelectValueEquivalence`) rewrites the true arm before the fold is reached; no fix.

---

### PR 213313: `(zext X) & (sext X) --> zext X` / `(zext X) | (sext X) --> sext X`

- **Pattern File (`eval/patterns/pr213313.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  match:c andOr [] Binary (?ty ?x, ?y) {
      %ret = and ?ty ?x, ?y
  } or {
      %ret = or disjoint:?_ ?ty ?x, ?y
  }

  %zext = zext i?small ?x to i?big
  %sext = sext i?small ?x to i?big
  %root = andOr:?anch:c i?big %zext, %sext
  ```

- **LLVM Implementation (`InstructionSimplify.cpp:2204-2214` in `simplifyAndInst`, `2470-2480` in `simplifyOrInst`)**:
  ```cpp
  // [MetaphIR eval] PR 213313: zext(X) | sext(X) --> sext(X).
  if (!metaphir_eval::foldsDisabled()) {
    Value *X = nullptr;
    if (match(Op0, m_ZExt(m_Value(X))) && match(Op1, m_SExt(m_Specific(X)))) {
      metaphir_eval::reportAnchor(Q.CxtI, "pr213313_or");
      return Op1;
    }
    ...
  }
  ```
  The anchor is reported on `Q.CxtI`, the instruction whose simplification started the query. That is not necessarily the `and`/`or` whose operands are `(zext X, sext X)`.

- **Metrics**: |G|=15, |P|=10, TP=10, FP=0, FN=5 (Anchor F1: **80.00%**, Function F1: **86.96%**)

All 5 FNs have one cause: **the anchor fires inside a recursive InstSimplify query that fails, and the IR is never changed**. All five are in `abseil-cpp__raw_hash_set_test.bc` (three functions), anchored at `%.sroa.0.6.insert.insert.i.i.i` / `%.sroa.0.6.insert.insert.i.i.i.i.i.i`.

#### False Negative Example
- **Target File & Function**: `abseil-cpp__raw_hash_set_test.bc` @ `@_ZN4absl12lts_2026052618container_internal12raw_hash_setINS1_12_GLOBAL__N_111ValuePolicyINS3_12AlignedValueItLi5EEELb0ELb1EEEJEE22find_or_prepare_insertIiEESt4pairINS8_8iteratorEbERKT_`
- **Target LLVM IR** (anchor = `%.sroa.0.6.insert.insert.i.i.i.i.i.i`):
  ```llvm
  %13 = load i32, ptr %2, align 4
  %14 = sext i32 %13 to i64
  ...
  %.sroa.0.2.insert.insert.i.i.i.i.i.i = zext i32 %13 to i64
  %isneg.i.i.i.i.i.i = icmp slt i32 %13, 0
  %.sroa.0.4.insert.ext.i.i.i.i.i.i = select i1 %isneg.i.i.i.i.i.i, i64 281470681743360, i64 0
  %.sroa.0.4.insert.insert.i.i.i.i.i.i = or disjoint i64 %.sroa.0.4.insert.ext.i.i.i.i.i.i, %.sroa.0.2.insert.insert.i.i.i.i.i.i
  %.sroa.0.6.insert.shift.i.i.i.i.i.i = and i64 %14, -281474976710656
  %.sroa.0.6.insert.insert.i.i.i.i.i.i = or disjoint i64 %.sroa.0.4.insert.insert.i.i.i.i.i.i, %.sroa.0.6.insert.shift.i.i.i.i.i.i
  ```
- **Step-by-Step Explanation**:
  1. The anchored root is `or (or (select, zext X), (and (sext X), 0xFFFF000000000000))`. No single `and`/`or` in the function has the operands `(zext X, sext X)`, so the pattern correctly finds no match.
  2. `visitOr(root)` calls `simplifyOrInst(root)`, which tries reassociation (`simplifyAssociativeBinOp`) and distribution (`expandBinOp`: `A | (B & C) → (A | B) & (A | C)`). These sub-queries call `simplifyOrInst(zext X, sext X)` on operand pairs that aren't in the IR, with `Q.CxtI` still set to the root. The fold matches and reports the root. gdb backtrace: `reportAnchor ← simplifyOrInst ← expandBinOp ← simplifyOrInst ← simplifyAssociativeBinOp ← simplifyOrInst ← InstCombinerImpl::visitOr`.
  3. The other half of the expansion (`0xFFFF…0000 | zext X`) doesn't simplify, so the outer query fails and the result is thrown away. After InstCombine the root is still the same `or disjoint`. A reduced copy of this IR fires the anchor 4-5 times and leaves the function unchanged.
- **Resolution**: Accepted. These anchors are reported for simplify queries on operand pairs that are not in the IR, and nothing gets folded; the instrumentation is kept as is.

---

### PR 209322: `udiv X, (known negative Y) --> zext (X >= Y)`

- **Pattern File (`eval/patterns/pr209322.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %udiv = udiv:?anch exact:?_ i?bits ?x, ?y:knownNegative
  ```

- **LLVM Implementation (`InstCombineMulDivRem.cpp:1853-1859`)**:
  ```cpp
  Type *Ty = I.getType();
  if (!metaphir_eval::foldsDisabled() &&
      isKnownNegative(Op1, SQ.getWithInstruction(&I))) {
    metaphir_eval::reportAnchor(&I, "pr209322");
    Value *Cmp = Builder.CreateICmpUGE(Op0, Op1);
    return CastInst::CreateZExtOrBitCast(Cmp, Ty);
  }
  ```
  `visitUDiv` reaches this code only after `simplifyUDivInst` (line 1803), `commonIDivTransforms` (line 1811), the `(X lshr C1) udiv C2` fold, and the pr214541 fold.

- **Metrics**: |G|=10, |P|=12, TP=10, FP=2, FN=0 (Anchor F1: **90.91%**, Function F1: **95.24%**)

Both FPs are in `pr214541__div.ll` and come from earlier transforms in `visitUDiv` that return first.

#### False Positive 1/2: `commonIDivTransforms` shift/divisor fold
- **Target File & Function**: `pr214541__div.ll` @ `@test30`, anchor `%div`
- **Target LLVM IR**:
  ```llvm
  %mul = shl nuw i32 %a, 31
  %div = udiv i32 %mul, -2147483648
  ret i32 %div
  ```
- **Step-by-Step Explanation**:
  1. The divisor `-2147483648` (`0x80000000`) is known negative, so the pattern matches.
  2. `commonIDivTransforms` (called at line 1811) matches `(X shl nuw C1) udiv C2` with `C2` a multiple of `1 << C1` (lines 1430-1441). It rewrites `%div` to `udiv %a, 1`, which then simplifies to `%a`.
  3. `visitUDiv` returns before line 1854, so no anchor is reported.

#### False Positive 2/2: InstSimplify folds the outer udiv to 0
- **Target File & Function**: `pr214541__div.ll` @ `@test5`, anchor `%C` (`%B` is a TP)
- **Target LLVM IR**:
  ```llvm
  %B = udiv i32 %A, -16
  %C = udiv i32 %B, -4
  ret i32 %C
  ```
- **Step-by-Step Explanation**:
  1. Both `-16` and `-4` are known negative, so the pattern matches `%B` and `%C`.
  2. `%B = udiv %A, 0xFFFFFFF0` is at most 1, which is always less than `0xFFFFFFFC`. So `simplifyUDivInst` (line 1803) folds `%C` to `0` before any InstCombine fold is tried. Running plain `opt -passes=instsimplify` on the input already gives `ret i32 0`.
  3. The anchor at line 1856 is never reached for `%C`.
- **Resolution**: Expected. Earlier transformations in the same visitor handle both instances first; no fix.

---

### PR 204089: `zext/sext (trunc nuw/nsw X) --> X`

- **Pattern File (`eval/patterns/pr204089.mpir`)**:
  ```mpir
  ;; treatIntAsVec(true)
  %trunc = trunc:?anch nuw:?nuw nsw:?nsw i?big ?x to i?small
  %ext = zextOrSext:?ext i?small %trunc to i?big
  ;; ((opcode(?ext) == "zext" && ?nuw) || (opcode(?ext) == "sext" && ?nsw))
  ```

- **LLVM Implementation (`InstructionSimplify.cpp:5763-5775`)**:
  ```cpp
  if (!metaphir_eval::foldsDisabled()) {
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
  ```

- **Metrics**: |G|=4021, |P|=19, TP=3, FP=16, FN=4018 (Anchor F1: **0.15%**, Function F1: **0.48%**; functions |G|=1249, |P|=5, TP=3)

The fold lives in `simplifyCastInst`, which InstCombine calls both on real cast instructions and on *hypothetical* casts whose operand has been substituted: an incoming value of a phi (`foldOpIntoPhi`) or an arm of a select (`FoldOpIntoSelect`). The anchor reports the `trunc` operand, so a firing on a hypothetical `ext(trunc)` is attributed to a real `trunc` even though no `ext` uses it directly. The 3 TPs are all in the unit-test file `pr204089__cast.ll` (`sext_of_trunc_nsw`, `zext_of_trunc_nuw`, `zext_of_trunc_nuw_vec`). In the real-world corpus the direct `ext(trunc)` shape essentially never appears; every corpus firing goes through an operand substitution.

#### Divergence Breakdown

| Cause | Count | Evidence |
|:---|:---:|:---|
| FN: `ext(phi)` pushed through the phi by `foldOpIntoPhi`, with the anchored trunc feeding the phi directly | 3843 | static check of all 4018 FNs |
| FN: same as above, but the trunc reaches the `ext` through a chain of phis (trunc → phi → phi → … → ext) | 142 | static check; 12/12 sampled gdb backtraces are `foldOpIntoPhi` |
| FN: `ext(select)` pushed into the select arms by `FoldOpIntoSelect` | 33 | static check; 1 sampled gdb backtrace |
| FP: function is `optnone`, so InstCombine skips it | 16 | `-debug-pass-manager`: "Skipping pass InstCombinePass … due to optnone attribute" |

How the counts were obtained:
- **Static check (all 4018 FNs):** each FN was classified by how its anchored trunc reaches a flag-compatible `zext`/`sext` in the input IR: through one phi (3843) or through one select (33). None had a direct `ext` user. The remaining 142 had no one-level route.
- **Dynamic check:** gdb backtraces at `reportAnchor` were taken for a random sample of 60 FNs from 60 different files, plus 12 of the 142 unclassified FNs.
  - In the 60-FN sample, 59 went through `simplifyInstructionWithOperands ← foldOpIntoPhi ← commonCastTransforms ← visitZExt/visitSExt` (51 zext, 8 sext) and 1 went through `simplifyOperationIntoSelectOperand ← FoldOpIntoSelect ← commonCastTransforms`. The static and dynamic classifications agree on every sampled case.
  - All 12 of the unclassified FNs also went through `foldOpIntoPhi`; their IR shows multi-level phi webs, typically SROA-split Rust aggregates such as `%.sroa.N.sroa.M.0.extract.truncK`.

So roughly **99.2% of FNs (3985) are `foldOpIntoPhi` and 0.8% (33) are `FoldOpIntoSelect`**. Caveat: the anchor fires as soon as an incoming value or arm simplifies, but `foldOpIntoPhi` can still abandon the whole phi fold afterwards (e.g. "More than one non-simplified value", `InstructionCombining.cpp:2027`). Some G anchors may therefore record a successful simplify query that led to no IR change. This fraction was not measured.

#### False Negative Example 1 — `foldOpIntoPhi` (3985 FNs)
- **Target File & Function**: `abc__Glucose.bc` @ `@_ZN5Gluco4sortINS_3LitENS_16LessThan_defaultIS1_EEEEvPT_iT0_`
- **Target LLVM IR**:
  ```llvm
  44:                                               ; preds = %55, %.lr.ph
    %.034 = phi i32 [ %.tr4147, %.lr.ph ], [ %57, %55 ]
    ...
    %50 = sext i32 %.034 to i64
  ...
  55:                                               ; preds = %54
    %57 = trunc nsw i64 %indvars.iv.next56 to i32
  ```
- **Step-by-Step Explanation**:
  1. No `sext`/`zext` uses `%57` directly. The only related cast is `%50 = sext i32 %.034`, whose operand is the phi `%.034`.
  2. `visitSExt(%50)` → `commonCastTransforms` → `foldOpIntoPhi` (`InstCombineCasts.cpp:275`) tries to push the `sext` through the phi.
  3. For each incoming value, `simplifyInstructionWithPHI` calls `simplifyInstructionWithOperands(%50, {incoming}, CxtI = InBB terminator)` (`InstructionCombining.cpp:1868`). For the `%55` edge this simplifies the hypothetical `sext i32 %57 to i64` to `%indvars.iv.next56` and fires the anchor on `%57`.
  4. Here the phi fold commits: after InstCombine the phi becomes `%.034 = phi i64 [ %44, %.lr.ph ], [ %indvars.iv.next56, %55 ]`.
  5. The fold is real, but it happens through phi translation. The `ext(trunc)` shape never exists in the IR, so the static pattern cannot match it.

#### False Negative Example 2 — `FoldOpIntoSelect` (33 FNs)
- **Target File & Function**: `ffmpeg__dcaadpcm.bc` @ `@ff_dcaadpcm_do_real`
- **Target LLVM IR**:
  ```llvm
  %..i = tail call i64 @llvm.smin.i64(i64 %70, i64 %28)
  %72 = trunc nsw i64 %..i to i32
  %73 = select i1 %71, i32 %26, i32 %72
  %74 = sext i32 %73 to i64
  ```
- **Step-by-Step Explanation**:
  1. `%72` feeds a select arm. The `sext` applies to the select `%73`, not to `%72`.
  2. `visitSExt(%74)` → `commonCastTransforms` → `FoldOpIntoSelect` (`InstCombineCasts.cpp:261`) → `simplifyOperationIntoSelectOperand` (`InstructionCombining.cpp:1749`) simplifies the hypothetical `sext i32 %72 to i64` to `%..i` and fires the anchor on `%72`.
  3. As in Example 1, no `ext(trunc)` exists in the input IR.

#### False Positive Example — `optnone` functions (all 16 FPs)
- **Target File & Function**: `hdf5__H5FDonion_history.bc` @ `@H5FD__onion_history_decode` (5 FPs) and `hdf5__H5FDonion_index.bc` @ `@H5FD__onion_revision_record_decode` (11 FPs)
- **Target LLVM IR**:
  ```llvm
  store i8 1, ptr %12, align 1
  %47 = load i8, ptr %12, align 1, !range !18, !noundef !19
  %48 = trunc nuw i8 %47 to i1
  %49 = zext i1 %48 to i8
  store i8 %49, ptr %12, align 1
  ```
- **Step-by-Step Explanation**:
  1. Both functions carry the `optnone` attribute. Their bodies are unoptimized -O0-style IR, with bools round-tripped through memory as `trunc nuw i8 → i1` / `zext i1 → i8`.
  2. The pattern correctly matches the literal `zext(trunc nuw)` shape.
  3. The pass manager skips InstCombine on `optnone` functions (`-debug-pass-manager`: "Skipping pass InstCombinePass on H5FD__onion_history_decode due to optnone attribute"), so the fold never runs and no anchor is reported. The IR is unchanged after `opt`.
- **Resolution**:
  - **FNs (4018):** ignored, and the instrumentation stays as is. Every FN examined is a genuine fold firing on a hypothetical cast created by operand substitution, either through `foldOpIntoPhi` (≈3985) or `FoldOpIntoSelect` (33). Matching these would require phi/select translation in the pattern matcher, which is out of scope.
  - **FPs (16):** accepted. They all come from InstCombine skipping `optnone` functions.
