; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: custom. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/extractelement-vector.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-VECTOR
; EXTRACTELEMENT-VECTOR: extractelement-vector.mpir:1:21: error: expected type
; RUN: not %metaphir-parse %t/extractelement-comma.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-COMMA
; EXTRACTELEMENT-COMMA: extractelement-comma.mpir:1:34: error: expected ',' between operands (got 'i64')
; RUN: not %metaphir-parse %t/extractelement-index.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTELEMENT-INDEX
; EXTRACTELEMENT-INDEX: extractelement-index.mpir:1:35: error: expected type
; RUN: not %metaphir-parse %t/extractvalue-aggregate.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-AGGREGATE
; EXTRACTVALUE-AGGREGATE: extractvalue-aggregate.mpir:1:19: error: expected type
; RUN: not %metaphir-parse %t/extractvalue-index.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-INDEX
; EXTRACTVALUE-INDEX: extractvalue-index.mpir:1:29: error: expected value
; RUN: not %metaphir-parse %t/extractvalue-capture.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-CAPTURE
; EXTRACTVALUE-CAPTURE: extractvalue-capture.mpir:1:32: error: expected value-array meta variable
; RUN: not %metaphir-parse %t/extractvalue-capture-sort.mpir 2>&1 | FileCheck %s --check-prefix=EXTRACTVALUE-CAPTURE-SORT
; EXTRACTVALUE-CAPTURE-SORT: extractvalue-capture-sort.mpir:1:32: error: meta variable '?s' is used with an incompatible type
; RUN: not %metaphir-parse %t/insertvalue-aggregate.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-AGGREGATE
; INSERTVALUE-AGGREGATE: insertvalue-aggregate.mpir:1:18: error: expected type
; RUN: not %metaphir-parse %t/insertvalue-comma.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-COMMA
; INSERTVALUE-COMMA: insertvalue-comma.mpir:1:27: error: expected ',' between operands (got 'i32')
; RUN: not %metaphir-parse %t/insertvalue-value.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-VALUE
; INSERTVALUE-VALUE: insertvalue-value.mpir:1:28: error: expected type
; RUN: not %metaphir-parse %t/insertvalue-index.mpir 2>&1 | FileCheck %s --check-prefix=INSERTVALUE-INDEX
; INSERTVALUE-INDEX: insertvalue-index.mpir:1:35: error: expected value
; RUN: not %metaphir-parse %t/alloca-type.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-TYPE
; ALLOCA-TYPE: alloca-type.mpir:1:13: error: expected type
; RUN: not %metaphir-parse %t/alloca-align.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ALIGN
; ALLOCA-ALIGN: alloca-align.mpir:1:24: error: expected value
; RUN: not %metaphir-parse %t/alloca-addrspace-paren.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-PAREN
; ALLOCA-ADDRSPACE-PAREN: alloca-addrspace-paren.mpir:1:28: error: expected '(' after 'addrspace' (got '1')
; RUN: not %metaphir-parse %t/alloca-addrspace-value.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-VALUE
; ALLOCA-ADDRSPACE-VALUE: alloca-addrspace-value.mpir:1:28: error: expected value
; RUN: not %metaphir-parse %t/alloca-addrspace-close.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-ADDRSPACE-CLOSE
; ALLOCA-ADDRSPACE-CLOSE: alloca-addrspace-close.mpir:1:29: error: expected ')' after 'addrspace' (got end of line)
; RUN: not %metaphir-parse %t/alloca-count.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-COUNT
; ALLOCA-COUNT: alloca-count.mpir:1:18: error: expected type
; RUN: not %metaphir-parse %t/alloca-duplicate-align.mpir 2>&1 | FileCheck %s --check-prefix=ALLOCA-DUPLICATE-ALIGN
; ALLOCA-DUPLICATE-ALIGN: alloca-duplicate-align.mpir:1:33: error: duplicate keyed operand
; RUN: not %metaphir-parse %t/load-type.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-TYPE
; LOAD-TYPE: load-type.mpir:1:11: error: expected type
; RUN: not %metaphir-parse %t/load-comma.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-COMMA
; LOAD-COMMA: load-comma.mpir:1:15: error: expected ',' between operands (got 'ptr')
; RUN: not %metaphir-parse %t/load-pointer.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-POINTER
; LOAD-POINTER: load-pointer.mpir:1:16: error: expected type
; RUN: not %metaphir-parse %t/load-align.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-ALIGN
; LOAD-ALIGN: load-align.mpir:1:24: error: expected 'align'
; RUN: not %metaphir-parse %t/load-align-value.mpir 2>&1 | FileCheck %s --check-prefix=LOAD-ALIGN-VALUE
; LOAD-ALIGN-VALUE: load-align-value.mpir:1:30: error: expected value
; RUN: not %metaphir-parse %t/store-value.mpir 2>&1 | FileCheck %s --check-prefix=STORE-VALUE
; STORE-VALUE: store-value.mpir:1:7: error: expected type
; RUN: not %metaphir-parse %t/store-comma.mpir 2>&1 | FileCheck %s --check-prefix=STORE-COMMA
; STORE-COMMA: store-comma.mpir:1:14: error: expected ',' between operands (got 'ptr')
; RUN: not %metaphir-parse %t/store-pointer.mpir 2>&1 | FileCheck %s --check-prefix=STORE-POINTER
; STORE-POINTER: store-pointer.mpir:1:15: error: expected type
; RUN: not %metaphir-parse %t/store-align.mpir 2>&1 | FileCheck %s --check-prefix=STORE-ALIGN
; STORE-ALIGN: store-align.mpir:1:23: error: expected 'align'
; RUN: not %metaphir-parse %t/gep-inrange-paren.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-PAREN
; GEP-INRANGE-PAREN: gep-inrange-paren.mpir:1:28: error: expected '(' after 'inrange' (got '0')
; RUN: not %metaphir-parse %t/gep-inrange-lower.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-LOWER
; GEP-INRANGE-LOWER: gep-inrange-lower.mpir:1:28: error: expected value
; RUN: not %metaphir-parse %t/gep-inrange-comma.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-COMMA
; GEP-INRANGE-COMMA: gep-inrange-comma.mpir:1:30: error: expected ',' between operands (got '4')
; RUN: not %metaphir-parse %t/gep-inrange-upper.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-UPPER
; GEP-INRANGE-UPPER: gep-inrange-upper.mpir:1:31: error: expected value
; RUN: not %metaphir-parse %t/gep-inrange-close.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INRANGE-CLOSE
; GEP-INRANGE-CLOSE: gep-inrange-close.mpir:1:33: error: expected ')' after 'inrange' (got 'i8')
; RUN: not %metaphir-parse %t/gep-type.mpir 2>&1 | FileCheck %s --check-prefix=GEP-TYPE
; GEP-TYPE: gep-type.mpir:1:20: error: expected type
; RUN: not %metaphir-parse %t/gep-comma.mpir 2>&1 | FileCheck %s --check-prefix=GEP-COMMA
; GEP-COMMA: gep-comma.mpir:1:23: error: expected ',' between operands (got 'ptr')
; RUN: not %metaphir-parse %t/gep-pointer.mpir 2>&1 | FileCheck %s --check-prefix=GEP-POINTER
; GEP-POINTER: gep-pointer.mpir:1:24: error: expected type
; RUN: not %metaphir-parse %t/gep-index.mpir 2>&1 | FileCheck %s --check-prefix=GEP-INDEX
; GEP-INDEX: gep-index.mpir:1:32: error: expected type
; RUN: not %metaphir-parse %t/gep-capture.mpir 2>&1 | FileCheck %s --check-prefix=GEP-CAPTURE
; GEP-CAPTURE: gep-capture.mpir:1:35: error: expected type-array meta variable
; RUN: not %metaphir-parse %t/ret-type.mpir 2>&1 | FileCheck %s --check-prefix=RET-TYPE
; RET-TYPE: ret-type.mpir:1:5: error: expected type
; RUN: not %metaphir-parse %t/ret-value.mpir 2>&1 | FileCheck %s --check-prefix=RET-VALUE
; RET-VALUE: ret-value.mpir:1:9: error: expected value
; RUN: not %metaphir-parse %t/br-type.mpir 2>&1 | FileCheck %s --check-prefix=BR-TYPE
; BR-TYPE: br-type.mpir:1:4: error: expected type
; RUN: not %metaphir-parse %t/br-label.mpir 2>&1 | FileCheck %s --check-prefix=BR-LABEL
; BR-LABEL: br-label.mpir:1:10: error: expected value
; RUN: not %metaphir-parse %t/br-comma.mpir 2>&1 | FileCheck %s --check-prefix=BR-COMMA
; BR-COMMA: br-comma.mpir:1:10: error: expected ',' between operands (got 'label')
; RUN: not %metaphir-parse %t/br-true.mpir 2>&1 | FileCheck %s --check-prefix=BR-TRUE
; BR-TRUE: br-true.mpir:1:11: error: expected type
; RUN: not %metaphir-parse %t/br-comma2.mpir 2>&1 | FileCheck %s --check-prefix=BR-COMMA2
; BR-COMMA2: br-comma2.mpir:1:20: error: expected ',' between operands (got 'label')
; RUN: not %metaphir-parse %t/br-false.mpir 2>&1 | FileCheck %s --check-prefix=BR-FALSE
; BR-FALSE: br-false.mpir:1:21: error: expected type
; RUN: not %metaphir-parse %t/cmp-predicate.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE
; CMP-PREDICATE: cmp-predicate.mpir:1:11: error: expected comparison predicate
; RUN: not %metaphir-parse %t/cmp-predicate-sort.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE-SORT
; CMP-PREDICATE-SORT: cmp-predicate-sort.mpir:1:18: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/cmp-operands.mpir 2>&1 | FileCheck %s --check-prefix=CMP-OPERANDS
; CMP-OPERANDS: cmp-operands.mpir:1:21: error: expected ',' between operands (got '?y')
; RUN: not %metaphir-parse %t/phi-type.mpir 2>&1 | FileCheck %s --check-prefix=PHI-TYPE
; PHI-TYPE: phi-type.mpir:1:10: error: expected type
; RUN: not %metaphir-parse %t/phi-open.mpir 2>&1 | FileCheck %s --check-prefix=PHI-OPEN
; PHI-OPEN: phi-open.mpir:1:14: error: expected '[' in phi (got '0')
; RUN: not %metaphir-parse %t/phi-value.mpir 2>&1 | FileCheck %s --check-prefix=PHI-VALUE
; PHI-VALUE: phi-value.mpir:1:15: error: expected value
; RUN: not %metaphir-parse %t/phi-comma.mpir 2>&1 | FileCheck %s --check-prefix=PHI-COMMA
; PHI-COMMA: phi-comma.mpir:1:17: error: expected ',' between operands (got '?b')
; RUN: not %metaphir-parse %t/phi-block.mpir 2>&1 | FileCheck %s --check-prefix=PHI-BLOCK
; PHI-BLOCK: phi-block.mpir:1:18: error: expected value
; RUN: not %metaphir-parse %t/phi-close.mpir 2>&1 | FileCheck %s --check-prefix=PHI-CLOSE
; PHI-CLOSE: phi-close.mpir:1:20: error: expected ']' in phi (got end of line)
; RUN: not %metaphir-parse %t/call-type.mpir 2>&1 | FileCheck %s --check-prefix=CALL-TYPE
; CALL-TYPE: call-type.mpir:1:11: error: expected type
; RUN: not %metaphir-parse %t/call-callee.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CALLEE
; CALL-CALLEE: call-callee.mpir:1:15: error: expected value
; RUN: not %metaphir-parse %t/call-open.mpir 2>&1 | FileCheck %s --check-prefix=CALL-OPEN
; CALL-OPEN: call-open.mpir:1:18: error: expected '(' in call (got 'i32')
; RUN: not %metaphir-parse %t/call-capture.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE
; CALL-CAPTURE: call-capture.mpir:1:21: error: expected type-array meta variable
; RUN: not %metaphir-parse %t/call-capture-types.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-TYPES
; CALL-CAPTURE-TYPES: call-capture-types.mpir:1:21: error: expected type-array meta variable
; RUN: not %metaphir-parse %t/call-capture-types-sort.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-TYPES-SORT
; CALL-CAPTURE-TYPES-SORT: call-capture-types-sort.mpir:1:29: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/call-capture-values.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-VALUES
; CALL-CAPTURE-VALUES: call-capture-values.mpir:1:24: error: expected value-array meta variable
; RUN: not %metaphir-parse %t/call-capture-values-sort.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CAPTURE-VALUES-SORT
; CALL-CAPTURE-VALUES-SORT: call-capture-values-sort.mpir:1:32: error: meta variable '?x' is used with an incompatible type
; RUN: not %metaphir-parse %t/call-argument.mpir 2>&1 | FileCheck %s --check-prefix=CALL-ARGUMENT
; CALL-ARGUMENT: call-argument.mpir:1:22: error: expected value
; RUN: not %metaphir-parse %t/call-next-argument.mpir 2>&1 | FileCheck %s --check-prefix=CALL-NEXT-ARGUMENT
; CALL-NEXT-ARGUMENT: call-next-argument.mpir:1:26: error: expected type
; RUN: not %metaphir-parse %t/call-close.mpir 2>&1 | FileCheck %s --check-prefix=CALL-CLOSE
; CALL-CLOSE: call-close.mpir:1:24: error: expected ')' after call arguments (got end of line)
; RUN: not %metaphir-parse %t/cmp-predicate-earlier-sort.mpir 2>&1 | FileCheck %s --check-prefix=CMP-PREDICATE-EARLIER-SORT
; CMP-PREDICATE-EARLIER-SORT: cmp-predicate-earlier-sort.mpir:2:11: error: meta variable '?n' is used with an incompatible type

