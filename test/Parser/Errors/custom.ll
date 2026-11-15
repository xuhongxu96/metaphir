; What the parser rejects: custom. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/extractelement-vector.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-VECTOR
; RUN: not %metaphir-parse %t/extractelement-comma.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-COMMA
; RUN: not %metaphir-parse %t/extractelement-index.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-INDEX
; RUN: not %metaphir-parse %t/extractvalue-aggregate.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-AGGREGATE
; RUN: not %metaphir-parse %t/extractvalue-index.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-INDEX
; RUN: not %metaphir-parse %t/extractvalue-capture.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-CAPTURE
; RUN: not %metaphir-parse %t/extractvalue-capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-CAPTURE-SORT
; RUN: not %metaphir-parse %t/insertvalue-aggregate.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-AGGREGATE
; RUN: not %metaphir-parse %t/insertvalue-comma.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-COMMA
; RUN: not %metaphir-parse %t/insertvalue-value.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-VALUE
; RUN: not %metaphir-parse %t/insertvalue-index.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-INDEX
; RUN: not %metaphir-parse %t/alloca-type.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-TYPE
; RUN: not %metaphir-parse %t/alloca-align.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ALIGN
; RUN: not %metaphir-parse %t/alloca-addrspace-paren.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-PAREN
; RUN: not %metaphir-parse %t/alloca-addrspace-value.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-VALUE
; RUN: not %metaphir-parse %t/alloca-addrspace-close.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-CLOSE
; RUN: not %metaphir-parse %t/alloca-count.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-COUNT
; RUN: not %metaphir-parse %t/alloca-duplicate-align.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-DUPLICATE-ALIGN
; RUN: not %metaphir-parse %t/load-type.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-TYPE
; RUN: not %metaphir-parse %t/load-comma.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-COMMA
; RUN: not %metaphir-parse %t/load-pointer.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-POINTER
; RUN: not %metaphir-parse %t/load-align.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-ALIGN
; RUN: not %metaphir-parse %t/load-align-value.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-ALIGN-VALUE
; RUN: not %metaphir-parse %t/store-value.mpir 2>&1 | FileCheck %s --check-prefix=STORE-VALUE
; RUN: not %metaphir-parse %t/store-comma.mpir 2>&1 | FileCheck %s --check-prefix=STORE-COMMA
; RUN: not %metaphir-parse %t/store-pointer.mpir 2>&1 | FileCheck %s --check-prefix=STORE-POINTER
; RUN: not %metaphir-parse %t/store-align.mpir 2>&1 | FileCheck %s --check-prefix=STORE-ALIGN
; RUN: not %metaphir-parse %t/gep-inrange-paren.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-PAREN
; RUN: not %metaphir-parse %t/gep-inrange-lower.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-LOWER
; RUN: not %metaphir-parse %t/gep-inrange-comma.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-COMMA
; RUN: not %metaphir-parse %t/gep-inrange-upper.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-UPPER
; RUN: not %metaphir-parse %t/gep-inrange-close.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-CLOSE
; RUN: not %metaphir-parse %t/gep-type.mpir 2>&1 | FileCheck %s --check-prefix=GEP-TYPE
; RUN: not %metaphir-parse %t/gep-comma.mpir 2>&1 | FileCheck %s --check-prefix=GEP-COMMA
; RUN: not %metaphir-parse %t/gep-pointer.mpir 2>&1 | FileCheck %s --check-prefix=GEP-POINTER
; RUN: not %metaphir-parse %t/gep-index.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INDEX
; RUN: not %metaphir-parse %t/gep-capture.mpir 2>&1 | FileCheck %s --check-prefix=GEP-CAPTURE
; RUN: not %metaphir-parse %t/ret-type.mpir 2>&1 | FileCheck %s --check-prefix=RET-TYPE
; RUN: not %metaphir-parse %t/ret-value.mpir 2>&1 | FileCheck %s --check-prefix=RET-VALUE
; RUN: not %metaphir-parse %t/br-type.mpir 2>&1 | FileCheck %s --check-prefix=BR-TYPE
; RUN: not %metaphir-parse %t/br-label.mpir 2>&1 | FileCheck %s --check-prefix=BR-LABEL
; RUN: not %metaphir-parse %t/br-comma.mpir 2>&1 | FileCheck %s --check-prefix=BR-COMMA
; RUN: not %metaphir-parse %t/br-true.mpir 2>&1 | FileCheck %s --check-prefix=BR-TRUE
; RUN: not %metaphir-parse %t/br-comma2.mpir 2>&1 | FileCheck %s --check-prefix=BR-COMMA2
; RUN: not %metaphir-parse %t/br-false.mpir 2>&1 | FileCheck %s --check-prefix=BR-FALSE
; RUN: not %metaphir-parse %t/cmp-predicate.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE
; RUN: not %metaphir-parse %t/cmp-predicate-sort.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE-SORT
; RUN: not %metaphir-parse %t/cmp-operands.mpir 2>&1 | FileCheck %s --check-prefix=CMP-OPERANDS
; RUN: not %metaphir-parse %t/phi-type.mpir 2>&1 | FileCheck %s --check-prefix=PHI-TYPE
; RUN: not %metaphir-parse %t/phi-open.mpir 2>&1 | FileCheck %s --check-prefix=PHI-OPEN
; RUN: not %metaphir-parse %t/phi-value.mpir 2>&1 | FileCheck %s --check-prefix=PHI-VALUE
; RUN: not %metaphir-parse %t/phi-comma.mpir 2>&1 | FileCheck %s --check-prefix=PHI-COMMA
; RUN: not %metaphir-parse %t/phi-block.mpir 2>&1 | FileCheck %s --check-prefix=PHI-BLOCK
; RUN: not %metaphir-parse %t/phi-close.mpir 2>&1 | FileCheck %s --check-prefix=PHI-CLOSE
; RUN: not %metaphir-parse %t/call-type.mpir 2>&1 | FileCheck %s --check-prefix=CALL-TYPE
; RUN: not %metaphir-parse %t/call-callee.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CALLEE
; RUN: not %metaphir-parse %t/call-open.mpir 2>&1 | FileCheck %s --check-prefix=CALL-OPEN
; RUN: not %metaphir-parse %t/call-capture.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE
; RUN: not %metaphir-parse %t/call-capture-types.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-TYPES
; RUN: not %metaphir-parse %t/call-capture-types-sort.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-TYPES-SORT
; RUN: not %metaphir-parse %t/call-capture-values.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-VALUES
; RUN: not %metaphir-parse %t/call-capture-values-sort.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-VALUES-SORT
; RUN: not %metaphir-parse %t/call-argument.mpir 2>&1 | FileCheck %s --check-prefix=CALL-ARGUMENT
; RUN: not %metaphir-parse %t/call-next-argument.mpir 2>&1 | FileCheck %s --check-prefix=CALL-NEXT-ARGUMENT
; RUN: not %metaphir-parse %t/call-close.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CLOSE
; RUN: not %metaphir-parse %t/cmp-predicate-earlier-sort.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE-EARLIER-SORT
;--- extractelement-vector.mpir
%a = extractelement ), i64 0
; EXTRACTELEMENT-VECTOR: expected type

