; RUN: split-file %s %t
; RUN: %metaphir-match %t/add-bw.mpir %t/input.ll | FileCheck %s --check-prefix=ADDBW
; RUN: %metaphir-match %t/add-bw2.mpir %t/input.ll | FileCheck %s --check-prefix=ADDBW2
; RUN: %metaphir-match %t/add-wide.mpir %t/input.ll | FileCheck %s --check-prefix=ADDWIDE
; RUN: %metaphir-match %t/mul-bw.mpir %t/input.ll | FileCheck %s --check-prefix=MULBW
; RUN: %metaphir-match %t/mul-wide.mpir %t/input.ll | FileCheck %s --check-prefix=MULWIDE
; RUN: %metaphir-match %t/shl-bw.mpir %t/input.ll | FileCheck %s --check-prefix=SHLBW
; RUN: %metaphir-match %t/neg-bw.mpir %t/input.ll | FileCheck %s --check-prefix=NEGBW
; RUN: not %metaphir-parse %t/too-many.mpir 2>&1 | FileCheck %s --check-prefix=TOOMANY
; RUN: not %metaphir-parse %t/cmp-bw.mpir 2>&1 | FileCheck %s --check-prefix=CMPBW

; Arithmetic constraint operations accept an optional trailing bitwidth: with a
; bitwidth the operands are cast to it and the arithmetic wraps modulo 2^W; by
; default (no bitwidth) add/sub/mul automatically widen so they cannot overflow.
;--- input.ll
define i8 @wrap_add(i8 %unused) {
entry:
  %r = add i8 5, 251
  ret i8 %r
}
; ADDBW: target 0: @wrap_add
; ADDBW-NEXT:   match 0:
; ADDBW-NEXT:     {?anch = %r, ?bits = 8, ?c1 = 5, ?c2 = -5}

; ADDBW2: target 0: @wrap_add
; ADDBW2-NEXT:   no match
; ADDBW2-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2 ?bits) 56)

; ADDWIDE: target 0: @wrap_add
; ADDWIDE-NEXT:   no match
; ADDWIDE-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2) 56)

; MULBW: target 0: @wrap_add
; MULBW-NEXT:   no match

; MULWIDE: target 0: @wrap_add
; MULWIDE-NEXT:   no match

; SHLBW: target 0: @wrap_add
; SHLBW-NEXT:   no match

; NEGBW: target 0: @wrap_add
; NEGBW-NEXT:   no match

define i8 @neg_sum(i8 %unused) {
entry:
  %r = add i8 -100, -100
  ret i8 %r
}
; ADDBW-NEXT: target 1: @neg_sum
; ADDBW-NEXT:   no match
; ADDBW-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2 ?bits) 0)

; ADDBW2-NEXT: target 1: @neg_sum
; ADDBW2-NEXT:   match 0:
; ADDBW2-NEXT:     {?anch = %r, ?bits = 8, ?c1 = -100, ?c2 = -100}

; ADDWIDE-NEXT: target 1: @neg_sum
; ADDWIDE-NEXT:   no match
; ADDWIDE-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2) 56)

; MULBW-NEXT: target 1: @neg_sum
; MULBW-NEXT:   no match

; MULWIDE-NEXT: target 1: @neg_sum
; MULWIDE-NEXT:   no match

; SHLBW-NEXT: target 1: @neg_sum
; SHLBW-NEXT:   no match

; NEGBW-NEXT: target 1: @neg_sum
; NEGBW-NEXT:   no match

define i8 @nowrap_add(i8 %unused) {
entry:
  %r = add i8 3, 4
  ret i8 %r
}
; ADDBW-NEXT: target 2: @nowrap_add
; ADDBW-NEXT:   no match
; ADDBW-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2 ?bits) 0)

; ADDBW2-NEXT: target 2: @nowrap_add
; ADDBW2-NEXT:   no match
; ADDBW2-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2 ?bits) 56)

; ADDWIDE-NEXT: target 2: @nowrap_add
; ADDWIDE-NEXT:   no match
; ADDWIDE-NEXT:   constraint not satisfied: (== (+ ?c1 ?c2) 56)

; MULBW-NEXT: target 2: @nowrap_add
; MULBW-NEXT:   no match

; MULWIDE-NEXT: target 2: @nowrap_add
; MULWIDE-NEXT:   no match

