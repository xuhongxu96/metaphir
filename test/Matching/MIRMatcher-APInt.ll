; RUN: split-file %s %t
; RUN: %metaphir-match %t/apint.mpir %t/input.ll | FileCheck %s --check-prefix=APINT
; RUN: %metaphir-match %t/allow-poison.mpir %t/input.ll | FileCheck %s --check-prefix=ALLOW
; RUN: %metaphir-match %t/any.mpir %t/input.ll | FileCheck %s --check-prefix=ANY

; ':apInt' is m_APInt: an integer constant or a splat of one, with no poison
; lanes. ':apIntAllowPoison' is m_APIntAllowPoison, and ':anyIntegralConstant'
; is m_AnyIntegralConstant, which also accepts non-splat vectors.

;--- apint.mpir
%r = call:?anch ?ty @id(?ty ?c:apInt)

;--- allow-poison.mpir
%r = call:?anch ?ty @id(?ty ?c:apIntAllowPoison)

;--- any.mpir
%r = call:?anch ?ty @id(?ty ?c:anyIntegralConstant)

;--- input.ll
; Calls give their own function type, so one declaration serves them all.
declare void @id()

define i32 @scalar() {
  %r = call i32 @id(i32 7)
  ret i32 %r
}
; APINT: target 0: @scalar
; APINT-NEXT:   match 0:
; APINT-NEXT:     {?anch = %r, ?c = 7, ?ty = i32}
; ALLOW: target 0: @scalar
; ALLOW-NEXT:   match 0:
; ALLOW-NEXT:     {?anch = %r, ?c = 7, ?ty = i32}
; ANY: target 0: @scalar
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?c = 7, ?ty = i32}

define <2 x i32> @splat() {
  %r = call <2 x i32> @id(<2 x i32> <i32 7, i32 7>)
  ret <2 x i32> %r
}
; APINT-NEXT: target 1: @splat
; APINT-NEXT:   match 0:
; APINT-NEXT:     {?anch = %r, ?c = splat (i32 7), ?ty = <2 x i32>}
; ALLOW-NEXT: target 1: @splat
; ALLOW-NEXT:   match 0:
; ALLOW-NEXT:     {?anch = %r, ?c = splat (i32 7), ?ty = <2 x i32>}
; ANY-NEXT: target 1: @splat
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?c = splat (i32 7), ?ty = <2 x i32>}

define <2 x i32> @splat_poison() {
  %r = call <2 x i32> @id(<2 x i32> <i32 7, i32 poison>)
  ret <2 x i32> %r
}
; APINT-NEXT: target 2: @splat_poison
; APINT-NEXT:   no match
; APINT-NEXT:   constraint not satisfied: {{.*}}
; ALLOW-NEXT: target 2: @splat_poison
; ALLOW-NEXT:   match 0:
; ALLOW-NEXT:     {?anch = %r, ?c = <i32 7, i32 poison>, ?ty = <2 x i32>}
; ANY-NEXT: target 2: @splat_poison
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?c = <i32 7, i32 poison>, ?ty = <2 x i32>}

define <2 x i32> @non_splat() {
  %r = call <2 x i32> @id(<2 x i32> <i32 1, i32 2>)
  ret <2 x i32> %r
}
; APINT-NEXT: target 3: @non_splat
; APINT-NEXT:   no match
; APINT-NEXT:   constraint not satisfied: {{.*}}
; ALLOW-NEXT: target 3: @non_splat
; ALLOW-NEXT:   no match
; ALLOW-NEXT:   constraint not satisfied: {{.*}}
; ANY-NEXT: target 3: @non_splat
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?c = <i32 1, i32 2>, ?ty = <2 x i32>}

define <2 x float> @float_splat() {
  %r = call <2 x float> @id(<2 x float> <float 1.0, float 1.0>)
  ret <2 x float> %r
}
; APINT-NEXT: target 4: @float_splat
; APINT-NEXT:   no match
; APINT-NEXT:   constraint not satisfied: {{.*}}
; ALLOW-NEXT: target 4: @float_splat
; ALLOW-NEXT:   no match
; ALLOW-NEXT:   constraint not satisfied: {{.*}}
; ANY-NEXT: target 4: @float_splat
; ANY-NEXT:   no match
; ANY-NEXT:   constraint not satisfied: {{.*}}
