; RUN: split-file %s %t
; RUN: %metaphir-match %t/nat.mpir %t/nat.ll | FileCheck %s --check-prefix=NAT
; RUN: %metaphir-match %t/nat-unsigned.mpir %t/nat.ll | FileCheck %s --check-prefix=U
; RUN: %metaphir-match %t/icmp-rhs.mpir %t/icmp-rhs.ll | FileCheck %s --check-prefix=ICMP
; RUN: not %metaphir-parse %t/notvar.mpir 2>&1 | FileCheck %s --check-prefix=ERR

; The ':constantint' meta flag binds a constant operand as an integer (like the Nat
; meta type used for widths), so it can be used in constraint arithmetic.
;--- nat.mpir
%udiv = udiv:?anch i?bits ?x, ?c:constantint
;; slt(?c, 0)

;--- nat.ll
define i32 @neg_constant_divisor(i32 %x) {
entry:
  %r = udiv i32 %x, -8
  ret i32 %r
}
; NAT: target 0: @neg_constant_divisor
; NAT-NEXT:   match 0:
; NAT-NEXT:     {?anch = %r, ?bits = 32, ?c = 4294967288, ?x = %x}

; U: target 0: @neg_constant_divisor
; U-NEXT:   match 0:
; U-NEXT:     {?anch = %r, ?bits = 32, ?c = 4294967288, ?x = %x}

define i32 @pos_constant_divisor(i32 %x) {
entry:
  %r = udiv i32 %x, 8
  ret i32 %r
}
; NAT-NEXT: target 1: @pos_constant_divisor
; NAT-NEXT:   no match
; NAT-NEXT:   constraint not satisfied: (slt ?c 0)

; U-NEXT: target 1: @pos_constant_divisor
; U-NEXT:   match 0:
; U-NEXT:     {?anch = %r, ?bits = 32, ?c = 8, ?x = %x}

define i32 @dynamic_divisor(i32 %x, i32 %y) {
entry:
  %r = udiv i32 %x, %y
  ret i32 %r
}
; NAT-NEXT: target 2: @dynamic_divisor
; NAT-NEXT:   no match

; U-NEXT: target 2: @dynamic_divisor
; U-NEXT:   no match

; Signed binding of ':constantint' keeps 'slt' on negative constants correct, while
; unsigned comparisons still operate on the bit pattern.
;--- nat-unsigned.mpir
%udiv = udiv:?anch i?bits ?x, ?c:constantint
;; ugt(?c, 1)
; Meta flags are accepted on the RHS of icmp/fcmp and ':constantint' binds the
; constant there as well.
;--- icmp-rhs.mpir
%neg = sub i?bits 0, ?x
%and = and:c i?bits %neg, ?x
%cmp = icmp:?anch eq i?bits %and, ?c:constantint
;; sgt(?bits, 1)
;; (?c == 0) || (?c == 1)

;--- icmp-rhs.ll
define i32 @zero_or_one(i32 %x) {
entry:
  %n = sub i32 0, %x
  %a = and i32 %n, %x
  %c = icmp eq i32 %a, 0
  %r = zext i1 %c to i32
  ret i32 %r
}
; ICMP: target 0: @zero_or_one
; ICMP-NEXT:   match 0:
; ICMP-NEXT:     {?anch = %c, ?bits = 32, ?c = 0, ?x = %x}

define i32 @two(i32 %x) {
entry:
  %n = sub i32 0, %x
  %a = and i32 %n, %x
  %c = icmp eq i32 %a, 2
  %r = zext i1 %c to i32
  ret i32 %r
}
; ICMP-NEXT: target 1: @two
; ICMP-NEXT:   no match
; ICMP-NEXT:   constraint not satisfied: (|| (== ?c 0) (== ?c 1))

; ':constantint' requires a meta variable operand.
;--- notvar.mpir
%neg = sub i?bits 0, ?x
%add = add i?bits %neg, %neg:constantint
; ERR: ':constantint' can only be applied to a meta variable operand
