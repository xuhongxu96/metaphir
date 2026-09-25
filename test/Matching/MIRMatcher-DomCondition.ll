; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s

; Value-tracking constraints see facts implied by a dominating conditional
; branch (DomConditionCache), like InstCombine does.

;--- pattern.mpir
%udiv1 = udiv:s i?bits ?x, ?y
%udiv2 = udiv:?anch i?bits %udiv1, ?z
;; noOverflow("umul", ?y, ?z)

;--- input.ll
define i64 @guarded(i64 %x, i32 %a, i32 %b) {
entry:
  %pos = icmp sgt i32 %a, 0
  br i1 %pos, label %then, label %exit
then:
  %y = sext i32 %a to i64
  %z = zext i32 %b to i64
  %d1 = udiv i64 %x, %y
  %d2 = udiv i64 %d1, %z
  ret i64 %d2
exit:
  ret i64 0
}
; CHECK: target 0: @guarded
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %d2, ?bits = 64, ?x = %x, ?y = %y, ?z = %z}

define i64 @unguarded(i64 %x, i32 %a, i32 %b) {
  %y = sext i32 %a to i64
  %z = zext i32 %b to i64
  %d1 = udiv i64 %x, %y
  %d2 = udiv i64 %d1, %z
  ret i64 %d2
}
; CHECK-NEXT: target 1: @unguarded
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (noOverflow "umul" ?y ?z)
