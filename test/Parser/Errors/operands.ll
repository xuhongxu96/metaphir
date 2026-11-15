; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: operands. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/binary-first.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-FIRST
; BINARY-FIRST: binary-first.mpir:1:10: error: expected type
; RUN: not %metaphir-parse %t/binary-comma.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-COMMA
; BINARY-COMMA: binary-comma.mpir:1:17: error: expected ',' between operands (got '1')
; RUN: not %metaphir-parse %t/binary-second.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SECOND
; BINARY-SECOND: binary-second.mpir:1:18: error: expected value
; RUN: not %metaphir-parse %t/binary-second-flag.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SECOND-FLAG
; BINARY-SECOND-FLAG: binary-second-flag.mpir:1:20: error: unknown metaflag ':nope'
; RUN: not %metaphir-parse %t/operand-value.mpir 2>&1 | FileCheck %s --check-prefix=OPERAND-VALUE
; OPERAND-VALUE: operand-value.mpir:1:14: error: expected value
; RUN: not %metaphir-parse %t/cast-source.mpir 2>&1 | FileCheck %s --check-prefix=CAST-SOURCE
; CAST-SOURCE: cast-source.mpir:1:11: error: expected type
; RUN: not %metaphir-parse %t/cast-to.mpir 2>&1 | FileCheck %s --check-prefix=CAST-TO
; CAST-TO: cast-to.mpir:1:17: error: expected 'to' in conversion
; RUN: not %metaphir-parse %t/cast-destination.mpir 2>&1 | FileCheck %s --check-prefix=CAST-DESTINATION
; CAST-DESTINATION: cast-destination.mpir:1:20: error: expected type
; RUN: not %metaphir-parse %t/nary-comma.mpir 2>&1 | FileCheck %s --check-prefix=NARY-COMMA
; NARY-COMMA: nary-comma.mpir:1:19: error: expected ',' between operands (got 'i32')
; RUN: not %metaphir-parse %t/nary-extra.mpir 2>&1 | FileCheck %s --check-prefix=NARY-EXTRA
; NARY-EXTRA: nary-extra.mpir:1:34: error: 'select' takes 3 operands
; RUN: not %metaphir-parse %t/nary-operand.mpir 2>&1 | FileCheck %s --check-prefix=NARY-OPERAND
; NARY-OPERAND: nary-operand.mpir:1:20: error: expected type

;--- binary-first.mpir
%a = add ) ?x, 1

;--- binary-comma.mpir
%a = add i32 ?x 1

;--- binary-second.mpir
%a = add i32 ?x, )

;--- binary-second-flag.mpir
%a = add i32 ?x, ?y:nope

;--- operand-value.mpir
%a = add i32 ), 1

;--- cast-source.mpir
%a = zext ) ?x to i32

;--- cast-to.mpir
%a = zext i8 ?x i32

;--- cast-destination.mpir
%a = zext i8 ?x to )

;--- nary-comma.mpir
%a = select i1 ?c i32 ?x, i32 ?y

;--- nary-extra.mpir
%a = select i1 ?c, i32 ?x, i32 ?y, i32 ?z

;--- nary-operand.mpir
%a = select i1 ?c, ), i32 ?y

