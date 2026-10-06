; RUN: split-file %s %t
; RUN: %metaphir-match %t/immConstant.mpir %t/input.ll | FileCheck %s --check-prefix=IMM-CONSTANT
; RUN: %metaphir-match %t/undef.mpir %t/input.ll | FileCheck %s --check-prefix=UNDEF
; RUN: %metaphir-match %t/zeroOrPoison.mpir %t/input.ll | FileCheck %s --check-prefix=ZERO-OR-POISON
; RUN: %metaphir-match %t/allOnesOrPoison.mpir %t/input.ll | FileCheck %s --check-prefix=ALL-ONES-OR-POISON
; RUN: %metaphir-match %t/signMask.mpir %t/input.ll | FileCheck %s --check-prefix=SIGN-MASK
; RUN: %metaphir-match %t/maxSignedValue.mpir %t/input.ll | FileCheck %s --check-prefix=MAX-SIGNED-VALUE
; RUN: %metaphir-match %t/negatedPower2.mpir %t/input.ll | FileCheck %s --check-prefix=NEGATED-POWER2
; RUN: %metaphir-match %t/negatedPower2OrZero.mpir %t/input.ll | FileCheck %s --check-prefix=NEGATED-POWER2-OR-ZERO
; RUN: %metaphir-match %t/power2OrZero.mpir %t/input.ll | FileCheck %s --check-prefix=POWER2-OR-ZERO
; RUN: %metaphir-match %t/lowBitMaskOrZero.mpir %t/input.ll | FileCheck %s --check-prefix=LOW-BIT-MASK-OR-ZERO
; RUN: %metaphir-match %t/shiftedMask.mpir %t/input.ll | FileCheck %s --check-prefix=SHIFTED-MASK
; RUN: %metaphir-match %t/negative.mpir %t/input.ll | FileCheck %s --check-prefix=NEGATIVE
; RUN: %metaphir-match %t/nonNegative.mpir %t/input.ll | FileCheck %s --check-prefix=NON-NEGATIVE
; RUN: %metaphir-match %t/strictlyPositive.mpir %t/input.ll | FileCheck %s --check-prefix=STRICTLY-POSITIVE
; RUN: %metaphir-match %t/nonPositive.mpir %t/input.ll | FileCheck %s --check-prefix=NON-POSITIVE
; RUN: %metaphir-match %t/nonZeroInt.mpir %t/input.ll | FileCheck %s --check-prefix=NON-ZERO-INT

; Constant classes named after their PatternMatch.h matchers. A vector
; satisfies a per-element class when every lane does; poison lanes are
; skipped (undef lanes are not), as in LLVM's cst_pred_ty.

;--- immConstant.mpir
%r = call:?anch ?ty @id(?ty ?c:immConstant)

;--- undef.mpir
%r = call:?anch ?ty @id(?ty ?c:undef)

;--- zeroOrPoison.mpir
%r = call:?anch ?ty @id(?ty ?c:zeroOrPoison)

;--- allOnesOrPoison.mpir
%r = call:?anch ?ty @id(?ty ?c:allOnesOrPoison)

;--- signMask.mpir
%r = call:?anch ?ty @id(?ty ?c:signMask)

;--- maxSignedValue.mpir
%r = call:?anch ?ty @id(?ty ?c:maxSignedValue)

;--- negatedPower2.mpir
%r = call:?anch ?ty @id(?ty ?c:negatedPower2)

;--- negatedPower2OrZero.mpir
%r = call:?anch ?ty @id(?ty ?c:negatedPower2OrZero)

;--- power2OrZero.mpir
%r = call:?anch ?ty @id(?ty ?c:power2OrZero)

;--- lowBitMaskOrZero.mpir
%r = call:?anch ?ty @id(?ty ?c:lowBitMaskOrZero)

;--- shiftedMask.mpir
%r = call:?anch ?ty @id(?ty ?c:shiftedMask)

;--- negative.mpir
%r = call:?anch ?ty @id(?ty ?c:negative)

;--- nonNegative.mpir
%r = call:?anch ?ty @id(?ty ?c:nonNegative)

;--- strictlyPositive.mpir
%r = call:?anch ?ty @id(?ty ?c:strictlyPositive)

;--- nonPositive.mpir
%r = call:?anch ?ty @id(?ty ?c:nonPositive)

;--- nonZeroInt.mpir
%r = call:?anch ?ty @id(?ty ?c:nonZeroInt)

