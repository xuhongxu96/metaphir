; RUN: split-file %s %t
; RUN: %metaphir-match %t/zext-or-sext.mpir %t/zext-or-sext.ll | FileCheck %s --check-prefix=ZOS
; RUN: %metaphir-match %t/bitwise-logic.mpir %t/bitwise-logic.ll | FileCheck %s --check-prefix=BL
; RUN: %metaphir-match %t/bitwise-logic-c.mpir %t/bitwise-logic.ll | FileCheck %s --check-prefix=BLC
; RUN: %metaphir-match %t/predicate.mpir %t/predicate.ll | FileCheck %s --check-prefix=PRED

; zextOrSext matches either a zext or a sext (m_ZExtOrSExt style), so a single
; pattern covers both the zext(trunc) and sext(trunc) forms.
;--- zext-or-sext.mpir
%trunc = trunc i?big ?x to i?small
%ext = zextOrSext:?anch i?small %trunc to i?big

;--- zext-or-sext.ll
define i32 @f_zext(i32 %x) {
entry:
  %t = trunc i32 %x to i8
  %r = zext i8 %t to i32
  ret i32 %r
}
; ZOS: target 0: @f_zext
; ZOS-NEXT:   match 0:
; ZOS-NEXT:     {?anch = %r, ?big = 32, ?small = 8, ?x = %x}

define i32 @f_sext(i32 %x) {
entry:
  %t = trunc i32 %x to i8
  %r = sext i8 %t to i32
  ret i32 %r
}
; ZOS-NEXT: target 1: @f_sext
; ZOS-NEXT:   match 0:
; ZOS-NEXT:     {?anch = %r, ?big = 32, ?small = 8, ?x = %x}

define i8 @f_bitcast(i32 %x) {
entry:
  %t = trunc i32 %x to i8
  %r = bitcast i8 %t to i8
  ret i8 %r
}
; ZOS-NEXT: target 2: @f_bitcast
; ZOS-NEXT:   no match

; bitwiseLogic matches and/or/xor in natural operand order.
;--- bitwise-logic.mpir
%n = sub i8 0, ?x
%l = bitwiseLogic:?anch i8 ?y, %n

; bitwiseLogic also accepts ':c' to match the operands in either order.
;--- bitwise-logic-c.mpir
%n = sub i8 0, ?x
%l = bitwiseLogic:?anch:c i8 ?y, %n

;--- bitwise-logic.ll
define i8 @f_and(i8 %v, i8 %w) {
entry:
  %n = sub i8 0, %v
  %l = and i8 %w, %n
  ret i8 %l
}
; BL: target 0: @f_and
; BL-NEXT:   match 0:
; BL-NEXT:     {?anch = %l, ?x = %v, ?y = %w}

; BLC: target 0: @f_and
; BLC-NEXT:   match 0:
; BLC-NEXT:     {?anch = %l, ?x = %v, ?y = %w}

define i8 @f_or_swapped(i8 %v, i8 %w) {
entry:
  %n = sub i8 0, %v
  %l = or i8 %n, %w
  ret i8 %l
}
; BL-NEXT: target 1: @f_or_swapped
; BL-NEXT:   no match

; BLC-NEXT: target 1: @f_or_swapped
; BLC-NEXT:   match 0:
; BLC-NEXT:     {?anch = %l, ?x = %v, ?y = %w}

define i8 @f_xor(i8 %v, i8 %w) {
entry:
  %n = sub i8 0, %v
  %l = xor i8 %w, %n
  ret i8 %l
}
; BL-NEXT: target 2: @f_xor
; BL-NEXT:   match 0:
; BL-NEXT:     {?anch = %l, ?x = %v, ?y = %w}

; BLC-NEXT: target 2: @f_xor
; BLC-NEXT:   match 0:
; BLC-NEXT:     {?anch = %l, ?x = %v, ?y = %w}

define i8 @f_add(i8 %v, i8 %w) {
entry:
  %n = sub i8 0, %v
  %l = add i8 %w, %n
  ret i8 %l
}
; BL-NEXT: target 3: @f_add
; BL-NEXT:   no match

; BLC-NEXT: target 3: @f_add
; BLC-NEXT:   no match

; A comparison predicate can be captured into a meta variable and constrained
; on by name, instead of hard-coding the predicate in the instruction.
;--- predicate.mpir
%sub = sub i?bits ?x, ?y
%cmp = icmp:?anch ?pred i?bits %sub, ?c:constantInt
;; (?pred == "ugt") && ugt(?c, 1)

;--- predicate.ll
define i1 @f_ugt(i32 %x, i32 %y) {
entry:
  %s = sub i32 %x, %y
  %c = icmp ugt i32 %s, 5
  ret i1 %c
}
; PRED: target 0: @f_ugt
; PRED-NEXT:   match 0:
; PRED-NEXT:     {?anch = %c, ?bits = 32, ?c = 5, ?pred = ugt, ?x = %x, ?y = %y}

define i1 @f_ult(i32 %x, i32 %y) {
entry:
  %s = sub i32 %x, %y
  %c = icmp ult i32 %s, 5
  ret i1 %c
}
; PRED-NEXT: target 1: @f_ult
; PRED-NEXT:   no match
; PRED-NEXT:   constraint not satisfied: (&& (== ?pred "ugt") (ugt ?c 1))
