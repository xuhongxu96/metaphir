; RUN: split-file %s %t
; RUN: %metaphir-match %t/log2.mpir %t/input.ll | FileCheck %s --check-prefix=L2
; RUN: %metaphir-match %t/log2-or.mpir %t/input.ll | FileCheck %s --check-prefix=L2O
; RUN: %metaphir-match %t/popcount.mpir %t/popcount.ll | FileCheck %s --check-prefix=PC
; RUN: %metaphir-match %t/ispowertwo.mpir %t/ispowertwo.ll | FileCheck %s --check-prefix=POW

; 'log2' computes the integer floor log2 of a positive constant.
;--- log2.mpir
%udiv = udiv:?anch i?bits ?x, ?d:constantInt
;; log2(?d) == 3

; It can be nested in arithmetic expressions.
;--- log2-or.mpir
%udiv = udiv:?anch i?bits ?x, ?d:constantInt
;; (log2(?d) + 1) == 5

; 'popcount' counts the number of set bits of an integer constant.
;--- popcount.mpir
%lshr = lshr:?anch i?bits ?x, ?amt:constantInt
;; popcount(?amt) == 1

;--- popcount.ll
define i32 @bits7(i32 %x) {
entry:
  %r = lshr i32 %x, 7
  ret i32 %r
}
; PC: target 0: @bits7
; PC-NEXT:   no match
; PC-NEXT:   constraint not satisfied: (== (popcount ?amt) 1)

define i32 @bits8(i32 %x) {
entry:
  %r = lshr i32 %x, 8
  ret i32 %r
}
; PC-NEXT: target 1: @bits8
; PC-NEXT:   match 0:
; PC-NEXT:     {?amt = 8, ?anch = %r, ?bits = 32, ?x = %x}

define i32 @bits3(i32 %x) {
entry:
  %r = lshr i32 %x, 3
  ret i32 %r
}
; PC-NEXT: target 2: @bits3
; PC-NEXT:   no match
; PC-NEXT:   constraint not satisfied: (== (popcount ?amt) 1)

;--- input.ll
define i32 @pow2_8(i32 %x) {
entry:
  %r = udiv i32 %x, 8
  ret i32 %r
}
; L2: target 0: @pow2_8
; L2-NEXT:   match 0:
; L2-NEXT:     {?anch = %r, ?bits = 32, ?d = 8, ?x = %x}

; L2O: target 0: @pow2_8
; L2O-NEXT:   no match
; L2O-NEXT:   constraint not satisfied: (== (+ (log2 ?d) 1) 5)

define i32 @pow2_16(i32 %x) {
entry:
  %r = udiv i32 %x, 16
  ret i32 %r
}
; L2-NEXT: target 1: @pow2_16
; L2-NEXT:   no match
; L2-NEXT:   constraint not satisfied: (== (log2 ?d) 3)

; L2O-NEXT: target 1: @pow2_16
; L2O-NEXT:   match 0:
; L2O-NEXT:     {?anch = %r, ?bits = 32, ?d = 16, ?x = %x}

define i32 @pow2_6(i32 %x) {
entry:
  %r = udiv i32 %x, 6
  ret i32 %r
}
; L2-NEXT: target 2: @pow2_6
; L2-NEXT:   no match
; L2-NEXT:   constraint not satisfied: (== (log2 ?d) 3)

; L2O-NEXT: target 2: @pow2_6
; L2O-NEXT:   no match
; L2O-NEXT:   constraint not satisfied: (== (+ (log2 ?d) 1) 5)

define i32 @pow2_1(i32 %x) {
entry:
  %r = udiv i32 %x, 1
  ret i32 %r
}
; L2-NEXT: target 3: @pow2_1
; L2-NEXT:   no match
; L2-NEXT:   constraint not satisfied: (== (log2 ?d) 3)

; L2O-NEXT: target 3: @pow2_1
; L2O-NEXT:   no match
; L2O-NEXT:   constraint not satisfied: (== (+ (log2 ?d) 1) 5)

; 'isPowerOfTwo' checks whether a constant is a power of two.
;--- ispowertwo.mpir
%udiv = udiv:?anch i?bits ?x, ?d:constantInt
;; isPowerOfTwo(?d)

;--- ispowertwo.ll
define i32 @d8(i32 %x) {
entry:
  %r = udiv i32 %x, 8
  ret i32 %r
}
; POW: target 0: @d8
; POW-NEXT:   match 0:
; POW-NEXT:     {?anch = %r, ?bits = 32, ?d = 8, ?x = %x}

define i32 @d6(i32 %x) {
entry:
  %r = udiv i32 %x, 6
  ret i32 %r
}
; POW-NEXT: target 1: @d6
; POW-NEXT:   no match
; POW-NEXT:   constraint not satisfied: (isPowerOfTwo ?d)

define i32 @d1(i32 %x) {
entry:
  %r = udiv i32 %x, 1
  ret i32 %r
}
; POW-NEXT: target 2: @d1
; POW-NEXT:   match 0:
; POW-NEXT:     {?anch = %r, ?bits = 32, ?d = 1, ?x = %x}

define i32 @d0(i32 %x) {
entry:
  %r = udiv i32 %x, 0
  ret i32 %r
}
; POW-NEXT: target 3: @d0
; POW-NEXT:   no match
; POW-NEXT:   constraint not satisfied: (isPowerOfTwo ?d)
