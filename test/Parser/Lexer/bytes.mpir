; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; Bytes a test file cannot hold as text: carriage returns end lines (in
; pattern and in constraint lines), a NUL inside the file is white space,
; and a control character is named by its code.
; RUN: printf 'add\r\nsub\rmul \000 xor\n;; a\r\n;; b\r' > %t.mpir
; RUN: %metaphir-lex --line-numbers %t.mpir | FileCheck %s
; RUN: printf 'add \001' > %t.control.mpir
; RUN: not %metaphir-lex %t.control.mpir 2>&1 | FileCheck %s --check-prefix=CONTROL
; A comment the file ends in, right after a star.
; RUN: printf 'add /* x *' > %t.comment.mpir
; RUN: not %metaphir-lex %t.comment.mpir 2>&1 | FileCheck %s --check-prefix=COMMENT

; CHECK:      1: kw_add
; CHECK-NEXT: 2: kw_sub
; CHECK-NEXT: 2: kw_mul
; CHECK-NEXT: 2: kw_xor
; CHECK-NEXT: 3: ConstraintMarker
; CHECK-NEXT: 3: Identifier a
; CHECK-NEXT: 4: ConstraintMarker
; CHECK-NEXT: 4: Identifier b
; CHECK-NEXT: 4: Eof

; CONTROL: error: unexpected character '\x01'
; COMMENT: error: unterminated comment
