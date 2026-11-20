; Tokens the other lexer tests do not have: labels of every spelling,
; quoted names with escapes, comments, numbers in each notation, and the
; operators of constraint lines.
; RUN: %metaphir-lex %s | FileCheck %s

.dot.label:
; CHECK: LabelStr .dot.label

$dollar:
; CHECK-NEXT: LabelStr $dollar

-dash:
; CHECK-NEXT: LabelStr -dash

-1x:
; CHECK-NEXT: LabelStr -1x

12ab:
; CHECK-NEXT: LabelStr 12ab

42:
; CHECK-NEXT: LabelID 42

"quoted label":
; CHECK-NEXT: LabelStr quoted label

/* a comment * with a star */ add /* another */
; CHECK-NEXT: kw_add

%"local name" "" @"global \22quoted\22 \\ \zz" "a\41b"
; CHECK-NEXT: LocalVar local name
; CHECK-NEXT: StringConstant 
; CHECK-NEXT: GlobalVar global "quoted" \ \zz
; CHECK-NEXT: StringConstant aAb

u0xFF s0xFF 0x7FF0000000000000
; CHECK-NEXT: APSInt 255
; CHECK-NEXT: APSInt -1
; CHECK-NEXT: APFloat +Inf

+1.5 +2.5e10 +3.5e-2 -4.5E+3 6. 7.e
; CHECK-NEXT: APFloat 1.5
; CHECK-NEXT: APFloat 2.5E+10
; CHECK-NEXT: APFloat 0.035000000000000003
; CHECK-NEXT: APFloat -4500
; CHECK-NEXT: APFloat 6
; CHECK-NEXT: APFloat 7
; CHECK-NEXT: Identifier e

i32x b8y
; CHECK-NEXT: Type i32
; CHECK-NEXT: kw_x
; CHECK-NEXT: Type b8
; CHECK-NEXT: Identifier y

;; a <= b >= c > d < e % f = g { } is-odd - 1 ! != == && || * / + ( ) [ ] , "s" ?v true false treatIntAsVec
; CHECK-NEXT: ConstraintMarker
; CHECK-NEXT: Identifier a
; CHECK-NEXT: lessequal
; CHECK-NEXT: Identifier b
; CHECK-NEXT: greaterequal
; CHECK-NEXT: Identifier c
; CHECK-NEXT: greater
; CHECK-NEXT: Identifier d
; CHECK-NEXT: less
; CHECK-NEXT: Identifier e
; CHECK-NEXT: percent
; CHECK-NEXT: Identifier f
; CHECK-NEXT: equal
; CHECK-NEXT: Identifier g
; CHECK-NEXT: lbrace
; CHECK-NEXT: rbrace
; CHECK-NEXT: Identifier is-odd
; CHECK-NEXT: minus
; CHECK-NEXT: APSInt 1
; CHECK-NEXT: exclaim
; CHECK-NEXT: notequal
; CHECK-NEXT: equalequal
; CHECK-NEXT: ampamp
; CHECK-NEXT: barbar
; CHECK-NEXT: star
; CHECK-NEXT: slash
; CHECK-NEXT: plus
; CHECK-NEXT: lparen
; CHECK-NEXT: rparen
; CHECK-NEXT: lsquare
; CHECK-NEXT: rsquare
; CHECK-NEXT: comma
; CHECK-NEXT: StringConstant s
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: kw_true
; CHECK-NEXT: kw_false
; CHECK-NEXT: kw_treatIntAsVec
; CHECK-NEXT: Eof
