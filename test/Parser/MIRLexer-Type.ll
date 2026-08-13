; RUN: %metaphir-lex %s | FileCheck %s

%1 = add ?ty %x, %y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaVar ty
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%2 = add <4 x ?ty2> %x, %y
; CHECK-NEXT: LocalVarID 2
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: less
; CHECK-NEXT: APSInt 4
; CHECK-NEXT: kw_x
; CHECK-NEXT: MetaVar ty2
; CHECK-NEXT: greater
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: Eof
