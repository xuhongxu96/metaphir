; RUN: %metaphir-lex %s | FileCheck %s

%r = fadd float +1.5, -2.0
;; ?n + 2 * 3 == 7 && !false || sdiv(?n, -2) != 0 || ?values[?n] == ?x || isa(?x, "BinaryOperator")
; CHECK: LocalVar r
; CHECK-NEXT: equal
; CHECK-NEXT: kw_fadd
; CHECK-NEXT: kw_float
; CHECK-NEXT: APFloat 1.5
; CHECK-NEXT: comma
; CHECK-NEXT: APFloat -2
; CHECK-NEXT: ConstraintMarker
; CHECK-NEXT: MetaVar n
; CHECK-NEXT: plus
; CHECK-NEXT: APSInt 2
; CHECK-NEXT: star
; CHECK-NEXT: APSInt 3
; CHECK-NEXT: equalequal
; CHECK-NEXT: APSInt 7
; CHECK-NEXT: ampamp
; CHECK-NEXT: exclaim
; CHECK-NEXT: kw_false
; CHECK-NEXT: barbar
; CHECK-NEXT: Identifier sdiv
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar n
; CHECK-NEXT: comma
; CHECK-NEXT: minus
; CHECK-NEXT: APSInt 2
; CHECK-NEXT: rparen
; CHECK-NEXT: notequal
; CHECK-NEXT: APSInt 0
; CHECK-NEXT: barbar
; CHECK-NEXT: MetaVar values
; CHECK-NEXT: lsquare
; CHECK-NEXT: MetaVar n
; CHECK-NEXT: rsquare
; CHECK-NEXT: equalequal
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: barbar
; CHECK-NEXT: Identifier isa
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: comma
; CHECK-NEXT: StringConstant BinaryOperator
; CHECK-NEXT: rparen
; CHECK-NEXT: Eof
