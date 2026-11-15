; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: constraints. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/expression-expected.mpir 2>&1 | FileCheck %s --check-prefix=EXPRESSION-EXPECTED
; EXPRESSION-EXPECTED: expression-expected.mpir:2:4: error: expected constraint expression
; RUN: not %metaphir-parse %t/ordered-comparison.mpir 2>&1 | FileCheck %s --check-prefix=ORDERED-COMPARISON
; ORDERED-COMPARISON: ordered-comparison.mpir:2:7: error: use slt/ult/sle/ule/sgt/ugt/sge/uge for ordered comparisons
; RUN: not %metaphir-parse %t/division.mpir 2>&1 | FileCheck %s --check-prefix=DIVISION
; DIVISION: division.mpir:2:7: error: use sdiv/udiv/srem/urem for signed or unsigned arithmetic
; RUN: not %metaphir-parse %t/unknown-variable.mpir 2>&1 | FileCheck %s --check-prefix=UNKNOWN-VARIABLE
; UNKNOWN-VARIABLE: unknown-variable.mpir:2:4: error: constraint references unknown meta variable '?nowhere'
; RUN: not %metaphir-parse %t/wildcard-variable.mpir 2>&1 | FileCheck %s --check-prefix=WILDCARD-VARIABLE
; WILDCARD-VARIABLE: wildcard-variable.mpir:2:4: error: a constraint cannot refer to '?_', which stands for a different value each time; name the variable
; RUN: not %metaphir-parse %t/unknown-operation.mpir 2>&1 | FileCheck %s --check-prefix=UNKNOWN-OPERATION
; UNKNOWN-OPERATION: unknown-operation.mpir:2:4: error: unknown constraint operation 'nothing'
; RUN: not %metaphir-parse %t/arity.mpir 2>&1 | FileCheck %s --check-prefix=ARITY
; ARITY: arity.mpir:2:4: error: constraint operation 'isZero' expects 1 argument, got 3
; RUN: not %metaphir-parse %t/arity-range.mpir 2>&1 | FileCheck %s --check-prefix=ARITY-RANGE
; ARITY-RANGE: arity-range.mpir:2:4: error: constraint operation 'udiv' expects 2 to 3 arguments, got 1
; RUN: not %metaphir-parse %t/argument.mpir 2>&1 | FileCheck %s --check-prefix=ARGUMENT
; ARGUMENT: argument.mpir:2:4: error: constraint operation 'isZero' expects 1 argument, got 0
; RUN: not %metaphir-parse %t/argument-close.mpir 2>&1 | FileCheck %s --check-prefix=ARGUMENT-CLOSE
; ARGUMENT-CLOSE: argument-close.mpir:2:13: error: expected ')' after constraint arguments (got end of line)
; RUN: not %metaphir-parse %t/paren-close.mpir 2>&1 | FileCheck %s --check-prefix=PAREN-CLOSE
; PAREN-CLOSE: paren-close.mpir:2:9: error: expected ')' in constraint (got end of line)
; RUN: not %metaphir-parse %t/paren-inner.mpir 2>&1 | FileCheck %s --check-prefix=PAREN-INNER
; PAREN-INNER: paren-inner.mpir:2:5: error: expected constraint expression
; RUN: not %metaphir-parse %t/unary-operand.mpir 2>&1 | FileCheck %s --check-prefix=UNARY-OPERAND
; UNARY-OPERAND: unary-operand.mpir:2:5: error: expected constraint expression
; RUN: not %metaphir-parse %t/unary-sort.mpir 2>&1 | FileCheck %s --check-prefix=UNARY-SORT
; UNARY-SORT: unary-sort.mpir:2:5: error: operand of '!' must be a boolean
; RUN: not %metaphir-parse %t/binary-right.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-RIGHT
; BINARY-RIGHT: binary-right.mpir:2:12: error: expected constraint expression
; RUN: not %metaphir-parse %t/binary-sort.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SORT
; BINARY-SORT: binary-sort.mpir:2:12: error: operand of '&&' must be a boolean
; RUN: not %metaphir-parse %t/chained.mpir 2>&1 | FileCheck %s --check-prefix=CHAINED
; CHAINED: chained.mpir:2:11: error: comparisons cannot be chained; add parentheses
; RUN: not %metaphir-parse %t/array-element.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-ELEMENT
; ARRAY-ELEMENT: array-element.mpir:2:5: error: expected constraint expression
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; ARRAY-CLOSE: array-close.mpir:2:22: error: expected ']' after array literal (got end of line)
; RUN: not %metaphir-parse %t/array-mixed.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-MIXED
; ARRAY-MIXED: array-mixed.mpir:2:4: error: constraint array literal elements must have the same type
; RUN: not %metaphir-parse %t/index-expression.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-EXPRESSION
; INDEX-EXPRESSION: index-expression.mpir:2:10: error: expected constraint expression
; RUN: not %metaphir-parse %t/index-close.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-CLOSE
; INDEX-CLOSE: index-close.mpir:2:18: error: expected ']' after array index (got end of line)
; RUN: not %metaphir-parse %t/index-of-non-array.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-OF-NON-ARRAY
; INDEX-OF-NON-ARRAY: index-of-non-array.mpir:2:5: error: constraint subscript requires an array operand
; RUN: not %metaphir-parse %t/call-open.mpir 2>&1 | FileCheck %s --check-prefix=CALL-OPEN
; CALL-OPEN: call-open.mpir:2:11: error: expected '(' after constraint operation 'isZero' (got '?x')

;--- expression-expected.mpir
%a = add i32 ?x, 1
;; )

;--- ordered-comparison.mpir
%a = add i32 ?x, 1
;; ?x < 1

;--- division.mpir
%a = add i32 ?x, 1
;; ?x / 2 == 1

;--- unknown-variable.mpir
%a = add i32 ?x, 1
;; ?nowhere == 1

;--- wildcard-variable.mpir
%a = add i32 ?x, 1
;; ?_ == 1

;--- unknown-operation.mpir
%a = add i32 ?x, 1
;; nothing(?x)

;--- arity.mpir
%a = add i32 ?x, 1
;; isZero(?x, ?x, ?x)

;--- arity-range.mpir
%a = add i32 ?x, 1
;; udiv(1) == 1

;--- argument.mpir
%a = add i32 ?x, 1
;; isZero())

;--- argument-close.mpir
%a = add i32 ?x, 1
;; isZero(?x

;--- paren-close.mpir
%a = add i32 ?x, 1
;; (true

;--- paren-inner.mpir
%a = add i32 ?x, 1
;; ()

;--- unary-operand.mpir
%a = add i32 ?x, 1
;; !)

;--- unary-sort.mpir
%a = add i32 ?x, 1
;; !"text"

;--- binary-right.mpir
%a = add i32 ?x, 1
;; true && )

;--- binary-sort.mpir
%a = add i32 ?x, 1
;; true && "text"

;--- chained.mpir
%a = add i32 ?x, 1
;; 1 == 1 == 1

;--- array-element.mpir
%a = add i32 ?x, 1
;; [)] == [1]

;--- array-close.mpir
%a = add i32 ?x, 1
;; ["a", "b" == ["a"]

;--- array-mixed.mpir
%a = add i32 ?x, 1
;; ["a", ?x][0] == "a"

;--- index-expression.mpir
%a = add i32 ?x, 1
;; ["a"][)] == "a"

;--- index-close.mpir
%a = add i32 ?x, 1
;; ["a"][0 == "a"

;--- index-of-non-array.mpir
%a = add i32 ?x, 1
;; 1[0] == 1

;--- call-open.mpir
%a = add i32 ?x, 1
;; isZero ?x