;--- extractelement-vector.mpir
%a = extractelement ), i64 0

;--- extractelement-comma.mpir
%a = extractelement <2 x i32> ?v i64 0

;--- extractelement-index.mpir
%a = extractelement <2 x i32> ?v, )

;--- extractvalue-aggregate.mpir
%a = extractvalue ), 0

;--- extractvalue-index.mpir
%a = extractvalue {i32} ?s, )

;--- extractvalue-capture.mpir
%a = extractvalue {i32} ?s, ...5

;--- extractvalue-capture-sort.mpir
%a = extractvalue {i32} ?s, ...?s

;--- insertvalue-aggregate.mpir
%a = insertvalue ), i32 1, 0

;--- insertvalue-comma.mpir
%a = insertvalue {i32} ?s i32 1, 0

;--- insertvalue-value.mpir
%a = insertvalue {i32} ?s, ), 0

;--- insertvalue-index.mpir
%a = insertvalue {i32} ?s, i32 1, )

;--- alloca-type.mpir
%a = alloca )

;--- alloca-align.mpir
%a = alloca i32, align )

;--- alloca-addrspace-paren.mpir
%a = alloca i32, addrspace 1

;--- alloca-addrspace-value.mpir
%a = alloca i32, addrspace()

;--- alloca-addrspace-close.mpir
%a = alloca i32, addrspace(1

;--- alloca-count.mpir
%a = alloca i32, )

