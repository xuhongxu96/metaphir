; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/ctlz.ll %t/cttz.ll %t/ordinary.ll | FileCheck %s

; Literal intrinsic names (@llvm.ctlz) match an overloaded intrinsic callee
; (llvm.ctlz.i32) without needing an ?id meta + name constraint.

;--- pattern.mpir
%ctlz = call i?bits @llvm.ctlz(i?bits ?x, i1 ?isz)

;--- ctlz.ll
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

define i32 @ctlz_match(i32 %x) {
  %r = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  ret i32 %r
}
; CHECK: target 0: @ctlz_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?bits = 32, ?isz = false, ?x = %x}

;--- cttz.ll
declare i32 @llvm.cttz.i32(i32, i1 immarg)

define i32 @cttz_nomatch(i32 %x) {
  %r = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  ret i32 %r
}
; CHECK-NEXT: target 1: @cttz_nomatch
; CHECK-NEXT:   no match

;--- ordinary.ll
declare i32 @ordinary(i32)

define i32 @ordinary_nomatch(i32 %x) {
  %r = call i32 @ordinary(i32 %x)
  ret i32 %r
}
; CHECK-NEXT: target 2: @ordinary_nomatch
; CHECK-NEXT:   no match
