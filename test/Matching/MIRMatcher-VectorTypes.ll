; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s --check-prefix=ZEROINIT
; RUN: %metaphir-match %t/pattern-zero.mpir %t/input.ll | FileCheck %s --check-prefix=ZEROFLAG
; RUN: %metaphir-match %t/pattern-scalable.mpir %t/input.ll | FileCheck %s --check-prefix=SCALABLE
; RUN: %metaphir-match %t/pattern-scalar.mpir %t/input.ll | FileCheck %s --check-prefix=SCALAR

; Vector (fixed and scalable) types are supported in patterns. A vector zero is
; written with 'zeroinitializer' or matched with the ':zero' meta flag. A
; scalar 'i?bits' pattern does not match a vector operand.

;--- pattern.mpir
%trunc = trunc <2 x i?big> ?x to <2 x i?small>
%sub = sub <2 x i?small> zeroinitializer, %trunc
%zext = zext:?anch <2 x i?small> %sub to <2 x i?big>

;--- pattern-zero.mpir
%trunc = trunc <2 x i?big> ?x to <2 x i?small>
%sub = sub <2 x i?small> ?zero:zero, %trunc
%zext = zext:?anch <2 x i?small> %sub to <2 x i?big>

;--- pattern-scalable.mpir
%trunc = trunc <vscale x 2 x i?big> ?x to <vscale x 2 x i?small>
%sub = sub <vscale x 2 x i?small> zeroinitializer, %trunc
%zext = zext:?anch <vscale x 2 x i?small> %sub to <vscale x 2 x i?big>

;--- pattern-scalar.mpir
%trunc = trunc i?big ?x to i?small
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- input.ll
define <2 x i128> @vec(<2 x i128> %x) {
  %t = trunc <2 x i128> %x to <2 x i64>
  %s = sub <2 x i64> zeroinitializer, %t
  %z = zext <2 x i64> %s to <2 x i128>
  ret <2 x i128> %z
}
; ZEROINIT: target 0: @vec
; ZEROINIT-NEXT:   match 0:
; ZEROINIT-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}

; ZEROFLAG: target 0: @vec
; ZEROFLAG-NEXT:   match 0:
; ZEROFLAG-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x, ?zero = zeroinitializer}

; SCALABLE: target 0: @vec
; SCALABLE-NEXT:   no match

; SCALAR: target 0: @vec
; SCALAR-NEXT:   no match

define <vscale x 2 x i128> @scalable(<vscale x 2 x i128> %x) {
  %t = trunc <vscale x 2 x i128> %x to <vscale x 2 x i64>
  %s = sub <vscale x 2 x i64> zeroinitializer, %t
  %z = zext <vscale x 2 x i64> %s to <vscale x 2 x i128>
  ret <vscale x 2 x i128> %z
}
; ZEROINIT-NEXT: target 1: @scalable
; ZEROINIT-NEXT:   no match

; ZEROFLAG-NEXT: target 1: @scalable
; ZEROFLAG-NEXT:   no match

; SCALABLE-NEXT: target 1: @scalable
; SCALABLE-NEXT:   match 0:
; SCALABLE-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}

; SCALAR-NEXT: target 1: @scalable
; SCALAR-NEXT:   no match
