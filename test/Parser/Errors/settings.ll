; What the parser rejects: settings. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/setting-paren.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-PAREN
; RUN: not %metaphir-parse %t/setting-value.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-VALUE
; RUN: not %metaphir-parse %t/setting-close.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-CLOSE
; RUN: not %metaphir-parse %t/setting-trailing.mpir 2>&1 | FileCheck %s --check-prefix=SETTING-TRAILING
;--- setting-paren.mpir
;; treatIntAsVec true
; SETTING-PAREN: expected '(' after 'treatIntAsVec' (got 'true')

%a = add i32 ?x, 1

;--- setting-value.mpir
;; treatIntAsVec(1)
; SETTING-VALUE: expected 'true' or 'false' in 'treatIntAsVec'

%a = add i32 ?x, 1

;--- setting-close.mpir
;; treatIntAsVec(true
; SETTING-CLOSE: expected ')' after setting value (got end of line)

%a = add i32 ?x, 1

;--- setting-trailing.mpir
;; treatIntAsVec(true) 1
; SETTING-TRAILING: unexpected token after pattern setting

%a = add i32 ?x, 1
