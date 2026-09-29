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
; BOOLEAN: boolean.ll:2:10: error: constraint must have a boolean result

;--- subscript.ll
add i32 ?x, ?y
;; ?x[0] == ?y
; SUBSCRIPT: subscript.ll:2:6: error: constraint subscript requires an array operand

;--- index.ll
call ?t ?f(...?tys ?args)
;; ?args[true] == ?f
; INDEX: index.ll:2:10: error: constraint array index must be an integer

;--- array-element.ll
add i32 ?x, ?y
;; [1, 2][0] == 1
; ARRAY-ELEMENT: array-element.ll:2:4: error: constraint array literal requires type, value, or string elements

;--- arity.ll
add i?bits ?x, ?y
;; ult(?bits)
; ARITY: arity.ll:2:4: error: constraint operation 'ult' expects 2 arguments, got 1

;--- duplicate-parameter.ll
match m [] Binary (?t ?x, ?x) {
  %ret = add ?t ?x, ?x
}
add i32 ?a, ?b
; DUPLICATE: duplicate-parameter.ll:1:27: error: duplicate parameter '?x' in match declaration

;--- empty-branch.ll
match m [] Unary (?t ?x) {
  ;; true
}
add i32 ?a, ?b
; EMPTY-BRANCH: empty-branch.ll:3:1: error: match branch must contain at least one instruction

;--- unary-arity.ll
match m [] Unary (?t ?x, ?t ?y) {
  %ret = add ?t ?x, ?y
}
add i32 ?a, ?b
; UNARY-ARITY: unary-arity.ll:1:12: error: 'Unary' matcher takes exactly one operand parameter
