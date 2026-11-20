; RUN: split-file %s %t
; RUN: %metaphir-match %t/num-sign-bits.mpir %t/input.ll | FileCheck %s --check-prefix=SIGN
; RUN: %metaphir-match %t/max-significant-bits.mpir %t/input.ll | FileCheck %s --check-prefix=SIGNIFICANT

; numSignBits and maxSignificantBits are ComputeNumSignBits and
; ComputeMaxSignificantBits.

;--- num-sign-bits.mpir
%r = add:?anch i32 ?x, ?y
;; uge(numSignBits(?x), 25)

;--- max-significant-bits.mpir
%r = add:?anch i32 ?x, ?y
;; ule(maxSignificantBits(?x), 8)

;--- input.ll

; 25 sign bits, 8 significant bits.
define i32 @sext_i8(i8 %v, i32 %y) {
  %x = sext i8 %v to i32
  %r = add i32 %x, %y
  ret i32 %r
}
; SIGN: target 0: @sext_i8
; SIGN-NEXT:   match 0:
; SIGN-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; SIGNIFICANT: target 0: @sext_i8
; SIGNIFICANT-NEXT:   match 0:
; SIGNIFICANT-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

define i32 @sext_i16(i16 %v, i32 %y) {
  %x = sext i16 %v to i32
  %r = add i32 %x, %y
  ret i32 %r
}
; SIGN-NEXT: target 1: @sext_i16
; SIGN-NEXT:   no match
; SIGN-NEXT:   constraint not satisfied: (uge (numSignBits ?x) 25)

; SIGNIFICANT-NEXT: target 1: @sext_i16
; SIGNIFICANT-NEXT:   no match
; SIGNIFICANT-NEXT:   constraint not satisfied: (ule (maxSignificantBits ?x) 8)

define i32 @ashr(i32 %v, i32 %y) {
  %x = ashr i32 %v, 24
  %r = add i32 %x, %y
  ret i32 %r
}
; SIGN-NEXT: target 2: @ashr
; SIGN-NEXT:   match 0:
; SIGN-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; SIGNIFICANT-NEXT: target 2: @ashr
; SIGNIFICANT-NEXT:   match 0:
; SIGNIFICANT-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

define i32 @argument(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}
; SIGN-NEXT: target 3: @argument
; SIGN-NEXT:   no match
; SIGN-NEXT:   constraint not satisfied: (uge (numSignBits ?x) 25)
; SIGN-NOT: {{.}}

; SIGNIFICANT-NEXT: target 3: @argument
; SIGNIFICANT-NEXT:   no match
; SIGNIFICANT-NEXT:   constraint not satisfied: (ule (maxSignificantBits ?x) 8)
; SIGNIFICANT-NOT: {{.}}
