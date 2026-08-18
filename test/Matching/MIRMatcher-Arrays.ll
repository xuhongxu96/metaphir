; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
%left = call i32 @left(i32 ?prefix, ...?types ?values)
call i32 @right(i32 ?prefix, ...?types ?values)
; CHECK: target 0: @array_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?prefix = %x, ?types = [i8, ptr], ?values = [%y, %p]}
; CHECK-NEXT: target 1: @array_no_match
; CHECK-NEXT:   no match

;--- match.ll
declare i32 @left(i32, i8, ptr)
declare i32 @right(i32, i8, ptr)

define i32 @array_match(i32 %x, i8 %y, ptr %p) {
  %left = call i32 @left(i32 %x, i8 %y, ptr %p)
  %right = call i32 @right(i32 %x, i8 %y, ptr %p)
  ret i32 %right
}

;--- no-match.ll
declare i32 @left(i32, i8, ptr)
declare i32 @right(i32, i8, ptr)

define i32 @array_no_match(i32 %x, i8 %y, ptr %p, i8 %z) {
  %left = call i32 @left(i32 %x, i8 %y, ptr %p)
  %right = call i32 @right(i32 %x, i8 %z, ptr %p)
  ret i32 %right
}