;--- input.ll
@g = global i8 0
declare void @id()

define i8 @sign_mask() {
  %r = call i8 @id(i8 -128)
  ret i8 %r
}
; IMM-CONSTANT: target 0: @sign_mask
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; UNDEF: target 0: @sign_mask
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON: target 0: @sign_mask
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON: target 0: @sign_mask
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK: target 0: @sign_mask
; SIGN-MASK-NEXT:   match 0:
; SIGN-MASK-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; MAX-SIGNED-VALUE: target 0: @sign_mask
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2: target 0: @sign_mask
; NEGATED-POWER2-NEXT:   match 0:
; NEGATED-POWER2-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; NEGATED-POWER2-OR-ZERO: target 0: @sign_mask
; NEGATED-POWER2-OR-ZERO-NEXT:   match 0:
; NEGATED-POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; POWER2-OR-ZERO: target 0: @sign_mask
; POWER2-OR-ZERO-NEXT:   match 0:
; POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; LOW-BIT-MASK-OR-ZERO: target 0: @sign_mask
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK: target 0: @sign_mask
; SHIFTED-MASK-NEXT:   match 0:
; SHIFTED-MASK-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; NEGATIVE: target 0: @sign_mask
; NEGATIVE-NEXT:   match 0:
; NEGATIVE-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; NON-NEGATIVE: target 0: @sign_mask
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE: target 0: @sign_mask
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE: target 0: @sign_mask
; NON-POSITIVE-NEXT:   match 0:
; NON-POSITIVE-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

; NON-ZERO-INT: target 0: @sign_mask
; NON-ZERO-INT-NEXT:   match 0:
; NON-ZERO-INT-NEXT:     {?anch = %r, ?c = -128, ?ty = i8}

