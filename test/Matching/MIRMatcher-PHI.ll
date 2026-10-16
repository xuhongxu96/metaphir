; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/constraint-mismatch.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
?loop:
%value = phi:?instruction i32 [0, ?entry], [?incoming, ?loop]
;; ?incoming == ?instruction

;--- match.ll
define i32 @phi_match(i1 %condition) {
entry:
  br i1 %condition, label %loop, label %exit

loop:
  %value = phi i32 [0, %entry], [%value, %loop]
  br label %loop

exit:
  ret i32 0
}
; CHECK: target 0: @phi_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?entry = %entry, ?incoming = %value, ?instruction = %value, ?loop = %loop}

;--- constraint-mismatch.ll
define i32 @phi_constraint_mismatch(i1 %condition) {
entry:
  %other = add i32 0, 0
  br i1 %condition, label %loop, label %exit

loop:
  %value = phi i32 [0, %entry], [%other, %loop]
  br label %loop

exit:
  ret i32 0
}
; CHECK-NEXT: target 1: @phi_constraint_mismatch
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (== ?incoming ?instruction)

;--- no-match.ll
define i32 @phi_no_match(i1 %condition) {
entry:
  br i1 %condition, label %loop, label %exit

loop:
  %value = phi i32 [1, %entry], [%value, %loop]
  br label %loop

exit:
  ret i32 0
}
; CHECK-NEXT: target 2: @phi_no_match
; CHECK-NEXT:   no match
; CHECK-NOT: {{.}}
