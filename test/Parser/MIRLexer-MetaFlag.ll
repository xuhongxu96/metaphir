; RUN: %metaphir-lex %s | FileCheck %s

%1 = add:s i8 %x, %y
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaFlag s
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%2 = add:su i8 %x, %y
; CHECK-NEXT: LocalVarID 2
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaFlag su
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%3 = add i8 %x, %y:su
; CHECK-NEXT: LocalVarID 3
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y
; CHECK-NEXT: MetaFlag su

%4 = add i8 %x:s, %y
; CHECK-NEXT: LocalVarID 4
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: MetaFlag s
; CHECK-NEXT: comma
; CHECK-NEXT: LocalVar y

%5 = add:c:o(1) i8 %x:s, ?y:su:apint
; CHECK-NEXT: LocalVarID 5
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: MetaFlag c
; CHECK-NEXT: MetaFlag o
; CHECK-NEXT: lparen
; CHECK-NEXT: APSInt 1
; CHECK-NEXT: rparen
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: MetaFlag s
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar y
; CHECK-NEXT: MetaFlag su
; CHECK-NEXT: MetaFlag apint

%6 = add i8 %x, ?c:allones:or(:poison)
; CHECK-NEXT: LocalVarID 6
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar c
; CHECK-NEXT: MetaFlag allones
; CHECK-NEXT: MetaFlag or
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaFlag poison
; CHECK-NEXT: rparen

%7 = add i8 %x, ?c:not(:poison)
; CHECK-NEXT: LocalVarID 7
; CHECK-NEXT: equal
; CHECK-NEXT: kw_add
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar x
; CHECK-NEXT: comma
; CHECK-NEXT: MetaVar c
; CHECK-NEXT: MetaFlag not
; CHECK-NEXT: lparen
; CHECK-NEXT: MetaFlag poison
; CHECK-NEXT: rparen
; CHECK-NEXT: Eof
