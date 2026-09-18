; RUN: %metaphir-lex %s | FileCheck %s

%1 = add:?instr i?bits %x, ?y:apInt
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaCaptureVar instr
; CHECK-NEXT: MetaIntVar bits
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar y
; CHECK-NEXT: MetaFlag apInt
; CHECK-NEXT: Eof
