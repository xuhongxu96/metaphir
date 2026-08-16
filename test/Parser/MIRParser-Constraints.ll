; RUN: %metaphir-parse %s | FileCheck %s

%sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allones, :not(:poison))
; CHECK: pattern instructions=1 constraints=3
; CHECK-NEXT: %sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allones,:not(:poison))

;; ?wrapped == true
; CHECK-NEXT: constraint (== ?wrapped true)

;; ?bits + 2 * 3 == 7 && !false || sdiv(?bits, -2) != 0
; CHECK-NEXT: constraint (|| (&& (== (+ ?bits (* 2 3)) 7) (! false)) (!= (sdiv ?bits (- 2)) 0))

;; custom_predicate(?bits, urem(?bits, 4))
; CHECK-NEXT: constraint (custom_predicate ?bits (urem ?bits 4))
; CHECK-NEXT: meta ?wrapped type=i1
; CHECK-NEXT: meta ?bits type=Nat
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
