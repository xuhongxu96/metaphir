; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the lexer rejects. Each case is a file of its own; the tokens before
; the error are printed first.
; RUN: split-file %s %t
; RUN: not %metaphir-lex %t/unexpected-hash.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-HASH
; UNEXPECTED-HASH: unexpected-hash.mpir:1:5: error: unexpected character '#'
; RUN: not %metaphir-lex %t/unexpected-dot.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-DOT
; UNEXPECTED-DOT: unexpected-dot.mpir:1:5: error: unexpected character '.'
; RUN: not %metaphir-lex %t/unexpected-pipe.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-PIPE
; UNEXPECTED-PIPE: unexpected-pipe.mpir:1:5: error: unexpected character '|'
; RUN: not %metaphir-lex %t/unexpected-ampersand.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-AMPERSAND
; UNEXPECTED-AMPERSAND: unexpected-ampersand.mpir:1:5: error: unexpected character '&'
; RUN: not %metaphir-lex %t/unexpected-slash.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-SLASH
; UNEXPECTED-SLASH: unexpected-slash.mpir:1:5: error: unexpected character '/'
; RUN: not %metaphir-lex %t/unexpected-dollar.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-DOLLAR
; UNEXPECTED-DOLLAR: unexpected-dollar.mpir:1:5: error: unexpected character '$'
; RUN: not %metaphir-lex %t/unexpected-minus.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-MINUS
; UNEXPECTED-MINUS: unexpected-minus.mpir:1:5: error: unexpected character '-'
; RUN: not %metaphir-lex %t/unexpected-plus.mpir 2>&1 | FileCheck %s --check-prefix=UNEXPECTED-PLUS
; UNEXPECTED-PLUS: unexpected-plus.mpir:1:5: error: unexpected character '+'
; RUN: not %metaphir-lex %t/plus-integer.mpir 2>&1 | FileCheck %s --check-prefix=PLUS-INTEGER
; PLUS-INTEGER: plus-integer.mpir:1:5: error: unexpected character '+'
; RUN: not %metaphir-lex %t/unterminated-comment.mpir 2>&1 | FileCheck %s --check-prefix=UNTERMINATED-COMMENT
; UNTERMINATED-COMMENT: unterminated-comment.mpir:1:5: error: unterminated comment
; RUN: not %metaphir-lex %t/unterminated-comment-star.mpir 2>&1 | FileCheck %s --check-prefix=UNTERMINATED-COMMENT-STAR
; UNTERMINATED-COMMENT-STAR: unterminated-comment-star.mpir:1:5: error: unterminated comment
; RUN: not %metaphir-lex %t/percent-alone.mpir 2>&1 | FileCheck %s --check-prefix=PERCENT-ALONE
; PERCENT-ALONE: percent-alone.mpir:1:5: error: expected a name or a number after '%'
; RUN: not %metaphir-lex %t/at-alone.mpir 2>&1 | FileCheck %s --check-prefix=AT-ALONE
; AT-ALONE: at-alone.mpir:1:5: error: expected a name or a number after '@'
; RUN: not %metaphir-lex %t/value-number-large.mpir 2>&1 | FileCheck %s --check-prefix=VALUE-NUMBER-LARGE
; VALUE-NUMBER-LARGE: value-number-large.mpir:1:5: error: value number is too large
; RUN: not %metaphir-lex %t/label-number-large.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-NUMBER-LARGE
; LABEL-NUMBER-LARGE: label-number-large.mpir:1:1: error: value number is too large
; RUN: not %metaphir-lex %t/global-unterminated.mpir 2>&1 | FileCheck %s --check-prefix=GLOBAL-UNTERMINATED
; GLOBAL-UNTERMINATED: global-unterminated.mpir:1:5: error: end of file in global variable name
; RUN: not %metaphir-lex %t/global-nul.mpir 2>&1 | FileCheck %s --check-prefix=GLOBAL-NUL
; GLOBAL-NUL: global-nul.mpir:1:5: error: NUL character is not allowed in names
; RUN: not %metaphir-lex %t/label-nul.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-NUL
; LABEL-NUL: label-nul.mpir:1:1: error: NUL character is not allowed in names
; RUN: not %metaphir-lex %t/string-unterminated.mpir 2>&1 | FileCheck %s --check-prefix=STRING-UNTERMINATED
; STRING-UNTERMINATED: string-unterminated.mpir:1:5: error: end of file in string constant
; RUN: not %metaphir-lex %t/meta-int-name.mpir 2>&1 | FileCheck %s --check-prefix=META-INT-NAME
; META-INT-NAME: meta-int-name.mpir:1:5: error: invalid meta variable name for integer type
; RUN: not %metaphir-lex %t/hex-integer.mpir 2>&1 | FileCheck %s --check-prefix=HEX-INTEGER
; HEX-INTEGER: hex-integer.mpir:1:5: error: invalid hexadecimal integer constant
; RUN: not %metaphir-lex %t/hex-float-kind.mpir 2>&1 | FileCheck %s --check-prefix=HEX-FLOAT-KIND
; HEX-FLOAT-KIND: hex-float-kind.mpir:1:5: error: 0xK floating-point constants are not supported
; RUN: not %metaphir-lex %t/hex-float-digits.mpir 2>&1 | FileCheck %s --check-prefix=HEX-FLOAT-DIGITS
; HEX-FLOAT-DIGITS: hex-float-digits.mpir:1:5: error: expected hexadecimal digits after '0x'
; RUN: not %metaphir-lex %t/hex-float-point.mpir 2>&1 | FileCheck %s --check-prefix=HEX-FLOAT-POINT
; HEX-FLOAT-POINT: hex-float-point.mpir:1:5: error: hexadecimal floating-point literals are not supported; write the IEEE bit pattern as 0x<hex digits>
; RUN: not %metaphir-lex %t/hex-float-large.mpir 2>&1 | FileCheck %s --check-prefix=HEX-FLOAT-LARGE
; HEX-FLOAT-LARGE: hex-float-large.mpir:1:5: error: hexadecimal constant is too large (more than 64 bits)
; RUN: not %metaphir-lex %t/meta-variable-name.mpir 2>&1 | FileCheck %s --check-prefix=META-VARIABLE-NAME
; META-VARIABLE-NAME: meta-variable-name.mpir:1:5: error: invalid meta variable name
; RUN: not %metaphir-lex %t/meta-capture-name.mpir 2>&1 | FileCheck %s --check-prefix=META-CAPTURE-NAME
; META-CAPTURE-NAME: meta-capture-name.mpir:1:4: error: invalid meta capture variable name
; RUN: not %metaphir-lex %t/integer-width.mpir 2>&1 | FileCheck %s --check-prefix=INTEGER-WIDTH
; INTEGER-WIDTH: integer-width.mpir:1:5: error: integer bit width must be between 1 and 8388608
; RUN: not %metaphir-lex %t/byte-width.mpir 2>&1 | FileCheck %s --check-prefix=BYTE-WIDTH
; BYTE-WIDTH: byte-width.mpir:1:5: error: byte bit width must be between 1 and 8388608
; RUN: not %metaphir-lex %t/constraint-hash.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-HASH
; CONSTRAINT-HASH: constraint-hash.mpir:1:4: error: unexpected character '#'
; RUN: not %metaphir-lex %t/constraint-ampersand.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-AMPERSAND
; CONSTRAINT-AMPERSAND: constraint-ampersand.mpir:1:6: error: unexpected character '&'
; RUN: not %metaphir-lex %t/constraint-pipe.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-PIPE
; CONSTRAINT-PIPE: constraint-pipe.mpir:1:6: error: unexpected character '|'
; RUN: not %metaphir-lex %t/constraint-string.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-STRING
; CONSTRAINT-STRING: constraint-string.mpir:1:4: error: end of file in string constant
; RUN: not %metaphir-lex %t/constraint-question.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-QUESTION
; CONSTRAINT-QUESTION: constraint-question.mpir:1:4: error: invalid meta variable name
; RUN: not %metaphir-lex %t/identifier-dot.mpir 2>&1 | FileCheck %s --check-prefix=IDENTIFIER-DOT
; IDENTIFIER-DOT: identifier-dot.mpir:1:11: error: unexpected character '.'

