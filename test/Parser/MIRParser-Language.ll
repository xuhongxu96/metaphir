; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; Definitions, constraint lexing and constraint type checking.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/redefine-stdlib-constraint.ll 2>&1 | FileCheck %s --check-prefix=REDEF-CONSTRAINT
; RUN: not %metaphir-parse %t/redefine-own-constraint.ll 2>&1 | FileCheck %s --check-prefix=REDEF-OWN
; RUN: not %metaphir-parse %t/builtin-operator-name.ll 2>&1 | FileCheck %s --check-prefix=BUILTIN-OP
; RUN: not %metaphir-parse %t/redefine-stdlib-metaflag.ll 2>&1 | FileCheck %s --check-prefix=REDEF-METAFLAG
; RUN: not %metaphir-parse %t/builtin-metaflag-name.ll 2>&1 | FileCheck %s --check-prefix=BUILTIN-METAFLAG
; RUN: not %metaphir-parse %t/redefine-matcher.ll 2>&1 | FileCheck %s --check-prefix=REDEF-MATCHER
; RUN: %metaphir-parse %t/multiline-bodies.ll | FileCheck %s --check-prefix=MULTILINE
; RUN: %metaphir-parse %t/composite-print.ll | FileCheck %s --check-prefix=COMPOSITE-PRINT
; RUN: %metaphir-parse %t/minus-after-variable.ll | FileCheck %s --check-prefix=MINUS
; RUN: not %metaphir-parse %t/hyphen-in-pattern.ll 2>&1 | FileCheck %s --check-prefix=HYPHEN
; RUN: not %metaphir-parse %t/hyphen-in-capture.ll 2>&1 | FileCheck %s --check-prefix=HYPHEN-CAPTURE
; RUN: %metaphir-parse %t/hyphen-in-local.ll | FileCheck %s --check-prefix=HYPHEN-LOCAL
; RUN: not %metaphir-parse %t/chained-comparison.ll 2>&1 | FileCheck %s --check-prefix=CHAINED
; RUN: not %metaphir-parse %t/value-constraint.ll 2>&1 | FileCheck %s --check-prefix=VALUE
; RUN: not %metaphir-parse %t/string-constraint.ll 2>&1 | FileCheck %s --check-prefix=STRING
; RUN: not %metaphir-parse %t/string-operand.ll 2>&1 | FileCheck %s --check-prefix=STRING-OPERAND
; RUN: not %metaphir-parse %t/type-operand.ll 2>&1 | FileCheck %s --check-prefix=TYPE-OPERAND
; RUN: not %metaphir-parse %t/builtin-argument-kind.ll 2>&1 | FileCheck %s --check-prefix=ARGUMENT-KIND
; RUN: not %metaphir-parse %t/user-arity.ll 2>&1 | FileCheck %s --check-prefix=USER-ARITY
; RUN: not %metaphir-parse %t/user-result.ll 2>&1 | FileCheck %s --check-prefix=USER-RESULT
; RUN: %metaphir-parse %t/coercible.ll | FileCheck %s --check-prefix=COERCIBLE

; A name is defined once; the standard library's definitions count.
;--- redefine-stdlib-constraint.ll
constraint isOdd(?v) {
  true
}
; REDEF-CONSTRAINT: redefine-stdlib-constraint.ll:1:12: error: redefinition of constraint 'isOdd'

;--- redefine-own-constraint.ll
constraint mine(?v) {
  true
}
constraint mine(?v) {
  false
}
; REDEF-OWN: redefine-own-constraint.ll:4:12: error: redefinition of constraint 'mine'

;--- builtin-operator-name.ll
constraint ult(?a, ?b) {
  true
}
; BUILTIN-OP: error: 'ult' is a built-in constraint operation and cannot be redefined

;--- redefine-stdlib-metaflag.ll
metaflag :zero(?v) {
  true
}
; REDEF-METAFLAG: error: redefinition of metaflag ':zero'

