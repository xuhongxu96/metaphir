; RUN: %metaphir-parse %s | FileCheck %s

%sum = add:c nsw:?has_nsw i?bits ?x, ?y:allones
; CHECK: pattern instructions=3 constraints=1
; CHECK-NEXT: %sum = add:c nsw:?has_nsw i?bits ?x, ?y:allones

%cmp = icmp ?pred i?bits %sum, ?z
; CHECK-NEXT: %cmp = icmp ?pred i?bits %sum, ?z

br i1 %cmp, label %yes, label ?no
; CHECK-NEXT: br i1 %cmp, label %yes, label ?no

;; ?has_nsw == true || ult(?bits, 64)
; CHECK-NEXT: constraint (|| (== ?has_nsw true) (ult ?bits 64))
; CHECK-NEXT: meta ?has_nsw type=i1
; CHECK-NEXT: meta ?bits type=Nat
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
; CHECK-NEXT: meta ?pred type=CmpPredicate
; CHECK-NEXT: meta ?z type=Value
; CHECK-NEXT: meta ?yes type=BasicBlock
; CHECK-NEXT: meta ?no type=BasicBlock
