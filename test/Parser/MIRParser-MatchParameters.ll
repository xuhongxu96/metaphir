; The parameter list of a 'match' declaration follows the declared archetype,
; so a wrong shape is reported at the declaration instead of silently producing
; a matcher that never expands.

; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/missing-comma.ll 2>&1 | FileCheck %s --check-prefix=COMMA
; RUN: not %metaphir-parse %t/missing-to.ll 2>&1 | FileCheck %s --check-prefix=TO
; RUN: not %metaphir-parse %t/short-binary.ll 2>&1 | FileCheck %s --check-prefix=SHORT
; RUN: not %metaphir-parse %t/type-for-operand.ll 2>&1 | FileCheck %s --check-prefix=OPERAND
; RUN: not %metaphir-parse %t/unary-two.ll 2>&1 | FileCheck %s --check-prefix=UNARY
; RUN: not %metaphir-parse %t/nary-empty.ll 2>&1 | FileCheck %s --check-prefix=EMPTY
; RUN: not %metaphir-parse %t/nary-few.ll 2>&1 | FileCheck %s --check-prefix=FEW
; RUN: not %metaphir-parse %t/nary-many.ll 2>&1 | FileCheck %s --check-prefix=MANY
; RUN: not %metaphir-parse %t/builtin-many.ll 2>&1 | FileCheck %s --check-prefix=BUILTIN

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

; 'Unary' is a Nary matcher that must declare exactly one operand.
;--- unary-two.ll
match bad [] Unary (?ty ?x, ?ty ?y) {
; UNARY: Unary matcher takes exactly one operand parameter

	%ret = add ?ty ?x, ?y
}
;--- nary-empty.ll
match bad [] Nary () {
; EMPTY: Nary matcher needs at least one operand parameter

	%ret = freeze i32 0
}

; A Nary matcher's arity is the length of its parameter list, and every use
; must spell exactly that many typed operands.
;--- nary-few.ll
match pick [] Nary (i1 ?c, ?ty ?t, ?ty ?f) {
	%ret = select i1 ?c, ?ty ?t, ?ty ?f
}
%r = pick i1 ?cond, i32 ?a
; FEW: expected ',' between operands (got Newline)

;--- nary-many.ll
match pick [] Nary (i1 ?c, ?ty ?t, ?ty ?f) {
	%ret = select i1 ?c, ?ty ?t, ?ty ?f
}
%r = pick i1 ?cond, i32 ?a, i32 ?b, i32 ?d
; MANY: 'pick' takes 3 operands

;--- builtin-many.ll
%r = select i1 ?c, i32 ?a, i32 ?b, i32 ?d
; BUILTIN: 'select' takes 3 operands
