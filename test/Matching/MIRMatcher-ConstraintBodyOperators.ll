; Constraint and metaflag bodies are lexed with the constraint sub-lexer even
; though no ';;' marker introduces them, so multi-character operators such as
; '==', '!=', '&&', '||' and '+' must be available there.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/user-def.mpir %t/input.ll | FileCheck %s

;--- user-def.mpir
constraint isevenlike(?v) {
	urem(?v, 2) + 0 == 0 && urem(?v, 4) != 1 || urem(?v, 8) == 3
}
metaflag :evenlike(?v) {
	isevenlike(?v)
}

%add = add:?anch i32 ?x, ?c:evenlike

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
; CHECK-NEXT:   constraint not satisfied: (isevenlike ?c)

define i32 @f_mod8(i32 %x) {
entry:
  %r = add i32 %x, 11
  ret i32 %r
}
; CHECK-NEXT: target 2: @f_mod8
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?c = 11, ?x = %x}
