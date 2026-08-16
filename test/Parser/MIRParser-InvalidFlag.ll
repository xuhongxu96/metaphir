; RUN: not %metaphir-parse %s 2>&1 | FileCheck %s

add exact i32 ?x, ?y
; CHECK: flag 'exact' is not valid for 'add'
