; RUN: split-file %s %t
; RUN: %metaphir-parse %t/ok.mpir | FileCheck %s --check-prefix=OK
; RUN: not %metaphir-parse %t/negated-capture.mpir 2>&1 | FileCheck %s --check-prefix=NEGCAP
; RUN: not %metaphir-parse %t/wildcard.mpir 2>&1 | FileCheck %s --check-prefix=WILDCARD
; RUN: not %metaphir-parse %t/duplicate.mpir 2>&1 | FileCheck %s --check-prefix=DUP
; RUN: not %metaphir-parse %t/conflict.mpir 2>&1 | FileCheck %s --check-prefix=CONFLICT
; RUN: not %metaphir-parse %t/no-flag.mpir 2>&1 | FileCheck %s --check-prefix=NOFLAG
; RUN: not %metaphir-parse %t/unsupported.mpir 2>&1 | FileCheck %s --check-prefix=BADFLAG

;--- ok.mpir
%r = add nsw !nuw i32 ?x, ?y
; OK: %r = add nsw !nuw i32 ?x, ?y

;--- negated-capture.mpir
%r = add !nsw:?f i32 ?x, ?y
; NEGCAP: a negated flag cannot be captured

;--- wildcard.mpir
%r = add nsw:?_ i32 ?x, ?y
; WILDCARD: flag 'nsw' cannot be captured by '?_'; omit the flag, which matches whether or not it is present

;--- duplicate.mpir
%r = add nsw nsw i32 ?x, ?y
; DUP: flag 'nsw' is written more than once

;--- conflict.mpir
%r = add nsw !nsw i32 ?x, ?y
; CONFLICT: flag 'nsw' is written more than once

;--- no-flag.mpir
%r = add ! i32 ?x, ?y
; NOFLAG: expected a flag after '!'

;--- unsupported.mpir
%r = add !exact i32 ?x, ?y
; BADFLAG: flag 'exact' is not valid for 'add'
