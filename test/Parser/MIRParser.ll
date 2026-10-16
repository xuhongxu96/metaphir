; RUN: %metaphir-parse %s | FileCheck %s

%sum = add:c nsw:?has_nsw i?bits ?x, ?y:allOnes
; CHECK: pattern instructions=6 constraints=1
; CHECK-NEXT: %sum = add:c nsw:?has_nsw i?bits ?x, ?y:allOnes

%cmp = icmp ?pred i?bits %sum, ?z
; CHECK-NEXT: %cmp = icmp ?pred i?bits %sum, ?z

%trunc = trunc <?n x i?big> ?x to <?n x i?small>
; CHECK-NEXT: %trunc = trunc <?n x i?big> ?x to <?n x i?small>

%sub = sub <?n x i?small> 0, %trunc
; CHECK-NEXT: %sub = sub <?n x i?small> 0, %trunc

%zext = zext:?anch <?n x i?small> %sub to <?n x i?big>
; CHECK-NEXT: %zext = zext:?anch <?n x i?small> %sub to <?n x i?big>

br i1 %cmp, label %yes, label ?no
; CHECK-NEXT: br i1 %cmp, label ?yes, label ?no

;; ?has_nsw == true || ult(?bits, 64)
; CHECK-NEXT: constraint (|| (== ?has_nsw true) (ult ?bits 64))
; CHECK-NEXT: meta ?has_nsw type=i1
; CHECK-NEXT: meta ?bits type=Nat
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
; CHECK-NEXT: meta ?pred type=CmpPredicate
; CHECK-NEXT: meta ?z type=Value
; CHECK-NEXT: meta ?n type=Nat
; CHECK-NEXT: meta ?big type=Nat
; CHECK-NEXT: meta ?small type=Nat
; CHECK-NEXT: meta ?anch type=Instruction
; CHECK-NEXT: meta ?yes type=BasicBlock
; CHECK-NEXT: meta ?no type=BasicBlock
; CHECK-NOT: {{.}}
