; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s

;--- pattern.mpir
%udiv1 = udiv:s i?bits ?x, ?y
%udiv2 = udiv:?anch i?bits %udiv1, ?z
;; is-known-nonzero(?z) && no-overflow("umul", ?y, ?z)

;--- input.ll
define i8 @bounded(i8 %a, i8 range(i8 0, 15) %b, i8 range(i8 1, 16) %c) {
  %d1 = udiv i8 %a, %b
  %d2 = udiv i8 %d1, %c
  ret i8 %d2
}
; CHECK: target 0: @bounded
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %d2, ?bits = 8, ?x = %a, ?y = %b, ?z = %c}

; EXPLICIT: target 0: @bounded
; EXPLICIT-NEXT:   match 0:
; EXPLICIT-NEXT:     {?anch = %d2, ?bits = 8, ?x = %a, ?y = %b, ?z = %c}

; The divisors are unbounded, so is-known-nonzero and no-overflow cannot be
; proven.
define i8 @unbounded(i8 %a, i8 %b, i8 %c) {
  %d1 = udiv i8 %a, %b
  %d2 = udiv i8 %d1, %c
  ret i8 %d2
}
; CHECK-NEXT: target 1: @unbounded
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (&& (is-known-nonzero ?z) (no-overflow "umul" ?y ?z))

; EXPLICIT-NEXT: target 1: @unbounded
; EXPLICIT-NEXT:   no match
; EXPLICIT-NEXT:   constraint not satisfied: (&& (is-known-nonzero ?z ?anch) (no-overflow "umul" ?y ?z ?anch))

; Explicit ?ctx overrides the constraint's default context instruction.
;--- explicit.mpir
%udiv1 = udiv:s i?bits ?x, ?y
%udiv2 = udiv:?anch i?bits %udiv1, ?z
;; is-known-nonzero(?z, ?anch) && no-overflow("umul", ?y, ?z, ?anch)
; RUN: %metaphir-match %t/explicit.mpir %t/input.ll | FileCheck %s --check-prefix=EXPLICIT
