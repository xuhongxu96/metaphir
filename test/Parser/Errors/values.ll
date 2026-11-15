; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: values. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/value-expected.mpir 2>&1 | FileCheck %s --check-prefix=VALUE-EXPECTED
; VALUE-EXPECTED: value-expected.mpir:1:14: error: expected value
; RUN: not %metaphir-parse %t/local-undefined.mpir 2>&1 | FileCheck %s --check-prefix=LOCAL-UNDEFINED
; LOCAL-UNDEFINED: local-undefined.mpir:1:14: error: undefined or forward local reference '%nowhere'
; RUN: not %metaphir-parse %t/intrinsic-id.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID
; INTRINSIC-ID: intrinsic-id.mpir:1:21: error: invalid meta variable name
; RUN: not %metaphir-parse %t/intrinsic-id-sort.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID-SORT
; INTRINSIC-ID-SORT: intrinsic-id-sort.mpir:1:28: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/aggregate-type.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-TYPE
; AGGREGATE-TYPE: aggregate-type.mpir:1:24: error: expected type
; RUN: not %metaphir-parse %t/aggregate-value.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-VALUE
; AGGREGATE-VALUE: aggregate-value.mpir:1:28: error: expected value
; RUN: not %metaphir-parse %t/aggregate-close.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-CLOSE
; AGGREGATE-CLOSE: aggregate-close.mpir:1:36: error: expected end of aggregate constant (got end of line)
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; ARRAY-CLOSE: array-close.mpir:1:36: error: expected end of aggregate constant (got end of line)
; RUN: not %metaphir-parse %t/struct-close.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-CLOSE
; STRUCT-CLOSE: struct-close.mpir:1:25: error: expected end of aggregate constant (got end of line)
; RUN: not %metaphir-parse %t/block-local-sort.mpir 2>&1 | FileCheck %s --check-prefix=BLOCK-LOCAL-SORT
; BLOCK-LOCAL-SORT: block-local-sort.mpir:2:10: error: meta variable '?n' is used with an incompatible type
; RUN: not %metaphir-parse %t/intrinsic-id-earlier-sort.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID-EARLIER-SORT
; INTRINSIC-ID-EARLIER-SORT: intrinsic-id-earlier-sort.mpir:2:21: error: meta variable '?n' is used with an incompatible type

;--- value-expected.mpir
%a = add i32 =, 1

;--- local-undefined.mpir
%a = add i32 %nowhere, 1

;--- intrinsic-id.mpir
%a = call i32 @llvm.?(i32 ?x)

;--- intrinsic-id-sort.mpir
%a = call i32 @llvm.?x(i32 ?x)

;--- aggregate-type.mpir
%a = freeze <2 x i32> <), i32 1>

;--- aggregate-value.mpir
%a = freeze <2 x i32> <i32 ), i32 1>

;--- aggregate-close.mpir
%a = freeze <2 x i32> <i32 1, i32 2

;--- array-close.mpir
%a = freeze [2 x i32] [i32 1, i32 2

;--- struct-close.mpir
%a = freeze {i32} {i32 1

;--- block-local-sort.mpir
%a = add i?n ?x, 1
br label %n

;--- intrinsic-id-earlier-sort.mpir
%a = add i?n ?x, 1
%b = call i32 @llvm.?n(i32 %a)

