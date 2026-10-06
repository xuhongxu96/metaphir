; RUN: split-file %s %t
; RUN: %metaphir-match %t/literal.mpir %t/input.ll | FileCheck %s --check-prefix=LITERAL
; RUN: %metaphir-match %t/predicate.mpir %t/input.ll | FileCheck %s --check-prefix=PRED
; RUN: %metaphir-match %t/plain.mpir %t/input.ll | FileCheck %s --check-prefix=PLAIN
; RUN: %metaphir-match %t/fcmp.mpir %t/input.ll | FileCheck %s --check-prefix=FCMP

; ':c' on a compare (m_c_ICmp, m_c_FCmp): the swapped operands match with the
; swapped predicate, and '?pred' binds the predicate for the operands in the
; pattern's order.

;--- literal.mpir
%a = add i32 ?p, 1
%c = icmp:?anch:c slt i32 %a, ?y

;--- predicate.mpir
%a = add i32 ?p, 1
%c = icmp:?anch:c ?pred i32 %a, ?y

;--- plain.mpir
%a = add i32 ?p, 1
%c = icmp:?anch slt i32 %a, ?y

;--- fcmp.mpir
%a = fadd float ?p, 1.0
%c = fcmp:?anch:c olt float %a, ?y

;--- input.ll

define i1 @in_order(i32 %p, i32 %y) {
  %a = add i32 %p, 1
  %c = icmp slt i32 %a, %y
  ret i1 %c
}
; LITERAL: target 0: @in_order
; LITERAL-NEXT: match 0:
; LITERAL-NEXT: {?anch = %c, ?p = %p, ?y = %y}
; PRED: target 0: @in_order
; PRED-NEXT: match 0:
; PRED-NEXT: {?anch = %c, ?p = %p, ?pred = slt, ?y = %y}
; PLAIN: target 0: @in_order
; PLAIN-NEXT: match 0:
; PLAIN-NEXT: {?anch = %c, ?p = %p, ?y = %y}
; FCMP: target 0: @in_order
; FCMP-NEXT: no match

; y s> a is a s< y.
define i1 @swapped(i32 %p, i32 %y) {
  %a = add i32 %p, 1
  %c = icmp sgt i32 %y, %a
  ret i1 %c
}
; LITERAL-NEXT: target 1: @swapped
; LITERAL-NEXT: match 0:
; LITERAL-NEXT: {?anch = %c, ?p = %p, ?y = %y}
; PRED-NEXT: target 1: @swapped
; PRED-NEXT: match 0:
; PRED-NEXT: {?anch = %c, ?p = %p, ?pred = slt, ?y = %y}
; PLAIN-NEXT: target 1: @swapped
; PLAIN-NEXT: no match
; FCMP-NEXT: target 1: @swapped
; FCMP-NEXT: no match

; y s< a is a s> y: '?pred' binds sgt.
define i1 @swapped_other(i32 %p, i32 %y) {
  %a = add i32 %p, 1
  %c = icmp slt i32 %y, %a
  ret i1 %c
}
; LITERAL-NEXT: target 2: @swapped_other
; LITERAL-NEXT: no match
; PRED-NEXT: target 2: @swapped_other
; PRED-NEXT: match 0:
; PRED-NEXT: {?anch = %c, ?p = %p, ?pred = sgt, ?y = %y}
; PLAIN-NEXT: target 2: @swapped_other
; PLAIN-NEXT: no match
; FCMP-NEXT: target 2: @swapped_other
; FCMP-NEXT: no match

define i1 @equality(i32 %p, i32 %y) {
  %a = add i32 %p, 1
  %c = icmp eq i32 %y, %a
  ret i1 %c
}
; LITERAL-NEXT: target 3: @equality
; LITERAL-NEXT: no match
; PRED-NEXT: target 3: @equality
; PRED-NEXT: match 0:
; PRED-NEXT: {?anch = %c, ?p = %p, ?pred = eq, ?y = %y}
; PLAIN-NEXT: target 3: @equality
; PLAIN-NEXT: no match
; FCMP-NEXT: target 3: @equality
; FCMP-NEXT: no match

define i1 @fcmp_in_order(float %p, float %y) {
  %a = fadd float %p, 1.0
  %c = fcmp olt float %a, %y
  ret i1 %c
}
; LITERAL-NEXT: target 4: @fcmp_in_order
; LITERAL-NEXT: no match
; PRED-NEXT: target 4: @fcmp_in_order
; PRED-NEXT: no match
; PLAIN-NEXT: target 4: @fcmp_in_order
; PLAIN-NEXT: no match
; FCMP-NEXT: target 4: @fcmp_in_order
; FCMP-NEXT: match 0:
; FCMP-NEXT: {?anch = %c, ?p = %p, ?y = %y}

define i1 @fcmp_swapped(float %p, float %y) {
  %a = fadd float %p, 1.0
  %c = fcmp ogt float %y, %a
  ret i1 %c
}
; LITERAL-NEXT: target 5: @fcmp_swapped
; LITERAL-NEXT: no match
; PRED-NEXT: target 5: @fcmp_swapped
; PRED-NEXT: no match
; PLAIN-NEXT: target 5: @fcmp_swapped
; PLAIN-NEXT: no match
; FCMP-NEXT: target 5: @fcmp_swapped
; FCMP-NEXT: match 0:
; FCMP-NEXT: {?anch = %c, ?p = %p, ?y = %y}
