; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; Literals the lexer cannot represent are diagnosed rather than truncated,
; wrapped or asserted on.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/value-number.ll 2>&1 | FileCheck %s --check-prefix=VALUE-NUMBER
; RUN: not %metaphir-parse %t/label-number.ll 2>&1 | FileCheck %s --check-prefix=LABEL-NUMBER
; RUN: not %metaphir-parse %t/hex-fp.ll 2>&1 | FileCheck %s --check-prefix=HEX-FP
; RUN: not %metaphir-parse %t/hex-fp-17-digits.ll 2>&1 | FileCheck %s --check-prefix=HEX-FP-17
; RUN: not %metaphir-parse %t/width-wraps.ll 2>&1 | FileCheck %s --check-prefix=WIDTH
; RUN: not %metaphir-parse %t/width-zero-after-wrap.ll 2>&1 | FileCheck %s --check-prefix=WIDTH
; RUN: not %metaphir-parse %t/width-too-large.ll 2>&1 | FileCheck %s --check-prefix=WIDTH
; RUN: %metaphir-parse %t/constraint-int.ll 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-INT
; RUN: %metaphir-parse %t/constraint-uint.ll 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-UINT
; RUN: not %metaphir-parse %t/metaflag-int.ll 2>&1 | FileCheck %s --check-prefix=METAFLAG-INT
; RUN: not %metaphir-parse %t/hex-float-literal.ll 2>&1 | FileCheck %s --check-prefix=HEX-FLOAT-LITERAL
; RUN: not %metaphir-parse %t/ampersand.ll 2>&1 | FileCheck %s --check-prefix=AMPERSAND
; RUN: not %metaphir-parse %t/slash.ll 2>&1 | FileCheck %s --check-prefix=SLASH
; RUN: %metaphir-parse %t/signed-hex.ll | FileCheck %s --check-prefix=SIGNED-HEX
; RUN: %metaphir-parse %t/true.ll | FileCheck %s --check-prefix=TRUE

;--- value-number.ll
%99999999999 = add i32 ?x, ?y
; VALUE-NUMBER: error: value number is too large

;--- label-number.ll
99999999999:
add i32 ?x, ?y
; LABEL-NUMBER: error: value number is too large

;--- hex-fp.ll
fadd double ?x, 0x20000000000000000
; HEX-FP: error: hexadecimal constant is too large

;--- hex-fp-17-digits.ll
fadd double ?x, 0x1FFFFFFFFFFFFFFFF
; HEX-FP-17: error: hexadecimal constant is too large

;--- width-wraps.ll
add i4294967297 ?x, ?y
; WIDTH: error: integer bit width must be between 1 and 8388608

;--- width-zero-after-wrap.ll
add i4294967296 ?x, ?y

;--- width-too-large.ll
add i9000000 ?x, ?y

;--- constraint-int.ll
add i32 ?x, ?y
;; ?x == 9223372036854775808
; Constraint integers are arbitrary precision.
; CONSTRAINT-INT: constraint (== ?x 9223372036854775808)

;--- constraint-uint.ll
add i32 ?x, ?y
;; ?x == 340282366920938463463374607431768211456
; CONSTRAINT-UINT: constraint (== ?x 340282366920938463463374607431768211456)

;--- metaflag-int.ll
add:o(9223372036854775808) i32 ?x, ?y
; METAFLAG-INT: error: metaflag integer argument is too large

;--- hex-float-literal.ll
fadd double ?x, 0x1.8p1
; HEX-FLOAT-LITERAL: error: hexadecimal floating-point literals are not supported

;--- ampersand.ll
add i32 ?x & ?y
; AMPERSAND: error: unexpected character '&'

;--- slash.ll
add i32 ?x / ?y
; SLASH: error: unexpected character '/'

;--- signed-hex.ll
add i8 ?x, s0x7F
; SIGNED-HEX: add i8 ?x, 127

;--- true.ll
add i1 ?x, true
; TRUE: add i1 ?x, 1
