; The metaflag and constraint vocabularies are extended by defining them, and
; the parser resolves every name against the context. A definition must precede
; its use, as it does for composite matchers.

; RUN: split-file %s %t
; RUN: %metaphir-parse %t/defined.ll | FileCheck %s --check-prefix=OK
; RUN: not %metaphir-parse %t/unknown-flag.ll 2>&1 | FileCheck %s --check-prefix=FLAG
; RUN: not %metaphir-parse %t/unknown-op.ll 2>&1 | FileCheck %s --check-prefix=OP

;--- defined.ll
constraint custom_predicate(?v) {
	isZero(?v)
}

metaflag :future_pred(?v) {
	custom_predicate(?v)
}

add i?bits ?x:future_pred:not(:poison), ?y
; OK: pattern instructions=1 constraints=1
; OK-NEXT: add i?bits ?x:future_pred:not(:poison), ?y

;; custom_predicate(?x) && (slt(?bits, 32) || ?bits+1 == 64)
; OK-NEXT: constraint (&& (custom_predicate ?x) (|| (slt ?bits 32) (== (+ ?bits 1) 64)))
; OK-NEXT: meta ?bits type=Nat
; OK-NEXT: meta ?x type=Value
; OK-NEXT: meta ?y type=Value

;--- unknown-flag.ll
add i?bits ?x:no_such_pred, ?y
; FLAG: unknown metaflag ':no_such_pred'

;--- unknown-op.ll
add i?bits ?x, ?y
;; no_such_op(?x)
; OP: unknown constraint operation 'no_such_op'