; SHLBW-NEXT: target 2: @nowrap_add
; SHLBW-NEXT:   no match

; NEGBW-NEXT: target 2: @nowrap_add
; NEGBW-NEXT:   no match

define i8 @wrap_mul(i8 %unused) {
entry:
  %r = mul i8 16, 16
  ret i8 %r
}
; ADDBW-NEXT: target 3: @wrap_mul
; ADDBW-NEXT:   no match

; ADDBW2-NEXT: target 3: @wrap_mul
; ADDBW2-NEXT:   no match

; ADDWIDE-NEXT: target 3: @wrap_mul
; ADDWIDE-NEXT:   no match

; MULBW-NEXT: target 3: @wrap_mul
; MULBW-NEXT:   match 0:
; MULBW-NEXT:     {?anch = %r, ?bits = 8, ?c1 = 16, ?c2 = 16}

; MULWIDE-NEXT: target 3: @wrap_mul
; MULWIDE-NEXT:   no match
; MULWIDE-NEXT:   constraint not satisfied: (== (* ?c1 ?c2) 0)

; SHLBW-NEXT: target 3: @wrap_mul
; SHLBW-NEXT:   no match

; NEGBW-NEXT: target 3: @wrap_mul
; NEGBW-NEXT:   no match

define i8 @shl_two(i8 %unused) {
entry:
  %r = shl i8 1, 2
  ret i8 %r
}
; ADDBW-NEXT: target 4: @shl_two
; ADDBW-NEXT:   no match

; ADDBW2-NEXT: target 4: @shl_two
; ADDBW2-NEXT:   no match

; ADDWIDE-NEXT: target 4: @shl_two
; ADDWIDE-NEXT:   no match

; MULBW-NEXT: target 4: @shl_two
; MULBW-NEXT:   no match

; MULWIDE-NEXT: target 4: @shl_two
; MULWIDE-NEXT:   no match

; SHLBW-NEXT: target 4: @shl_two
; SHLBW-NEXT:   match 0:
; SHLBW-NEXT:     {?anch = %r, ?bits = 8, ?s = 2}

; NEGBW-NEXT: target 4: @shl_two
; NEGBW-NEXT:   no match

define i8 @neg_five(i8 %unused) {
entry:
  %r = sub i8 0, -5
  ret i8 %r
}
; ADDBW-NEXT: target 5: @neg_five
; ADDBW-NEXT:   no match

; ADDBW2-NEXT: target 5: @neg_five
; ADDBW2-NEXT:   no match

; ADDWIDE-NEXT: target 5: @neg_five
; ADDWIDE-NEXT:   no match

; MULBW-NEXT: target 5: @neg_five
; MULBW-NEXT:   no match

; MULWIDE-NEXT: target 5: @neg_five
; MULWIDE-NEXT:   no match

; SHLBW-NEXT: target 5: @neg_five
; SHLBW-NEXT:   no match

; NEGBW-NEXT: target 5: @neg_five
; NEGBW-NEXT:   match 0:
; NEGBW-NEXT:     {?a = -5, ?anch = %r, ?bits = 8}

;--- add-bw.mpir
%add = add:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; add(?c1, ?c2, ?bits) == 0

;--- add-bw2.mpir
%add = add:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; add(?c1, ?c2, ?bits) == 56

;--- add-wide.mpir
%add = add:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; (?c1 + ?c2) == 56

;--- mul-bw.mpir
%mul = mul:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; mul(?c1, ?c2, ?bits) == 0

;--- mul-wide.mpir
%mul = mul:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; (?c1 * ?c2) == 0

;--- shl-bw.mpir
%shl = shl:?anch i?bits 1, ?s:constantInt
;; shl(1, ?s, ?bits) == 4

;--- neg-bw.mpir
%sub = sub:?anch i?bits 0, ?a:constantInt
;; neg(?a, ?bits) == 5

;--- too-many.mpir
%add = add:?anch i?bits ?c1:constantInt, ?c2:constantInt
;; add(?c1, ?c2, ?bits, 1) == 0
; TOOMANY: built-in constraint operation expects 2 to 3 arguments

;--- cmp-bw.mpir
%udiv = udiv:?anch i?bits ?x, ?c:constantInt
;; slt(?c, 0, ?bits)
; CMPBW: built-in constraint operation expects 2 arguments
