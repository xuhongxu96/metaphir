; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: instruction. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/not-a-matcher.mpir 2>&1 | FileCheck %s --check-prefix=NOT-A-MATCHER
; NOT-A-MATCHER: not-a-matcher.mpir:1:6: error: expected instruction matcher
; RUN: not %metaphir-parse %t/duplicate-result.mpir 2>&1 | FileCheck %s --check-prefix=DUPLICATE-RESULT
; DUPLICATE-RESULT: duplicate-result.mpir:2:1: error: duplicate instruction result '%a'
; RUN: not %metaphir-parse %t/result-equal.mpir 2>&1 | FileCheck %s --check-prefix=RESULT-EQUAL
; RESULT-EQUAL: result-equal.mpir:1:4: error: expected '=' after instruction result (got 'add')
; RUN: not %metaphir-parse %t/capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=CAPTURE-SORT
; CAPTURE-SORT: capture-sort.mpir:2:9: error: meta variable '?c' is used with an incompatible type
; RUN: not %metaphir-parse %t/not-commutative.mpir 2>&1 | FileCheck %s --check-prefix=NOT-COMMUTATIVE
; NOT-COMMUTATIVE: not-commutative.mpir:1:9: error: commutative matching is not valid for 'sub'

;--- not-a-matcher.mpir
%a = bogus i32 ?x

;--- duplicate-result.mpir
%a = add i32 ?x, 1
%a = add i32 ?x, 2

;--- result-equal.mpir
%a add i32 ?x, 1

;--- capture-sort.mpir
%a = add i?c ?x, 1
%b = add:?c i32 %a, 1

;--- not-commutative.mpir
%a = sub:c i32 ?x, 1

