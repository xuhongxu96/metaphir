; What the parser rejects: operands. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/binary-first.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-FIRST
; RUN: not %metaphir-parse %t/binary-comma.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-COMMA
; RUN: not %metaphir-parse %t/binary-second.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SECOND
; RUN: not %metaphir-parse %t/binary-second-flag.mpir 2>&1 | FileCheck %s --check-prefix=BINARY-SECOND-FLAG
; RUN: not %metaphir-parse %t/operand-value.mpir 2>&1 | FileCheck %s --check-prefix=OPERAND-VALUE
; RUN: not %metaphir-parse %t/cast-source.mpir 2>&1 | FileCheck %s --check-prefix=CAST-SOURCE
; RUN: not %metaphir-parse %t/cast-to.mpir 2>&1 | FileCheck %s --check-prefix=CAST-TO
; RUN: not %metaphir-parse %t/cast-destination.mpir 2>&1 | FileCheck %s --check-prefix=CAST-DESTINATION
; RUN: not %metaphir-parse %t/nary-comma.mpir 2>&1 | FileCheck %s --check-prefix=NARY-COMMA
; RUN: not %metaphir-parse %t/nary-extra.mpir 2>&1 | FileCheck %s --check-prefix=NARY-EXTRA
; RUN: not %metaphir-parse %t/nary-operand.mpir 2>&1 | FileCheck %s --check-prefix=NARY-OPERAND
;--- binary-first.mpir
%a = add ) ?x, 1
; BINARY-FIRST: expected type

;--- binary-comma.mpir
%a = add i32 ?x 1
; BINARY-COMMA: expected ',' between operands (got '1')

;--- binary-second.mpir
%a = add i32 ?x, )
; BINARY-SECOND: expected value

;--- binary-second-flag.mpir
%a = add i32 ?x, ?y:nope
; BINARY-SECOND-FLAG: unknown metaflag ':nope'

;--- operand-value.mpir
%a = add i32 ), 1
; OPERAND-VALUE: expected value

;--- cast-source.mpir
%a = zext ) ?x to i32
; CAST-SOURCE: expected type

;--- cast-to.mpir
%a = zext i8 ?x i32
; CAST-TO: expected 'to' in conversion

;--- cast-destination.mpir
%a = zext i8 ?x to )
; CAST-DESTINATION: expected type

;--- nary-comma.mpir
%a = select i1 ?c i32 ?x, i32 ?y
; NARY-COMMA: expected ',' between operands (got 'i32')

;--- nary-extra.mpir
%a = select i1 ?c, i32 ?x, i32 ?y, i32 ?z
; NARY-EXTRA: 'select' takes 3 operands

;--- nary-operand.mpir
%a = select i1 ?c, ), i32 ?y
; NARY-OPERAND: expected type
