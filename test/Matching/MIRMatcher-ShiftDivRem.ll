; RUN: split-file %s %t
; RUN: %metaphir-match %t/shift.mpir %t/input.ll | FileCheck %s --check-prefix=SHIFT
; RUN: %metaphir-match %t/shift-exact.mpir %t/input.ll | FileCheck %s --check-prefix=SHIFTX
; RUN: %metaphir-match %t/logical-shift.mpir %t/input.ll | FileCheck %s --check-prefix=LSHIFT
; RUN: %metaphir-match %t/idiv.mpir %t/input.ll | FileCheck %s --check-prefix=IDIV
; RUN: %metaphir-match %t/idiv-not-exact.mpir %t/input.ll | FileCheck %s --check-prefix=IDIVX
; RUN: %metaphir-match %t/irem.mpir %t/input.ll | FileCheck %s --check-prefix=IREM

; 'shift' is m_Shift, 'logicalShift' m_LogicalShift, 'idiv' m_IDiv and
; 'irem' m_IRem. shl has no 'exact', so the 'exact' forms exclude it.

;--- shift.mpir
%r = shift:?anch i32 ?x, ?y

;--- shift-exact.mpir
%r = shift:?anch exact i32 ?x, ?y

;--- logical-shift.mpir
%r = logicalShift:?anch i32 ?x, ?y

;--- idiv.mpir
%r = idiv:?anch i32 ?x, ?y

;--- idiv-not-exact.mpir
%r = idiv:?anch !exact i32 ?x, ?y

;--- irem.mpir
%r = irem:?anch i32 ?x, ?y

;--- input.ll

define i32 @shl(i32 %a, i32 %b) {
  %r = shl nuw i32 %a, %b
  ret i32 %r
}
; SHIFT: target 0: @shl
; SHIFT-NEXT: match 0:
; SHIFT-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; SHIFTX: target 0: @shl
; SHIFTX-NEXT: no match
; LSHIFT: target 0: @shl
; LSHIFT-NEXT: match 0:
; LSHIFT-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; IDIV: target 0: @shl
; IDIV-NEXT: no match
; IDIVX: target 0: @shl
; IDIVX-NEXT: no match
; IREM: target 0: @shl
; IREM-NEXT: no match

define i32 @lshr_exact(i32 %a, i32 %b) {
  %r = lshr exact i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 1: @lshr_exact
; SHIFT-NEXT: match 0:
; SHIFT-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; SHIFTX-NEXT: target 1: @lshr_exact
; SHIFTX-NEXT: match 0:
; SHIFTX-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; LSHIFT-NEXT: target 1: @lshr_exact
; LSHIFT-NEXT: match 0:
; LSHIFT-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; IDIV-NEXT: target 1: @lshr_exact
; IDIV-NEXT: no match
; IDIVX-NEXT: target 1: @lshr_exact
; IDIVX-NEXT: no match
; IREM-NEXT: target 1: @lshr_exact
; IREM-NEXT: no match

define i32 @ashr(i32 %a, i32 %b) {
  %r = ashr i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 2: @ashr
; SHIFT-NEXT: match 0:
; SHIFT-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; SHIFTX-NEXT: target 2: @ashr
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 2: @ashr
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 2: @ashr
; IDIV-NEXT: no match
; IDIVX-NEXT: target 2: @ashr
; IDIVX-NEXT: no match
; IREM-NEXT: target 2: @ashr
; IREM-NEXT: no match

define i32 @udiv_exact(i32 %a, i32 %b) {
  %r = udiv exact i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 3: @udiv_exact
; SHIFT-NEXT: no match
; SHIFTX-NEXT: target 3: @udiv_exact
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 3: @udiv_exact
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 3: @udiv_exact
; IDIV-NEXT: match 0:
; IDIV-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; IDIVX-NEXT: target 3: @udiv_exact
; IDIVX-NEXT: no match
; IREM-NEXT: target 3: @udiv_exact
; IREM-NEXT: no match

define i32 @sdiv(i32 %a, i32 %b) {
  %r = sdiv i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 4: @sdiv
; SHIFT-NEXT: no match
; SHIFTX-NEXT: target 4: @sdiv
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 4: @sdiv
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 4: @sdiv
; IDIV-NEXT: match 0:
; IDIV-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; IDIVX-NEXT: target 4: @sdiv
; IDIVX-NEXT: match 0:
; IDIVX-NEXT: {?anch = %r, ?x = %a, ?y = %b}
; IREM-NEXT: target 4: @sdiv
; IREM-NEXT: no match

define i32 @urem(i32 %a, i32 %b) {
  %r = urem i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 5: @urem
; SHIFT-NEXT: no match
; SHIFTX-NEXT: target 5: @urem
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 5: @urem
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 5: @urem
; IDIV-NEXT: no match
; IDIVX-NEXT: target 5: @urem
; IDIVX-NEXT: no match
; IREM-NEXT: target 5: @urem
; IREM-NEXT: match 0:
; IREM-NEXT: {?anch = %r, ?x = %a, ?y = %b}

define i32 @srem(i32 %a, i32 %b) {
  %r = srem i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 6: @srem
; SHIFT-NEXT: no match
; SHIFTX-NEXT: target 6: @srem
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 6: @srem
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 6: @srem
; IDIV-NEXT: no match
; IDIVX-NEXT: target 6: @srem
; IDIVX-NEXT: no match
; IREM-NEXT: target 6: @srem
; IREM-NEXT: match 0:
; IREM-NEXT: {?anch = %r, ?x = %a, ?y = %b}

define i32 @mul(i32 %a, i32 %b) {
  %r = mul i32 %a, %b
  ret i32 %r
}
; SHIFT-NEXT: target 7: @mul
; SHIFT-NEXT: no match
; SHIFTX-NEXT: target 7: @mul
; SHIFTX-NEXT: no match
; LSHIFT-NEXT: target 7: @mul
; LSHIFT-NEXT: no match
; IDIV-NEXT: target 7: @mul
; IDIV-NEXT: no match
; IDIVX-NEXT: target 7: @mul
; IDIVX-NEXT: no match
; IREM-NEXT: target 7: @mul
; IREM-NEXT: no match
