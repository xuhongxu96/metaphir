; RUN: split-file %s %t
; RUN: %metaphir-match %t/shared.mpir %t/input.ll | FileCheck %s --check-prefix=SHARED
; RUN: %metaphir-match %t/constrained.mpir %t/input.ll | FileCheck %s --check-prefix=CONSTRAINED
; RUN: %metaphir-match %t/literal.mpir %t/input.ll | FileCheck %s --check-prefix=LITERAL
; RUN: %metaphir-match %t/both-commuted.mpir %t/input.ll | FileCheck %s --check-prefix=BOTH

; A predicate that '?pred' binds for the operands in the pattern's order must
; agree wherever the pattern uses it: a commuted compare binds it to the
; swapped predicate of the instruction it matched swapped.

;--- shared.mpir
%c1 = icmp:?a1 ?pred i32 ?x, ?y
%c2 = icmp:?a2:c ?pred i32 ?y, ?z

;--- constrained.mpir
%c = icmp:?anch:c ?pred i32 ?x, ?y
;; ?pred == "slt"

;--- literal.mpir
%c = icmp:?anch:c sgt i32 ?x, ?y

;--- both-commuted.mpir
%c1 = icmp:?a1:c ?pred i32 ?x, ?y
%c2 = icmp:?a2:c ?pred i32 ?y, ?z

;--- input.ll
define void @in_order(i32 %a, i32 %b, i32 %c) {
  %c1 = icmp slt i32 %a, %b
  %c2 = icmp slt i32 %b, %c
  ret void
}
; SHARED: target 0: @in_order
; SHARED-NEXT:   match 0:
; SHARED-NEXT:     {?a1 = %c1, ?a2 = %c2, ?pred = slt, ?x = %a, ?y = %b, ?z = %c}

; CONSTRAINED: target 0: @in_order
; CONSTRAINED-NEXT:   match 0:
; CONSTRAINED-NEXT:     {?anch = %c1, ?pred = slt, ?x = %a, ?y = %b}
; CONSTRAINED-NEXT:   match 1:
; CONSTRAINED-NEXT:     {?anch = %c2, ?pred = slt, ?x = %b, ?y = %c}

; LITERAL: target 0: @in_order
; LITERAL-NEXT:   match 0:
; LITERAL-NEXT:     {?anch = %c1, ?x = %b, ?y = %a}
; LITERAL-NEXT:   match 1:
; LITERAL-NEXT:     {?anch = %c2, ?x = %c, ?y = %b}

; BOTH: target 0: @in_order
; BOTH-NEXT:   match 0:
; BOTH-NEXT:     {?a1 = %c1, ?a2 = %c2, ?pred = slt, ?x = %a, ?y = %b, ?z = %c}
; BOTH-NEXT:   match 1:
; BOTH-NEXT:     {?a1 = %c2, ?a2 = %c1, ?pred = sgt, ?x = %c, ?y = %b, ?z = %a}

; The second compare is 'c sgt b', which is 'b slt c': the same predicate.
define void @swapped_agrees(i32 %a, i32 %b, i32 %c) {
  %c1 = icmp slt i32 %a, %b
  %c2 = icmp sgt i32 %c, %b
  ret void
}
; SHARED-NEXT: target 1: @swapped_agrees
; SHARED-NEXT:   match 0:
; SHARED-NEXT:     {?a1 = %c1, ?a2 = %c2, ?pred = slt, ?x = %a, ?y = %b, ?z = %c}
; SHARED-NEXT:   match 1:
; SHARED-NEXT:     {?a1 = %c2, ?a2 = %c1, ?pred = sgt, ?x = %c, ?y = %b, ?z = %a}

; CONSTRAINED-NEXT: target 1: @swapped_agrees
; CONSTRAINED-NEXT:   match 0:
; CONSTRAINED-NEXT:     {?anch = %c1, ?pred = slt, ?x = %a, ?y = %b}
; CONSTRAINED-NEXT:   match 1:
; CONSTRAINED-NEXT:     {?anch = %c2, ?pred = slt, ?x = %b, ?y = %c}

