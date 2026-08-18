; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
%sum = add:?inst:c nsw:?has_nsw i?bits ?x, ?y
%cmp = icmp ?pred i?bits %sum, ?limit
br i1 %cmp, label ?yes, label ?no
; CHECK: target 0: @diamond
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?bits = 32, ?has_nsw = true, ?inst = %sum, ?limit = %limit, ?no = %no, ?pred = ult, ?x = %a, ?y = %b, ?yes = %yes}
; CHECK-NEXT:   match 1:
; CHECK-NEXT:     {?bits = 32, ?has_nsw = true, ?inst = %sum, ?limit = %limit, ?no = %no, ?pred = ult, ?x = %b, ?y = %a, ?yes = %yes}
; CHECK-NEXT: target 1: @wrong_opcode
; CHECK-NEXT:   no match

;--- match.ll
define i32 @diamond(i32 %a, i32 %b, i32 %limit) {
entry:
  %sum = add nsw i32 %a, %b
  %cmp = icmp ult i32 %sum, %limit
  br i1 %cmp, label %yes, label %no

yes:
  ret i32 %sum

no:
  ret i32 %limit
}

;--- no-match.ll
define i32 @wrong_opcode(i32 %a, i32 %b, i32 %limit) {
entry:
  %sum = sub i32 %a, %b
  %cmp = icmp ult i32 %sum, %limit
  br i1 %cmp, label %yes, label %no

yes:
  ret i32 %sum

no:
  ret i32 %limit
}
