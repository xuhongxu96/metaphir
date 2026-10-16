; RUN: %metaphir-parse %s | FileCheck %s

%fneg = fneg fast float ?f
; CHECK: pattern instructions=49 constraints=0
; CHECK-NEXT: %fneg = fneg fast float ?f

%add = add nsw i32 ?a, ?b
; CHECK-NEXT: %add = add nsw i32 ?a, ?b

%fadd = fadd nnan float ?f, ?g
; CHECK-NEXT: %fadd = fadd nnan float ?f, ?g

%sub = sub nuw i32 ?a, ?b
; CHECK-NEXT: %sub = sub nuw i32 ?a, ?b

%fsub = fsub nsz float ?f, ?g
; CHECK-NEXT: %fsub = fsub nsz float ?f, ?g

%mul = mul nsw nuw i32 ?a, ?b
; CHECK-NEXT: %mul = mul nsw nuw i32 ?a, ?b

%fmul = fmul contract float ?f, ?g
; CHECK-NEXT: %fmul = fmul contract float ?f, ?g

%udiv = udiv exact i32 ?a, ?b
; CHECK-NEXT: %udiv = udiv exact i32 ?a, ?b

%sdiv = sdiv exact i32 ?a, ?b
; CHECK-NEXT: %sdiv = sdiv exact i32 ?a, ?b

%fdiv = fdiv arcp float ?f, ?g
; CHECK-NEXT: %fdiv = fdiv arcp float ?f, ?g

%urem = urem i32 ?a, ?b
; CHECK-NEXT: %urem = urem i32 ?a, ?b

%srem = srem i32 ?a, ?b
; CHECK-NEXT: %srem = srem i32 ?a, ?b

%frem = frem afn float ?f, ?g
; CHECK-NEXT: %frem = frem afn float ?f, ?g

%shl = shl nsw i32 ?a, ?b
; CHECK-NEXT: %shl = shl nsw i32 ?a, ?b

%lshr = lshr exact i32 ?a, ?b
; CHECK-NEXT: %lshr = lshr exact i32 ?a, ?b

%ashr = ashr:o i32 ?a, ?b
; CHECK-NEXT: %ashr = ashr:o i32 ?a, ?b

%and = and:c i32 ?a, ?b
; CHECK-NEXT: %and = and:c i32 ?a, ?b

%or = or disjoint i32 ?a, ?b
; CHECK-NEXT: %or = or disjoint i32 ?a, ?b

%xor = xor i32 ?a, ?b
; CHECK-NEXT: %xor = xor i32 ?a, ?b

%extractelement = extractelement <4 x i32> ?vec, i32 ?idx
; CHECK-NEXT: %extractelement = extractelement <4 x i32> ?vec, i32 ?idx

%insertelement = insertelement <4 x i32> ?vec, i32 ?a, i32 ?idx
; CHECK-NEXT: %insertelement = insertelement <4 x i32> ?vec, i32 ?a, i32 ?idx

%shuffle = shufflevector <4 x i32> ?vec, <4 x i32> ?vec2, <4 x i32> ?mask
; CHECK-NEXT: %shuffle = shufflevector <4 x i32> ?vec, <4 x i32> ?vec2, <4 x i32> ?mask

%extractvalue = extractvalue {i32, float} ?agg, 0
; CHECK-NEXT: %extractvalue = extractvalue {i32, float} ?agg, 0

%insertvalue = insertvalue {i32, float} ?agg, i32 ?a, 0
; CHECK-NEXT: %insertvalue = insertvalue {i32, float} ?agg, i32 ?a, 0

%alloca = alloca inalloca i32, i32 ?count, addrspace(?as), align ?align
; CHECK-NEXT: %alloca = alloca inalloca i32, i32 ?count, align ?align, addrspace(?as)

%load = load volatile i32, ptr ?ptr, align ?align
; CHECK-NEXT: %load = load volatile i32, ptr ?ptr, align ?align

%store = store volatile i32 ?a, ptr ?ptr, align ?align
; CHECK-NEXT: %store = store volatile i32 ?a, ptr ?ptr, align ?align

