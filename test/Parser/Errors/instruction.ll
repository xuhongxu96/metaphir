; What the parser rejects: instruction. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/not-a-matcher.mpir 2>&1 | FileCheck %s --check-prefix=NOT-A-MATCHER
; RUN: not %metaphir-parse %t/duplicate-result.mpir 2>&1 | FileCheck %s --check-prefix=DUPLICATE-RESULT
; RUN: not %metaphir-parse %t/result-equal.mpir 2>&1 | FileCheck %s --check-prefix=RESULT-EQUAL
; RUN: not %metaphir-parse %t/capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=CAPTURE-SORT
; RUN: not %metaphir-parse %t/not-commutative.mpir 2>&1 | FileCheck %s --check-prefix=NOT-COMMUTATIVE
;--- not-a-matcher.mpir
%a = bogus i32 ?x
; NOT-A-MATCHER: expected instruction matcher

;--- duplicate-result.mpir
%a = add i32 ?x, 1
%a = add i32 ?x, 2
; DUPLICATE-RESULT: duplicate instruction result '%a'

;--- result-equal.mpir
%a add i32 ?x, 1
; RESULT-EQUAL: expected '=' after instruction result (got 'add')

;--- capture-sort.mpir
%a = add i?c ?x, 1
%b = add:?c i32 %a, 1
; CAPTURE-SORT: meta variable '?c' is used with an incompatible type

;--- not-commutative.mpir
%a = sub:c i32 ?x, 1
; NOT-COMMUTATIVE: commutative matching is not valid for 'sub'
