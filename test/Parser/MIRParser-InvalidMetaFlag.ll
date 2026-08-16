; RUN: not %metaphir-parse %s 2>&1 | FileCheck %s

add i32 ?x:c, ?y
; CHECK: meta flag ':c' is not valid in this position
