; RUN: not %metaphir-parse %s 2>&1 | FileCheck %s

add i32 %undefined, ?x
; CHECK: undefined or forward local reference '%undefined'
