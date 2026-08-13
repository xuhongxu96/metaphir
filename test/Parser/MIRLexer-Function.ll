; RUN: %metaphir-lex %s | FileCheck %s

%1 = call i32 ?f(i32 %x)
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_call
; CHECK-NEXT: Type i32
; CHECK-NEXT: MetaVar f
; CHECK-NEXT: lparen
; CHECK-NEXT: Type i32
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: rparen
; CHECK-NEXT: Eof
