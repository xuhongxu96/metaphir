; RUN: split-file %s %t
; RUN: %metaphir-match %t/shared.mpir %t/input.ll | FileCheck %s

; A predicate variable is bound to the predicate as spelled: an icmp's and an
; fcmp's predicate of the same name ('ult') are the same binding.

;--- shared.mpir
%i = icmp:?anch ?p i32 ?a, ?b
%f = fcmp ?p float ?x, ?y

;--- input.ll
define void @same_name(i32 %a, i32 %b, float %x, float %y) {
  %i = icmp ult i32 %a, %b
  %f = fcmp ult float %x, %y
  ret void
}
; CHECK: target 0: @same_name
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?a = %a, ?anch = %i, ?b = %b, ?p = ult, ?x = %x, ?y = %y}

define void @different_names(i32 %a, i32 %b, float %x, float %y) {
  %i = icmp ult i32 %a, %b
  %f = fcmp ugt float %x, %y
  ret void
}
; CHECK-NEXT: target 1: @different_names
; CHECK-NEXT:   no match
; CHECK-NOT: {{.}}