;--- extractelement-comma.mpir
%a = extractelement <2 x i32> ?v i64 0
; EXTRACTELEMENT-COMMA: expected ',' between operands (got 'i64')

;--- extractelement-index.mpir
%a = extractelement <2 x i32> ?v, )
; EXTRACTELEMENT-INDEX: expected type

;--- extractvalue-aggregate.mpir
%a = extractvalue ), 0
; EXTRACTVALUE-AGGREGATE: expected type

;--- extractvalue-index.mpir
%a = extractvalue {i32} ?s, )
; EXTRACTVALUE-INDEX: expected value

;--- extractvalue-capture.mpir
%a = extractvalue {i32} ?s, ...5
; EXTRACTVALUE-CAPTURE: expected value-array meta variable

;--- extractvalue-capture-sort.mpir
%a = extractvalue {i32} ?s, ...?s
; EXTRACTVALUE-CAPTURE-SORT: meta variable '?s' is used with an incompatible type

;--- insertvalue-aggregate.mpir
%a = insertvalue ), i32 1, 0
; INSERTVALUE-AGGREGATE: expected type

;--- insertvalue-comma.mpir
%a = insertvalue {i32} ?s i32 1, 0
; INSERTVALUE-COMMA: expected ',' between operands (got 'i32')

;--- insertvalue-value.mpir
%a = insertvalue {i32} ?s, ), 0
; INSERTVALUE-VALUE: expected type

