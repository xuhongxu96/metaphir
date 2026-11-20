; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=6 constraints=1

%sum = add:c nsw:?has_nsw i?bits ?x, ?y:allOnes
; CHECK: %sum = add:c nsw:?has_nsw i?bits ?x, ?y:allOnes

%cmp = icmp ?pred i?bits %sum, ?z
; CHECK: %cmp = icmp ?pred i?bits %sum, ?z

%trunc = trunc <?n x i?big> ?x to <?n x i?small>
; CHECK: %trunc = trunc <?n x i?big> ?x to <?n x i?small>

%sub = sub <?n x i?small> 0, %trunc
; CHECK: %sub = sub <?n x i?small> 0, %trunc

%zext = zext:?anch <?n x i?small> %sub to <?n x i?big>
; CHECK: %zext = zext:?anch <?n x i?small> %sub to <?n x i?big>
; CHECK-NEXT: br i1 %cmp, label ?yes, label ?no

br i1 %cmp, label %yes, label ?no

;; ?has_nsw == true || ult(?bits, 64)
; CHECK: constraint (|| (== ?has_nsw true) (ult ?bits 64))
; CHECK-DAG: meta ?has_nsw type=i1
; CHECK-DAG: meta ?bits type=Nat
; CHECK-DAG: meta ?x type=Value
; CHECK-DAG: meta ?y type=Value
; CHECK-DAG: meta ?pred type=CmpPredicate
; CHECK-DAG: meta ?z type=Value
; CHECK-DAG: meta ?n type=Nat
; CHECK-DAG: meta ?big type=Nat
; CHECK-DAG: meta ?small type=Nat
; CHECK-DAG: meta ?anch type=Instruction
; CHECK-DAG: meta ?yes type=BasicBlock
; CHECK-DAG: meta ?no type=BasicBlock
