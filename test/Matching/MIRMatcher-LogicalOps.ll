; RUN: split-file %s %t
; RUN: %metaphir-match %t/and.mpir %t/input.ll | FileCheck %s --check-prefix=AND
; RUN: %metaphir-match %t/c-and.mpir %t/input.ll | FileCheck %s --check-prefix=CAND
; RUN: %metaphir-match %t/or.mpir %t/input.ll | FileCheck %s --check-prefix=OR
; RUN: %metaphir-match %t/op.mpir %t/input.ll | FileCheck %s --check-prefix=OP
; RUN: %metaphir-match %t/vec.mpir %t/input.ll | FileCheck %s --check-prefix=VEC

; 'logicalAnd' / 'logicalOr' are m_LogicalAnd / m_LogicalOr: the bitwise form
; or the poison-blocking select form. ':c' gives the m_c_ forms, and
; 'logicalOp' is m_LogicalOp.

;--- and.mpir
%a = icmp eq i32 ?p, ?q
%r = logicalAnd:?anch i1 %a, ?y

;--- c-and.mpir
%a = icmp eq i32 ?p, ?q
%r = logicalAnd:?anch:c i1 %a, ?y

;--- or.mpir
%a = icmp eq i32 ?p, ?q
%r = logicalOr:?anch i1 %a, ?y

;--- op.mpir
%a = icmp eq i32 ?p, ?q
%r = logicalOp:?anch i1 %a, ?y

;--- vec.mpir
%r = logicalAnd:?anch <2 x i1> ?x, ?y

;--- input.ll

define i1 @and(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = and i1 %a, %b
  ret i1 %r
}
; AND: target 0: @and
; AND-NEXT:   match 0:
; AND-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; CAND: target 0: @and
; CAND-NEXT:   match 0:
; CAND-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; OR: target 0: @and
; OR-NEXT:   no match

; OP: target 0: @and
; OP-NEXT:   match 0:
; OP-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; VEC: target 0: @and
; VEC-NEXT:   no match

define i1 @select_and(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = select i1 %a, i1 %b, i1 false
  ret i1 %r
}
; AND-NEXT: target 1: @select_and
; AND-NEXT:   match 0:
; AND-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; CAND-NEXT: target 1: @select_and
; CAND-NEXT:   match 0:
; CAND-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; OR-NEXT: target 1: @select_and
; OR-NEXT:   no match
; OR-NEXT:   constraint not satisfied: (isAllOnes ?_r$_true)

; OP-NEXT: target 1: @select_and
; OP-NEXT:   match 0:
; OP-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; VEC-NEXT: target 1: @select_and
; VEC-NEXT:   no match

; The condition is the second operand: only the commuted form matches.
define i1 @select_and_swapped(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = select i1 %b, i1 %a, i1 false
  ret i1 %r
}
; AND-NEXT: target 2: @select_and_swapped
; AND-NEXT:   no match

; CAND-NEXT: target 2: @select_and_swapped
; CAND-NEXT:   match 0:
; CAND-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; OR-NEXT: target 2: @select_and_swapped
; OR-NEXT:   no match

; OP-NEXT: target 2: @select_and_swapped
; OP-NEXT:   no match

; VEC-NEXT: target 2: @select_and_swapped
; VEC-NEXT:   no match

define i1 @or(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = or i1 %a, %b
  ret i1 %r
}
; AND-NEXT: target 3: @or
; AND-NEXT:   no match

; CAND-NEXT: target 3: @or
; CAND-NEXT:   no match

; OR-NEXT: target 3: @or
; OR-NEXT:   match 0:
; OR-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; OP-NEXT: target 3: @or
; OP-NEXT:   match 0:
; OP-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; VEC-NEXT: target 3: @or
; VEC-NEXT:   no match

define i1 @select_or(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = select i1 %a, i1 true, i1 %b
  ret i1 %r
}
; AND-NEXT: target 4: @select_or
; AND-NEXT:   no match
; AND-NEXT:   constraint not satisfied: (isZero ?_r$_false)

; CAND-NEXT: target 4: @select_or
; CAND-NEXT:   no match
; CAND-NEXT:   constraint not satisfied: (isZero ?_r$_false)

; OR-NEXT: target 4: @select_or
; OR-NEXT:   match 0:
; OR-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; OP-NEXT: target 4: @select_or
; OP-NEXT:   match 0:
; OP-NEXT:     {?anch = %r, ?p = %p, ?q = %q, ?y = %b}

; VEC-NEXT: target 4: @select_or
; VEC-NEXT:   no match

; select A, B, true is neither.
define i1 @select_neither(i32 %p, i32 %q, i1 %b) {
  %a = icmp eq i32 %p, %q
  %r = select i1 %a, i1 %b, i1 true
  ret i1 %r
}
; AND-NEXT: target 5: @select_neither
; AND-NEXT:   no match
; AND-NEXT:   constraint not satisfied: (isZero ?_r$_false)

; CAND-NEXT: target 5: @select_neither
; CAND-NEXT:   no match
; CAND-NEXT:   constraint not satisfied: (isZero ?_r$_false)

; OR-NEXT: target 5: @select_neither
; OR-NEXT:   no match
; OR-NEXT:   constraint not satisfied: (isAllOnes ?_r$_true)

; OP-NEXT: target 5: @select_neither
; OP-NEXT:   no match
; OP-NEXT:   constraint not satisfied: (isZero ?_r$_false)
; OP-NEXT:   constraint not satisfied: (isAllOnes ?_r$_true)

; VEC-NEXT: target 5: @select_neither
; VEC-NEXT:   no match

define <2 x i1> @vec_select(<2 x i1> %a, <2 x i1> %b) {
  %r = select <2 x i1> %a, <2 x i1> %b, <2 x i1> zeroinitializer
  ret <2 x i1> %r
}
; AND-NEXT: target 6: @vec_select
; AND-NEXT:   no match

; CAND-NEXT: target 6: @vec_select
; CAND-NEXT:   no match

; OR-NEXT: target 6: @vec_select
; OR-NEXT:   no match

; OP-NEXT: target 6: @vec_select
; OP-NEXT:   no match

; VEC-NEXT: target 6: @vec_select
; VEC-NEXT:   match 0:
; VEC-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
