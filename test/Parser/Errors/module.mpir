; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: module. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/missing-file.mpir 2>&1 | FileCheck %s --check-prefix=MISSING-FILE
; MISSING-FILE: missing-file.mpir: error: cannot read file: {{.*}}
; RUN: not %metaphir-parse %t/empty.mpir 2>&1 | FileCheck %s --check-prefix=EMPTY
; EMPTY: empty.mpir:3:1: error: expected at least one instruction matcher
; RUN: not %metaphir-parse %t/unnamed-middle.mpir 2>&1 | FileCheck %s --check-prefix=UNNAMED-MIDDLE
; UNNAMED-MIDDLE: unnamed-middle.mpir:2:1: error: only the final instruction may omit a result assignment
; RUN: not %metaphir-parse %t/after-instruction.mpir 2>&1 | FileCheck %s --check-prefix=AFTER-INSTRUCTION
; AFTER-INSTRUCTION: after-instruction.mpir:1:20: error: unexpected token after instruction
; RUN: not %metaphir-parse %t/after-constraint.mpir 2>&1 | FileCheck %s --check-prefix=AFTER-CONSTRAINT
; AFTER-CONSTRAINT: after-constraint.mpir:2:9: error: unexpected token after constraint
; RUN: not %metaphir-parse %t/non-boolean.mpir 2>&1 | FileCheck %s --check-prefix=NON-BOOLEAN
; NON-BOOLEAN: non-boolean.mpir:2:6: error: constraint must have a boolean result
; RUN: not %metaphir-parse %t/lexer-error.mpir 2>&1 | FileCheck %s --check-prefix=LEXER-ERROR
; LEXER-ERROR: lexer-error.mpir:2:1: error: end of file in string constant

;--- empty.mpir
; nothing here

;--- unnamed-middle.mpir
add i32 ?x, 1
%b = add i32 ?y, 1

;--- after-instruction.mpir
%a = add i32 ?x, 1 2

;--- after-constraint.mpir
%a = add i32 ?x, 1
;; true false

;--- non-boolean.mpir
%a = add i32 ?x, 1
;; 1 + 2

;--- lexer-error.mpir
%a = add i32 ?x, 1
"unterminated

