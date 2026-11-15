; Function types print as LLVM spells them.
; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=2 constraints=0

%r = call i32 (i32, ...) ?f(i32 ?x)
; CHECK: %r = call i32 (i32, ...) ?f(i32 ?x)

%s = call void () ?g()
; CHECK: %s = call void () ?g()
; CHECK-DAG: meta ?f type=Function
; CHECK-DAG: meta ?x type=Value
; CHECK-NEXT: meta ?g type=Function
