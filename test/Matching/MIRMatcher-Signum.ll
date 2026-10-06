; RUN: split-file %s %t
; RUN: %metaphir-match %t/signum.mpir %t/input.ll | FileCheck %s --check-prefix=SIGNUM

; 'signum' is m_Signum: (x >>s (BW-1)) | (-x >>u (BW-1)), the 'or' either way
; round, for scalars and vectors alike; each shift amount is a splat of BW-1
; without poison lanes (m_SpecificInt).

;--- signum.mpir
%r = signum:?anch i?bits ?x

;--- input.ll

define i32 @scalar(i32 %x) {
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; SIGNUM: target 0: @scalar
; SIGNUM-NEXT: match 0:
; SIGNUM-NEXT: {?anch = %r, ?bits = 32, ?x = %x}

define i32 @commuted_or(i32 %x) {
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %r = or i32 %rhs, %lhs
  ret i32 %r
}
; SIGNUM-NEXT: target 1: @commuted_or
; SIGNUM-NEXT: match 0:
; SIGNUM-NEXT: {?anch = %r, ?bits = 32, ?x = %x}

define i32 @nsw_neg(i32 %x) {
  %neg = sub nsw i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; SIGNUM-NEXT: target 2: @nsw_neg
; SIGNUM-NEXT: match 0:
; SIGNUM-NEXT: {?anch = %r, ?bits = 32, ?x = %x}

define i32 @wrong_shift(i32 %x) {
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 30
  %rhs = lshr i32 %neg, 30
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; SIGNUM-NEXT: target 3: @wrong_shift
; SIGNUM-NEXT: no match
; SIGNUM-NEXT: constraint not satisfied: (&& (== ?_r$_ls (- ?bits 1)) (== ?_r$_rs (- ?bits 1)))

define <2 x i32> @vector(<2 x i32> %x) {
  %neg = sub <2 x i32> zeroinitializer, %x
  %lhs = ashr <2 x i32> %x, splat (i32 31)
  %rhs = lshr <2 x i32> %neg, splat (i32 31)
  %r = or <2 x i32> %lhs, %rhs
  ret <2 x i32> %r
}
; SIGNUM-NEXT: target 4: @vector
; SIGNUM-NEXT: match 0:
; SIGNUM-NEXT: {?anch = %r, ?bits = 32, ?x = %x}

; m_SpecificInt does not allow poison lanes.
define <2 x i32> @vector_poison_shift(<2 x i32> %x) {
  %neg = sub <2 x i32> zeroinitializer, %x
  %lhs = ashr <2 x i32> %x, <i32 31, i32 poison>
  %rhs = lshr <2 x i32> %neg, splat (i32 31)
  %r = or <2 x i32> %lhs, %rhs
  ret <2 x i32> %r
}
; SIGNUM-NEXT: target 5: @vector_poison_shift
; SIGNUM-NEXT: no match
; SIGNUM-NEXT: constraint not satisfied: (isAPInt ?_r$_ls)

; m_Neg's zero may have poison lanes.
define <2 x i32> @vector_poison_zero(<2 x i32> %x) {
  %neg = sub <2 x i32> <i32 0, i32 poison>, %x
  %lhs = ashr <2 x i32> %x, splat (i32 31)
  %rhs = lshr <2 x i32> %neg, splat (i32 31)
  %r = or <2 x i32> %lhs, %rhs
  ret <2 x i32> %r
}
; SIGNUM-NEXT: target 6: @vector_poison_zero
; SIGNUM-NEXT: match 0:
; SIGNUM-NEXT: {?anch = %r, ?bits = 32, ?x = %x}
