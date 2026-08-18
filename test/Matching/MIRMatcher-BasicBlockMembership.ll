; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/different-blocks.ll | FileCheck %s

;--- pattern.mpir
?block:
%sum = add i32 ?x, ?x
%difference = sub i32 ?x, ?x

;--- match.ll
define i32 @same_block(i32 %input) {
body:
  %doubled = add i32 %input, %input
  %zero = sub i32 %input, %input
  ret i32 %zero
}
; CHECK: target 0: @same_block
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?block = %body, ?x = %input}

;--- different-blocks.ll
define i32 @different_blocks(i32 %input) {
producer:
  %doubled = add i32 %input, %input
  br label %consumer

consumer:
  %zero = sub i32 %input, %input
  ret i32 %zero
}
; CHECK-NEXT: target 1: @different_blocks
; CHECK-NEXT:   no match
