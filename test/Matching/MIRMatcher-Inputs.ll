; RUN: split-file %s %t
; RUN: mkdir -p %t/irs/nested
; RUN: cp %t/ll-input.ll %t/irs/input.ll
; RUN: llvm-as %t/bc-input.ll -o %t/irs/nested/input.bc
; RUN: %metaphir-match %t/pattern.mpir %t/irs | FileCheck %s --check-prefix=DIR
; RUN: %metaphir-match %t/pattern.mpir %t/irs/nested/input.bc | FileCheck %s --check-prefix=BC

;--- pattern.mpir
%sum = add i32 ?x, ?y

;--- ll-input.ll
define i32 @from_ll(i32 %x, i32 %y) {
entry:
  %sum = add i32 %x, %y
  ret i32 %sum
}
; DIR: target 0: @from_ll
; DIR-NEXT:   match 0:
; DIR-NEXT:     {?x = %x, ?y = %y}

;--- bc-input.ll
define i32 @from_bc(i32 %x, i32 %y) {
entry:
  %sum = add i32 %x, %y
  ret i32 %sum
}
; DIR-NEXT: target 1: @from_bc
; DIR-NEXT:   match 0:
; DIR-NEXT:     {?x = %x, ?y = %y}

; BC: target 0: @from_bc
; BC-NEXT:   match 0:
; BC-NEXT:     {?x = %x, ?y = %y}
