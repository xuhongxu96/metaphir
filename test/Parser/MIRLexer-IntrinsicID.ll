; RUN: %metaphir-lex %s | FileCheck %s

%1 = call i32 @llvm.?id(i32 %x)
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_call
; CHECK-NEXT: Type i32
; CHECK-NEXT: GlobalVar llvm.
; CHECK-NEXT: MetaVar id
; CHECK-NEXT: lparen
; CHECK-NEXT: Type i32
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: rparen
; CHECK-NEXT: Eof
