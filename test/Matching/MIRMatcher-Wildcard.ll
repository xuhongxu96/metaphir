; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; '?_' matches anything: two of them need not bind the same value, and the
; match reports neither.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only %t/two-values.mpir %t/f.ll | FileCheck %s --check-prefix=TWO-VALUES
; RUN: %metaphir-match --matches-only %t/predicate.mpir %t/f.ll | FileCheck %s --check-prefix=PREDICATE
; RUN: %metaphir-match --matches-only %t/named.mpir %t/f.ll | FileCheck %s --check-prefix=NAMED

;--- f.ll
define i32 @f(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  %c = icmp slt i32 %a, %b
  %s = add i32 %a, %a
  ret i32 %r
}

;--- two-values.mpir
%r = add:?anch i32 ?_, ?_
; Both adds match, %a + %b as well as %a + %a.
; TWO-VALUES:      f.ll	@f	{?anch = %r}
; TWO-VALUES-NEXT: f.ll	@f	{?anch = %s}

;--- predicate.mpir
%c = icmp:?anch ?_ i32 ?_, ?_
; PREDICATE: f.ll	@f	{?anch = %c}

;--- named.mpir
; A named variable still binds one value: only %a + %a.
%r = add:?anch i32 ?y, ?y
; NAMED:     f.ll	@f	{?anch = %s, ?y = %a}
; NAMED-NOT: ?anch = %r
