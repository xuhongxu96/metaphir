; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=3 constraints=0

%vec = add <2 x i32> ?x, <i32 1, i32 2>
; CHECK: %vec = add <2 x i32> ?x, <i32 1, i32 2>

%elt = extractelement <2 x i32> %vec, i32 0
; CHECK: %elt = extractelement <2 x i32> %vec, i32 0
; CHECK-NEXT: call ?ret @llvm.?id(i32 %elt, ...?types ?values)
; CHECK-DAG: meta ?x type=Value

call ?ret @llvm.?id(i32 %elt, ...?types ?values)
; CHECK: meta ?ret type=Type
; CHECK-NEXT: meta ?id type=Intrinsic::ID
; CHECK-NEXT: meta ?types type=Type[]
; CHECK-NEXT: meta ?values type=Value[]
