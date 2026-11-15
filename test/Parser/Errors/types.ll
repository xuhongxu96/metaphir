; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: types. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/type-expected.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-EXPECTED
; TYPE-EXPECTED: type-expected.mpir:1:13: error: expected type
; RUN: not %metaphir-parse %t/type-void.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-VOID
; TYPE-VOID: type-void.mpir:1:13: error: void type is not allowed here
; RUN: not %metaphir-parse %t/type-meta-int-sort.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-META-INT-SORT
; TYPE-META-INT-SORT: type-meta-int-sort.mpir:2:13: error: meta variable '?n' is used with an incompatible type
; RUN: not %metaphir-parse %t/type-meta-sort.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-META-SORT
; TYPE-META-SORT: type-meta-sort.mpir:2:13: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/addrspace-paren.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-PAREN
; ADDRSPACE-PAREN: addrspace-paren.mpir:1:27: error: expected '(' after 'addrspace' (got '3')
; RUN: not %metaphir-parse %t/addrspace-number.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-NUMBER
; ADDRSPACE-NUMBER: addrspace-number.mpir:1:27: error: expected an address space number
; RUN: not %metaphir-parse %t/addrspace-close.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-CLOSE
; ADDRSPACE-CLOSE: addrspace-close.mpir:1:29: error: expected ')' after address space (got '?x')
; RUN: not %metaphir-parse %t/vscale-x.mpir 2>&1 | FileCheck %s --check-prefix=VSCALE-X
; VSCALE-X: vscale-x.mpir:1:21: error: expected 'x' after vscale
; RUN: not %metaphir-parse %t/vector-huge.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-HUGE
; VECTOR-HUGE: vector-huge.mpir:1:14: error: invalid vector size
; RUN: not %metaphir-parse %t/array-huge.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-HUGE
; ARRAY-HUGE: array-huge.mpir:1:14: error: invalid array size
; RUN: not %metaphir-parse %t/vector-size.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-SIZE
; VECTOR-SIZE: vector-size.mpir:1:14: error: expected vector size (got 'x')
; RUN: not %metaphir-parse %t/vector-x.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-X
; VECTOR-X: vector-x.mpir:1:16: error: expected 'x' after vector size
; RUN: not %metaphir-parse %t/vector-element.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-ELEMENT
; VECTOR-ELEMENT: vector-element.mpir:1:18: error: expected type
; RUN: not %metaphir-parse %t/vector-close.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-CLOSE
; VECTOR-CLOSE: vector-close.mpir:1:22: error: expected '>' after vector type (got '?x')
; RUN: not %metaphir-parse %t/array-size.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-SIZE
; ARRAY-SIZE: array-size.mpir:1:14: error: expected array size (got 'x')
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; ARRAY-CLOSE: array-close.mpir:1:22: error: expected ']' after array type (got '?x')
; RUN: not %metaphir-parse %t/struct-element.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-ELEMENT
; STRUCT-ELEMENT: struct-element.mpir:1:19: error: expected type
; RUN: not %metaphir-parse %t/struct-close.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-CLOSE
; STRUCT-CLOSE: struct-close.mpir:1:18: error: expected '}' after struct type (got '?x')
; RUN: not %metaphir-parse %t/packed-struct-close.mpir 2>&1 | FileCheck %s --check-prefix=PACKED-STRUCT-CLOSE
; PACKED-STRUCT-CLOSE: packed-struct-close.mpir:1:20: error: expected '>' after packed struct (got '?x')
; RUN: not %metaphir-parse %t/packed-struct-element.mpir 2>&1 | FileCheck %s --check-prefix=PACKED-STRUCT-ELEMENT
; PACKED-STRUCT-ELEMENT: packed-struct-element.mpir:1:15: error: expected type
; RUN: not %metaphir-parse %t/function-parameter.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-PARAMETER
; FUNCTION-PARAMETER: function-parameter.mpir:1:17: error: expected value
; RUN: not %metaphir-parse %t/function-close.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-CLOSE
; FUNCTION-CLOSE: function-close.mpir:1:20: error: expected ')' after function type (got '?f')
; RUN: not %metaphir-parse %t/function-varargs.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-VARARGS
; FUNCTION-VARARGS: function-varargs.mpir:1:19: error: expected ')' after function type (got ',')
; RUN: not %metaphir-parse %t/count-sort.mpir 2>&1 | FileCheck %s --check-prefix=COUNT-SORT
; COUNT-SORT: count-sort.mpir:2:14: error: meta variable '?t' is used with an incompatible type
; RUN: not %metaphir-parse %t/function-parameter-type.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-PARAMETER-TYPE
; FUNCTION-PARAMETER-TYPE: function-parameter-type.mpir:1:21: error: expected type

;--- type-expected.mpir
%a = freeze 5 ?x

;--- type-void.mpir
%a = freeze void ?x

;--- type-meta-int-sort.mpir
%a = freeze ?n ?x
%b = freeze i?n %a

;--- type-meta-sort.mpir
%a = freeze i32 ?x
%b = freeze ?x %a

;--- addrspace-paren.mpir
%a = freeze ptr addrspace 3 ?x

;--- addrspace-number.mpir
%a = freeze ptr addrspace(?n) ?x

;--- addrspace-close.mpir
%a = freeze ptr addrspace(3 ?x

;--- vscale-x.mpir
%a = freeze <vscale 4 x i32> ?x

;--- vector-huge.mpir
%a = freeze <99999999999999999999 x i32> ?x

;--- array-huge.mpir
%a = freeze [999999999999999999999999 x i32] ?x

;--- vector-size.mpir
%a = freeze <x i32> ?x

;--- vector-x.mpir
%a = freeze <4 i32> ?x

;--- vector-element.mpir
%a = freeze <4 x )> ?x

;--- vector-close.mpir
%a = freeze <4 x i32 ?x

;--- array-size.mpir
%a = freeze [x i32] ?x

;--- array-close.mpir
%a = freeze [4 x i32 ?x

;--- struct-element.mpir
%a = freeze {i32, )} ?x

;--- struct-close.mpir
%a = freeze {i32 ?x

;--- packed-struct-close.mpir
%a = freeze <{i32} ?x

;--- packed-struct-element.mpir
%a = freeze <{)}> ?x

;--- function-parameter.mpir
%a = call i32 ()) ?f()

;--- function-close.mpir
%a = call i32 (i32 ?f()

;--- function-varargs.mpir
%a = call i32 (..., i32) ?f()

;--- count-sort.mpir
%a = freeze ?t ?x
%b = freeze <?t x i32> %a

;--- function-parameter-type.mpir
%a = call i32 (i32, )) ?f()

