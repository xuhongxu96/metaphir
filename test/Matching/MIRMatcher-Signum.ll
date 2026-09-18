; RUN: split-file %s %t
; RUN: %metaphir-match %t/signum.mpir %t/input.ll | FileCheck %s

;--- signum.mpir
%r = signum:?anch i?bits ?x

;--- input.ll
define i32 @signum_i32(i32 %x) {
entry:
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; CHECK: target 0: @signum_i32
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?bits = 32, ?shift = 31, ?x = %x}

define i32 @not_signum_wrong_shift(i32 %x) {
entry:
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 30
  %rhs = lshr i32 %neg, 30
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; CHECK-NEXT: target 1: @not_signum_wrong_shift
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (== ?shift (- ?bits 1))
