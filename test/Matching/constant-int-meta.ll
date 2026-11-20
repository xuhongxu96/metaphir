; RUN: split-file %s %t
; RUN: %metaphir-match %t/nat.mpir %t/nat.ll | FileCheck %s --check-prefix=NAT
; RUN: %metaphir-match %t/nat-unsigned.mpir %t/nat.ll | FileCheck %s --check-prefix=U
; RUN: %metaphir-match %t/icmp-rhs.mpir %t/icmp-rhs.ll | FileCheck %s --check-prefix=ICMP
; RUN: not %metaphir-parse %t/notvar.mpir 2>&1 | FileCheck %s --check-prefix=ERR
; RUN: %metaphir-match %t/local.mpir %t/local.ll | FileCheck %s --check-prefix=LOCAL

; The ':constantInt' meta flag lowers to an 'isConstantInt' constraint, so the
; operand keeps its value binding and constraint arithmetic reaches the integer
; through a coercion.
;--- nat.mpir
%udiv = udiv:?anch i?bits ?x, ?c:constantInt
;; slt(?c, 0)

;--- nat.ll
define i32 @neg_constant_divisor(i32 %x) {
entry:
  %r = udiv i32 %x, -8
  ret i32 %r
}
; NAT: target 0: @neg_constant_divisor
; NAT-NEXT:   match 0:
; NAT-NEXT:     {?anch = %r, ?bits = 32, ?c = -8, ?x = %x}

; U: target 0: @neg_constant_divisor
; U-NEXT:   match 0:
; U-NEXT:     {?anch = %r, ?bits = 32, ?c = -8, ?x = %x}

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
; NAT-NEXT:   constraint not satisfied: (isConstantInt ?c)
; NAT-NOT: {{.}}

; U-NEXT: target 2: @dynamic_divisor
; U-NEXT:   no match
; U-NEXT:   constraint not satisfied: (isConstantInt ?c)
; U-NOT: {{.}}

; Constants coerce to signed integers, so 'slt' on a negative constant is
; correct, while unsigned comparisons still operate on the bit pattern.
;--- nat-unsigned.mpir
%udiv = udiv:?anch i?bits ?x, ?c:constantInt
;; ugt(?c, 1)
; Meta flags are accepted on the RHS of icmp/fcmp, and ':constantInt' applies
; to that operand as well.
;--- icmp-rhs.mpir
%neg = sub i?bits 0, ?x
%and = and:c i?bits %neg, ?x
%cmp = icmp:?anch eq i?bits %and, ?c:constantInt
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
; ICMP-NOT: {{.}}

; ':constantInt' requires a meta variable or a local value, not a constant.
;--- notvar.mpir
%add = add ptr ?x, @g:constantInt
; ERR: metaflag ':constantInt' can only be applied to a meta variable or a local value

; A metaflag on a local operand constrains the instruction it names: only the
; add whose result has one use matches.
;--- local.mpir
%a = add i64 ?x, ?y
%b = add:?anch i64 %a:s, 1

;--- local.ll
define i64 @one(i64 %p, i64 %q) {
  %a = add i64 %p, %q
  %b = add i64 %a, 1
  ret i64 %b
}
; LOCAL: target 0: @one
; LOCAL-NEXT:   match 0:
; LOCAL-NEXT:     {?anch = %b, ?x = %p, ?y = %q}

define i64 @two(i64 %p, i64 %q) {
  %a = add i64 %p, %q
  %b = add i64 %a, 1
  %c = mul i64 %a, %b
  ret i64 %c
}
; LOCAL-NEXT: target 1: @two
; LOCAL-NEXT:   no match
; LOCAL-NEXT:   constraint not satisfied: (hasOneUse %a)
; LOCAL-NOT: {{.}}
