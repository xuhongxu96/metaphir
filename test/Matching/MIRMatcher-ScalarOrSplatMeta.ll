; RUN: split-file %s %t
; RUN: %metaphir-match %t/test.mpir %t/input.ll | FileCheck %s

;--- test.mpir
;; treatIntAsVec(true)
%and = and:?anch i?bits ?x, ?c:or(:scalar, :constantSplat)

;--- input.ll
define i32 @scalar(i32 %x) {
  %r = and i32 %x, 7
  ret i32 %r
}
; CHECK: target 0: @scalar
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?bits = 32, ?c = 7, ?x = %x}

define <2 x i32> @splat_vec(<2 x i32> %x) {
  %r = and <2 x i32> %x, <i32 7, i32 7>
  ret <2 x i32> %r
}
; CHECK-NEXT: target 1: @splat_vec
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %r, ?bits = 32, ?c = splat (i32 7), ?x = %x}

define <2 x i32> @nonsplat_vec(<2 x i32> %x) {
  %r = and <2 x i32> %x, <i32 7, i32 15>
  ret <2 x i32> %r
}
; CHECK-NEXT: target 2: @nonsplat_vec
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (|| (isScalar ?c) (isConstantSplat ?c))
; CHECK-NOT: {{.}}
