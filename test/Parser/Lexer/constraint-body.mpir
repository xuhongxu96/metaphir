; The lexer tracks constraint context itself, so a 'constraint'/'metaflag'
; body is tokenized as a constraint expression even without a ';;' marker,
; while a 'match' body keeps pattern syntax.

; RUN: %metaphir-lex %s | FileCheck %s

constraint iseven(?v) {
; CHECK: kw_constraint
; CHECK-NEXT: Identifier iseven
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: rparen
; CHECK-NEXT: lbrace

	urem(?v, 2) == 0 && ?v != 0
; CHECK-NEXT: Identifier urem
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: comma
; CHECK-NEXT: APSInt 2
; CHECK-NEXT: rparen
; CHECK-NEXT: equalequal
; CHECK-NEXT: APSInt 0
; CHECK-NEXT: ampamp
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: notequal
; CHECK-NEXT: APSInt 0

}
; CHECK-NEXT: rbrace

metaflag :even(?v) {
; CHECK-NEXT: kw_metaflag
; CHECK-NEXT: MetaFlag even
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: rparen
; CHECK-NEXT: lbrace

	iseven(?v)
; CHECK-NEXT: Identifier iseven
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar v
; CHECK-NEXT: rparen

}
; CHECK-NEXT: rbrace

match addzero [] Binary (?ty ?x, ?y) {
; CHECK-NEXT: kw_match
; CHECK-NEXT: Identifier addzero
; CHECK-NEXT: lsquare
; CHECK-NEXT: rsquare
; CHECK-NEXT: kw_Binary
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaVar ty
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar y
; CHECK-NEXT: rparen
; CHECK-NEXT: lbrace

	%ret = add ?ty ?x, ?y
; CHECK-NEXT: LocalVar ret
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaVar ty
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar y

	;; ?x != ?y
; CHECK-NEXT: ConstraintMarker
; CHECK-NEXT: MetaVar x
; CHECK-NEXT: notequal
; CHECK-NEXT: MetaVar y

}
; CHECK-NEXT: rbrace
; CHECK-NEXT: Eof
