; Diagnostics for custom metaflag parameters and placement marks.

; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/too-few.ll 2>&1 | FileCheck %s --check-prefix=FEW
; RUN: not %metaphir-parse %t/too-many.ll 2>&1 | FileCheck %s --check-prefix=MANY
; RUN: not %metaphir-parse %t/default-is-operand.ll 2>&1 | FileCheck %s --check-prefix=DEFAULT
; RUN: not %metaphir-parse %t/instruction-only.ll 2>&1 | FileCheck %s --check-prefix=IONLY
; RUN: %metaphir-parse %t/no-capture.ll | FileCheck %s --check-prefix=NOCAP
; RUN: %metaphir-parse %t/marks.ll | FileCheck %s --check-prefix=MARKS

;--- too-few.ll
metaflag :between(?v, ?lo, ?hi) {
	sle(?lo, ?v) && sle(?v, ?hi)
}

%r = add i32 ?x, ?c:between(5)
; FEW: metaflag ':between' expects 2 arguments, got 1

;--- too-many.ll
metaflag :atleast(?v, ?lo) {
	sle(?lo, ?v)
}

%r = add i32 ?x, ?c:atleast(5, 8)
; MANY: metaflag ':atleast' expects 1 argument, got 2

; No mark means operand-only, so an instruction use is rejected.
;--- default-is-operand.ll
metaflag :onoperand(?v) {
	isZero(?v)
}

%r = add:?anch:onoperand i32 ?x, ?y
; DEFAULT: metaflag ':onoperand' is not valid in this position

; ':i' is the mirror case: instruction-only, so an operand use is rejected.
;--- instruction-only.ll
metaflag:i :oninstruction(?i) {
	opcode(?i) == "add"
}

%r = add i32 ?x, ?y:oninstruction
; IONLY: metaflag ':oninstruction' is not valid in this position

; The subject of an instruction flag is named through the instruction's capture,
; but the pattern need not write one: lowering synthesizes a hidden capture.
;--- no-capture.ll
metaflag:i :oninstruction(?i) {
	opcode(?i) == "add"
}

%r = add:oninstruction i32 ?x, ?y
; NOCAP: pattern instructions=1 constraints=0
; NOCAP-NEXT: %r = add:oninstruction i32 ?x, ?y
; NOCAP-NEXT: meta ?x type=Value
; NOCAP-NEXT: meta ?y type=Value
; NOCAP-NOT: {{.}}

; ':i:o' permits both positions.
;--- marks.ll
metaflag:i:o :anyvalue(?v) {
	isa(?v, "Value")
}

%r = add:?anch:anyvalue i32 ?x, ?y:anyvalue
; MARKS: pattern instructions=1 constraints=0
; MARKS-NEXT: %r = add:?anch:anyvalue i32 ?x, ?y:anyvalue
; MARKS-NEXT: meta ?anch type=Instruction
; MARKS-NEXT: meta ?x type=Value
; MARKS-NEXT: meta ?y type=Value
; MARKS-NOT: {{.}}
