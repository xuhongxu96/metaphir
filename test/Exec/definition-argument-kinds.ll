; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; A definition takes the arrays a pattern binds as arguments. A string
; cannot be one, and an argument that fails to evaluate fails the match: the
; constraint then rejects every match.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/arrays.mpir %t/ir.ll | FileCheck %s
; RUN: %metaphir-match --matches-only %t/string.mpir %t/ir.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty
; RUN: %metaphir-match --matches-only %t/failing.mpir %t/ir.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty

;--- arrays.mpir
constraint takesTypes(?ts) {
  true
}
constraint takesValues(?vs) {
  true
}
%c = call ?t @f(...?tys ?vals)
;; takesTypes(?tys)
;; takesValues(?vals)

;--- string.mpir
constraint takesString(?s) {
  true
}
%c = call ?t @f(...?tys ?vals)
;; takesString("abc")

;--- failing.mpir
constraint takesInt(?n) {
  true
}
%c = call ?t @f(...?tys ?vals)
;; takesInt(udiv(1, 0))

;--- ir.ll
declare i32 @f(i32, i8)
define i32 @g(i32 %a, i8 %b) {
  %c = call i32 @f(i32 %a, i8 %b)
  ret i32 %c
}

; CHECK: @g	{?t = i32, ?tys = [i32, i8], ?vals = [%a, %b]}
; NONE-NOT: {{.}}
