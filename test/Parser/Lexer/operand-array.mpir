; RUN: %metaphir-lex %s | FileCheck %s

%1 = call ?retTy @llvm.?id(...?tyArr ?valArr)
; CHECK: LocalVarID 1
; CHECK-NEXT: equal
; CHECK-NEXT: kw_call
; CHECK-NEXT: MetaVar retTy
; CHECK-NEXT: IntrinsicPrefix
; CHECK-NEXT: MetaVar id
; CHECK-NEXT: lparen
; CHECK-NEXT: dotdotdot
; CHECK-NEXT: MetaVar tyArr
; CHECK-NEXT: MetaVar valArr
; CHECK-NEXT: rparen

%2 = call i32 @f(i8 %a, ...?tyArr ?valArr) ; partial capture
; CHECK-NEXT: LocalVarID 2
; CHECK-NEXT: equal
; CHECK-NEXT: kw_call
; CHECK-NEXT: Type i32
; CHECK-NEXT: GlobalVar f
; CHECK-NEXT: lparen
; CHECK-NEXT: Type i8
; CHECK-NEXT: LocalVar a
; CHECK-NEXT: comma
; CHECK-NEXT: dotdotdot
; CHECK-NEXT: MetaVar tyArr
; CHECK-NEXT: MetaVar valArr
; CHECK-NEXT: rparen

%3 = extractvalue {i32, float} %agg, ...?valArr
; CHECK-NEXT: LocalVarID 3
; CHECK-NEXT: equal
; CHECK-NEXT: kw_extractvalue
; CHECK-NEXT: lbrace
; CHECK-NEXT: Type i32
; CHECK-NEXT: comma
; CHECK-NEXT: kw_float
; CHECK-NEXT: rbrace
; CHECK-NEXT: LocalVar agg
; CHECK-NEXT: comma
; CHECK-NEXT: dotdotdot
; CHECK-NEXT: MetaVar valArr
; CHECK-NEXT: Eof
