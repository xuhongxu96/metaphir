; RUN: split-file %s %t
; RUN: %metaphir-match %t/countl-zero.mpir %t/input.ll | FileCheck %s --check-prefix=CLZ
; RUN: %metaphir-match %t/countr-zero.mpir %t/input.ll | FileCheck %s --check-prefix=CTZ
; RUN: %metaphir-match %t/countl-one.mpir %t/input.ll | FileCheck %s --check-prefix=CLO
; RUN: %metaphir-match %t/countr-one.mpir %t/input.ll | FileCheck %s --check-prefix=CTO
; RUN: %metaphir-match %t/explicit-width.mpir %t/input.ll | FileCheck %s --check-prefix=WIDTH
; RUN: %metaphir-match %t/known-trailing-zeros.mpir %t/input.ll | FileCheck %s --check-prefix=KNOWN
; RUN: %metaphir-match %t/bit-width.mpir %t/input.ll | FileCheck %s --check-prefix=BITS

; Bit counts named after APInt's, at the operand's width (a constant's type,
; or an explicit one), and bitWidth, the width of a value's or type's
; scalar type.

;--- countl-zero.mpir
%r = and:?anch i?n ?x, ?c
;; countl_zero(?c) == 4

;--- countr-zero.mpir
%r = and:?anch i?n ?x, ?c
;; countr_zero(?c) == 3

;--- countl-one.mpir
%r = and:?anch i?n ?x, ?c
;; countl_one(?c) == 5

;--- countr-one.mpir
%r = and:?anch i?n ?x, ?c
;; countr_one(?c) == 4

;--- explicit-width.mpir
%r = and:?anch i?n ?x, ?c
;; countl_zero(?c, 16) == 12

;--- known-trailing-zeros.mpir
%r = and:?anch i?n ?x, ?c
;; countr_one(knownZeros(knownBits(?x))) == 2

;--- bit-width.mpir
%r = and:?anch ?ty ?x, ?c
;; bitWidth(?x) == 8 && bitWidth(?ty) == 8

;--- input.ll

; 0b00001111 at i8; 12 leading zeros at i16.
define i8 @i8_f(i8 %x) {
  %r = and i8 %x, 15
  ret i8 %r
}
; CLZ: target 0: @i8_f
; CLZ-NEXT: match 0:
; CLZ-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; CTZ: target 0: @i8_f
; CTZ-NEXT: no match
; CTZ-NEXT: constraint not satisfied: (== (countr_zero ?c) 3)
; CLO: target 0: @i8_f
; CLO-NEXT: no match
; CLO-NEXT: constraint not satisfied: (== (countl_one ?c) 5)
; CTO: target 0: @i8_f
; CTO-NEXT: match 0:
; CTO-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; WIDTH: target 0: @i8_f
; WIDTH-NEXT: match 0:
; WIDTH-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; KNOWN: target 0: @i8_f
; KNOWN-NEXT: no match
; KNOWN-NEXT: constraint not satisfied: (== (countr_one (knownZeros (knownBits ?x))) 2)
; BITS: target 0: @i8_f
; BITS-NEXT: match 0:
; BITS-NEXT: {?anch = %r, ?c = 15, ?ty = i8, ?x = %x}

; 0b11111000.
define i8 @i8_neg8(i8 %x) {
  %r = and i8 %x, -8
  ret i8 %r
}
; CLZ-NEXT: target 1: @i8_neg8
; CLZ-NEXT: no match
; CLZ-NEXT: constraint not satisfied: (== (countl_zero ?c) 4)
; CTZ-NEXT: target 1: @i8_neg8
; CTZ-NEXT: match 0:
; CTZ-NEXT: {?anch = %r, ?c = -8, ?n = 8, ?x = %x}
; CLO-NEXT: target 1: @i8_neg8
; CLO-NEXT: match 0:
; CLO-NEXT: {?anch = %r, ?c = -8, ?n = 8, ?x = %x}
; CTO-NEXT: target 1: @i8_neg8
; CTO-NEXT: no match
; CTO-NEXT: constraint not satisfied: (== (countr_one ?c) 4)
; WIDTH-NEXT: target 1: @i8_neg8
; WIDTH-NEXT: no match
; WIDTH-NEXT: constraint not satisfied: (== (countl_zero ?c 16) 12)
; KNOWN-NEXT: target 1: @i8_neg8
; KNOWN-NEXT: no match
; KNOWN-NEXT: constraint not satisfied: (== (countr_one (knownZeros (knownBits ?x))) 2)
; BITS-NEXT: target 1: @i8_neg8
; BITS-NEXT: match 0:
; BITS-NEXT: {?anch = %r, ?c = -8, ?ty = i8, ?x = %x}

