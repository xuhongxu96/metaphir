; RUN: split-file %s %t
; RUN: %metaphir-match %t/pow2.mpir %t/input.ll | FileCheck %s --check-prefix=P2
; RUN: %metaphir-match %t/pow2-or-const.mpir %t/input.ll | FileCheck %s --check-prefix=ORC

; ':powerOfTwo' matches an integer (or vector) constant that is a power of two.
;--- pow2.mpir
%udiv = udiv:?anch i?bits ?x, ?d:powerOfTwo

; It can be combined with other flags via ':or' (power of two, or 0).
;--- pow2-or-const.mpir
%udiv = udiv:?anch i?bits ?x, ?d:or(:powerOfTwo, :constantInt)

;--- input.ll
define i32 @pow2_8(i32 %x) {
entry:
  %r = udiv i32 %x, 8
  ret i32 %r
}
; P2: target 0: @pow2_8
; P2-NEXT:   match 0:
; P2-NEXT:     {?anch = %r, ?bits = 32, ?d = 8, ?x = %x}

; ORC: target 0: @pow2_8
; ORC-NEXT:   match 0:
; ORC-NEXT:     {?anch = %r, ?bits = 32, ?d = 8, ?x = %x}

define i32 @pow2_1(i32 %x) {
entry:
  %r = udiv i32 %x, 1
  ret i32 %r
}
; P2-NEXT: target 1: @pow2_1
; P2-NEXT:   match 0:
; P2-NEXT:     {?anch = %r, ?bits = 32, ?d = 1, ?x = %x}

; ORC-NEXT: target 1: @pow2_1
; ORC-NEXT:   match 0:
; ORC-NEXT:     {?anch = %r, ?bits = 32, ?d = 1, ?x = %x}

define i32 @not_pow2_6(i32 %x) {
entry:
  %r = udiv i32 %x, 6
  ret i32 %r
}
; P2-NEXT: target 2: @not_pow2_6
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isPowerOfTwo ?d)

; ORC-NEXT: target 2: @not_pow2_6
; ORC-NEXT:   match 0:
; ORC-NEXT:     {?anch = %r, ?bits = 32, ?d = 6, ?x = %x}

define i32 @dynamic(i32 %x, i32 %y) {
entry:
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 3: @dynamic
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isPowerOfTwo ?d)

; ORC-NEXT: target 3: @dynamic
; ORC-NEXT:   no match
; ORC-NEXT:   constraint not satisfied: (|| (isPowerOfTwo ?d) (isConstantInt ?d))
