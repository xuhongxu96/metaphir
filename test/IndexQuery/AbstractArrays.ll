; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; Array literals in constraints are evaluated before the IR is read, for the
; index's filter as well as for the matches: each kind of element, indexed by
; a constant. A literal indexed out of bounds has no value, and rejects.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/types.mpir %t/add.ll \
; RUN:   | FileCheck %s --check-prefix=TYPES
; RUN: %metaphir-match --matches-only %t/values.mpir %t/add.ll \
; RUN:   | FileCheck %s --check-prefix=VALUES
; RUN: %metaphir-match --matches-only %t/values-wrong.mpir %t/add.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty
; RUN: %metaphir-match --matches-only %t/values-bounds.mpir %t/add.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE --allow-empty
; RUN: %metaphir-match --matches-only %t/strings.mpir %t/add.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=STRINGS

;--- types.mpir
%c = call ?t @f(...?tys ?vals)
;; [?t, ?t][1] == ?t
;--- values.mpir
%r = add i32 ?a, ?b
;; [?a, ?b][1] == ?b
;--- values-wrong.mpir
%r = add i32 ?a, ?b
;; [?a, ?b][1] == ?a
;--- values-bounds.mpir
%r = add i32 ?a, ?b
;; [?a, ?b][3] == ?a
;--- strings.mpir
%c = call ?t @f(...?tys ?vals)
;; ["x", "y"][1] == "y"

;--- add.ll
define i32 @h(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
declare i32 @f(i32, i8)
define i32 @g(i32 %a, i8 %b) {
  %c = call i32 @f(i32 %a, i8 %b)
  ret i32 %c
}

; VALUES: @h	{?a = %a, ?b = %b}
; TYPES: @g	{?t = i32, ?tys = [i32, i8], ?vals = [%a, %b]}
; STRINGS: @g	{?t = i32, ?tys = [i32, i8], ?vals = [%a, %b]}
; NONE-NOT: {{.}}
