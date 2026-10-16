; RUN: split-file %s %t
; RUN: %metaphir-match %t/splat.mpir %t/input.ll | FileCheck %s --check-prefix=SPLAT
; RUN: %metaphir-match %t/non-splat.mpir %t/input.ll | FileCheck %s --check-prefix=NONSPLAT

; ':constantSplat' lowers to an 'isConstantSplat' constraint, matching a vector
; constant whose elements are all equal. The operand keeps its value binding;
; constraint arithmetic reaches the repeated element through a coercion.

;--- splat.mpir
%udiv = udiv:?anch <?N x i?bits> ?x, ?c:constantSplat
;; and(?c, 1) == 1

;--- non-splat.mpir
%udiv = udiv:?anch <?N x i?bits> ?x, ?c:constantSplat
;; ?c == 1

;--- input.ll
define <2 x i32> @odd_splat(<2 x i32> %x) {
  %r = udiv <2 x i32> %x, <i32 3, i32 3>
  ret <2 x i32> %r
}
; SPLAT: target 0: @odd_splat
; SPLAT-NEXT:   match 0:
; SPLAT-NEXT:     {?N = 2, ?anch = %r, ?bits = 32, ?c = splat (i32 3), ?x = %x}

; NONSPLAT: target 0: @odd_splat
; NONSPLAT-NEXT:   no match
; NONSPLAT-NEXT:   constraint not satisfied: (== ?c 1)

define <2 x i32> @even_splat(<2 x i32> %x) {
  %r = udiv <2 x i32> %x, <i32 4, i32 4>
  ret <2 x i32> %r
}
; SPLAT-NEXT: target 1: @even_splat
; SPLAT-NEXT:   no match
; SPLAT-NEXT:   constraint not satisfied: (== (and ?c 1) 1)

; NONSPLAT-NEXT: target 1: @even_splat
; NONSPLAT-NEXT:   no match
; NONSPLAT-NEXT:   constraint not satisfied: (== ?c 1)

define <2 x i32> @one_splat(<2 x i32> %x) {
  %r = udiv <2 x i32> %x, <i32 1, i32 1>
  ret <2 x i32> %r
}
; SPLAT-NEXT: target 2: @one_splat
; SPLAT-NEXT:   match 0:
; SPLAT-NEXT:     {?N = 2, ?anch = %r, ?bits = 32, ?c = splat (i32 1), ?x = %x}

; NONSPLAT-NEXT: target 2: @one_splat
; NONSPLAT-NEXT:   match 0:
; NONSPLAT-NEXT:     {?N = 2, ?anch = %r, ?bits = 32, ?c = splat (i32 1), ?x = %x}

define <2 x i32> @non_splat(<2 x i32> %x) {
  %r = udiv <2 x i32> %x, <i32 1, i32 2>
  ret <2 x i32> %r
}
; SPLAT-NEXT: target 3: @non_splat
; SPLAT-NEXT:   no match
; SPLAT-NEXT:   constraint not satisfied: (isConstantSplat ?c)

; NONSPLAT-NEXT: target 3: @non_splat
; NONSPLAT-NEXT:   no match
; NONSPLAT-NEXT:   constraint not satisfied: (isConstantSplat ?c)
