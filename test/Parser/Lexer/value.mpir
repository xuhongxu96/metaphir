; RUN: %metaphir-lex %s | FileCheck %s

%1 = add i8 ?x, ?y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: Type i8
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar y
; CHECK-NEXT: Eof
