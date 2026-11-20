; What the parser rejects: constraints. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/expression-expected.mpir 2>&1 | FileCheck %s --check-prefix=EXPRESSION-EXPECTED
; RUN: not %metaphir-parse %t/ordered-comparison.mpir 2>&1 | FileCheck %s --check-prefix=ORDERED-COMPARISON
; RUN: not %metaphir-parse %t/division.mpir 2>&1 | FileCheck %s --check-prefix=DIVISION
; RUN: not %metaphir-parse %t/unknown-variable.mpir 2>&1 | FileCheck %s --check-prefix=UNKNOWN-VARIABLE
; RUN: not %metaphir-parse %t/wildcard-variable.mpir 2>&1 | FileCheck %s --check-prefix=WILDCARD-VARIABLE
; RUN: not %metaphir-parse %t/unknown-operation.mpir 2>&1 | FileCheck %s --check-prefix=UNKNOWN-OPERATION
; RUN: not %metaphir-parse %t/arity.mpir 2>&1 | FileCheck %s --check-prefix=ARITY
; RUN: not %metaphir-parse %t/arity-range.mpir 2>&1 | FileCheck %s --check-prefix=ARITY-RANGE
; RUN: not %metaphir-parse %t/argument.mpir 2>&1 | FileCheck %s --check-prefix=ARGUMENT
; RUN: not %metaphir-parse %t/argument-close.mpir 2>&1 | FileCheck %s --check-prefix=ARGUMENT-CLOSE
; RUN: not %metaphir-parse %t/paren-close.mpir 2>&1 | FileCheck %s --check-prefix=PAREN-CLOSE
; RUN: not %metaphir-parse %t/paren-inner.mpir 2>&1 | FileCheck %s --check-prefix=PAREN-INNER
; RUN: not %metaphir-parse %t/unary-operand.mpir 2>&1 | FileCheck %s --check-prefix=UNARY-OPERAND
; RUN: not %metaphir-parse %t/unary-sort.mpir 2>&1 | FileCheck %s --check-prefix=UNARY-SORT
; RUN: not %metaphir-parse %t/binary-right.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-RIGHT
; RUN: not %metaphir-parse %t/binary-sort.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SORT
; RUN: not %metaphir-parse %t/chained.mpir 2>&1 | FileCheck %s --check-prefix=CHAINED
; RUN: not %metaphir-parse %t/array-element.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-ELEMENT
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; RUN: not %metaphir-parse %t/array-mixed.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-MIXED
; RUN: not %metaphir-parse %t/index-expression.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-EXPRESSION
; RUN: not %metaphir-parse %t/index-close.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-CLOSE
; RUN: not %metaphir-parse %t/index-of-non-array.mpir 2>&1 | FileCheck %s --check-prefix=INDEX-OF-NON-ARRAY
; RUN: not %metaphir-parse %t/call-open.mpir 2>&1 | FileCheck %s --check-prefix=CALL-OPEN
;--- expression-expected.mpir
%a = add i32 ?x, 1
;; )
; EXPRESSION-EXPECTED: expected constraint expression

;--- ordered-comparison.mpir
%a = add i32 ?x, 1
;; ?x < 1
; ORDERED-COMPARISON: use slt/ult/sle/ule/sgt/ugt/sge/uge for ordered comparisons

;--- division.mpir
%a = add i32 ?x, 1
;; ?x / 2 == 1
; DIVISION: use sdiv/udiv/srem/urem for signed or unsigned arithmetic

;--- unknown-variable.mpir
%a = add i32 ?x, 1
;; ?nowhere == 1
; UNKNOWN-VARIABLE: constraint references unknown meta variable '?nowhere'

;--- wildcard-variable.mpir
%a = add i32 ?x, 1
;; ?_ == 1
; WILDCARD-VARIABLE: a constraint cannot refer to '?_', which stands for a different value each time; name the variable

;--- unknown-operation.mpir
%a = add i32 ?x, 1
;; nothing(?x)
; UNKNOWN-OPERATION: unknown constraint operation 'nothing'

;--- arity.mpir
%a = add i32 ?x, 1
;; isZero(?x, ?x, ?x)
; ARITY: constraint operation 'isZero' expects 1 argument, got 3

;--- arity-range.mpir
%a = add i32 ?x, 1
;; udiv(1) == 1
; ARITY-RANGE: constraint operation 'udiv' expects 2 to 3 arguments, got 1

;--- argument.mpir
%a = add i32 ?x, 1
;; isZero())
; ARGUMENT: constraint operation 'isZero' expects 1 argument, got 0

;--- argument-close.mpir
%a = add i32 ?x, 1
;; isZero(?x
; ARGUMENT-CLOSE: expected ')' after constraint arguments (got end of line)

;--- paren-close.mpir
%a = add i32 ?x, 1
;; (true
; PAREN-CLOSE: expected ')' in constraint (got end of line)

;--- paren-inner.mpir
%a = add i32 ?x, 1
;; ()
; PAREN-INNER: expected constraint expression

;--- unary-operand.mpir
%a = add i32 ?x, 1
;; !)
; UNARY-OPERAND: expected constraint expression

;--- unary-sort.mpir
%a = add i32 ?x, 1
;; !"text"
; UNARY-SORT: operand of '!' must be a boolean

;--- binary-right.mpir
%a = add i32 ?x, 1
;; true && )
; BINARY-RIGHT: expected constraint expression

;--- binary-sort.mpir
%a = add i32 ?x, 1
;; true && "text"
; BINARY-SORT: operand of '&&' must be a boolean

;--- chained.mpir
%a = add i32 ?x, 1
;; 1 == 1 == 1
; CHAINED: comparisons cannot be chained; add parentheses

;--- array-element.mpir
%a = add i32 ?x, 1
;; [)] == [1]
; ARRAY-ELEMENT: expected constraint expression

;--- array-close.mpir
%a = add i32 ?x, 1
;; ["a", "b" == ["a"]
; ARRAY-CLOSE: expected ']' after array literal (got end of line)

;--- array-mixed.mpir
%a = add i32 ?x, 1
;; ["a", ?x][0] == "a"
; ARRAY-MIXED: constraint array literal elements must have the same type

;--- index-expression.mpir
%a = add i32 ?x, 1
;; ["a"][)] == "a"
; INDEX-EXPRESSION: expected constraint expression

;--- index-close.mpir
%a = add i32 ?x, 1
;; ["a"][0 == "a"
; INDEX-CLOSE: expected ']' after array index (got end of line)

;--- index-of-non-array.mpir
%a = add i32 ?x, 1
;; 1[0] == 1
; INDEX-OF-NON-ARRAY: constraint subscript requires an array operand

;--- call-open.mpir
%a = add i32 ?x, 1
;; isZero ?x
; CALL-OPEN: expected '(' after constraint operation 'isZero' (got '?x')
