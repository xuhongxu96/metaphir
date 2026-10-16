; Composite use-site meta flags must be interpreted at the composite boundary.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/commutative.mpir %t | FileCheck %s --check-prefix=COMMUTATIVE
; RUN: %metaphir-match %t/or-self.mpir %t | FileCheck %s --check-prefix=OR-SELF

;--- commutative.mpir
match:c addmul [] Binary (?ty ?x, ?y) {
	%tmp = add ?ty ?x, ?y
	%ret = mul ?ty %tmp, ?y
}

%r = addmul:c i32 1, 2

;--- or-self.mpir
match addop [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%value = sub i32 ?x, ?y
%r = addop:o i32 %value, 0

;--- commutative.ll
define i32 @commutative(i32 %unused) {
entry:
  %a = add i32 2, 1
  %r = mul i32 %a, 1
  ret i32 %r
}
; COMMUTATIVE: target 0: @commutative
; COMMUTATIVE-NEXT:   match 0:
; COMMUTATIVE-NEXT:     {}

; OR-SELF: target 0: @commutative
; OR-SELF-NEXT:   no match

;--- or-self.ll
define i32 @or_self(i32 %x, i32 %y) {
entry:
  %r = sub i32 %x, %y
  ret i32 %r
}
; COMMUTATIVE-NEXT: target 1: @or_self
; COMMUTATIVE-NEXT:   no match
; COMMUTATIVE-NOT: {{.}}

; OR-SELF-NEXT: target 1: @or_self
; OR-SELF-NEXT:   match 0:
; OR-SELF-NEXT:     {?x = %x, ?y = %y}
; OR-SELF-NOT: {{.}}