%gep = getelementptr inbounds nuw i32, ptr ?ptr, i32 ?idx
; CHECK-NEXT: %gep = getelementptr inbounds nuw i32, ptr ?ptr, i32 ?idx

%trunc = trunc nsw i32 ?a to i8
; CHECK-NEXT: %trunc = trunc nsw i32 ?a to i8

%zext = zext nneg i8 ?small to i32
; CHECK-NEXT: %zext = zext nneg i8 ?small to i32

%sext = sext i8 ?small to i32
; CHECK-NEXT: %sext = sext i8 ?small to i32

%fptrunc = fptrunc reassoc double ?d to float
; CHECK-NEXT: %fptrunc = fptrunc reassoc double ?d to float

%fpext = fpext fast float ?f to double
; CHECK-NEXT: %fpext = fpext fast float ?f to double

%fptoui = fptoui float ?f to i32
; CHECK-NEXT: %fptoui = fptoui float ?f to i32

%fptosi = fptosi float ?f to i32
; CHECK-NEXT: %fptosi = fptosi float ?f to i32

%uitofp = uitofp nneg i32 ?a to float
; CHECK-NEXT: %uitofp = uitofp nneg i32 ?a to float

%sitofp = sitofp nnan i32 ?a to float
; CHECK-NEXT: %sitofp = sitofp nnan i32 ?a to float

%ptrtoint = ptrtoint ptr ?ptr to i64
; CHECK-NEXT: %ptrtoint = ptrtoint ptr ?ptr to i64

%ptrtoaddr = ptrtoaddr ptr ?ptr to i64
; CHECK-NEXT: %ptrtoaddr = ptrtoaddr ptr ?ptr to i64

%inttoptr = inttoptr i64 ?address to ptr
; CHECK-NEXT: %inttoptr = inttoptr i64 ?address to ptr

%bitcast = bitcast i32 ?a to float
; CHECK-NEXT: %bitcast = bitcast i32 ?a to float

%cmp = icmp samesign ?pred i32 ?a, ?b
; CHECK-NEXT: %cmp = icmp samesign ?pred i32 ?a, ?b

%fcmp = fcmp fast ?fpred float ?f, ?g
; CHECK-NEXT: %fcmp = fcmp fast ?fpred float ?f, ?g

%phi = phi i32 [?a, %left], [?b, ?right]
; CHECK-NEXT: %phi = phi i32 [?a, ?left], [?b, ?right]

%select = select nnan i1 ?cond, float ?f, float ?g
; CHECK-NEXT: %select = select nnan i1 ?cond, float ?f, float ?g

%freeze = freeze i32 ?a
; CHECK-NEXT: %freeze = freeze i32 ?a

%call = call:c i32 @f(i32 ?a, i32 ?b)
; CHECK-NEXT: %call = call:c i32 @f(i32 ?a, i32 ?b)

%branch = br i1 %cmp, label %left, label ?right
; CHECK-NEXT: %branch = br i1 %cmp, label ?left, label ?right

ret i32 %call
; CHECK-NEXT: ret i32 %call
; CHECK-NEXT: meta ?f type=Value
; CHECK-NEXT: meta ?a type=Value
; CHECK-NEXT: meta ?b type=Value
; CHECK-NEXT: meta ?g type=Value
; CHECK-NEXT: meta ?vec type=Value
; CHECK-NEXT: meta ?idx type=Nat
; CHECK-NEXT: meta ?vec2 type=Value
; CHECK-NEXT: meta ?mask type=Value
; CHECK-NEXT: meta ?agg type=Value
; CHECK-NEXT: meta ?count type=Nat
; CHECK-NEXT: meta ?as type=Nat
; CHECK-NEXT: meta ?align type=Nat
; CHECK-NEXT: meta ?ptr type=Value
; CHECK-NEXT: meta ?small type=Value
; CHECK-NEXT: meta ?d type=Value
; CHECK-NEXT: meta ?address type=Value
; CHECK-NEXT: meta ?pred type=CmpPredicate
; CHECK-NEXT: meta ?fpred type=CmpPredicate
; CHECK-NEXT: meta ?left type=BasicBlock
; CHECK-NEXT: meta ?right type=BasicBlock
; CHECK-NEXT: meta ?cond type=i1
; CHECK-NOT: {{.}}
