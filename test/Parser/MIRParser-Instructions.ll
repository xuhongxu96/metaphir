; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=49 constraints=0

%fneg = fneg fast float ?f
; CHECK: %fneg = fneg fast float ?f

%add = add nsw i32 ?a, ?b
; CHECK: %add = add nsw i32 ?a, ?b

%fadd = fadd nnan float ?f, ?g
; CHECK: %fadd = fadd nnan float ?f, ?g

%sub = sub nuw i32 ?a, ?b
; CHECK: %sub = sub nuw i32 ?a, ?b

%fsub = fsub nsz float ?f, ?g
; CHECK: %fsub = fsub nsz float ?f, ?g

%mul = mul nsw nuw i32 ?a, ?b
; CHECK: %mul = mul nsw nuw i32 ?a, ?b

%fmul = fmul contract float ?f, ?g
; CHECK: %fmul = fmul contract float ?f, ?g

%udiv = udiv exact i32 ?a, ?b
; CHECK: %udiv = udiv exact i32 ?a, ?b

%sdiv = sdiv exact i32 ?a, ?b
; CHECK: %sdiv = sdiv exact i32 ?a, ?b

%fdiv = fdiv arcp float ?f, ?g
; CHECK: %fdiv = fdiv arcp float ?f, ?g

%urem = urem i32 ?a, ?b
; CHECK: %urem = urem i32 ?a, ?b

%srem = srem i32 ?a, ?b
; CHECK: %srem = srem i32 ?a, ?b

%frem = frem afn float ?f, ?g
; CHECK: %frem = frem afn float ?f, ?g

%shl = shl nsw i32 ?a, ?b
; CHECK: %shl = shl nsw i32 ?a, ?b

%lshr = lshr exact i32 ?a, ?b
; CHECK: %lshr = lshr exact i32 ?a, ?b

%ashr = ashr:o i32 ?a, ?b
; CHECK: %ashr = ashr:o i32 ?a, ?b

%and = and:c i32 ?a, ?b
; CHECK: %and = and:c i32 ?a, ?b

%or = or disjoint i32 ?a, ?b
; CHECK: %or = or disjoint i32 ?a, ?b

%xor = xor i32 ?a, ?b
; CHECK: %xor = xor i32 ?a, ?b

%extractelement = extractelement <4 x i32> ?vec, i32 ?idx
; CHECK: %extractelement = extractelement <4 x i32> ?vec, i32 ?idx

%insertelement = insertelement <4 x i32> ?vec, i32 ?a, i32 ?idx
; CHECK: %insertelement = insertelement <4 x i32> ?vec, i32 ?a, i32 ?idx

%shuffle = shufflevector <4 x i32> ?vec, <4 x i32> ?vec2, <4 x i32> ?mask
; CHECK: %shuffle = shufflevector <4 x i32> ?vec, <4 x i32> ?vec2, <4 x i32> ?mask

%extractvalue = extractvalue {i32, float} ?agg, 0
; CHECK: %extractvalue = extractvalue {i32, float} ?agg, 0

%insertvalue = insertvalue {i32, float} ?agg, i32 ?a, 0
; CHECK: %insertvalue = insertvalue {i32, float} ?agg, i32 ?a, 0

%alloca = alloca inalloca i32, i32 ?count, addrspace(?as), align ?align
; CHECK: %alloca = alloca inalloca i32, i32 ?count, align ?align, addrspace(?as)

%load = load volatile i32, ptr ?ptr, align ?align
; CHECK: %load = load volatile i32, ptr ?ptr, align ?align

%store = store volatile i32 ?a, ptr ?ptr, align ?align
; CHECK: %store = store volatile i32 ?a, ptr ?ptr, align ?align

%gep = getelementptr inbounds nuw i32, ptr ?ptr, i32 ?idx
; CHECK: %gep = getelementptr inbounds nuw i32, ptr ?ptr, i32 ?idx

%trunc = trunc nsw i32 ?a to i8
; CHECK: %trunc = trunc nsw i32 ?a to i8

%zext = zext nneg i8 ?small to i32
; CHECK: %zext = zext nneg i8 ?small to i32

%sext = sext i8 ?small to i32
; CHECK: %sext = sext i8 ?small to i32

%fptrunc = fptrunc reassoc double ?d to float
; CHECK: %fptrunc = fptrunc reassoc double ?d to float

%fpext = fpext fast float ?f to double
; CHECK: %fpext = fpext fast float ?f to double

%fptoui = fptoui float ?f to i32
; CHECK: %fptoui = fptoui float ?f to i32

%fptosi = fptosi float ?f to i32
; CHECK: %fptosi = fptosi float ?f to i32

%uitofp = uitofp nneg i32 ?a to float
; CHECK: %uitofp = uitofp nneg i32 ?a to float

%sitofp = sitofp nnan i32 ?a to float
; CHECK: %sitofp = sitofp nnan i32 ?a to float

%ptrtoint = ptrtoint ptr ?ptr to i64
; CHECK: %ptrtoint = ptrtoint ptr ?ptr to i64

%ptrtoaddr = ptrtoaddr ptr ?ptr to i64
; CHECK: %ptrtoaddr = ptrtoaddr ptr ?ptr to i64

%inttoptr = inttoptr i64 ?address to ptr
; CHECK: %inttoptr = inttoptr i64 ?address to ptr

%bitcast = bitcast i32 ?a to float
; CHECK: %bitcast = bitcast i32 ?a to float

%cmp = icmp samesign ?pred i32 ?a, ?b
; CHECK: %cmp = icmp samesign ?pred i32 ?a, ?b

%fcmp = fcmp fast ?fpred float ?f, ?g
; CHECK: %fcmp = fcmp fast ?fpred float ?f, ?g

%phi = phi i32 [?a, %left], [?b, ?right]
; CHECK: %phi = phi i32 [?a, ?left], [?b, ?right]

%select = select nnan i1 ?cond, float ?f, float ?g
; CHECK: %select = select nnan i1 ?cond, float ?f, float ?g

%freeze = freeze i32 ?a
; CHECK: %freeze = freeze i32 ?a

%call = call:c i32 @f(i32 ?a, i32 ?b)
; CHECK: %call = call:c i32 @f(i32 ?a, i32 ?b)

%branch = br i1 %cmp, label %left, label ?right
; CHECK: %branch = br i1 %cmp, label ?left, label ?right
; CHECK-NEXT: ret i32 %call
; CHECK-DAG: meta ?f type=Value
; CHECK-DAG: meta ?a type=Value
; CHECK-DAG: meta ?b type=Value
; CHECK-DAG: meta ?g type=Value
; CHECK-DAG: meta ?vec type=Value
; CHECK-DAG: meta ?idx type=Nat
; CHECK-DAG: meta ?vec2 type=Value
; CHECK-DAG: meta ?mask type=Value
; CHECK-DAG: meta ?agg type=Value
; CHECK-DAG: meta ?count type=Nat
; CHECK-DAG: meta ?as type=Nat
; CHECK-DAG: meta ?align type=Nat
; CHECK-DAG: meta ?ptr type=Value
; CHECK-DAG: meta ?small type=Value
; CHECK-DAG: meta ?d type=Value
; CHECK-DAG: meta ?address type=Value
; CHECK-DAG: meta ?pred type=CmpPredicate
; CHECK-DAG: meta ?fpred type=CmpPredicate
; CHECK-DAG: meta ?left type=BasicBlock
; CHECK-DAG: meta ?right type=BasicBlock
; CHECK-DAG: meta ?cond type=i1

ret i32 %call
