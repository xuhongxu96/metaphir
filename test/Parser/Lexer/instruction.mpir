; RUN: %metaphir-lex %s | FileCheck %s

%1 = add:?inst nsw i32 %x, %y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaCaptureVar inst
; CHECK-NEXT: kw_nsw
; CHECK-NEXT: Type i32
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: Eof
