; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
%slot = alloca i32, i32 1, align ?alignment, addrspace(?address_space)
getelementptr i32, ptr %slot, i32 ?index

;--- match.ll
define ptr addrspace(5) @keyed_operands(i32 %index) {
  %slot = alloca i32, align 16, addrspace(5)
  %result = getelementptr i32, ptr addrspace(5) %slot, i32 %index
  ret ptr addrspace(5) %result
}
; CHECK: target 0: @keyed_operands
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?address_space = 5, ?alignment = 16, ?index = %index}

;--- no-match.ll
define ptr addrspace(5) @wrong_element_type(i32 %index) {
  %slot = alloca i64, align 16, addrspace(5)
  %result = getelementptr i64, ptr addrspace(5) %slot, i32 %index
  ret ptr addrspace(5) %result
}
; CHECK-NEXT: target 1: @wrong_element_type
; CHECK-NEXT:   no match
