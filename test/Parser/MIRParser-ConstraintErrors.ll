; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/unknown.ll 2>&1 | FileCheck %s --check-prefix=UNKNOWN
; RUN: not %metaphir-parse %t/arity.ll 2>&1 | FileCheck %s --check-prefix=ARITY
; RUN: not %metaphir-parse %t/integer-result.ll 2>&1 | FileCheck %s --check-prefix=RESULT
; RUN: not %metaphir-parse %t/after-constraint.ll 2>&1 | FileCheck %s --check-prefix=AFTER
; RUN: not %metaphir-parse %t/o-negative.ll 2>&1 | FileCheck %s --check-prefix=O-NEGATIVE
; RUN: not %metaphir-parse %t/o-range.ll 2>&1 | FileCheck %s --check-prefix=O-RANGE

;--- unknown.ll
add i32 ?x, ?y
;; ?missing == 0
; UNKNOWN: constraint references unknown meta variable '?missing'


;--- arity.ll
add i?bits ?x, ?y
;; ult(?bits)
; ARITY: built-in constraint operation expects 2 arguments


;--- integer-result.ll
add i?bits ?x, ?y
;; ?bits + 1
; RESULT: constraint must have a boolean result


;--- after-constraint.ll
add i32 ?x, ?y
;; true
sub i32 ?x, ?y
; AFTER: instruction is not allowed after constraints


;--- o-negative.ll
add:o(-1) i32 ?x, ?y
; O-NEGATIVE: :o expects one non-negative operand index


;--- o-range.ll
add:o(2) i32 ?x, ?y
; O-RANGE: :o operand index is out of range