; LITERAL-NEXT: target 1: @swapped_agrees
; LITERAL-NEXT:   match 0:
; LITERAL-NEXT:     {?anch = %c1, ?x = %b, ?y = %a}
; LITERAL-NEXT:   match 1:
; LITERAL-NEXT:     {?anch = %c2, ?x = %c, ?y = %b}

; BOTH-NEXT: target 1: @swapped_agrees
; BOTH-NEXT:   match 0:
; BOTH-NEXT:     {?a1 = %c1, ?a2 = %c2, ?pred = slt, ?x = %a, ?y = %b, ?z = %c}
; BOTH-NEXT:   match 1:
; BOTH-NEXT:     {?a1 = %c2, ?a2 = %c1, ?pred = sgt, ?x = %c, ?y = %b, ?z = %a}

; 'c slt b' is 'b sgt c', not 'slt': the second compare disagrees.
define void @swapped_disagrees(i32 %a, i32 %b, i32 %c) {
  %c1 = icmp slt i32 %a, %b
  %c2 = icmp slt i32 %c, %b
  ret void
}
; SHARED-NEXT: target 2: @swapped_disagrees
; SHARED-NEXT:   no match
; SHARED-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))

; CONSTRAINED-NEXT: target 2: @swapped_disagrees
; CONSTRAINED-NEXT:   match 0:
; CONSTRAINED-NEXT:     {?anch = %c1, ?pred = slt, ?x = %a, ?y = %b}
; CONSTRAINED-NEXT:   match 1:
; CONSTRAINED-NEXT:     {?anch = %c2, ?pred = slt, ?x = %c, ?y = %b}

; LITERAL-NEXT: target 2: @swapped_disagrees
; LITERAL-NEXT:   match 0:
; LITERAL-NEXT:     {?anch = %c1, ?x = %b, ?y = %a}
; LITERAL-NEXT:   match 1:
; LITERAL-NEXT:     {?anch = %c2, ?x = %b, ?y = %c}

; BOTH-NEXT: target 2: @swapped_disagrees
; BOTH-NEXT:   no match
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))

define i1 @single_swapped(i32 %a, i32 %b) {
  %c = icmp sgt i32 %b, %a
  ret i1 %c
}
; SHARED-NEXT: target 3: @single_swapped
; SHARED-NEXT:   no match
; SHARED-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))

; CONSTRAINED-NEXT: target 3: @single_swapped
; CONSTRAINED-NEXT:   match 0:
; CONSTRAINED-NEXT:     {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}

; LITERAL-NEXT: target 3: @single_swapped
; LITERAL-NEXT:   match 0:
; LITERAL-NEXT:     {?anch = %c, ?x = %b, ?y = %a}

; BOTH-NEXT: target 3: @single_swapped
; BOTH-NEXT:   no match
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))

define i1 @single_in_order(i32 %a, i32 %b) {
  %c = icmp slt i32 %a, %b
  ret i1 %c
}
; SHARED-NEXT: target 4: @single_in_order
; SHARED-NEXT:   no match
; SHARED-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))
; SHARED-NOT: {{.}}

; CONSTRAINED-NEXT: target 4: @single_in_order
; CONSTRAINED-NEXT:   match 0:
; CONSTRAINED-NEXT:     {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; CONSTRAINED-NOT: {{.}}

; LITERAL-NEXT: target 4: @single_in_order
; LITERAL-NEXT:   match 0:
; LITERAL-NEXT:     {?anch = %c, ?x = %b, ?y = %a}
; LITERAL-NOT: {{.}}

; BOTH-NEXT: target 4: @single_in_order
; BOTH-NEXT:   no match
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))
; BOTH-NEXT:   constraint not satisfied: (== ?pred (swappedPredicate ?_swapped$pred))
; BOTH-NOT: {{.}}
