; What the parser rejects: metaflags. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/mf-unknown.mpir 2>&1 | FileCheck %s --check-prefix=MF-UNKNOWN
; RUN: not %metaphir-parse %t/mf-nested-unknown.mpir 2>&1 | FileCheck %s --check-prefix=MF-NESTED-UNKNOWN
; RUN: not %metaphir-parse %t/mf-nested-placement.mpir 2>&1 | FileCheck %s --check-prefix=MF-NESTED-PLACEMENT
; RUN: not %metaphir-parse %t/mf-argument.mpir 2>&1 | FileCheck %s --check-prefix=MF-ARGUMENT
; RUN: not %metaphir-parse %t/mf-close.mpir 2>&1 | FileCheck %s --check-prefix=MF-CLOSE
; RUN: not %metaphir-parse %t/mf-count.mpir 2>&1 | FileCheck %s --check-prefix=MF-COUNT
; RUN: not %metaphir-parse %t/mf-o-flag.mpir 2>&1 | FileCheck %s --check-prefix=MF-O-FLAG
; RUN: not %metaphir-parse %t/mf-not-integer.mpir 2>&1 | FileCheck %s --check-prefix=MF-NOT-INTEGER
; RUN: not %metaphir-parse %t/mf-user-count.mpir 2>&1 | FileCheck %s --check-prefix=MF-USER-COUNT
; RUN: not %metaphir-parse %t/mf-too-large.mpir 2>&1 | FileCheck %s --check-prefix=MF-TOO-LARGE
; RUN: not %metaphir-parse %t/mf-position.mpir 2>&1 | FileCheck %s --check-prefix=MF-POSITION
; RUN: not %metaphir-parse %t/mf-instruction-on-operand.mpir 2>&1 | FileCheck %s --check-prefix=MF-INSTRUCTION-ON-OPERAND
; RUN: not %metaphir-parse %t/mf-on-constant.mpir 2>&1 | FileCheck %s --check-prefix=MF-ON-CONSTANT
; RUN: not %metaphir-parse %t/o-range.mpir 2>&1 | FileCheck %s --check-prefix=O-RANGE
; RUN: not %metaphir-parse %t/o-two-indices.mpir 2>&1 | FileCheck %s --check-prefix=O-TWO-INDICES
; RUN: not %metaphir-parse %t/c-call-arity.mpir 2>&1 | FileCheck %s --check-prefix=C-CALL-ARITY
; RUN: not %metaphir-parse %t/c-call-array.mpir 2>&1 | FileCheck %s --check-prefix=C-CALL-ARRAY
;--- mf-unknown.mpir
%a = add i32 ?x:nope, 1
; MF-UNKNOWN: unknown metaflag ':nope'

;--- mf-nested-unknown.mpir
%a = add i32 ?x:or(:nope), 1
; MF-NESTED-UNKNOWN: unknown metaflag ':nope'

;--- mf-nested-placement.mpir
metaflag:i :onlyinst(?i) {
  true
}
%a = add i32 ?x:not(:onlyinst), 1
; MF-NESTED-PLACEMENT: metaflag ':onlyinst' is not valid as a nested metaflag

;--- mf-argument.mpir
%a = add i32 ?x:or(?y), 1
; MF-ARGUMENT: expected integer or nested metaflag argument

;--- mf-close.mpir
%a = add i32 ?x:or(:zero, 1
; MF-CLOSE: expected ')' after metaflag arguments (got end of line)

;--- mf-count.mpir
%a = add i32 ?x:not(), 1
; MF-COUNT: invalid number of arguments for metaflag ':not'

;--- mf-o-flag.mpir
%a = add:o(:zero) i32 ?x, 1
; MF-O-FLAG: metaflag ':o' expects integer arguments

;--- mf-not-integer.mpir
%a = add i32 ?x:not(1), 1
; MF-NOT-INTEGER: metaflag ':not' expects nested metaflags

;--- mf-user-count.mpir
metaflag :two(?v, ?n) {
  ?v == ?n
}
%a = add i32 ?x:two, 1
; MF-USER-COUNT: metaflag ':two' expects 1 argument, got 0

;--- mf-too-large.mpir
metaflag :two(?v, ?n) {
  ?v == ?n
}
%a = add i32 ?x:two(99999999999999999999), 1
; MF-TOO-LARGE: metaflag integer argument is too large

;--- mf-position.mpir
%a = add:zero i32 ?x, 1
; MF-POSITION: metaflag ':zero' is not valid in this position

;--- mf-instruction-on-operand.mpir
metaflag:i :onlyinst(?i) {
  true
}
%a = add i32 ?x:onlyinst, 1
; MF-INSTRUCTION-ON-OPERAND: metaflag ':onlyinst' is not valid in this position

;--- mf-on-constant.mpir
%a = select i1 ?c, ptr null:zero, ptr ?p
; MF-ON-CONSTANT: metaflag ':zero' can only be applied to a meta variable or a local value

;--- o-range.mpir
%a = add:o(2) i32 ?x, 1
; O-RANGE: metaflag ':o' operand index is out of range

;--- o-two-indices.mpir
%a = add:o(0, 1) i32 ?x, 1
; O-TWO-INDICES: invalid number of arguments for metaflag ':o'

;--- c-call-arity.mpir
%a = call:c i32 @f(i32 ?x, i32 ?y, i32 ?z)
; C-CALL-ARITY: metaflag ':c' requires a call with exactly two arguments

;--- c-call-array.mpir
%a = call:c i32 @f(i32 ?x, ...?t ?v)
; C-CALL-ARRAY: metaflag ':c' requires a call with exactly two arguments
