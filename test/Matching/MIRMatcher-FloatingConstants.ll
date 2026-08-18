; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/wrong-value.ll %t/wrong-zero.ll | FileCheck %s

;--- pattern.mpir
fadd float 0.1, -0.0

;--- match.ll
define float @float_match() {
  %result = fadd float 0.1, -0.0
  ret float %result
}
; CHECK: target 0: @float_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {}

;--- wrong-value.ll
define float @wrong_value() {
  %result = fadd float 0.2, -0.0
  ret float %result
}
; CHECK-NEXT: target 1: @wrong_value
; CHECK-NEXT:   no match

;--- wrong-zero.ll
define float @wrong_zero() {
  %result = fadd float 0.1, 0.0
  ret float %result
}
; CHECK-NEXT: target 2: @wrong_zero
; CHECK-NEXT:   no match
