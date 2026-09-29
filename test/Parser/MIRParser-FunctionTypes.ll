; Function types print as LLVM spells them.
; RUN: %metaphir-parse %s | FileCheck %s

%r = call i32 (i32, ...) ?f(i32 ?x)
; CHECK: %r = call i32 (i32, ...) ?f(i32 ?x)

%s = call void () ?g()
; CHECK: %s = call void () ?g()
