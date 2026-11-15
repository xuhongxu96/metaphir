; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=3 constraints=0
; CHECK-NEXT: ?entry:

?entry:

%sum = add i32 ?x, ?y
; CHECK: %sum = add i32 ?x, ?y
; CHECK-NEXT: br label ?exit
; CHECK-NEXT: ?exit:
; CHECK-NEXT: ret i32 %sum
; CHECK-DAG: meta ?entry type=BasicBlock
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
; CHECK-NEXT: meta ?exit type=BasicBlock

br label %exit

exit:

ret i32 %sum
