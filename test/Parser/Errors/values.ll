; What the parser rejects: values. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/value-expected.mpir 2>&1 | FileCheck %s --check-prefix=VALUE-EXPECTED
; RUN: not %metaphir-parse %t/local-undefined.mpir 2>&1 | FileCheck %s --check-prefix=LOCAL-UNDEFINED
; RUN: not %metaphir-parse %t/intrinsic-id.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID
; RUN: not %metaphir-parse %t/intrinsic-id-sort.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID-SORT
; RUN: not %metaphir-parse %t/aggregate-type.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-TYPE
; RUN: not %metaphir-parse %t/aggregate-value.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-VALUE
; RUN: not %metaphir-parse %t/aggregate-close.mpir 2>&1 | FileCheck %s --check-prefix=AGGREGATE-CLOSE
; RUN: not %metaphir-parse %t/array-close.mpir 2>&1 | FileCheck %s --check-prefix=ARRAY-CLOSE
; RUN: not %metaphir-parse %t/struct-close.mpir 2>&1 | FileCheck %s --check-prefix=STRUCT-CLOSE
; RUN: not %metaphir-parse %t/block-local-sort.mpir 2>&1 | FileCheck %s --check-prefix=BLOCK-LOCAL-SORT
; RUN: not %metaphir-parse %t/intrinsic-id-earlier-sort.mpir 2>&1 | FileCheck %s --check-prefix=INTRINSIC-ID-EARLIER-SORT
;--- value-expected.mpir
%a = add i32 =, 1
; VALUE-EXPECTED: expected value

;--- local-undefined.mpir
%a = add i32 %nowhere, 1
; LOCAL-UNDEFINED: undefined or forward local reference '%nowhere'

;--- intrinsic-id.mpir
%a = call i32 @llvm.?(i32 ?x)
; INTRINSIC-ID: invalid meta variable name

;--- intrinsic-id-sort.mpir
%a = call i32 @llvm.?x(i32 ?x)
; INTRINSIC-ID-SORT: meta variable '?x' is used with an incompatible type

;--- aggregate-type.mpir
%a = freeze <2 x i32> <), i32 1>
; AGGREGATE-TYPE: expected type

;--- aggregate-value.mpir
%a = freeze <2 x i32> <i32 ), i32 1>
; AGGREGATE-VALUE: expected value

;--- aggregate-close.mpir
%a = freeze <2 x i32> <i32 1, i32 2
; AGGREGATE-CLOSE: expected end of aggregate constant (got end of line)

;--- array-close.mpir
%a = freeze [2 x i32] [i32 1, i32 2
; ARRAY-CLOSE: expected end of aggregate constant (got end of line)

;--- struct-close.mpir
%a = freeze {i32} {i32 1
; STRUCT-CLOSE: expected end of aggregate constant (got end of line)

;--- block-local-sort.mpir
%a = add i?n ?x, 1
br label %n
; BLOCK-LOCAL-SORT: meta variable '?n' is used with an incompatible type

;--- intrinsic-id-earlier-sort.mpir
%a = add i?n ?x, 1
%b = call i32 @llvm.?n(i32 %a)
; INTRINSIC-ID-EARLIER-SORT: meta variable '?n' is used with an incompatible type