;--- builtin-metaflag-name.ll
metaflag :c(?v) {
  true
}
; BUILTIN-METAFLAG: error: ':c' is a built-in metaflag and cannot be redefined

;--- redefine-matcher.ll
match addLike [] Binary (?t ?x, ?y) {
  %ret = add ?t ?x, ?y
}
; REDEF-MATCHER: redefine-matcher.ll:1:7: error: redefinition of matcher 'addLike'

; A definition body may span lines.
;--- multiline-bodies.ll
constraint between(?v, ?lo, ?hi) {
  sge(?v, ?lo) &&
  sle(?v, ?hi)
}
metaflag :small(?v) {
  between(?v,
          0, 10)
}
add i32 ?x:small, ?y
;; between(?x, 1, 2)
; MULTILINE: add i32 ?x:small, ?y
; MULTILINE-NEXT: constraint (between ?x 1 2)

; In a constraint, '-' after a meta variable is subtraction.
;--- minus-after-variable.ll
add i?bits ?x, ?y
;; ?bits-1 == 7
; MINUS: constraint (== (- ?bits 1) 7)

;--- hyphen-in-pattern.ll
; A meta variable name never contains '-'.
add i32 ?a-b, ?c
; HYPHEN: hyphen-in-pattern.ll:2:11: error: unexpected character '-'

;--- hyphen-in-capture.ll
add:?r-1 i32 ?a, ?c
; HYPHEN-CAPTURE: hyphen-in-capture.ll:1:7: error: expected type

;--- hyphen-in-local.ll
; LLVM local names may contain '-'.
%a-b = add i32 ?a, ?c
%d = sub i32 %a-b, ?a
; HYPHEN-LOCAL: %d = sub i32 %a-b, ?a

;--- chained-comparison.ll
add i?bits ?x, ?y
;; ?bits == 8 == true
; CHAINED: chained-comparison.ll:2:15: error: comparisons cannot be chained; add parentheses

;--- value-constraint.ll
add i32 ?x, ?y
;; ?x
; VALUE: value-constraint.ll:2:4: error: constraint must have a boolean result

;--- string-constraint.ll
add i32 ?x, ?y
;; "s"
; STRING: error: constraint must have a boolean result

;--- string-operand.ll
add i32 ?x, ?y
;; "s" && true
; STRING-OPERAND: string-operand.ll:2:4: error: operand of '&&' must be a boolean

;--- type-operand.ll
add ?t ?x, ?y
;; ?t + 1 == 2
; TYPE-OPERAND: type-operand.ll:2:4: error: operand of '+' must be an integer

;--- builtin-argument-kind.ll
add i32 ?x, ?y
;; isa("Instruction", ?x)
; ARGUMENT-KIND: builtin-argument-kind.ll:2:8: error: argument 1 of 'isa' must be a value

;--- user-arity.ll
add i32 ?x, ?y
;; isOdd(?x, ?y)
; USER-ARITY: user-arity.ll:2:4: error: constraint operation 'isOdd' expects 1 argument, got 2

; The result of a call to a definition is its body's.
;--- user-result.ll
constraint seven(?v) {
  7
}
add i32 ?x, ?y
;; seven(?x)
; USER-RESULT: user-result.ll:5:4: error: constraint must have a boolean result

; Booleans and integers convert into each other, and a constant value into
; an integer.
;--- coercible.ll
add i?bits ?x, ?y
;; ?bits && ult(?x, true)
; COERCIBLE: constraint (&& ?bits (ult ?x true))

; A composite matcher's use prints as its archetype's instructions do: a cast
; with its destination type.
;--- composite-print.ll
%trunc = trunc i?big ?x to i?small
%ext = zextOrSext:?anch i?small %trunc to i?big
%sum = addLike nsw i?big %ext, 1
; COMPOSITE-PRINT:      %ext = zextOrSext:?anch i?small %trunc to i?big
; COMPOSITE-PRINT-NEXT: %sum = addLike nsw i?big %ext, 1