;--- alloca-duplicate-align.mpir
%a = alloca i32, align 4, align 8

;--- load-type.mpir
%a = load ), ptr ?p

;--- load-comma.mpir
%a = load i32 ptr ?p

;--- load-pointer.mpir
%a = load i32, )

;--- load-align.mpir
%a = load i32, ptr ?p, 4

;--- load-align-value.mpir
%a = load i32, ptr ?p, align )

;--- store-value.mpir
store ), ptr ?p

;--- store-comma.mpir
store i32 ?x ptr ?p

;--- store-pointer.mpir
store i32 ?x, )

;--- store-align.mpir
store i32 ?x, ptr ?p, 4

;--- gep-inrange-paren.mpir
%a = getelementptr inrange 0 i8, ptr ?p

;--- gep-inrange-lower.mpir
%a = getelementptr inrange() i8, ptr ?p

;--- gep-inrange-comma.mpir
%a = getelementptr inrange(0 4) i8, ptr ?p

;--- gep-inrange-upper.mpir
%a = getelementptr inrange(0, ) i8, ptr ?p

;--- gep-inrange-close.mpir
%a = getelementptr inrange(0, 4 i8, ptr ?p

;--- gep-type.mpir
%a = getelementptr ), ptr ?p

;--- gep-comma.mpir
%a = getelementptr i8 ptr ?p

