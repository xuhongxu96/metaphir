; A custom instruction matcher's name must be an identifier. Keywords are
; rejected, so a matcher can never collide with a keyword or shadow a built-in
; matcher (built-ins are recognized before composite lookup).

; RUN: split-file %s %t
; RUN: %metaphir-parse %t/ok.ll | FileCheck %s --check-prefix=OK
; RUN: not %metaphir-parse %t/flag-keyword.ll 2>&1 | FileCheck %s --check-prefix=FLAG
; RUN: not %metaphir-parse %t/type-keyword.ll 2>&1 | FileCheck %s --check-prefix=TYPE
; RUN: not %metaphir-parse %t/builtin-matcher.ll 2>&1 | FileCheck %s --check-prefix=BUILTIN
; RUN: not %metaphir-parse %t/constraint-keyword.ll 2>&1 | FileCheck %s --check-prefix=CONSTRAINT

;--- ok.ll
match addlike2 [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addlike2 i32 ?a, ?b
; OK: pattern instructions=1 constraints=0
; OK-NEXT: %r = addlike2 i32 ?a, ?b
; OK-NEXT: meta ?a type=Value
; OK-NEXT: meta ?b type=Value
; OK-NOT: {{.}}

;--- flag-keyword.ll
match nsw [] Binary (?ty ?x, ?y) {
; FLAG: expected matcher name in match declaration, which must be an identifier and not a keyword

	%ret = add ?ty ?x, ?y
}
;--- type-keyword.ll
match i32 [] Binary (?ty ?x, ?y) {
; TYPE: expected matcher name in match declaration, which must be an identifier and not a keyword

	%ret = add ?ty ?x, ?y
}
;--- builtin-matcher.ll
match add [] Binary (?ty ?x, ?y) {
; BUILTIN: expected matcher name in match declaration, which must be an identifier and not a keyword

	%ret = add ?ty ?x, ?y
}
;--- constraint-keyword.ll
constraint nsw(?v) {
; CONSTRAINT: expected constraint name, which must be an identifier and not a keyword

	isZero(?v)
}
