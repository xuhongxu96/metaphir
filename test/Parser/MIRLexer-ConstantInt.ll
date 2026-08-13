; RUN: %metaphir-lex %s | FileCheck %s

%1 = add i?bits %x, %y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaIntVar bits
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%2 = add <?n x b32> %x, %y
; CHECK-NEXT: LocalVarID 2
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: less
; CHECK-NEXT: MetaVar n
; CHECK-NEXT: kw_x
; CHECK-NEXT: Type b32
; CHECK-NEXT: greater
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%3 = add <4 x b?bits> %x, %y
; CHECK-NEXT: LocalVarID 3
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: less
; CHECK-NEXT: APSInt 4
; CHECK-NEXT: kw_x
; CHECK-NEXT: MetaIntVar bits
; CHECK-NEXT: greater
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: Eof
