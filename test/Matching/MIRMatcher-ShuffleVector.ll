; RUN: split-file %s %t
; RUN: %metaphir-match %t/any-mask.mpir %t/input.ll | FileCheck %s --check-prefix=ANY
; RUN: %metaphir-match %t/zero-mask.mpir %t/input.ll | FileCheck %s --check-prefix=SPLAT
; RUN: %metaphir-match %t/specific-mask.mpir %t/input.ll | FileCheck %s --check-prefix=SPECIFIC
; RUN: %metaphir-match %t/narrowing.mpir %t/input.ll | FileCheck %s --check-prefix=NARROW

; shufflevector's mask is matched as the constant vector of i32 the IR prints,
; poison for an undefined element (m_Shuffle with m_Mask / m_SpecificMask).

;--- any-mask.mpir
%s = shufflevector:?anch <4 x i32> ?a, <4 x i32> ?b, <4 x i32> ?mask

;--- zero-mask.mpir
%s = shufflevector:?anch <4 x i32> ?a, <4 x i32> ?b, <4 x i32> zeroinitializer

;--- specific-mask.mpir
%s = shufflevector:?anch <4 x i32> ?a, <4 x i32> ?b, <4 x i32> <i32 0, i32 4, i32 1, i32 5>

;--- narrowing.mpir
%s = shufflevector:?anch <4 x i32> ?a, <4 x i32> ?b, <2 x i32> ?mask

;--- input.ll

define <4 x i32> @interleave(<4 x i32> %a, <4 x i32> %b) {
  %s = shufflevector <4 x i32> %a, <4 x i32> %b, <4 x i32> <i32 0, i32 4, i32 1, i32 5>
  ret <4 x i32> %s
}
; ANY: target 0: @interleave
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?anch = %s, ?b = %b, ?mask = <i32 0, i32 4, i32 1, i32 5>}

; SPLAT: target 0: @interleave
; SPLAT-NEXT:   no match

; SPECIFIC: target 0: @interleave
; SPECIFIC-NEXT:   match 0:
; SPECIFIC-NEXT:     {?a = %a, ?anch = %s, ?b = %b}

; NARROW: target 0: @interleave
; NARROW-NEXT:   no match

define <4 x i32> @splat(<4 x i32> %a, <4 x i32> %b) {
  %s = shufflevector <4 x i32> %a, <4 x i32> poison, <4 x i32> zeroinitializer
  ret <4 x i32> %s
}
; ANY-NEXT: target 1: @splat
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?anch = %s, ?b = poison, ?mask = zeroinitializer}

; SPLAT-NEXT: target 1: @splat
; SPLAT-NEXT:   match 0:
; SPLAT-NEXT:     {?a = %a, ?anch = %s, ?b = poison}

; SPECIFIC-NEXT: target 1: @splat
; SPECIFIC-NEXT:   no match

; NARROW-NEXT: target 1: @splat
; NARROW-NEXT:   no match

; An undefined lane is poison in the mask.
define <4 x i32> @undefined_lane(<4 x i32> %a, <4 x i32> %b) {
  %s = shufflevector <4 x i32> %a, <4 x i32> %b, <4 x i32> <i32 0, i32 poison, i32 1, i32 5>
  ret <4 x i32> %s
}
; ANY-NEXT: target 2: @undefined_lane
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?anch = %s, ?b = %b, ?mask = <i32 0, i32 poison, i32 1, i32 5>}

; SPLAT-NEXT: target 2: @undefined_lane
; SPLAT-NEXT:   no match

; SPECIFIC-NEXT: target 2: @undefined_lane
; SPECIFIC-NEXT:   no match

; NARROW-NEXT: target 2: @undefined_lane
; NARROW-NEXT:   no match

; The mask has the result's length.
define <2 x i32> @narrow(<4 x i32> %a, <4 x i32> %b) {
  %s = shufflevector <4 x i32> %a, <4 x i32> %b, <2 x i32> <i32 3, i32 7>
  ret <2 x i32> %s
}
; ANY-NEXT: target 3: @narrow
; ANY-NEXT:   no match
; ANY-NOT: {{.}}

; SPLAT-NEXT: target 3: @narrow
; SPLAT-NEXT:   no match
; SPLAT-NOT: {{.}}

; SPECIFIC-NEXT: target 3: @narrow
; SPECIFIC-NEXT:   no match
; SPECIFIC-NOT: {{.}}

; NARROW-NEXT: target 3: @narrow
; NARROW-NEXT:   match 0:
; NARROW-NEXT:     {?a = %a, ?anch = %s, ?b = %b, ?mask = <i32 3, i32 7>}
; NARROW-NOT: {{.}}
