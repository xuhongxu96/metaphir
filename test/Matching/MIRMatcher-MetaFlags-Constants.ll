; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
call void @sink(i32 ?allones:allones, i32 ?safe:forbidpoison, i32 ?integral:integralconstant, float ?zero:zerofp, i32 ?poison:poison, i32 ?apint:apint, i32 ?either:or(:allones, :poison), i32 ?not_poison:not(:poison))

;--- match.ll
declare void @sink(i32, i32, i32, float, i32, i32, i32, i32)

define void @all_meta_flags_match() {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 poison, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK: target 0: @all_meta_flags_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?allones = -1, ?apint = 42, ?either = -1, ?integral = 17, ?not_poison = 0, ?poison = poison, ?safe = 7, ?zero = 0.000000e+00}

define void @all_meta_flags_match2() {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 poison, i32 42, i32 poison, i32 0)
  ret void
}
; CHECK-NEXT: target 1: @all_meta_flags_match2
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?allones = -1, ?apint = 42, ?either = poison, ?integral = 17, ?not_poison = 0, ?poison = poison, ?safe = 7, ?zero = 0.000000e+00}

;--- no-match.ll
declare void @sink(i32, i32, i32, float, i32, i32, i32, i32)

define void @bad_allones() {
  call void @sink(i32 0, i32 7, i32 17, float 0.0, i32 poison, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 2: @bad_allones
; CHECK-NEXT:   no match

define void @bad_forbidpoison() {
  call void @sink(i32 -1, i32 poison, i32 17, float 0.0, i32 poison, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 3: @bad_forbidpoison
; CHECK-NEXT:   no match

define void @bad_integralconstant(i32 %integral) {
  call void @sink(i32 -1, i32 7, i32 %integral, float 0.0, i32 poison, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 4: @bad_integralconstant
; CHECK-NEXT:   no match

define void @bad_zerofp() {
  call void @sink(i32 -1, i32 7, i32 17, float 1.0, i32 poison, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 5: @bad_zerofp
; CHECK-NEXT:   no match

define void @bad_poison() {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 0, i32 42, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 6: @bad_poison
; CHECK-NEXT:   no match

define void @bad_apint(i32 %value) {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 poison, i32 %value, i32 -1, i32 0)
  ret void
}
; CHECK-NEXT: target 7: @bad_apint
; CHECK-NEXT:   no match

define void @bad_or() {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 poison, i32 42, i32 0, i32 0)
  ret void
}
; CHECK-NEXT: target 8: @bad_or
; CHECK-NEXT:   no match

define void @bad_not() {
  call void @sink(i32 -1, i32 7, i32 17, float 0.0, i32 poison, i32 42, i32 -1, i32 poison)
  ret void
}
; CHECK-NEXT: target 9: @bad_not
; CHECK-NEXT:   no match
