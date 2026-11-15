; An instruction only one branch of a matcher reaches is still part of the
; pattern: where another branch matches, it is searched for on its own.
; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/ir.ll | FileCheck %s

;--- pattern.mpir
match oneOrBoth [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or {
  %ret = sub ?ty ?a, ?a
}
%p = shl i32 ?x, 1
%q = lshr i32 ?z, 1
%r = oneOrBoth i32 %p, %q

;--- ir.ll
define i32 @both(i32 %x, i32 %z) {
  %p = shl i32 %x, 1
  %q = lshr i32 %z, 1
  %r = add i32 %p, %q
  ret i32 %r
}
; CHECK: target 0: @both
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?x = %x, ?z = %z}

define i32 @one(i32 %x, i32 %z) {
  %p = shl i32 %x, 1
  %q = lshr i32 %z, 1
  %r = sub i32 %p, %p
  ret i32 %q
}
; CHECK-NEXT: target 1: @one
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?x = %x, ?z = %z}

define i32 @none(i32 %x) {
  %p = shl i32 %x, 1
  %r = sub i32 %p, %p
  ret i32 %r
}
; CHECK-NEXT: target 2: @none
; CHECK-NEXT:   no match
; CHECK-NOT: {{.}}
