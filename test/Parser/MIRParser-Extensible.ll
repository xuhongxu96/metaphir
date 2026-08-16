; RUN: %metaphir-parse %s | FileCheck %s

add i?bits ?x:future_pred:not(:poison), ?y
; CHECK: pattern instructions=1 constraints=1
; CHECK-NEXT: add i?bits ?x:future_pred:not(:poison), ?y

;; custom_predicate(?x) && (slt(?bits, 32) || ?bits+1 == 64)
; CHECK-NEXT: constraint (&& (custom_predicate ?x) (|| (slt ?bits 32) (== (+ ?bits 1) 64)))
; CHECK-NEXT: meta ?bits type=Nat
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
