; Diagnostics point at the construct at fault, not at the token after it.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/boolean.ll 2>&1 | FileCheck %s --check-prefix=BOOLEAN
; RUN: not %metaphir-parse %t/subscript.ll 2>&1 | FileCheck %s --check-prefix=SUBSCRIPT
; RUN: not %metaphir-parse %t/index.ll 2>&1 | FileCheck %s --check-prefix=INDEX
; RUN: not %metaphir-parse %t/array-element.ll 2>&1 | FileCheck %s --check-prefix=ARRAY-ELEMENT
; RUN: not %metaphir-parse %t/arity.ll 2>&1 | FileCheck %s --check-prefix=ARITY
; RUN: not %metaphir-parse %t/duplicate-parameter.ll 2>&1 | FileCheck %s --check-prefix=DUPLICATE
; RUN: not %metaphir-parse %t/empty-branch.ll 2>&1 | FileCheck %s --check-prefix=EMPTY-BRANCH
; RUN: not %metaphir-parse %t/unary-arity.ll 2>&1 | FileCheck %s --check-prefix=UNARY-ARITY

;--- boolean.ll
add i?bits ?x, ?y
;; ?bits + 1
; BOOLEAN: constraint must have a boolean result

;--- subscript.ll
add i32 ?x, ?y
;; ?x[0] == ?y
; SUBSCRIPT: constraint subscript requires an array operand

;--- index.ll
call ?t ?f(...?tys ?args)
;; ?args[true] == ?f
; INDEX: constraint array index must be an integer

;--- array-element.ll
add i32 ?x, ?y
;; [1, 2][0] == 1
; ARRAY-ELEMENT: constraint array literal requires type, value, or string elements

;--- arity.ll
add i?bits ?x, ?y
;; ult(?bits)
; ARITY: constraint operation 'ult' expects 2 arguments, got 1

;--- duplicate-parameter.ll
match m [] Binary (?t ?x, ?x) {
; DUPLICATE: duplicate parameter '?x' in match declaration

  %ret = add ?t ?x, ?x
}
add i32 ?a, ?b
;--- empty-branch.ll
match m [] Unary (?t ?x) {
  ;; true
}
; EMPTY-BRANCH: match branch must contain at least one instruction

add i32 ?a, ?b
;--- unary-arity.ll
match m [] Unary (?t ?x, ?t ?y) {
; UNARY-ARITY: 'Unary' matcher takes exactly one operand parameter

  %ret = add ?t ?x, ?y
}
add i32 ?a, ?b
