; RUN: split-file %s %t
; RUN: %metaphir-match %t/tiv.mpir %t/input.ll | FileCheck %s --check-prefix=TIV
; RUN: %metaphir-match %t/fixed.mpir %t/input.ll | FileCheck %s --check-prefix=FIXED
; RUN: %metaphir-match %t/switch.mpir %t/input.ll | FileCheck %s --check-prefix=SWITCH

; ';; treatIntAsVec(true)' is a global pattern setting (an ORed PatternSetting
; mask) that applies to the instructions following it. When set, a scalar
; integer type 'i?bits' (or a fixed 'i8') also matches a vector type
; '<?N x i?bits>' / '<?N x i8>', and scalar integer constants (e.g. 0) match
; vector splat constants (e.g. zeroinitializer). The setting can be toggled
; on/off mid-pattern; instructions use the setting active at their position.

;--- tiv.mpir
;; treatIntAsVec(true)
%trunc = trunc i?big ?x to i?small
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- fixed.mpir
;; treatIntAsVec(true)
%trunc = trunc i8 ?x to i4
%sub = sub i4 0, %trunc
%zext = zext:?anch i4 %sub to i8

;--- switch.mpir
;; treatIntAsVec(true)
%trunc = trunc i?big ?x to i?small
;; treatIntAsVec(false)
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- input.ll
define <2 x i128> @vec(<2 x i128> %x) {
  %t = trunc <2 x i128> %x to <2 x i64>
  %s = sub <2 x i64> zeroinitializer, %t
  %z = zext <2 x i64> %s to <2 x i128>
  ret <2 x i128> %z
}
; TIV: target 0: @vec
; TIV-NEXT:   match 0:
; TIV-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}

; FIXED: target 0: @vec
; FIXED-NEXT:   no match

; SWITCH: target 0: @vec
; SWITCH-NEXT:   no match

define i128 @scalar(i128 %x) {
  %t = trunc i128 %x to i64
  %s = sub i64 0, %t
  %z = zext i64 %s to i128
  ret i128 %z
}
; TIV-NEXT: target 1: @scalar
; TIV-NEXT:   match 0:
; TIV-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}

; FIXED-NEXT: target 1: @scalar
; FIXED-NEXT:   no match

; SWITCH-NEXT: target 1: @scalar
; SWITCH-NEXT:   match 0:
; SWITCH-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}

define <4 x i8> @vec8(<4 x i8> %x) {
  %t = trunc <4 x i8> %x to <4 x i4>
  %s = sub <4 x i4> zeroinitializer, %t
  %z = zext <4 x i4> %s to <4 x i8>
  ret <4 x i8> %z
}
; TIV-NEXT: target 2: @vec8
; TIV-NEXT:   match 0:
; TIV-NEXT:     {?anch = %z, ?big = 8, ?small = 4, ?x = %x}

; FIXED-NEXT: target 2: @vec8
; FIXED-NEXT:   match 0:
; FIXED-NEXT:     {?anch = %z, ?x = %x}

; SWITCH-NEXT: target 2: @vec8
; SWITCH-NEXT:   no match
