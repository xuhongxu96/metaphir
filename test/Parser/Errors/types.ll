; What the parser rejects: types. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/type-expected.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-EXPECTED
; RUN: not %metaphir-parse %t/type-void.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-VOID
; RUN: not %metaphir-parse %t/type-meta-int-sort.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-META-INT-SORT
; RUN: not %metaphir-parse %t/type-meta-sort.mpir 2>&1 | FileCheck %s --check-prefix=TYPE-META-SORT
; RUN: not %metaphir-parse %t/addrspace-paren.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-PAREN
; RUN: not %metaphir-parse %t/addrspace-number.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-NUMBER
; RUN: not %metaphir-parse %t/addrspace-close.mpir 2>&1 | FileCheck %s --check-prefix=ADDRSPACE-CLOSE
; RUN: not %metaphir-parse %t/vscale-x.mpir 2>&1 | FileCheck %s --check-prefix=VSCALE-X
; RUN: not %metaphir-parse %t/vector-huge.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-HUGE
; RUN: not %metaphir-parse %t/array-huge.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-HUGE
; RUN: not %metaphir-parse %t/vector-size.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-SIZE
; RUN: not %metaphir-parse %t/vector-x.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-X
; RUN: not %metaphir-parse %t/vector-element.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-ELEMENT
; RUN: not %metaphir-parse %t/vector-close.mpir 2>&1 | FileCheck %s --check-prefix=VECTOR-CLOSE
; RUN: not %metaphir-parse %t/array-size.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-SIZE
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; RUN: not %metaphir-parse %t/struct-element.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-ELEMENT
; RUN: not %metaphir-parse %t/struct-close.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-CLOSE
; RUN: not %metaphir-parse %t/packed-struct-close.mpir 2>&1 | FileCheck %s --check-prefix=PACKED-STRUCT-CLOSE
; RUN: not %metaphir-parse %t/packed-struct-element.mpir 2>&1 | FileCheck %s --check-prefix=PACKED-STRUCT-ELEMENT
; RUN: not %metaphir-parse %t/function-parameter.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-PARAMETER
; RUN: not %metaphir-parse %t/function-close.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-CLOSE
; RUN: not %metaphir-parse %t/function-varargs.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-VARARGS
; RUN: not %metaphir-parse %t/count-sort.mpir 2>&1 | FileCheck %s --check-prefix=COUNT-SORT
; RUN: not %metaphir-parse %t/function-parameter-type.mpir 2>&1 | FileCheck %s --check-prefix=FUNCTION-PARAMETER-TYPE
;--- type-expected.mpir
%a = freeze 5 ?x
; TYPE-EXPECTED: expected type

;--- type-void.mpir
%a = freeze void ?x
; TYPE-VOID: void type is not allowed here

;--- type-meta-int-sort.mpir
%a = freeze ?n ?x
%b = freeze i?n %a
; TYPE-META-INT-SORT: meta variable '?n' is used with an incompatible type

;--- type-meta-sort.mpir
%a = freeze i32 ?x
%b = freeze ?x %a
; TYPE-META-SORT: meta variable '?x' is used with an incompatible type

;--- addrspace-paren.mpir
%a = freeze ptr addrspace 3 ?x
; ADDRSPACE-PAREN: expected '(' after 'addrspace' (got '3')

;--- addrspace-number.mpir
%a = freeze ptr addrspace(?n) ?x
; ADDRSPACE-NUMBER: expected an address space number

;--- addrspace-close.mpir
%a = freeze ptr addrspace(3 ?x
; ADDRSPACE-CLOSE: expected ')' after address space (got '?x')

;--- vscale-x.mpir
%a = freeze <vscale 4 x i32> ?x
; VSCALE-X: expected 'x' after vscale

;--- vector-huge.mpir
%a = freeze <99999999999999999999 x i32> ?x
; VECTOR-HUGE: invalid vector size

;--- array-huge.mpir
%a = freeze [999999999999999999999999 x i32] ?x
; ARRAY-HUGE: invalid array size

;--- vector-size.mpir
%a = freeze <x i32> ?x
; VECTOR-SIZE: expected vector size (got 'x')

;--- vector-x.mpir
%a = freeze <4 i32> ?x
; VECTOR-X: expected 'x' after vector size

;--- vector-element.mpir
%a = freeze <4 x )> ?x
; VECTOR-ELEMENT: expected type

;--- vector-close.mpir
%a = freeze <4 x i32 ?x
; VECTOR-CLOSE: expected '>' after vector type (got '?x')

;--- array-size.mpir
%a = freeze [x i32] ?x
; ARRAY-SIZE: expected array size (got 'x')

;--- array-close.mpir
%a = freeze [4 x i32 ?x
; ARRAY-CLOSE: expected ']' after array type (got '?x')

;--- struct-element.mpir
%a = freeze {i32, )} ?x
; STRUCT-ELEMENT: expected type

;--- struct-close.mpir
%a = freeze {i32 ?x
; STRUCT-CLOSE: expected '}' after struct type (got '?x')

;--- packed-struct-close.mpir
%a = freeze <{i32} ?x
; PACKED-STRUCT-CLOSE: expected '>' after packed struct (got '?x')

;--- packed-struct-element.mpir
%a = freeze <{)}> ?x
; PACKED-STRUCT-ELEMENT: expected type

;--- function-parameter.mpir
%a = call i32 ()) ?f()
; FUNCTION-PARAMETER: expected value

;--- function-close.mpir
%a = call i32 (i32 ?f()
; FUNCTION-CLOSE: expected ')' after function type (got '?f')

;--- function-varargs.mpir
%a = call i32 (..., i32) ?f()
; FUNCTION-VARARGS: expected ')' after function type (got ',')

;--- count-sort.mpir
%a = freeze ?t ?x
%b = freeze <?t x i32> %a
; COUNT-SORT: meta variable '?t' is used with an incompatible type

;--- function-parameter-type.mpir
%a = call i32 (i32, )) ?f()
; FUNCTION-PARAMETER-TYPE: expected type
