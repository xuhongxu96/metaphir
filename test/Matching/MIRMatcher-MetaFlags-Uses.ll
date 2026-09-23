; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
%sum = add:su i32 ?shared:su, ?shared
%product = mul i32 %sum, %sum
%one = freeze:s i32 ?single:s
%consume = add i32 %one, %product
ret i32 %consume

;--- match.ll
define i32 @use_flags_match(i32 %shared, i32 %single) {
  %sum = add i32 %shared, %shared
  %product = mul i32 %sum, %sum
  %one = freeze i32 %single
  %consume = add i32 %one, %product
  ret i32 %consume
}
; CHECK: target 0: @use_flags_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?shared = %shared, ?single = %single}

;--- no-match.ll
define i32 @bad_operand_su(i32 %shared, i32 %single) {
  %sum = add i32 %shared, %shared
  %extra = add i32 %shared, 1
  %product = mul i32 %sum, %sum
  %one = freeze i32 %single
  %consume = add i32 %one, %product
  ret i32 %consume
}
; CHECK-NEXT: target 1: @bad_operand_su
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (hasOneUser ?shared)

define i32 @bad_instruction_su(i32 %shared, i32 %single) {
  %sum = add i32 %shared, %shared
  %extra = add i32 %sum, 1
  %product = mul i32 %sum, %sum
  %one = freeze i32 %single
  %consume = add i32 %one, %product
  ret i32 %consume
}
; CHECK-NEXT: target 2: @bad_instruction_su
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (hasOneUser %sum)

define i32 @bad_operand_s(i32 %shared, i32 %single) {
  %sum = add i32 %shared, %shared
  %product = mul i32 %sum, %sum
  %one = freeze i32 %single
  %extra = add i32 %single, 1
  %consume = add i32 %one, %product
  ret i32 %consume
}
; CHECK-NEXT: target 3: @bad_operand_s
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (hasOneUse ?single)

define i32 @bad_instruction_s(i32 %shared, i32 %single) {
  %sum = add i32 %shared, %shared
  %product = mul i32 %sum, %sum
  %one = freeze i32 %single
  %extra = add i32 %one, 1
  %consume = add i32 %one, %product
  ret i32 %consume
}
; CHECK-NEXT: target 4: @bad_instruction_s
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (hasOneUse %one)
