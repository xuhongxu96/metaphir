; RUN: split-file %s %t
; RUN: %metaphir-parse %t/conflict.ll 2>&1 | FileCheck %s --check-prefix=CONFLICT
; RUN: %metaphir-parse %t/fine.ll 2>&1 | FileCheck %s --check-prefix=FINE --implicit-check-not=warning:

; A meta variable '?name' and a local instruction '%name' sharing a name is
; almost always a mistake: an operand written '?shr' is disconnected from the
; instruction '%shr', so the pattern over-matches. The parser warns (without
; failing) when the two collide.

;--- conflict.ll
%shr = shr exact i?bits ?x, ?y
; CONFLICT: warning: meta variable '?shr' shares a name with local variable '%shr'
; CONFLICT: pattern instructions=2 constraints=1
; CONFLICT-NEXT: %shr = shr exact i?bits ?x, ?y

%trunc = trunc:?anch nuw:?nuw nsw:?nsw i?bits ?shr to i1
; CONFLICT-NEXT: %trunc = trunc:?anch nuw:?nuw nsw:?nsw i?bits ?shr to i1

;; (?nuw || ?nsw)
; CONFLICT-NEXT: constraint (|| ?nuw ?nsw)
; CONFLICT-NEXT: meta ?bits type=Nat
; CONFLICT-NEXT: meta ?x type=Value
; CONFLICT-NEXT: meta ?y type=Value
; CONFLICT-NEXT: meta ?anch type=Instruction
; CONFLICT-NEXT: meta ?nuw type=i1
; CONFLICT-NEXT: meta ?nsw type=i1
; CONFLICT-NEXT: meta ?shr type=Value

; Legitimate self/flag captures that share a name must NOT warn.
;--- fine.ll
%cmp = icmp:?cmp eq i32 ?a, ?b
; FINE: pattern instructions=2 constraints=0
; FINE-NEXT: %cmp = icmp:?cmp eq i32 ?a, ?b

%disjoint = or disjoint:?disjoint i32 1, 2
; FINE-NEXT: %disjoint = or disjoint:?disjoint i32 1, 2
; FINE-NEXT: meta ?cmp type=Instruction
; FINE-NEXT: meta ?a type=Value
; FINE-NEXT: meta ?b type=Value
; FINE-NEXT: meta ?disjoint type=i1
