; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/i32.ll %t/i64.ll | FileCheck %s

;--- pattern.mpir
%call = call:?instruction ?return_type ?callee(i?bits ?argument)
br i1 ?condition, label ?yes, label ?no

;--- i32.ll
declare i32 @callee32(i32)

define void @meta_i32(i32 %argument, i1 %condition) {
entry:
  %call = call i32 @callee32(i32 %argument)
  br i1 %condition, label %yes, label %no

yes:
  ret void

no:
  ret void
}
; CHECK: target 0: @meta_i32
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?argument = %argument, ?bits = 32, ?callee = @callee32, ?condition = %condition, ?instruction = %call, ?no = %no, ?return_type = i32, ?yes = %yes}

;--- i64.ll
declare i64 @callee64(i64)

define void @meta_i64(i64 %argument, i1 %condition) {
entry:
  %call = call i64 @callee64(i64 %argument)
  br i1 %condition, label %yes, label %no

yes:
  ret void

no:
  ret void
}
; CHECK-NEXT: target 1: @meta_i64
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?argument = %argument, ?bits = 64, ?callee = @callee64, ?condition = %condition, ?instruction = %call, ?no = %no, ?return_type = i64, ?yes = %yes}
; CHECK-NOT: {{.}}
