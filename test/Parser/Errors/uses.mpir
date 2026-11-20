; What the parser rejects: uses. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/use-capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=USE-CAPTURE-SORT
; RUN: not %metaphir-parse %t/use-metaflag.mpir 2>&1 | FileCheck %s --check-prefix=USE-METAFLAG
; RUN: not %metaphir-parse %t/use-not-commutative.mpir 2>&1 | FileCheck %s --check-prefix=USE-NOT-COMMUTATIVE
; RUN: not %metaphir-parse %t/use-flag.mpir 2>&1 | FileCheck %s --check-prefix=USE-FLAG
; RUN: not %metaphir-parse %t/use-operand.mpir 2>&1 | FileCheck %s --check-prefix=USE-OPERAND
; RUN: not %metaphir-parse %t/use-or-self-range.mpir 2>&1 | FileCheck %s --check-prefix=USE-OR-SELF-RANGE
;--- use-capture-sort.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%a = add i?c ?x, 1
%b = m:?c i32 %a, 1
; USE-CAPTURE-SORT: meta variable '?c' is used with an incompatible type

;--- use-metaflag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:nope i32 ?x, 1
; USE-METAFLAG: unknown metaflag ':nope'

;--- use-not-commutative.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:c i32 ?x, 1
; USE-NOT-COMMUTATIVE: commutative matching is not valid for 'm'

;--- use-flag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m exact i32 ?x, 1
; USE-FLAG: flag 'exact' is not valid for 'm'

;--- use-operand.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m i32 ?x 1
; USE-OPERAND: expected ',' between operands (got '1')

;--- use-or-self-range.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}
%b = m:o(4) i32 ?x, 1
; USE-OR-SELF-RANGE: metaflag ':o' operand index is out of range
