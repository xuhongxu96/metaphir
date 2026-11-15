; What the parser rejects: blocks. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/label-colon.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-COLON
; RUN: not %metaphir-parse %t/label-sort.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-SORT
; RUN: not %metaphir-parse %t/label-trailing.mpir 2>&1 | FileCheck %s --check-prefix=LABEL-TRAILING
; RUN: not %metaphir-parse %t/unused-block.mpir 2>&1 | FileCheck %s --check-prefix=UNUSED-BLOCK
;--- label-colon.mpir
?b
; LABEL-COLON: expected ':' after basic block meta variable (got end of line)

%a = add i32 ?x, 1

;--- label-sort.mpir
%a = add i32 ?x, 1
?x:
; LABEL-SORT: meta variable '?x' is used with an incompatible type

%b = add i32 %a, 1

;--- label-trailing.mpir
?b: 5
; LABEL-TRAILING: unexpected token after basic block label

%a = add i32 ?x, 1

;--- unused-block.mpir
%a = add i32 ?x, 1
?b:
; UNUSED-BLOCK: block '?b' has no instruction, and no instruction refers to it
