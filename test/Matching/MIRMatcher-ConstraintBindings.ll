; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/abs.ll %t/sqrt.ll %t/ordinary.ll | FileCheck %s
; RUN: %metaphir-match %t/error-pattern.mpir %t/abs.ll 2>&1 | FileCheck %s --check-prefix=ERROR

;--- pattern.mpir
call:?instruction ?return_type @llvm.?intrinsic(...?types ?values)
;; ?intrinsic == "llvm.abs"
;; ?return_type == "i32"
;; ?types == ["i32", "i1"]
;; ?values == ["%x", "false"]
;; isa(?instruction, "CallInst")

;--- error-pattern.mpir
call:?instruction ?return_type @llvm.?intrinsic(...?types ?values)
;; isa(?instruction, "ImaginaryValue")

;--- abs.ll
declare i32 @llvm.abs.i32(i32, i1 immarg)

define i32 @constraint_abs(i32 %x) {
entry:
  %result = call i32 @llvm.abs.i32(i32 %x, i1 false)
  ret i32 %result
}
; CHECK: target 0: @constraint_abs
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?instruction = %result, ?intrinsic = llvm.abs, ?return_type = i32, ?types = [i32, i1], ?values = [%x, false]}

;--- sqrt.ll
declare float @llvm.sqrt.f32(float)

define float @constraint_sqrt(float %x) {
entry:
  %result = call float @llvm.sqrt.f32(float %x)
  ret float %result
}
; CHECK-NEXT: target 1: @constraint_sqrt
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (== ?intrinsic "llvm.abs")
; CHECK-NEXT:   constraint not satisfied: (== ?return_type "i32")
; CHECK-NEXT:   constraint not satisfied: (== ?types ["i32","i1"])
; CHECK-NEXT:   constraint not satisfied: (== ?values ["%x","false"])

;--- ordinary.ll
declare i32 @ordinary(i32)

define i32 @constraint_ordinary(i32 %x) {
entry:
  %result = call i32 @ordinary(i32 %x)
  ret i32 %result
}
; CHECK-NEXT: target 2: @constraint_ordinary
; CHECK-NEXT:   no match

; ERROR: target 0: @constraint_abs
; ERROR-NEXT:   no match
; ERROR-NEXT:   constraint not satisfied: (isa ?instruction "ImaginaryValue") (cannot evaluate: unknown LLVM value class 'ImaginaryValue')
