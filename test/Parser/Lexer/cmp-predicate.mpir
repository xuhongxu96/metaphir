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

%2 = icmp eq i32 %x, %y
; CHECK-NEXT: LocalVarID 2
; CHECK-NEXT: equal
; CHECK-NEXT: kw_icmp
; CHECK-NEXT: kw_eq
; CHECK-NEXT: Type i32
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%3 = fcmp oeq float %x, %y
; CHECK-NEXT: LocalVarID 3
; CHECK-NEXT: equal
; CHECK-NEXT: kw_fcmp
; CHECK-NEXT: kw_oeq
; CHECK-NEXT: kw_float
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: Eof
