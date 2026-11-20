; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/i32.ll %t/i64.ll | FileCheck %s

;--- pattern.mpir
%call = call:?instruction ?return_type ?callee(i?bits ?argument)
;; ?bits == 64

;--- i32.ll
declare i32 @callee32(i32)

define i32 @constraint_i32(i32 %argument) {
entry:
  %call = call i32 @callee32(i32 %argument)
  ret i32 %call
}
; CHECK: target 0: @constraint_i32
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (== ?bits 64)

;--- i64.ll
declare i64 @callee64(i64)

define i64 @constraint_i64(i64 %argument) {
entry:
  %call = call i64 @callee64(i64 %argument)
  ret i64 %call
}
; CHECK-NEXT: target 1: @constraint_i64
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?argument = %argument, ?bits = 64, ?callee = @callee64, ?instruction = %call, ?return_type = i64}
; CHECK-NOT: {{.}}
