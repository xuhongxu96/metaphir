; RUN: %metaphir-parse %s | FileCheck %s

%vec = add <2 x i32> ?x, <i32 1, i32 2>
; CHECK: pattern instructions=3 constraints=0
; CHECK-NEXT: %vec = add <2 x i32> ?x, <i32 1, i32 2>

%elt = extractelement <2 x i32> %vec, i32 0
; CHECK-NEXT: %elt = extractelement <2 x i32> %vec, i32 0

call ?ret @llvm.?id(i32 %elt, ...?types ?values)
; CHECK-NEXT: call ?ret @llvm.?id(i32 %elt, ...?types ?values)
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?ret type=Type
; CHECK-NEXT: meta ?id type=Intrinsic::ID
; CHECK-NEXT: meta ?types type=Type[]
; CHECK-NEXT: meta ?values type=Value[]