define i8 @max_signed() {
  %r = call i8 @id(i8 127)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 1: @max_signed
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; UNDEF-NEXT: target 1: @max_signed
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 1: @max_signed
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 1: @max_signed
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 1: @max_signed
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 1: @max_signed
; MAX-SIGNED-VALUE-NEXT:   match 0:
; MAX-SIGNED-VALUE-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; NEGATED-POWER2-NEXT: target 1: @max_signed
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 1: @max_signed
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 1: @max_signed
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 1: @max_signed
; LOW-BIT-MASK-OR-ZERO-NEXT:   match 0:
; LOW-BIT-MASK-OR-ZERO-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; SHIFTED-MASK-NEXT: target 1: @max_signed
; SHIFTED-MASK-NEXT:   match 0:
; SHIFTED-MASK-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; NEGATIVE-NEXT: target 1: @max_signed
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 1: @max_signed
; NON-NEGATIVE-NEXT:   match 0:
; NON-NEGATIVE-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; STRICTLY-POSITIVE-NEXT: target 1: @max_signed
; STRICTLY-POSITIVE-NEXT:   match 0:
; STRICTLY-POSITIVE-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

; NON-POSITIVE-NEXT: target 1: @max_signed
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 1: @max_signed
; NON-ZERO-INT-NEXT:   match 0:
; NON-ZERO-INT-NEXT:     {?anch = %r, ?c = 127, ?ty = i8}

define i8 @minus_eight() {
  %r = call i8 @id(i8 -8)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 2: @minus_eight
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; UNDEF-NEXT: target 2: @minus_eight
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 2: @minus_eight
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 2: @minus_eight
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 2: @minus_eight
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 2: @minus_eight
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 2: @minus_eight
; NEGATED-POWER2-NEXT:   match 0:
; NEGATED-POWER2-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; NEGATED-POWER2-OR-ZERO-NEXT: target 2: @minus_eight
; NEGATED-POWER2-OR-ZERO-NEXT:   match 0:
; NEGATED-POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; POWER2-OR-ZERO-NEXT: target 2: @minus_eight
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 2: @minus_eight
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 2: @minus_eight
; SHIFTED-MASK-NEXT:   match 0:
; SHIFTED-MASK-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; NEGATIVE-NEXT: target 2: @minus_eight
; NEGATIVE-NEXT:   match 0:
; NEGATIVE-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; NON-NEGATIVE-NEXT: target 2: @minus_eight
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 2: @minus_eight
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 2: @minus_eight
; NON-POSITIVE-NEXT:   match 0:
; NON-POSITIVE-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

; NON-ZERO-INT-NEXT: target 2: @minus_eight
; NON-ZERO-INT-NEXT:   match 0:
; NON-ZERO-INT-NEXT:     {?anch = %r, ?c = -8, ?ty = i8}

define i8 @zero() {
  %r = call i8 @id(i8 0)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 3: @zero
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; UNDEF-NEXT: target 3: @zero
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 3: @zero
; ZERO-OR-POISON-NEXT:   match 0:
; ZERO-OR-POISON-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; ALL-ONES-OR-POISON-NEXT: target 3: @zero
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 3: @zero
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 3: @zero
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 3: @zero
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 3: @zero
; NEGATED-POWER2-OR-ZERO-NEXT:   match 0:
; NEGATED-POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; POWER2-OR-ZERO-NEXT: target 3: @zero
; POWER2-OR-ZERO-NEXT:   match 0:
; POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; LOW-BIT-MASK-OR-ZERO-NEXT: target 3: @zero
; LOW-BIT-MASK-OR-ZERO-NEXT:   match 0:
; LOW-BIT-MASK-OR-ZERO-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; SHIFTED-MASK-NEXT: target 3: @zero
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 3: @zero
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 3: @zero
; NON-NEGATIVE-NEXT:   match 0:
; NON-NEGATIVE-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; STRICTLY-POSITIVE-NEXT: target 3: @zero
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 3: @zero
; NON-POSITIVE-NEXT:   match 0:
; NON-POSITIVE-NEXT:     {?anch = %r, ?c = 0, ?ty = i8}

; NON-ZERO-INT-NEXT: target 3: @zero
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

define i8 @four() {
  %r = call i8 @id(i8 4)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 4: @four
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

; UNDEF-NEXT: target 4: @four
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 4: @four
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 4: @four
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 4: @four
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 4: @four
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 4: @four
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 4: @four
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 4: @four
; POWER2-OR-ZERO-NEXT:   match 0:
; POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

; LOW-BIT-MASK-OR-ZERO-NEXT: target 4: @four
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 4: @four
; SHIFTED-MASK-NEXT:   match 0:
; SHIFTED-MASK-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

; NEGATIVE-NEXT: target 4: @four
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 4: @four
; NON-NEGATIVE-NEXT:   match 0:
; NON-NEGATIVE-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

; STRICTLY-POSITIVE-NEXT: target 4: @four
; STRICTLY-POSITIVE-NEXT:   match 0:
; STRICTLY-POSITIVE-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

; NON-POSITIVE-NEXT: target 4: @four
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 4: @four
; NON-ZERO-INT-NEXT:   match 0:
; NON-ZERO-INT-NEXT:     {?anch = %r, ?c = 4, ?ty = i8}

define <2 x i8> @vec_zero_four() {
  %r = call <2 x i8> @id(<2 x i8> <i8 0, i8 4>)
  ret <2 x i8> %r
}
; IMM-CONSTANT-NEXT: target 5: @vec_zero_four
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = <i8 0, i8 4>, ?ty = <2 x i8>}

; UNDEF-NEXT: target 5: @vec_zero_four
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 5: @vec_zero_four
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 5: @vec_zero_four
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 5: @vec_zero_four
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 5: @vec_zero_four
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 5: @vec_zero_four
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 5: @vec_zero_four
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 5: @vec_zero_four
; POWER2-OR-ZERO-NEXT:   match 0:
; POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = <i8 0, i8 4>, ?ty = <2 x i8>}

; LOW-BIT-MASK-OR-ZERO-NEXT: target 5: @vec_zero_four
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 5: @vec_zero_four
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 5: @vec_zero_four
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 5: @vec_zero_four
; NON-NEGATIVE-NEXT:   match 0:
; NON-NEGATIVE-NEXT:     {?anch = %r, ?c = <i8 0, i8 4>, ?ty = <2 x i8>}

; STRICTLY-POSITIVE-NEXT: target 5: @vec_zero_four
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 5: @vec_zero_four
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 5: @vec_zero_four
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

define <2 x i8> @vec_minus_one_poison() {
  %r = call <2 x i8> @id(<2 x i8> <i8 -1, i8 poison>)
  ret <2 x i8> %r
}
; IMM-CONSTANT-NEXT: target 6: @vec_minus_one_poison
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; UNDEF-NEXT: target 6: @vec_minus_one_poison
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 6: @vec_minus_one_poison
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 6: @vec_minus_one_poison
; ALL-ONES-OR-POISON-NEXT:   match 0:
; ALL-ONES-OR-POISON-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; SIGN-MASK-NEXT: target 6: @vec_minus_one_poison
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 6: @vec_minus_one_poison
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 6: @vec_minus_one_poison
; NEGATED-POWER2-NEXT:   match 0:
; NEGATED-POWER2-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; NEGATED-POWER2-OR-ZERO-NEXT: target 6: @vec_minus_one_poison
; NEGATED-POWER2-OR-ZERO-NEXT:   match 0:
; NEGATED-POWER2-OR-ZERO-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; POWER2-OR-ZERO-NEXT: target 6: @vec_minus_one_poison
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 6: @vec_minus_one_poison
; LOW-BIT-MASK-OR-ZERO-NEXT:   match 0:
; LOW-BIT-MASK-OR-ZERO-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; SHIFTED-MASK-NEXT: target 6: @vec_minus_one_poison
; SHIFTED-MASK-NEXT:   match 0:
; SHIFTED-MASK-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; NEGATIVE-NEXT: target 6: @vec_minus_one_poison
; NEGATIVE-NEXT:   match 0:
; NEGATIVE-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; NON-NEGATIVE-NEXT: target 6: @vec_minus_one_poison
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 6: @vec_minus_one_poison
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 6: @vec_minus_one_poison
; NON-POSITIVE-NEXT:   match 0:
; NON-POSITIVE-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

; NON-ZERO-INT-NEXT: target 6: @vec_minus_one_poison
; NON-ZERO-INT-NEXT:   match 0:
; NON-ZERO-INT-NEXT:     {?anch = %r, ?c = <i8 -1, i8 poison>, ?ty = <2 x i8>}

define <2 x i8> @vec_minus_one_undef() {
  %r = call <2 x i8> @id(<2 x i8> <i8 -1, i8 undef>)
  ret <2 x i8> %r
}
; IMM-CONSTANT-NEXT: target 7: @vec_minus_one_undef
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = <i8 -1, i8 undef>, ?ty = <2 x i8>}

; UNDEF-NEXT: target 7: @vec_minus_one_undef
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 7: @vec_minus_one_undef
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 7: @vec_minus_one_undef
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 7: @vec_minus_one_undef
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 7: @vec_minus_one_undef
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 7: @vec_minus_one_undef
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 7: @vec_minus_one_undef
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 7: @vec_minus_one_undef
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 7: @vec_minus_one_undef
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 7: @vec_minus_one_undef
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 7: @vec_minus_one_undef
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 7: @vec_minus_one_undef
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 7: @vec_minus_one_undef
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 7: @vec_minus_one_undef
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 7: @vec_minus_one_undef
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

define i8 @undef() {
  %r = call i8 @id(i8 undef)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 8: @undef
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = undef, ?ty = i8}

; UNDEF-NEXT: target 8: @undef
; UNDEF-NEXT:   match 0:
; UNDEF-NEXT:     {?anch = %r, ?c = undef, ?ty = i8}

; ZERO-OR-POISON-NEXT: target 8: @undef
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 8: @undef
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 8: @undef
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 8: @undef
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 8: @undef
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 8: @undef
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 8: @undef
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 8: @undef
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 8: @undef
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 8: @undef
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 8: @undef
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 8: @undef
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 8: @undef
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 8: @undef
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

define i8 @poison() {
  %r = call i8 @id(i8 poison)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 9: @poison
; IMM-CONSTANT-NEXT:   match 0:
; IMM-CONSTANT-NEXT:     {?anch = %r, ?c = poison, ?ty = i8}

; UNDEF-NEXT: target 9: @poison
; UNDEF-NEXT:   match 0:
; UNDEF-NEXT:     {?anch = %r, ?c = poison, ?ty = i8}

; ZERO-OR-POISON-NEXT: target 9: @poison
; ZERO-OR-POISON-NEXT:   match 0:
; ZERO-OR-POISON-NEXT:     {?anch = %r, ?c = poison, ?ty = i8}

; ALL-ONES-OR-POISON-NEXT: target 9: @poison
; ALL-ONES-OR-POISON-NEXT:   match 0:
; ALL-ONES-OR-POISON-NEXT:     {?anch = %r, ?c = poison, ?ty = i8}

; SIGN-MASK-NEXT: target 9: @poison
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 9: @poison
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 9: @poison
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 9: @poison
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 9: @poison
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 9: @poison
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 9: @poison
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 9: @poison
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 9: @poison
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 9: @poison
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 9: @poison
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 9: @poison
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

define i8 @constant_expr() {
  %r = call i8 @id(i8 ptrtoint (ptr @g to i8))
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 10: @constant_expr
; IMM-CONSTANT-NEXT:   no match
; IMM-CONSTANT-NEXT:   constraint not satisfied: (isImmConstant ?c)

; UNDEF-NEXT: target 10: @constant_expr
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 10: @constant_expr
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 10: @constant_expr
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 10: @constant_expr
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 10: @constant_expr
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 10: @constant_expr
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 10: @constant_expr
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 10: @constant_expr
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 10: @constant_expr
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 10: @constant_expr
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 10: @constant_expr
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 10: @constant_expr
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 10: @constant_expr
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 10: @constant_expr
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 10: @constant_expr
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)

; A non-constant is in no class.
define i8 @argument(i8 %a) {
  %r = call i8 @id(i8 %a)
  ret i8 %r
}
; IMM-CONSTANT-NEXT: target 11: @argument
; IMM-CONSTANT-NEXT:   no match
; IMM-CONSTANT-NEXT:   constraint not satisfied: (isImmConstant ?c)

; UNDEF-NEXT: target 11: @argument
; UNDEF-NEXT:   no match
; UNDEF-NEXT:   constraint not satisfied: (isUndef ?c)

; ZERO-OR-POISON-NEXT: target 11: @argument
; ZERO-OR-POISON-NEXT:   no match
; ZERO-OR-POISON-NEXT:   constraint not satisfied: (isZeroOrPoison ?c)

; ALL-ONES-OR-POISON-NEXT: target 11: @argument
; ALL-ONES-OR-POISON-NEXT:   no match
; ALL-ONES-OR-POISON-NEXT:   constraint not satisfied: (isAllOnesOrPoison ?c)

; SIGN-MASK-NEXT: target 11: @argument
; SIGN-MASK-NEXT:   no match
; SIGN-MASK-NEXT:   constraint not satisfied: (isSignMask ?c)

; MAX-SIGNED-VALUE-NEXT: target 11: @argument
; MAX-SIGNED-VALUE-NEXT:   no match
; MAX-SIGNED-VALUE-NEXT:   constraint not satisfied: (isMaxSignedValue ?c)

; NEGATED-POWER2-NEXT: target 11: @argument
; NEGATED-POWER2-NEXT:   no match
; NEGATED-POWER2-NEXT:   constraint not satisfied: (isNegatedPower2 ?c)

; NEGATED-POWER2-OR-ZERO-NEXT: target 11: @argument
; NEGATED-POWER2-OR-ZERO-NEXT:   no match
; NEGATED-POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isNegatedPower2OrZero ?c)

; POWER2-OR-ZERO-NEXT: target 11: @argument
; POWER2-OR-ZERO-NEXT:   no match
; POWER2-OR-ZERO-NEXT:   constraint not satisfied: (isPower2OrZero ?c)

; LOW-BIT-MASK-OR-ZERO-NEXT: target 11: @argument
; LOW-BIT-MASK-OR-ZERO-NEXT:   no match
; LOW-BIT-MASK-OR-ZERO-NEXT:   constraint not satisfied: (isLowBitMaskOrZero ?c)

; SHIFTED-MASK-NEXT: target 11: @argument
; SHIFTED-MASK-NEXT:   no match
; SHIFTED-MASK-NEXT:   constraint not satisfied: (isShiftedMask ?c)

; NEGATIVE-NEXT: target 11: @argument
; NEGATIVE-NEXT:   no match
; NEGATIVE-NEXT:   constraint not satisfied: (isNegative ?c)

; NON-NEGATIVE-NEXT: target 11: @argument
; NON-NEGATIVE-NEXT:   no match
; NON-NEGATIVE-NEXT:   constraint not satisfied: (isNonNegative ?c)

; STRICTLY-POSITIVE-NEXT: target 11: @argument
; STRICTLY-POSITIVE-NEXT:   no match
; STRICTLY-POSITIVE-NEXT:   constraint not satisfied: (isStrictlyPositive ?c)

; NON-POSITIVE-NEXT: target 11: @argument
; NON-POSITIVE-NEXT:   no match
; NON-POSITIVE-NEXT:   constraint not satisfied: (isNonPositive ?c)

; NON-ZERO-INT-NEXT: target 11: @argument
; NON-ZERO-INT-NEXT:   no match
; NON-ZERO-INT-NEXT:   constraint not satisfied: (isNonZeroInt ?c)
