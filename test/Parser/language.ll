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
; RUN: %metaphir-parse %t/float-print.ll | FileCheck %s --check-prefix=FLOAT-PRINT
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
; REDEF-CONSTRAINT: redefinition of constraint 'isOdd'

  true
}
;--- redefine-own-constraint.ll
constraint mine(?v) {
  true
}
constraint mine(?v) {
; REDEF-OWN: redefinition of constraint 'mine'

  false
}
;--- builtin-operator-name.ll
constraint ult(?a, ?b) {
; BUILTIN-OP: 'ult' is a built-in constraint operation and cannot be redefined

  true
}
;--- redefine-stdlib-metaflag.ll
metaflag :zero(?v) {
; REDEF-METAFLAG: redefinition of metaflag ':zero'

  true
}
;--- builtin-metaflag-name.ll
metaflag :c(?v) {
; BUILTIN-METAFLAG: ':c' is a built-in metaflag and cannot be redefined

  true
}
;--- redefine-matcher.ll
match addLike [] Binary (?t ?x, ?y) {
; REDEF-MATCHER: redefinition of matcher 'addLike'

  %ret = add ?t ?x, ?y
}
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
; MULTILINE: pattern instructions=1 constraints=1
; MULTILINE-NEXT: add i32 ?x:small, ?y

;; between(?x, 1, 2)
; MULTILINE-NEXT: constraint (between ?x 1 2)
; MULTILINE-NEXT: meta ?x type=Value
; MULTILINE-NEXT: meta ?y type=Value
; MULTILINE-NOT: {{.}}

; In a constraint, '-' after a meta variable is subtraction.
;--- minus-after-variable.ll
add i?bits ?x, ?y
; MINUS: pattern instructions=1 constraints=1
; MINUS-NEXT: add i?bits ?x, ?y

;; ?bits-1 == 7
; MINUS-NEXT: constraint (== (- ?bits 1) 7)
; MINUS-NEXT: meta ?bits type=Nat
; MINUS-NEXT: meta ?x type=Value
; MINUS-NEXT: meta ?y type=Value
; MINUS-NOT: {{.}}

;--- hyphen-in-pattern.ll
; A meta variable name never contains '-'.
add i32 ?a-b, ?c
; HYPHEN: unexpected character '-'

;--- hyphen-in-capture.ll
add:?r-1 i32 ?a, ?c
; HYPHEN-CAPTURE: expected type

;--- hyphen-in-local.ll
; LLVM local names may contain '-'.
%a-b = add i32 ?a, ?c
; HYPHEN-LOCAL: pattern instructions=2 constraints=0
; HYPHEN-LOCAL-NEXT: %a-b = add i32 ?a, ?c

%d = sub i32 %a-b, ?a
; HYPHEN-LOCAL-NEXT: %d = sub i32 %a-b, ?a
; HYPHEN-LOCAL-NEXT: meta ?a type=Value
; HYPHEN-LOCAL-NEXT: meta ?c type=Value
; HYPHEN-LOCAL-NOT: {{.}}

;--- chained-comparison.ll
add i?bits ?x, ?y
;; ?bits == 8 == true
; CHAINED: comparisons cannot be chained; add parentheses

;--- value-constraint.ll
add i32 ?x, ?y
;; ?x
; VALUE: constraint must have a boolean result

;--- string-constraint.ll
add i32 ?x, ?y
;; "s"
; STRING: constraint must have a boolean result

;--- string-operand.ll
add i32 ?x, ?y
;; "s" && true
; STRING-OPERAND: operand of '&&' must be a boolean

;--- type-operand.ll
add ?t ?x, ?y
;; ?t + 1 == 2
; TYPE-OPERAND: operand of '+' must be an integer

;--- builtin-argument-kind.ll
add i32 ?x, ?y
;; isa("Instruction", ?x)
; ARGUMENT-KIND: argument 1 of 'isa' must be a value

;--- user-arity.ll
add i32 ?x, ?y
;; isOdd(?x, ?y)
; USER-ARITY: constraint operation 'isOdd' expects 1 argument, got 2

; The result of a call to a definition is its body's.
;--- user-result.ll
constraint seven(?v) {
  7
}
add i32 ?x, ?y
;; seven(?x)
; USER-RESULT: constraint must have a boolean result

; Booleans and integers convert into each other, and a constant value into
; an integer.
;--- coercible.ll
add i?bits ?x, ?y
; COERCIBLE: pattern instructions=1 constraints=1
; COERCIBLE-NEXT: add i?bits ?x, ?y

;; ?bits && ult(?x, true)
; COERCIBLE-NEXT: constraint (&& ?bits (ult ?x true))
; COERCIBLE-NEXT: meta ?bits type=Nat
; COERCIBLE-NEXT: meta ?x type=Value
; COERCIBLE-NEXT: meta ?y type=Value
; COERCIBLE-NOT: {{.}}

; A composite matcher's use prints as its archetype's instructions do: a cast
; with its destination type.
;--- composite-print.ll
%trunc = trunc i?big ?x to i?small
; COMPOSITE-PRINT: pattern instructions=3 constraints=0
; COMPOSITE-PRINT-NEXT: %trunc = trunc i?big ?x to i?small

%ext = zextOrSext:?anch i?small %trunc to i?big
; COMPOSITE-PRINT-NEXT: %ext = zextOrSext:?anch i?small %trunc to i?big

%sum = addLike nsw i?big %ext, 1
; COMPOSITE-PRINT-NEXT: %sum = addLike nsw i?big %ext, 1
; COMPOSITE-PRINT-NEXT: meta ?big type=Nat
; COMPOSITE-PRINT-NEXT: meta ?x type=Value
; COMPOSITE-PRINT-NEXT: meta ?small type=Nat
; COMPOSITE-PRINT-NEXT: meta ?anch type=Instruction
; COMPOSITE-PRINT-NOT: {{.}}

; Floating-point constants print as they are written, on one line: -0.0
; keeps its sign and an integral value its '.0'.
;--- float-print.ll
%a = fadd double ?x, -0.0
; FLOAT-PRINT: pattern instructions=2 constraints=0
; FLOAT-PRINT-NEXT: %a = fadd double ?x, -0.0

%b = fmul double %a, 2.0
; FLOAT-PRINT-NEXT: %b = fmul double %a, 2.0
; FLOAT-PRINT-NEXT: meta ?x type=Value
; FLOAT-PRINT-NOT: {{.}}
