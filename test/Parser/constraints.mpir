; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=4 constraints=15

; Names used in constraints are resolved against the context, so a
; user-defined operation is declared before use.
constraint custom_predicate(?a, ?b) {
	?a == ?b
}

%sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allOnes, :not(:poison))
; CHECK: %sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allOnes,:not(:poison))

%cmp = icmp ?predicate i32 ?x, ?y
; CHECK: %cmp = icmp ?predicate i32 ?x, ?y

%intrinsic_call = call i32 @llvm.?intrinsic(i32 ?x)
; CHECK: %intrinsic_call = call i32 @llvm.?intrinsic(i32 ?x)

%consume = call i32 @consume(...?types ?values)
; CHECK: %consume = call i32 @consume(...?types ?values)

;; ?wrapped == true
; CHECK: constraint (== ?wrapped true)

;; ?bits + 2 * 3 == 7 && !false || sdiv(?bits, -2) != 0
; CHECK: constraint (|| (&& (== (+ ?bits (* 2 3)) 7) (! false)) (!= (sdiv ?bits (- 2)) 0))

;; custom_predicate(?bits, urem(?bits, 4))
; CHECK: constraint (custom_predicate ?bits (urem ?bits 4))

;; ?types[0] == ?types[1]
; CHECK: constraint (== ?types[0] ?types[1])

;; ?values[?bits - 1] != ?x
; CHECK: constraint (!= ?values[(- ?bits 1)] ?x)

;; isa(?x, "BinaryOperator")
; CHECK: constraint (isa ?x "BinaryOperator")

;; ?predicate == "slt"
; CHECK: constraint (== ?predicate "slt")

;; ?intrinsic != "llvm.sqrt"
; CHECK: constraint (!= ?intrinsic "llvm.sqrt")

;; ?types == [?types[0], ?types[1]]
; CHECK: constraint (== ?types [?types[0],?types[1]])

;; ?values != [?x, ?y]
; CHECK: constraint (!= ?values [?x,?y])

;; ?types == ["i32", "ptr"]
; CHECK: constraint (== ?types ["i32","ptr"])

;; ?x == "%argument"
; CHECK: constraint (== ?x "%argument")

;; ["add", "sub"][1] == "sub"
; CHECK: constraint (== ["add","sub"][1] "sub")

;; lshr(?bits, 1) == 16
; CHECK: constraint (== (lshr ?bits 1) 16)

;; ashr(-8, 1) == -4
; CHECK: constraint (== (ashr (- 8) 1) (- 4))
; CHECK-DAG: meta ?wrapped type=i1
; CHECK-DAG: meta ?bits type=Nat
; CHECK-DAG: meta ?x type=Value
; CHECK-DAG: meta ?y type=Value
; CHECK-DAG: meta ?predicate type=CmpPredicate
; CHECK-DAG: meta ?intrinsic type=Intrinsic::ID
; CHECK-DAG: meta ?types type=Type[]
; CHECK-DAG: meta ?values type=Value[]
