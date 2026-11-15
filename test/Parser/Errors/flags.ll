; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: flags. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/flag-after-not.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-AFTER-NOT
; FLAG-AFTER-NOT: flag-after-not.mpir:1:12: error: expected a flag after '!'
; RUN: not %metaphir-parse %t/flag-not-of-opcode.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-NOT-OF-OPCODE
; FLAG-NOT-OF-OPCODE: flag-not-of-opcode.mpir:1:10: error: flag 'exact' is not valid for 'add'
; RUN: not %metaphir-parse %t/flag-twice.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-TWICE
; FLAG-TWICE: flag-twice.mpir:1:14: error: flag 'nsw' is written more than once
; RUN: not %metaphir-parse %t/flag-negated-capture.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-NEGATED-CAPTURE
; FLAG-NEGATED-CAPTURE: flag-negated-capture.mpir:1:14: error: a negated flag cannot be captured
; RUN: not %metaphir-parse %t/flag-capture-wildcard.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-CAPTURE-WILDCARD
; FLAG-CAPTURE-WILDCARD: flag-capture-wildcard.mpir:1:13: error: flag 'nsw' cannot be captured by '?_'; omit the flag, which matches whether or not it is present
; RUN: not %metaphir-parse %t/flag-capture-of-type.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-CAPTURE-OF-TYPE
; FLAG-CAPTURE-OF-TYPE: flag-capture-of-type.mpir:2:13: error: meta variable '?t' is used with an incompatible type

;--- flag-after-not.mpir
%a = add ! i32 ?x, 1

;--- flag-not-of-opcode.mpir
%a = add exact i32 ?x, 1

;--- flag-twice.mpir
%a = add nsw nsw i32 ?x, 1

;--- flag-negated-capture.mpir
%a = add !nsw:?c i32 ?x, 1

;--- flag-capture-wildcard.mpir
%a = add nsw:?_ i32 ?x, 1

;--- flag-capture-of-type.mpir
%a = freeze ?t ?x
%b = add nsw:?t i32 %a, 1

