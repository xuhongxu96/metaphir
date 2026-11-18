; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; A sequence's count can be a meta variable, which the patterns' uses of it
; must agree on; a fixed count must be the one of the value. A function type
; is no value's type, and a byte width is no integer's.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/shared.mpir %t/arrays.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=SHARED
; RUN: %metaphir-match --matches-only %t/fixed.mpir %t/arrays.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=FIXED
; RUN: %metaphir-match --matches-only %t/function.mpir %t/arrays.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty
; RUN: %metaphir-match --matches-only %t/byte.mpir %t/arrays.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty

;--- shared.mpir
%a = load [?n x i32], ptr ?p
%b = load [?n x i32], ptr ?q

;--- fixed.mpir
%a = load [4 x i32], ptr ?p

;--- function.mpir
%a = load i32 (i32), ptr ?p

;--- byte.mpir
%a = load b?n, ptr ?p

;--- arrays.ll
define void @same(ptr %p, ptr %q) {
  %a = load [2 x i32], ptr %p
  %b = load [2 x i32], ptr %q
  ret void
}

define void @mixed(ptr %p, ptr %q) {
  %a = load [2 x i32], ptr %p
  %b = load [3 x i32], ptr %q
  ret void
}

define void @four(ptr %p) {
  %a = load [4 x i32], ptr %p
  ret void
}

define void @scalar(ptr %p) {
  %i = load i32, ptr %p
  ret void
}

; Both loads may be one instruction, so @mixed matches with each of its counts
; on itself, but not with the count of its first load on its second.
; SHARED-DAG: @same {?n = 2, ?p = %p, ?q = %q}
; SHARED-DAG: @mixed {?n = 2, ?p = %p, ?q = %p}
; SHARED-DAG: @mixed {?n = 3, ?p = %q, ?q = %q}
; SHARED-NOT: @mixed {?n = 2, ?p = %p, ?q = %q}
; FIXED: @four
; FIXED-NOT: @mixed
; FIXED-NOT: @same
; NONE-NOT: {{.}}
