; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; --explain says why each function has no match: the structural match each
; rejecting constraint rejected, or what the function lacks for one.
; RUN: split-file %s %t
; RUN: %metaphir-match --explain %t/constraint.mpir %t/funcs.ll | FileCheck %s --check-prefix=CONSTRAINT
; RUN: %metaphir-match --explain %t/structure.mpir %t/funcs.ll | FileCheck %s --check-prefix=STRUCTURE
; RUN: %metaphir-match --explain %t/global.mpir %t/funcs.ll | FileCheck %s --check-prefix=GLOBAL
; RUN: not %metaphir-match --explain --matches-only %t/constraint.mpir %t/funcs.ll 2>&1 | FileCheck %s --check-prefix=MATCHES-ONLY

;--- funcs.ll
define i32 @inc(i32 %a) {
  %r = add i32 %a, 1
  ret i32 %r
}
define i32 @add2(i32 %a) {
  %r = add i32 %a, 2
  ret i32 %r
}
define i32 @apart(i32 %a, i32 %b) {
  %r = add i32 %a, 1
  %s = mul i32 %b, 3
  %t = xor i32 %r, %s
  ret i32 %t
}
define i8 @narrow(i8 %a) {
  %r = add i8 %a, 1
  ret i8 %r
}
define i32 @pop(i32 %a) {
  %r = call i32 @llvm.ctpop.i32(i32 %a)
  ret i32 %r
}
declare i32 @llvm.ctpop.i32(i32)

;--- constraint.mpir
%r = add i32 ?x, ?c
;; ?c == 1
; CONSTRAINT:      target 1: @add2
; CONSTRAINT-NEXT:   no match
; CONSTRAINT-NEXT:   constraint not satisfied: (== ?c 1)
; CONSTRAINT-NEXT:     rejected: {?c = 2, ?x = %a}	{%r@1 = #0}
; CONSTRAINT:      target 3: @narrow
; CONSTRAINT-NEXT:   no match
; CONSTRAINT-NEXT:   no structural match: no `add` in it has an i32 result
; CONSTRAINT-NEXT: target 4: @pop
; CONSTRAINT-NEXT:   no match
; CONSTRAINT-NEXT:   no structural match: it has no `add`

;--- structure.mpir
%r = add i32 ?x, ?c
%s = mul i32 %r, 3
; STRUCTURE:      target 0: @inc
; STRUCTURE-NEXT:   no match
; STRUCTURE-NEXT:   no structural match: it has no `mul`
; STRUCTURE:      target 2: @apart
; STRUCTURE-NEXT:   no match
; STRUCTURE-NEXT:   no structural match: no `mul` in it has an `add` operand

;--- global.mpir
%r = call i32 @llvm.cttz.i32(i32 ?x, i1 ?b)
; GLOBAL:      target 4: @pop
; GLOBAL-NEXT:   no match
; GLOBAL-NEXT:   no structural match: it uses no `@llvm.cttz.i32`

; MATCHES-ONLY: error: --explain is not for --matches-only
