; Function types print as LLVM spells them.
; RUN: %metaphir-parse %s | FileCheck %s

%r = call i32 (i32, ...) ?f(i32 ?x)
; CHECK: pattern instructions=2 constraints=0
; CHECK-NEXT: %r = call i32 (i32, ...) ?f(i32 ?x)

%s = call void () ?g()
; CHECK-NEXT: %s = call void () ?g()
; CHECK-NEXT: meta ?f type=Function
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?g type=Function
