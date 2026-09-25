; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s

; 'isGuaranteedNotToBeUndef' is backed by ValueTracking.

;--- pattern.mpir
%add = add:?anch i?bits ?x, 1
;; isGuaranteedNotToBeUndef(?x)

;--- input.ll
define i32 @noundef_arg(i32 noundef %x) {
  %r = add i32 %x, 1
  ret i32 %r
}
; CHECK: target 0: @noundef_arg
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?bits = 32, ?x = %x}

define i32 @plain_load(ptr %p) {
  %x = load i32, ptr %p
  %r = add i32 %x, 1
  ret i32 %r
}
; CHECK-NEXT: target 1: @plain_load
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndef ?x)
