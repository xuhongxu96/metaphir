; RUN: %metaphir-lex %s | FileCheck %s

%1 = icmp ?pred i32 %x, %y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_icmp
; CHECK-NEXT: MetaVar pred
; CHECK-NEXT: Type i32
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: Eof
