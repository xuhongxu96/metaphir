; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s

; A named instruction's result used as another instruction's operand must be
; the SAME value as that instruction's result. Here `trunc ... %shr to i1`
; requires the trunc's operand to be the `%shr` result. A `trunc(load)` in the
; same function as an unrelated `lshr` must NOT match -- only the trunc whose
; operand is literally the `lshr` result should.

;--- pattern.mpir
%shr = shr exact i?bits ?x, ?y
%trunc = trunc:?anch nuw:?nuw nsw:?nsw i?bits %shr to i1
;; (?nuw || ?nsw)

;--- input.ll
define i1 @good(i64 %x) {
entry:
  %s = lshr exact i64 %x, 3
  %t = trunc nuw i64 %s to i1
  ret i1 %t
}
; CHECK: target 0: @good
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %t, ?bits = 64, ?nsw = false, ?nuw = true, ?x = %x, ?y = 3}

define i1 @bad(i64 %x, ptr %p) {
entry:
  %s = lshr exact i64 %x, 3
  %l = load i64, ptr %p
  %t = trunc nuw i64 %l to i1
  ret i1 %t
}
; CHECK-NEXT: target 1: @bad
; CHECK-NEXT:   no match
; CHECK-NOT: {{.}}
