; What the parser rejects: flags. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/flag-after-not.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-AFTER-NOT
; RUN: not %metaphir-parse %t/flag-not-of-opcode.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-NOT-OF-OPCODE
; RUN: not %metaphir-parse %t/flag-twice.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-TWICE
; RUN: not %metaphir-parse %t/flag-negated-capture.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-NEGATED-CAPTURE
; RUN: not %metaphir-parse %t/flag-capture-wildcard.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-CAPTURE-WILDCARD
; RUN: not %metaphir-parse %t/flag-capture-of-type.mpir 2>&1 | FileCheck %s --check-prefix=FLAG-CAPTURE-OF-TYPE
;--- flag-after-not.mpir
%a = add ! i32 ?x, 1
; FLAG-AFTER-NOT: expected a flag after '!'

;--- flag-not-of-opcode.mpir
%a = add exact i32 ?x, 1
; FLAG-NOT-OF-OPCODE: flag 'exact' is not valid for 'add'

;--- flag-twice.mpir
%a = add nsw nsw i32 ?x, 1
; FLAG-TWICE: flag 'nsw' is written more than once

;--- flag-negated-capture.mpir
%a = add !nsw:?c i32 ?x, 1
; FLAG-NEGATED-CAPTURE: a negated flag cannot be captured

;--- flag-capture-wildcard.mpir
%a = add nsw:?_ i32 ?x, 1
; FLAG-CAPTURE-WILDCARD: flag 'nsw' cannot be captured by '?_'; omit the flag, which matches whether or not it is present

;--- flag-capture-of-type.mpir
%a = freeze ?t ?x
%b = add nsw:?t i32 %a, 1
; FLAG-CAPTURE-OF-TYPE: meta variable '?t' is used with an incompatible type
