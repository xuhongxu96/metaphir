; A 'constraint' definition is called with what a match binds: a flag and a
; type, each read as the definition's parameter, which its body reads.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/ir.ll | FileCheck %s

;--- pattern.mpir
constraint takesFlag(?b) {
  ?b
}
constraint takesType(?t) {
  bitWidth(?t) == 32
}
%c = call ?t @f(...?tys ?vals)
%e = zext nneg:?n i8 ?x to i32
;; takesFlag(?n)
;; takesType(?t)

;--- ir.ll
declare i32 @f(i32, i8)
define i32 @g(i32 %a, i8 %b) {
  %c = call i32 @f(i32 %a, i8 %b)
  %e = zext nneg i8 %b to i32
  ret i32 %c
}

; CHECK: @g	{?n = true, ?t = i32, ?tys = [i32, i8], ?vals = [%a, %b], ?x = %b}
