; A metaflag name is always written directly after ':', which keeps it
; unambiguous, so it may be spelled like a keyword. The built-in ':or' and the
; standard library's ':poison' rely on this: both share their spelling with
; keywords.

; RUN: split-file %s %t
; RUN: %metaphir-parse %t/keyword-names.ll | FileCheck %s --check-prefix=OK
; RUN: not %metaphir-parse %t/no-colon.ll 2>&1 | FileCheck %s --check-prefix=NO-COLON

;--- keyword-names.ll
constraint iszeroish(?v) {
	isZero(?v)
}
; ':add' shares a spelling with an opcode keyword, ':i32' with a type keyword.
metaflag :add(?v) {
	iszeroish(?v)
}
metaflag :i32(?v) {
	iszeroish(?v)
}

%r = add i32 ?x, ?c:add
; OK: pattern instructions=1 constraints=0
; OK-NEXT: %r = add i32 ?x, ?c:add
; OK-NEXT: meta ?x type=Value
; OK-NEXT: meta ?c type=Value
; OK-NOT: {{.}}

;--- no-colon.ll
metaflag even(?v) {
; NO-COLON: expected ':' followed by a metaflag name

	isZero(?v)
}