;--- insertvalue-index.mpir
%a = insertvalue {i32} ?s, i32 1, )
; INSERTVALUE-INDEX: expected value

;--- alloca-type.mpir
%a = alloca )
; ALLOCA-TYPE: expected type

;--- alloca-align.mpir
%a = alloca i32, align )
; ALLOCA-ALIGN: expected value

;--- alloca-addrspace-paren.mpir
%a = alloca i32, addrspace 1
; ALLOCA-ADDRSPACE-PAREN: expected '(' after 'addrspace' (got '1')

;--- alloca-addrspace-value.mpir
%a = alloca i32, addrspace()
; ALLOCA-ADDRSPACE-VALUE: expected value

;--- alloca-addrspace-close.mpir
%a = alloca i32, addrspace(1
; ALLOCA-ADDRSPACE-CLOSE: expected ')' after 'addrspace' (got end of line)

;--- alloca-count.mpir
%a = alloca i32, )
; ALLOCA-COUNT: expected type

;--- alloca-duplicate-align.mpir
%a = alloca i32, align 4, align 8
; ALLOCA-DUPLICATE-ALIGN: duplicate keyed operand

;--- load-type.mpir
%a = load ), ptr ?p
; LOAD-TYPE: expected type

;--- load-comma.mpir
%a = load i32 ptr ?p
; LOAD-COMMA: expected ',' between operands (got 'ptr')

;--- load-pointer.mpir
%a = load i32, )
; LOAD-POINTER: expected type

;--- load-align.mpir
%a = load i32, ptr ?p, 4
; LOAD-ALIGN: expected 'align'

;--- load-align-value.mpir
%a = load i32, ptr ?p, align )
; LOAD-ALIGN-VALUE: expected value

;--- store-value.mpir
store ), ptr ?p
; STORE-VALUE: expected type

;--- store-comma.mpir
store i32 ?x ptr ?p
; STORE-COMMA: expected ',' between operands (got 'ptr')

;--- store-pointer.mpir
store i32 ?x, )
; STORE-POINTER: expected type

;--- store-align.mpir
store i32 ?x, ptr ?p, 4
; STORE-ALIGN: expected 'align'

;--- gep-inrange-paren.mpir
%a = getelementptr inrange 0 i8, ptr ?p
; GEP-INRANGE-PAREN: expected '(' after 'inrange' (got '0')

;--- gep-inrange-lower.mpir
%a = getelementptr inrange() i8, ptr ?p
; GEP-INRANGE-LOWER: expected value

;--- gep-inrange-comma.mpir
%a = getelementptr inrange(0 4) i8, ptr ?p
; GEP-INRANGE-COMMA: expected ',' between operands (got '4')

;--- gep-inrange-upper.mpir
%a = getelementptr inrange(0, ) i8, ptr ?p
; GEP-INRANGE-UPPER: expected value

;--- gep-inrange-close.mpir
%a = getelementptr inrange(0, 4 i8, ptr ?p
; GEP-INRANGE-CLOSE: expected ')' after 'inrange' (got 'i8')

;--- gep-type.mpir
%a = getelementptr ), ptr ?p
; GEP-TYPE: expected type

;--- gep-comma.mpir
%a = getelementptr i8 ptr ?p
; GEP-COMMA: expected ',' between operands (got 'ptr')

