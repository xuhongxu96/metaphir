; Each '?_' is a variable of its own, of whatever sort its place needs.
; RUN: split-file %s %t
; RUN: %metaphir-parse %t/separate.mpir | FileCheck %s --check-prefix=SEPARATE
; RUN: not %metaphir-parse %t/constraint.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT

;--- separate.mpir
%c = icmp ?_ i32 ?_, ?_
; SEPARATE: pattern instructions=2 constraints=0
; SEPARATE-NEXT: %c = icmp ?_$0 i32 ?_$1, ?_$2

%r = add i32 ?_, ?x
; SEPARATE-NEXT: %r = add i32 ?_$3, ?x
; SEPARATE-NEXT: meta ?_$0 type=CmpPredicate
; SEPARATE-NEXT: meta ?_$1 type=Value
; SEPARATE-NEXT: meta ?_$2 type=Value
; SEPARATE-NEXT: meta ?_$3 type=Value
; SEPARATE-NEXT: meta ?x type=Value
; SEPARATE-NOT: {{.}}

;--- constraint.mpir
%r = add i32 ?_, ?x
;; isZero(?_)
; CONSTRAINT: a constraint cannot refer to '?_', which stands for a different value each time; name the variable
