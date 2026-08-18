; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/abs.ll %t/sqrt.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
call ?ret @llvm.?id(...?types ?values)

;--- abs.ll
declare i32 @llvm.abs.i32(i32, i1 immarg)

define i32 @abs_match(i32 %x) {
  %result = call i32 @llvm.abs.i32(i32 %x, i1 false)
  ret i32 %result
}
; CHECK: target 0: @abs_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?id = llvm.abs, ?ret = i32, ?types = [i32, i1], ?values = [%x, false]}

;--- sqrt.ll
declare float @llvm.sqrt.f32(float)

define float @sqrt_match(float %x) {
  %result = call float @llvm.sqrt.f32(float %x)
  ret float %result
}
; CHECK-NEXT: target 1: @sqrt_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?id = llvm.sqrt, ?ret = float, ?types = [float], ?values = [%x]}

;--- no-match.ll
declare i32 @ordinary(i32)

define i32 @intrinsic_no_match(i32 %x) {
  %result = call i32 @ordinary(i32 %x)
  ret i32 %result
}
; CHECK-NEXT: target 2: @intrinsic_no_match
; CHECK-NEXT:   no match
