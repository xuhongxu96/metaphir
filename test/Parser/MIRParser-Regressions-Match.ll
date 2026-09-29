; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; A match branch body is validated like a top-level pattern body.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/integer-constraint.ll 2>&1 | FileCheck %s --check-prefix=INTEGER-CONSTRAINT
; RUN: not %metaphir-parse %t/trailing-instruction.ll 2>&1 | FileCheck %s --check-prefix=TRAILING-INSTRUCTION
; RUN: not %metaphir-parse %t/trailing-constraint.ll 2>&1 | FileCheck %s --check-prefix=TRAILING-CONSTRAINT
; RUN: not %metaphir-parse %t/unnamed-not-last.ll 2>&1 | FileCheck %s --check-prefix=UNNAMED-NOT-LAST
; RUN: not %metaphir-parse %t/type-and-operand-same-name.ll 2>&1 | FileCheck %s --check-prefix=SAME-NAME
; RUN: not %metaphir-parse %t/commutative-call-array.ll 2>&1 | FileCheck %s --check-prefix=COMMUTATIVE-CALL-ARRAY
; RUN: %metaphir-parse %t/or-after-match.ll | FileCheck %s --check-prefix=OR-AFTER-MATCH

;--- integer-constraint.ll
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1
  ;; 5
}
m i32 ?a
; INTEGER-CONSTRAINT: error: constraint must have a boolean result

;--- trailing-instruction.ll
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1 %b = add ?t ?x, ?x
}
m i32 ?a
; TRAILING-INSTRUCTION: error: unexpected token after instruction

;--- trailing-constraint.ll
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1
  ;; true )
}
m i32 ?a
; TRAILING-CONSTRAINT: error: unexpected token after constraint

;--- unnamed-not-last.ll
match m [] Unary (?t ?x) {
  xor ?t ?x, -1
  %ret = add ?t ?x, ?x
}
m i32 ?a
; UNNAMED-NOT-LAST: error: only the final instruction may omit a result assignment

;--- type-and-operand-same-name.ll
match m [] Binary (?t ?t, ?y) {
  %ret = add ?t ?t, ?y
}
add i32 ?a, ?b
; SAME-NAME: error: duplicate parameter '?t' in match declaration

;--- or-after-match.ll
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1
}
or i32 ?a, ?b
; OR-AFTER-MATCH: or i32 ?a, ?b

; ':c' swaps exactly two call arguments; an argument array could hold any
; number.
;--- commutative-call-array.ll
%r = call:c i32 ?f(i32 ?a, ...?tys ?rest)
; COMMUTATIVE-CALL-ARRAY: error: metaflag ':c' requires a call with exactly two arguments