;--- gep-pointer.mpir
%a = getelementptr i8, )

;--- gep-index.mpir
%a = getelementptr i8, ptr ?p, )

;--- gep-capture.mpir
%a = getelementptr i8, ptr ?p, ...5

;--- ret-type.mpir
ret )

;--- ret-value.mpir
ret i32 )

;--- br-type.mpir
br )

;--- br-label.mpir
br label )

;--- br-comma.mpir
br i1 ?c label ?a, label ?b

;--- br-true.mpir
br i1 ?c, ), label ?b

;--- br-comma2.mpir
br i1 ?c, label ?a label ?b

;--- br-false.mpir
br i1 ?c, label ?a, )

;--- cmp-predicate.mpir
%a = icmp 5 i32 ?x, ?y

;--- cmp-predicate-sort.mpir
%a = icmp ?x i32 ?x, ?y

;--- cmp-operands.mpir
%a = icmp eq i32 ?x ?y

;--- phi-type.mpir
%a = phi )

;--- phi-open.mpir
%a = phi i32 0

;--- phi-value.mpir
%a = phi i32 [), ?b]

;--- phi-comma.mpir
%a = phi i32 [0 ?b]

;--- phi-block.mpir
%a = phi i32 [0, )]

;--- phi-close.mpir
%a = phi i32 [0, ?b

;--- call-type.mpir
%a = call ) @f()

;--- call-callee.mpir
%a = call i32 )()

;--- call-open.mpir
%a = call i32 @f i32 ?x

;--- call-capture.mpir
%a = call i32 @f(...)

;--- call-capture-types.mpir
%a = call i32 @f(...5 ?v)

;--- call-capture-types-sort.mpir
%a = call i32 @f(i32 ?x, ...?x ?v)

;--- call-capture-values.mpir
%a = call i32 @f(...?t 5)

;--- call-capture-values-sort.mpir
%a = call i32 @f(i32 ?x, ...?t ?x)

;--- call-argument.mpir
%a = call i32 @f(i32 ))

;--- call-next-argument.mpir
%a = call i32 @f(i32 ?x, ))

;--- call-close.mpir
%a = call i32 @f(i32 ?x

;--- cmp-predicate-earlier-sort.mpir
%a = add i?n ?x, 1
%b = icmp ?n i32 %a, 1

