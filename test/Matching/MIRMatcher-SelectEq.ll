; RUN: split-file %s %t
; RUN: %metaphir-match %t/select-eq-zero.mpir %t/input.ll | FileCheck %s --check-prefix=ZERO
; RUN: %metaphir-match %t/select-eq.mpir %t/input.ll | FileCheck %s --check-prefix=GEN

;--- select-eq-zero.mpir
%sel = selectEqZero:?anch i32 ?x, i32 ?a, i32 ?b

;--- select-eq.mpir
%sel = selectEq:?anch i32 ?x, i32 ?y, i32 ?a, i32 ?b

;--- input.ll
; eq 0 arm: ?a is the true value, ?b is the false value
define i32 @zero_eq(i32 %x, i32 %a, i32 %b) {
  %cmp = icmp eq i32 %x, 0
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}
; ZERO: target 0: @zero_eq
; ZERO-NEXT:   match 0:
; ZERO-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x}

; GEN: target 0: @zero_eq
; GEN-NEXT:   match 0:
; GEN-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x, ?y = 0}

; ne 0 arm: ?a is the value when x==0 (select's false arm), ?b is when x!=0 (true arm)
define i32 @zero_ne(i32 %x, i32 %a, i32 %b) {
  %cmp = icmp ne i32 %x, 0
  %sel = select i1 %cmp, i32 %b, i32 %a
  ret i32 %sel
}
; ZERO-NEXT: target 1: @zero_ne
; ZERO-NEXT:   match 0:
; ZERO-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x}

; GEN-NEXT: target 1: @zero_ne
; GEN-NEXT:   match 0:
; GEN-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x, ?y = 0}

; Non-zero comparison should not match selectEqZero
define i32 @nonzero_eq(i32 %x, i32 %a, i32 %b) {
  %cmp = icmp eq i32 %x, 1
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}
; ZERO-NEXT: target 2: @nonzero_eq
; ZERO-NEXT:   no match

; GEN-NEXT: target 2: @nonzero_eq
; GEN-NEXT:   match 0:
; GEN-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x, ?y = 1}

; General selectEq matching x == y
define i32 @gen_eq(i32 %x, i32 %y, i32 %a, i32 %b) {
  %cmp = icmp eq i32 %x, %y
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}
; ZERO-NEXT: target 3: @gen_eq
; ZERO-NEXT:   no match

; GEN-NEXT: target 3: @gen_eq
; GEN-NEXT:   match 0:
; GEN-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x, ?y = %y}

; General selectEq matching x != y
define i32 @gen_ne(i32 %x, i32 %y, i32 %a, i32 %b) {
  %cmp = icmp ne i32 %x, %y
  %sel = select i1 %cmp, i32 %b, i32 %a
  ret i32 %sel
}
; ZERO-NEXT: target 4: @gen_ne
; ZERO-NEXT:   no match

; GEN-NEXT: target 4: @gen_ne
; GEN-NEXT:   match 0:
; GEN-NEXT:     {?a = %a, ?anch = %sel, ?b = %b, ?x = %x, ?y = %y}

; Different predicate (slt) should not match selectEq
define i32 @gen_slt(i32 %x, i32 %y, i32 %a, i32 %b) {
  %cmp = icmp slt i32 %x, %y
  %sel = select i1 %cmp, i32 %a, i32 %b
  ret i32 %sel
}
; ZERO-NEXT: target 5: @gen_slt
; ZERO-NEXT:   no match
; ZERO-NOT: {{.}}

; GEN-NEXT: target 5: @gen_slt
; GEN-NEXT:   no match
; GEN-NOT: {{.}}
