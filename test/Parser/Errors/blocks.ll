; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: blocks. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/label-colon.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-COLON
; LABEL-COLON: label-colon.mpir:1:3: error: expected ':' after basic block meta variable (got end of line)
; RUN: not %metaphir-parse %t/label-sort.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-SORT
; LABEL-SORT: label-sort.mpir:2:1: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/label-trailing.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-TRAILING
; LABEL-TRAILING: label-trailing.mpir:1:5: error: unexpected token after basic block label
; RUN: not %metaphir-parse %t/unused-block.mpir 2>&1 | FileCheck %s --check-prefix=UNUSED-BLOCK
; UNUSED-BLOCK: unused-block.mpir:2:1: error: block '?b' has no instruction, and no instruction refers to it

;--- label-colon.mpir
?b
%a = add i32 ?x, 1

;--- label-sort.mpir
%a = add i32 ?x, 1
?x:
%b = add i32 %a, 1

;--- label-trailing.mpir
?b: 5
%a = add i32 ?x, 1

;--- unused-block.mpir
%a = add i32 ?x, 1
?b:

