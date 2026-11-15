; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; The tools run the same passes, in order, on what they parse: a pattern
; with a matcher, a choice and a constraint the index can look up finds
; its match with and without the index.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/corpus | FileCheck %s
; RUN: %metaphir-index build %t/corpus -o %t/index.mpidx
; RUN: %metaphir-match --matches-only --index %t/index.mpidx %t/pattern.mpir %t/corpus | FileCheck %s
; RUN: %metaphir-match --matches-only --index %t/index.mpidx --no-factor --no-structuralize %t/pattern.mpir %t/corpus | FileCheck %s

; CHECK: @f{{.*}}{?x = %a, ?y = %b}
; CHECK-NOT: @g

;--- pattern.mpir
%s = addLike:c i32 ?x, ?y
%m = mul:o i32 %s, 3
;; opcode(?y) == "shl" || opcode(?y) == "lshr"

;--- corpus/ir.ll
define i32 @f(i32 %a, i32 %v) {
  %b = shl i32 %v, 1
  %s = add i32 %b, %a
  %m = mul i32 %s, 3
  ret i32 %m
}
define i32 @g(i32 %a, i32 %b) {
  %s = add i32 %b, %a
  ret i32 %s
}
