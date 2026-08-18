; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/wrong-block.ll | FileCheck %s

;--- pattern.mpir
?entry:
%sum = add i32 ?x, ?y
br label ?consumer

?consumer:
%result = freeze i32 %sum
ret i32 %result
; CHECK: target 0: @cross_block
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?consumer = %continuation, ?entry = %start, ?x = %lhs, ?y = %rhs}
; CHECK-NEXT: target 1: @wrong_block
; CHECK-NEXT:   no match

;--- match.ll
define i32 @cross_block(i32 %lhs, i32 %rhs) {
start:
  %accumulated = add i32 %lhs, %rhs
  br label %continuation

continuation:
  %frozen = freeze i32 %accumulated
  ret i32 %frozen
}

;--- wrong-block.ll
define i32 @wrong_block(i32 %lhs, i32 %rhs) {
start:
  %accumulated = add i32 %lhs, %rhs
  br label %expected

expected:
  br label %elsewhere

elsewhere:
  %frozen = freeze i32 %accumulated
  ret i32 %frozen
}
