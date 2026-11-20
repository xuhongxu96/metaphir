; RUN: split-file %s %t
; RUN: %metaphir-parse %t/let.mpir | FileCheck %s
; RUN: %metaphir-parse %t/lets.mpir | FileCheck %s --check-prefix=LETS

; The pattern's summary lists a 'let' after its constraints.
;--- let.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; let ?swapped = swappedPredicate(?pred)
;; ?swapped == "sgt"

; CHECK: pattern instructions=1 constraints=1
; CHECK: constraint (== ?swapped "sgt")
; CHECK-NEXT: let ?swapped = (swappedPredicate ?pred)
; CHECK: meta ?swapped type=CmpPredicate

; The variable has the sort of the expression, and a 'let' of a variable
; written before keeps the sort it has, met with the expression's.
;--- lets.mpir
%r = add:?anch i?bits ?x, ?y
;; let ?double = ?bits * 2
;; let ?same = ?x == ?y

; LETS: let ?double = (* ?bits 2)
; LETS-NEXT: let ?same = (== ?x ?y)
; LETS: meta ?double type=Integer
; LETS: meta ?same type=i1
