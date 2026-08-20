; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s

;--- pattern.mpir
%trunc = trunc <?n x i?big> ?x to <?n x i?small>
%sub = sub <?n x i?small> ?zero:zero, %trunc
%zext = zext:?anch <?n x i?small> %sub to <?n x i?big>

;--- input.ll
define <2 x i128> @vec(<2 x i128> %x) {
  %t = trunc <2 x i128> %x to <2 x i64>
  %s = sub <2 x i64> zeroinitializer, %t
  %z = zext <2 x i64> %s to <2 x i128>
  ret <2 x i128> %z
}
; CHECK: target 0: @vec
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %z, ?big = 128, ?n = 2, ?small = 64, ?x = %x, ?zero = zeroinitializer}
