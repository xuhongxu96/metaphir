; '?_' matches anything: two of them need not bind the same value, and the
; match reports neither.
; RUN: split-file %s %t
; RUN: %metaphir-match %t/two-values.mpir %t/f.ll | FileCheck %s --check-prefix=TWO-VALUES
; RUN: %metaphir-match %t/predicate.mpir %t/f.ll | FileCheck %s --check-prefix=PREDICATE
; RUN: %metaphir-match %t/named.mpir %t/f.ll | FileCheck %s --check-prefix=NAMED

;--- f.ll
define i32 @f(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  %c = icmp slt i32 %a, %b
  %s = add i32 %a, %a
  ret i32 %r
}
; TWO-VALUES: target 0: @f
; TWO-VALUES-NEXT:   match 0:
; TWO-VALUES-NEXT:     {?anch = %r}
; TWO-VALUES-NEXT:   match 1:
; TWO-VALUES-NEXT:     {?anch = %s}
; TWO-VALUES-NOT: {{.}}

; PREDICATE: target 0: @f
; PREDICATE-NEXT:   match 0:
; PREDICATE-NEXT:     {?anch = %c}
; PREDICATE-NOT: {{.}}

; NAMED: target 0: @f
; NAMED-NEXT:   match 0:
; NAMED-NEXT:     {?anch = %s, ?y = %a}
; NAMED-NOT: {{.}}

;--- two-values.mpir
%r = add:?anch i32 ?_, ?_
; Both adds match, %a + %b as well as %a + %a.

;--- predicate.mpir
%c = icmp:?anch ?_ i32 ?_, ?_

;--- named.mpir
; A named variable still binds one value: only %a + %a.
%r = add:?anch i32 ?y, ?y
