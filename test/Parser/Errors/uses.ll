; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: uses. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/use-capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=USE-CAPTURE-SORT
; USE-CAPTURE-SORT: use-capture-sort.mpir:5:7: error: meta variable '?c' is used with an incompatible type
; RUN: not %metaphir-parse %t/use-metaflag.mpir 2>&1 | FileCheck %s --check-prefix=USE-METAFLAG
; USE-METAFLAG: use-metaflag.mpir:4:7: error: unknown metaflag ':nope'
; RUN: not %metaphir-parse %t/use-not-commutative.mpir 2>&1 | FileCheck %s --check-prefix=USE-NOT-COMMUTATIVE
; USE-NOT-COMMUTATIVE: use-not-commutative.mpir:4:7: error: commutative matching is not valid for 'm'
; RUN: not %metaphir-parse %t/use-flag.mpir 2>&1 | FileCheck %s --check-prefix=USE-FLAG
; USE-FLAG: use-flag.mpir:4:8: error: flag 'exact' is not valid for 'm'
; RUN: not %metaphir-parse %t/use-operand.mpir 2>&1 | FileCheck %s --check-prefix=USE-OPERAND
; USE-OPERAND: use-operand.mpir:4:15: error: expected ',' between operands (got '1')
; RUN: not %metaphir-parse %t/use-or-self-range.mpir 2>&1 | FileCheck %s --check-prefix=USE-OR-SELF-RANGE
; USE-OR-SELF-RANGE: use-or-self-range.mpir:4:7: error: metaflag ':o' operand index is out of range

;--- use-capture-sort.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%a = add i?c ?x, 1
%b = m:?c i32 %a, 1

;--- use-metaflag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:nope i32 ?x, 1

;--- use-not-commutative.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:c i32 ?x, 1

;--- use-flag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m exact i32 ?x, 1

;--- use-operand.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m i32 ?x 1

;--- use-or-self-range.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:o(4) i32 ?x, 1

