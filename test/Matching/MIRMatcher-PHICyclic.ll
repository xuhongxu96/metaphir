; RUN: split-file %s %t
; RUN: not %metaphir-match %t/pattern.mpir %t/target.ll 2>&1 | FileCheck %s

;--- pattern.mpir
?loop:
%value = phi i32 [0, ?entry], [%value, ?loop]
; CHECK: undefined or forward local reference '%value'

;--- target.ll
define i32 @phi_target(i1 %condition) {
entry:
  br i1 %condition, label %loop, label %exit

loop:
  %value = phi i32 [0, %entry], [%value, %loop]
  br label %loop

exit:
  ret i32 0
}
