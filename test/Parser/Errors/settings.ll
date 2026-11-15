; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: settings. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/setting-paren.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-PAREN
; SETTING-PAREN: setting-paren.mpir:1:18: error: expected '(' after 'treatIntAsVec' (got 'true')
; RUN: not %metaphir-parse %t/setting-value.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-VALUE
; SETTING-VALUE: setting-value.mpir:1:18: error: expected 'true' or 'false' in 'treatIntAsVec'
; RUN: not %metaphir-parse %t/setting-close.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-CLOSE
; SETTING-CLOSE: setting-close.mpir:1:22: error: expected ')' after setting value (got end of line)
; RUN: not %metaphir-parse %t/setting-trailing.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-TRAILING
; SETTING-TRAILING: setting-trailing.mpir:1:24: error: unexpected token after pattern setting

;--- setting-paren.mpir
;; treatIntAsVec true
%a = add i32 ?x, 1

;--- setting-value.mpir
;; treatIntAsVec(1)
%a = add i32 ?x, 1

;--- setting-close.mpir
;; treatIntAsVec(true
%a = add i32 ?x, 1

;--- setting-trailing.mpir
;; treatIntAsVec(true) 1
%a = add i32 ?x, 1

