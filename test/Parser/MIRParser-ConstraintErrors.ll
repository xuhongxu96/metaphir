; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/unknown.ll 2>&1 | FileCheck %s --check-prefix=UNKNOWN
; RUN: not %metaphir-parse %t/arity.ll 2>&1 | FileCheck %s --check-prefix=ARITY
; RUN: not %metaphir-parse %t/integer-result.ll 2>&1 | FileCheck %s --check-prefix=RESULT
; RUN: not %metaphir-parse %t/later-variable.ll 2>&1 | FileCheck %s --check-prefix=LATER
; RUN: not %metaphir-parse %t/o-negative.ll 2>&1 | FileCheck %s --check-prefix=O-NEGATIVE
; RUN: not %metaphir-parse %t/o-range.ll 2>&1 | FileCheck %s --check-prefix=O-RANGE
; RUN: not %metaphir-parse %t/non-array.ll 2>&1 | FileCheck %s --check-prefix=NON-ARRAY
; RUN: not %metaphir-parse %t/non-integer-index.ll 2>&1 | FileCheck %s --check-prefix=NON-INTEGER-INDEX
; RUN: not %metaphir-parse %t/empty-array.ll 2>&1 | FileCheck %s --check-prefix=EMPTY-ARRAY
; RUN: not %metaphir-parse %t/invalid-array-element.ll 2>&1 | FileCheck %s --check-prefix=INVALID-ARRAY-ELEMENT

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

;--- later-variable.ll
%sum = add i32 ?x, ?y
;; ?later == true
; LATER: constraint references unknown meta variable '?later'

%later = freeze i1 ?later


;--- o-negative.ll
add:o(-1) i32 ?x, ?y
; O-NEGATIVE: :o expects one non-negative operand index

;--- o-range.ll
add:o(2) i32 ?x, ?y
; O-RANGE: :o operand index is out of range

;--- non-array.ll
add i?bits ?x, ?y
;; ?bits[0] == 1
; NON-ARRAY: constraint subscript requires an array operand

;--- non-integer-index.ll
%sum = add nsw:?condition i32 ?x, ?y
call void @consume(...?types ?values)
;; ?values[?condition] == ?condition
; NON-INTEGER-INDEX: constraint array index must be an integer

;--- empty-array.ll
add i32 ?x, ?y
;; [] == []
; EMPTY-ARRAY: constraint array literal must not be empty

;--- invalid-array-element.ll
add i32 ?x, ?y
;; [1, 2] == [1, 2]
; INVALID-ARRAY-ELEMENT: constraint array literal requires type, value, or string elements
