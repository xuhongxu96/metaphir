; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: metaflags. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/mf-unknown.mpir 2>&1 | FileCheck %s --check-prefix=MF-UNKNOWN
; MF-UNKNOWN: mf-unknown.mpir:1:16: error: unknown metaflag ':nope'
; RUN: not %metaphir-parse %t/mf-nested-unknown.mpir 2>&1 | FileCheck %s --check-prefix=MF-NESTED-UNKNOWN
; MF-NESTED-UNKNOWN: mf-nested-unknown.mpir:1:20: error: unknown metaflag ':nope'
; RUN: not %metaphir-parse %t/mf-nested-placement.mpir 2>&1 | FileCheck %s --check-prefix=MF-NESTED-PLACEMENT
; MF-NESTED-PLACEMENT: mf-nested-placement.mpir:4:21: error: metaflag ':onlyinst' is not valid as a nested metaflag
; RUN: not %metaphir-parse %t/mf-argument.mpir 2>&1 | FileCheck %s --check-prefix=MF-ARGUMENT
; MF-ARGUMENT: mf-argument.mpir:1:20: error: expected integer or nested metaflag argument
; RUN: not %metaphir-parse %t/mf-close.mpir 2>&1 | FileCheck %s --check-prefix=MF-CLOSE
; MF-CLOSE: mf-close.mpir:1:28: error: expected ')' after metaflag arguments (got end of line)
; RUN: not %metaphir-parse %t/mf-count.mpir 2>&1 | FileCheck %s --check-prefix=MF-COUNT
; MF-COUNT: mf-count.mpir:1:16: error: invalid number of arguments for metaflag ':not'
; RUN: not %metaphir-parse %t/mf-o-flag.mpir 2>&1 | FileCheck %s --check-prefix=MF-O-FLAG
; MF-O-FLAG: mf-o-flag.mpir:1:9: error: metaflag ':o' expects integer arguments
; RUN: not %metaphir-parse %t/mf-not-integer.mpir 2>&1 | FileCheck %s --check-prefix=MF-NOT-INTEGER
; MF-NOT-INTEGER: mf-not-integer.mpir:1:16: error: metaflag ':not' expects nested metaflags
; RUN: not %metaphir-parse %t/mf-user-count.mpir 2>&1 | FileCheck %s --check-prefix=MF-USER-COUNT
; MF-USER-COUNT: mf-user-count.mpir:4:16: error: metaflag ':two' expects 1 argument, got 0
; RUN: not %metaphir-parse %t/mf-too-large.mpir 2>&1 | FileCheck %s --check-prefix=MF-TOO-LARGE
; MF-TOO-LARGE: mf-too-large.mpir:4:21: error: metaflag integer argument is too large
; RUN: not %metaphir-parse %t/mf-position.mpir 2>&1 | FileCheck %s --check-prefix=MF-POSITION
; MF-POSITION: mf-position.mpir:1:9: error: metaflag ':zero' is not valid in this position
; RUN: not %metaphir-parse %t/mf-instruction-on-operand.mpir 2>&1 | FileCheck %s --check-prefix=MF-INSTRUCTION-ON-OPERAND
; MF-INSTRUCTION-ON-OPERAND: mf-instruction-on-operand.mpir:4:16: error: metaflag ':onlyinst' is not valid in this position
; RUN: not %metaphir-parse %t/mf-on-constant.mpir 2>&1 | FileCheck %s --check-prefix=MF-ON-CONSTANT
; MF-ON-CONSTANT: mf-on-constant.mpir:1:33: error: metaflag ':zero' can only be applied to a meta variable or a local value
; RUN: not %metaphir-parse %t/o-range.mpir 2>&1 | FileCheck %s --check-prefix=O-RANGE
; O-RANGE: o-range.mpir:1:9: error: metaflag ':o' operand index is out of range
; RUN: not %metaphir-parse %t/o-two-indices.mpir 2>&1 | FileCheck %s --check-prefix=O-TWO-INDICES
; O-TWO-INDICES: o-two-indices.mpir:1:9: error: invalid number of arguments for metaflag ':o'
; RUN: not %metaphir-parse %t/c-call-arity.mpir 2>&1 | FileCheck %s --check-prefix=C-CALL-ARITY
; C-CALL-ARITY: c-call-arity.mpir:1:10: error: metaflag ':c' requires a call with exactly two arguments
; RUN: not %metaphir-parse %t/c-call-array.mpir 2>&1 | FileCheck %s --check-prefix=C-CALL-ARRAY
; C-CALL-ARRAY: c-call-array.mpir:1:10: error: metaflag ':c' requires a call with exactly two arguments

;--- mf-unknown.mpir
%a = add i32 ?x:nope, 1

;--- mf-nested-unknown.mpir
%a = add i32 ?x:or(:nope), 1

;--- mf-nested-placement.mpir
metaflag:i :onlyinst(?i) {
  true
}
%a = add i32 ?x:not(:onlyinst), 1

;--- mf-argument.mpir
%a = add i32 ?x:or(?y), 1

;--- mf-close.mpir
%a = add i32 ?x:or(:zero, 1

;--- mf-count.mpir
%a = add i32 ?x:not(), 1

;--- mf-o-flag.mpir
%a = add:o(:zero) i32 ?x, 1

;--- mf-not-integer.mpir
%a = add i32 ?x:not(1), 1

;--- mf-user-count.mpir
metaflag :two(?v, ?n) {
  ?v == ?n
}
%a = add i32 ?x:two, 1

;--- mf-too-large.mpir
metaflag :two(?v, ?n) {
  ?v == ?n
}
%a = add i32 ?x:two(99999999999999999999), 1

;--- mf-position.mpir
%a = add:zero i32 ?x, 1

;--- mf-instruction-on-operand.mpir
metaflag:i :onlyinst(?i) {
  true
}
%a = add i32 ?x:onlyinst, 1

;--- mf-on-constant.mpir
%a = select i1 ?c, ptr null:zero, ptr ?p

;--- o-range.mpir
%a = add:o(2) i32 ?x, 1

;--- o-two-indices.mpir
%a = add:o(0, 1) i32 ?x, 1

;--- c-call-arity.mpir
%a = call:c i32 @f(i32 ?x, i32 ?y, i32 ?z)

;--- c-call-array.mpir
%a = call:c i32 @f(i32 ?x, ...?t ?v)

