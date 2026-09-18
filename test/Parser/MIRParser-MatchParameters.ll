; The parameter list of a 'match' declaration follows the declared archetype,
; so a wrong shape is reported at the declaration instead of silently producing
; a matcher that never expands.

; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/missing-comma.ll 2>&1 | FileCheck %s --check-prefix=COMMA
; RUN: not %metaphir-parse %t/missing-to.ll 2>&1 | FileCheck %s --check-prefix=TO
; RUN: not %metaphir-parse %t/short-binary.ll 2>&1 | FileCheck %s --check-prefix=SHORT
; RUN: not %metaphir-parse %t/type-for-operand.ll 2>&1 | FileCheck %s --check-prefix=OPERAND

;--- missing-comma.ll
match bad [] Binary (?ty ?x ?y) {
; COMMA: expected ',' between operand parameters (got MetaVar)

	%ret = add ?ty ?x, ?y
}
;--- missing-to.ll
match bad [] Cast (?t1 ?x ?t2) {
; TO: expected 'to' before the result type (got MetaVar)

	%ret = zext ?t1 ?x to ?t2
}
;--- short-binary.ll
match bad [] Binary (?ty ?x) {
; SHORT: expected ',' between operand parameters (got rparen)

	%ret = add ?ty ?x, ?x
}
;--- type-for-operand.ll
match bad [] Binary (?ty i32, ?y) {
; OPERAND: expected operand meta variable in parameter list

	%ret = add ?ty ?x, ?y
}