;--- unexpected-hash.mpir
add #

;--- unexpected-dot.mpir
add . x

;--- unexpected-pipe.mpir
add | x

;--- unexpected-ampersand.mpir
add & x

;--- unexpected-slash.mpir
add / x

;--- unexpected-dollar.mpir
add $x

;--- unexpected-minus.mpir
add - x

;--- unexpected-plus.mpir
add + x

;--- plus-integer.mpir
add +1 x

;--- unterminated-comment.mpir
add /* never closed

;--- unterminated-comment-star.mpir
add /* never closed *

;--- percent-alone.mpir
add % x

;--- at-alone.mpir
add @ x

;--- value-number-large.mpir
add %99999999999999999999

;--- label-number-large.mpir
99999999999999999999:

;--- global-unterminated.mpir
add @"never closed

;--- global-nul.mpir
add @"a\00b"

;--- label-nul.mpir
"a\00b":

;--- string-unterminated.mpir
add "never closed

;--- meta-int-name.mpir
add i? x

;--- hex-integer.mpir
add u0xFz

;--- hex-float-kind.mpir
add 0xK0123

;--- hex-float-digits.mpir
add 0xZ

;--- hex-float-point.mpir
add 0x1.8

;--- hex-float-large.mpir
add 0x11111111111111111

;--- meta-variable-name.mpir
add ? x

;--- meta-capture-name.mpir
add:? x

;--- integer-width.mpir
add i0 x

;--- byte-width.mpir
add b99999999 x

;--- constraint-hash.mpir
;; #

;--- constraint-ampersand.mpir
;; a & b

;--- constraint-pipe.mpir
;; a | b

;--- constraint-string.mpir
;; "never closed

;--- constraint-question.mpir
;; ? x

;--- identifier-dot.mpir
add dotted.name