; At i32, 15 has 28 leading zeros.
define i32 @i32_f(i32 %x) {
  %r = and i32 %x, 15
  ret i32 %r
}
; CLZ-NEXT: target 2: @i32_f
; CLZ-NEXT: no match
; CLZ-NEXT: constraint not satisfied: (== (countl_zero ?c) 4)
; CTZ-NEXT: target 2: @i32_f
; CTZ-NEXT: no match
; CTZ-NEXT: constraint not satisfied: (== (countr_zero ?c) 3)
; CLO-NEXT: target 2: @i32_f
; CLO-NEXT: no match
; CLO-NEXT: constraint not satisfied: (== (countl_one ?c) 5)
; CTO-NEXT: target 2: @i32_f
; CTO-NEXT: match 0:
; CTO-NEXT: {?anch = %r, ?c = 15, ?n = 32, ?x = %x}
; WIDTH-NEXT: target 2: @i32_f
; WIDTH-NEXT: match 0:
; WIDTH-NEXT: {?anch = %r, ?c = 15, ?n = 32, ?x = %x}
; KNOWN-NEXT: target 2: @i32_f
; KNOWN-NEXT: no match
; KNOWN-NEXT: constraint not satisfied: (== (countr_one (knownZeros (knownBits ?x))) 2)
; BITS-NEXT: target 2: @i32_f
; BITS-NEXT: no match
; BITS-NEXT: constraint not satisfied: (&& (== (bitWidth ?x) 8) (== (bitWidth ?ty) 8))

; A splat is read as its element by the counts too, but 'i?n' needs treatIntAsVec; bitWidth is the element's.
define <2 x i8> @vec_splat(<2 x i8> %x) {
  %r = and <2 x i8> %x, <i8 15, i8 15>
  ret <2 x i8> %r
}
; CLZ-NEXT: target 3: @vec_splat
; CLZ-NEXT: no match
; CTZ-NEXT: target 3: @vec_splat
; CTZ-NEXT: no match
; CLO-NEXT: target 3: @vec_splat
; CLO-NEXT: no match
; CTO-NEXT: target 3: @vec_splat
; CTO-NEXT: no match
; WIDTH-NEXT: target 3: @vec_splat
; WIDTH-NEXT: no match
; KNOWN-NEXT: target 3: @vec_splat
; KNOWN-NEXT: no match
; BITS-NEXT: target 3: @vec_splat
; BITS-NEXT: match 0:
; BITS-NEXT: {?anch = %r, ?c = splat (i8 15), ?ty = <2 x i8>, ?x = %x}

; x = a << 2 has two known trailing zeros.
define i8 @known(i8 %a) {
  %x = shl i8 %a, 2
  %r = and i8 %x, 15
  ret i8 %r
}
; CLZ-NEXT: target 4: @known
; CLZ-NEXT: match 0:
; CLZ-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; CTZ-NEXT: target 4: @known
; CTZ-NEXT: no match
; CTZ-NEXT: constraint not satisfied: (== (countr_zero ?c) 3)
; CLO-NEXT: target 4: @known
; CLO-NEXT: no match
; CLO-NEXT: constraint not satisfied: (== (countl_one ?c) 5)
; CTO-NEXT: target 4: @known
; CTO-NEXT: match 0:
; CTO-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; WIDTH-NEXT: target 4: @known
; WIDTH-NEXT: match 0:
; WIDTH-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; KNOWN-NEXT: target 4: @known
; KNOWN-NEXT: match 0:
; KNOWN-NEXT: {?anch = %r, ?c = 15, ?n = 8, ?x = %x}
; BITS-NEXT: target 4: @known
; BITS-NEXT: match 0:
; BITS-NEXT: {?anch = %r, ?c = 15, ?ty = i8, ?x = %x}
