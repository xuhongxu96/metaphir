; RUN: %metaphir-parse %s | FileCheck %s

?entry:
; CHECK: pattern instructions=3 constraints=0
; CHECK-NEXT: ?entry:

%sum = add i32 ?x, ?y
; CHECK-NEXT: %sum = add i32 ?x, ?y

br label %exit
; CHECK-NEXT: br label ?exit

exit:
; CHECK-NEXT: ?exit:

ret i32 %sum
; CHECK-NEXT: ret i32 %sum
; CHECK-NEXT: meta ?entry type=BasicBlock
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
; CHECK-NEXT: meta ?exit type=BasicBlock
