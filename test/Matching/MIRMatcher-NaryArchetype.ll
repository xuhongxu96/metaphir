; RUN: split-file %s %t
; RUN: %metaphir-match %t/nary.mpir %t/input.ll | FileCheck %s --check-prefix=NARY
; RUN: %metaphir-match %t/unary.mpir %t/input.ll | FileCheck %s --check-prefix=UNARY

; A Nary matcher takes as many individually typed operands as its parameter
; list declares; 'Unary' is the one-operand case.

;--- nary.mpir
match selectPair [] Nary (i1 ?c, ?ty ?a, ?ty ?b, ?ty ?x, ?ty ?y) {
	%s1 = select i1 ?c, ?ty ?a, ?ty ?b
	%s2 = select i1 ?c, ?ty ?x, ?ty ?y
	%ret = add ?ty %s1, %s2
}

%r = selectPair:?anch i1 ?cond, i32 ?p, i32 ?q, i32 ?u, i32 ?v

;--- unary.mpir
match negate [] Unary (?ty ?x) {
	%ret = sub ?ty 0, ?x
}

%r = negate:?anch i32 ?v

;--- input.ll
define i32 @pair(i1 %c, i32 %a, i32 %b, i32 %x, i32 %y) {
  %s1 = select i1 %c, i32 %a, i32 %b
  %s2 = select i1 %c, i32 %x, i32 %y
  %r = add i32 %s1, %s2
  ret i32 %r
}
; NARY: target 0: @pair
; NARY-NEXT:   match 0:
; NARY-NEXT:     {?anch = %r, ?cond = %c, ?p = %a, ?q = %b, ?u = %x, ?v = %y}

; UNARY: target 0: @pair
; UNARY-NEXT:   no match

define i32 @neg(i32 %v) {
  %r = sub i32 0, %v
  ret i32 %r
}
; NARY-NEXT: target 1: @neg
; NARY-NEXT:   no match
; NARY-NOT: {{.}}

; UNARY-NEXT: target 1: @neg
; UNARY-NEXT:   match 0:
; UNARY-NEXT:     {?anch = %r, ?v = %v}
; UNARY-NOT: {{.}}
