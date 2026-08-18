; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/self.ll %t/wrapper.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
%difference = sub i32 ?x, ?y
add:o i32 %difference, 1
; CHECK: target 0: @self
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?x = %x, ?y = %y}
; CHECK-NEXT: target 1: @wrapper
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?x = %x, ?y = %y}
; CHECK-NEXT:   match 1:
; CHECK-NEXT:     {?x = %x, ?y = %y}
; CHECK-NEXT: target 2: @no_match
; CHECK-NEXT:   no match

;--- self.ll
define i32 @self(i32 %x, i32 %y) {
  %difference = sub i32 %x, %y
  ret i32 %difference
}

;--- wrapper.ll
define i32 @wrapper(i32 %x, i32 %y) {
  %difference = sub i32 %x, %y
  %result = add i32 %difference, 1
  ret i32 %result
}

;--- no-match.ll
define i32 @no_match(i32 %x, i32 %y) {
  %difference = mul i32 %x, %y
  ret i32 %difference
}
