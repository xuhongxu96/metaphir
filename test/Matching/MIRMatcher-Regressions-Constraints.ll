; Constraint evaluation regressions. Each pattern matches only if its
; constraint holds.
; RUN: split-file %s %t
; RUN: %metaphir-match %t/explicit-width-sign.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/width-too-large.mpir %t/add.ll | FileCheck %s --check-prefix=WIDTH
; RUN: %metaphir-match %t/in-signed-range.mpir %t/add8.ll | FileCheck %s --check-prefix=MATCH8
; RUN: %metaphir-match %t/low-bit-mask.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/mixed-sign-compare.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/sdiv-overflow.mpir %t/const8.ll | FileCheck %s --check-prefix=CONST8
; RUN: %metaphir-match %t/shl-widens.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/masked-signed.mpir %t/wide.ll | FileCheck %s --check-prefix=MASKED
; RUN: %metaphir-match %t/non-boolean.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/nat-unsigned.mpir %t/extract.ll | FileCheck %s --check-prefix=NAT
; RUN: %metaphir-match %t/user-arg-sign.mpir %t/add.ll | FileCheck %s --check-prefix=MATCH
; RUN: %metaphir-match %t/splat-poison.mpir %t/splat.ll | FileCheck %s --check-prefix=SPLAT
; RUN: %metaphir-match %t/commutative-once.mpir %t/same.ll | FileCheck %s --check-prefix=COMMUTATIVE

; MATCH: target 0: @f
; MATCH-NEXT:   match 0:
; MATCH-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; An explicit width converts a negative operand by sign extension.
;--- explicit-width-sign.mpir
%r = add:?anch i32 ?x, ?y
;; add(-1, 0, 128) == -1

; A width that does not fit is reported, not truncated to a small width.
;--- width-too-large.mpir
%r = add:?anch i32 ?x, ?y
;; add(1, 1, 4294967304) == 2
; WIDTH: target 0: @f
; WIDTH-NEXT:   no match
; WIDTH-NEXT:   constraint not satisfied: (== (+ 1 1 4294967304) 2) (cannot evaluate: bitwidth must be between 1 and 8388608)

; Range bounds wider than the value are not truncated to its width.
;--- in-signed-range.mpir
%r = add:?anch i8 ?x, ?y
;; inSignedRange(?x, -1000, 1000)

; An all-ones integer is a low bit mask, zero is not.
;--- low-bit-mask.mpir
%r = add:?anch i32 ?x, ?y
;; isLowBitMask(-1) && isLowBitMask(7) && !isLowBitMask(0) && !isLowBitMask(6)

; An unsigned operand keeps its value when compared with a signed one.
;--- mixed-sign-compare.mpir
%r = add:?anch i32 ?x, ?y
;; sgt(udiv(-1, 1), -1)

; Signed division of the most negative value by -1 does not wrap.
;--- sdiv-overflow.mpir
%r = add:?anch i8 ?c, ?d
;; sdiv(?c, ?d) == 128

;--- const8.ll
define i8 @g() {
  %r = add i8 -128, -1
  ret i8 %r
}
; CONST8: target 0: @g
; CONST8-NEXT:   match 0:
; CONST8-NEXT:     {?anch = %r, ?c = -128, ?d = -1}

; Without an explicit width, shl keeps the bits shifted out of the operand's
; width.
;--- shl-widens.mpir
%r = add:?anch i32 ?x, ?y
;; lshr(shl(3, 63), 63) == 3

; A negative mask is sign-extended to the value's width.
;--- masked-signed.mpir
%r = shl:?anch i128 ?x, 72
;; maskedValueIsZero(?anch, -256)

;--- wide.ll
define i128 @h(i8 %a) {
  %x = zext i8 %a to i128
  %r = shl i128 %x, 72
  ret i128 %r
}
; MASKED: target 0: @h
; MASKED-NEXT:   no match
; MASKED-NEXT:   constraint not satisfied: (maskedValueIsZero ?anch (- 256))

; A constraint whose value turns out not to be a boolean when evaluated is
; coerced, not crashed on.
;--- non-boolean.mpir
constraint id(?v) {
  ?v
}
%r = add:?anch i32 ?x, ?y
;; id(7)

; A Nat binding (here an element index) is unsigned.
;--- nat-unsigned.mpir
%r = extractelement:?anch <256 x i8> ?v, i8 ?n
;; ?n == 255

;--- extract.ll
define i8 @e(<256 x i8> %v) {
  %r = extractelement <256 x i8> %v, i8 255
  ret i8 %r
}
; NAT: target 0: @e
; NAT-NEXT:   match 0:
; NAT-NEXT:     {?anch = %r, ?n = 255, ?v = %v}

; A user-defined constraint receives its argument with its signedness.
;--- user-arg-sign.mpir
constraint isFF(?v) {
  ?v == 255
}
%r = add:?anch i32 ?x, ?y
;; isFF(and(255, 255, 8))

; A splat with poison lanes is an integer constant, as in LLVM's m_APInt.
;--- splat-poison.mpir
%r = add:?anch <2 x i32> ?x, ?c
;; ?c == 1

;--- splat.ll
define <2 x i32> @s(<2 x i32> %x) {
  %r = add <2 x i32> %x, <i32 1, i32 poison>
  ret <2 x i32> %r
}
; SPLAT: target 0: @s
; SPLAT-NEXT:   match 0:
; SPLAT-NEXT:     {?anch = %r, ?c = <i32 1, i32 poison>, ?x = %x}

; Matching both operand orders of 'add %v, %v' yields one match, not two.
;--- commutative-once.mpir
%r = add:?anch:c i32 ?a, ?b

;--- same.ll
define i32 @same(i32 %v) {
  %r = add i32 %v, %v
  ret i32 %r
}
; COMMUTATIVE: target 0: @same
; COMMUTATIVE-NEXT:   match 0:
; COMMUTATIVE-NEXT:     {?a = %v, ?anch = %r, ?b = %v}
; COMMUTATIVE-NOT: match 1

;--- add.ll
define i32 @f(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}

;--- add8.ll
define i8 @f(i8 %x, i8 %y) {
  %r = add i8 %x, %y
  ret i8 %r
}
; MATCH8: target 0: @f
; MATCH8-NEXT:   match 0:
; MATCH8-NEXT:     {?anch = %r, ?x = %x, ?y = %y}
