; RUN: split-file %s %t
; RUN: %metaphir-match %t/user-def.mpir %t/input.ll | FileCheck %s

;--- user-def.mpir
constraint iseven(?v) {
	urem(?v, 2) == 0
}
metaflag :even(?v) {
	iseven(?v)
}

%add = add:?anch i32 ?x, ?c:even

;--- input.ll
define i32 @f_even(i32 %x) {
entry:
  %r = add i32 %x, 4
  ret i32 %r
}
; CHECK: target 0: @f_even
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?c = 4, ?x = %x}

define i32 @f_odd(i32 %x) {
entry:
  %r = add i32 %x, 5
  ret i32 %r
}
; CHECK-NEXT: target 1: @f_odd
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (iseven ?c)
; CHECK-NOT: {{.}}