;--- gep-pointer.mpir
%a = getelementptr i8, )
; GEP-POINTER: expected type

;--- gep-index.mpir
%a = getelementptr i8, ptr ?p, )
; GEP-INDEX: expected type

;--- gep-capture.mpir
%a = getelementptr i8, ptr ?p, ...5
; GEP-CAPTURE: expected type-array meta variable

;--- ret-type.mpir
ret )
; RET-TYPE: expected type

;--- ret-value.mpir
ret i32 )
; RET-VALUE: expected value

;--- br-type.mpir
br )
; BR-TYPE: expected type

;--- br-label.mpir
br label )
; BR-LABEL: expected value

;--- br-comma.mpir
br i1 ?c label ?a, label ?b
; BR-COMMA: expected ',' between operands (got 'label')

;--- br-true.mpir
br i1 ?c, ), label ?b
; BR-TRUE: expected type

;--- br-comma2.mpir
br i1 ?c, label ?a label ?b
; BR-COMMA2: expected ',' between operands (got 'label')

;--- br-false.mpir
br i1 ?c, label ?a, )
; BR-FALSE: expected type

;--- cmp-predicate.mpir
%a = icmp 5 i32 ?x, ?y
; CMP-PREDICATE: expected comparison predicate

;--- cmp-predicate-sort.mpir
%a = icmp ?x i32 ?x, ?y
; CMP-PREDICATE-SORT: meta variable '?x' is used with an incompatible type

;--- cmp-operands.mpir
%a = icmp eq i32 ?x ?y
; CMP-OPERANDS: expected ',' between operands (got '?y')

;--- phi-type.mpir
%a = phi )
; PHI-TYPE: expected type

;--- phi-open.mpir
%a = phi i32 0
; PHI-OPEN: expected '[' in phi (got '0')

;--- phi-value.mpir
%a = phi i32 [), ?b]
; PHI-VALUE: expected value

;--- phi-comma.mpir
%a = phi i32 [0 ?b]
; PHI-COMMA: expected ',' between operands (got '?b')

;--- phi-block.mpir
%a = phi i32 [0, )]
; PHI-BLOCK: expected value

;--- phi-close.mpir
%a = phi i32 [0, ?b
; PHI-CLOSE: expected ']' in phi (got end of line)

;--- call-type.mpir
%a = call ) @f()
; CALL-TYPE: expected type

;--- call-callee.mpir
%a = call i32 )()
; CALL-CALLEE: expected value

;--- call-open.mpir
%a = call i32 @f i32 ?x
; CALL-OPEN: expected '(' in call (got 'i32')

;--- call-capture.mpir
%a = call i32 @f(...)
; CALL-CAPTURE: expected type-array meta variable

;--- call-capture-types.mpir
%a = call i32 @f(...5 ?v)
; CALL-CAPTURE-TYPES: expected type-array meta variable

;--- call-capture-types-sort.mpir
%a = call i32 @f(i32 ?x, ...?x ?v)
; CALL-CAPTURE-TYPES-SORT: meta variable '?x' is used with an incompatible type

;--- call-capture-values.mpir
%a = call i32 @f(...?t 5)
; CALL-CAPTURE-VALUES: expected value-array meta variable

;--- call-capture-values-sort.mpir
%a = call i32 @f(i32 ?x, ...?t ?x)
; CALL-CAPTURE-VALUES-SORT: meta variable '?x' is used with an incompatible type

;--- call-argument.mpir
%a = call i32 @f(i32 ))
; CALL-ARGUMENT: expected value

;--- call-next-argument.mpir
%a = call i32 @f(i32 ?x, ))
; CALL-NEXT-ARGUMENT: expected type

;--- call-close.mpir
%a = call i32 @f(i32 ?x
; CALL-CLOSE: expected ')' after call arguments (got end of line)

;--- cmp-predicate-earlier-sort.mpir
%a = add i?n ?x, 1
%b = icmp ?n i32 %a, 1
; CMP-PREDICATE-EARLIER-SORT: meta variable '?n' is used with an incompatible type
