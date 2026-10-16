; RUN: %metaphir-parse %s | FileCheck %s

; Names used in constraints are resolved against the context, so a
; user-defined operation is declared before use.
constraint custom_predicate(?a, ?b) {
	?a == ?b
}

%sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allOnes, :not(:poison))
; CHECK: pattern instructions=4 constraints=15
; CHECK-NEXT: %sum = add:o(1):su nsw:?wrapped i?bits ?x, ?y:or(:allOnes,:not(:poison))

%cmp = icmp ?predicate i32 ?x, ?y
; CHECK-NEXT: %cmp = icmp ?predicate i32 ?x, ?y

%intrinsic_call = call i32 @llvm.?intrinsic(i32 ?x)
; CHECK-NEXT: %intrinsic_call = call i32 @llvm.?intrinsic(i32 ?x)

%consume = call i32 @consume(...?types ?values)
; CHECK-NEXT: %consume = call i32 @consume(...?types ?values)

;; ?wrapped == true
; CHECK-NEXT: constraint (== ?wrapped true)

;; ?bits + 2 * 3 == 7 && !false || sdiv(?bits, -2) != 0
; CHECK-NEXT: constraint (|| (&& (== (+ ?bits (* 2 3)) 7) (! false)) (!= (sdiv ?bits (- 2)) 0))

;; custom_predicate(?bits, urem(?bits, 4))
; CHECK-NEXT: constraint (custom_predicate ?bits (urem ?bits 4))

;; ?types[0] == ?types[1]
; CHECK-NEXT: constraint (== ?types[0] ?types[1])

;; ?values[?bits - 1] != ?x
; CHECK-NEXT: constraint (!= ?values[(- ?bits 1)] ?x)

;; isa(?x, "BinaryOperator")
; CHECK-NEXT: constraint (isa ?x "BinaryOperator")

;; ?predicate == "slt"
; CHECK-NEXT: constraint (== ?predicate "slt")

;; ?intrinsic != "llvm.sqrt"
; CHECK-NEXT: constraint (!= ?intrinsic "llvm.sqrt")

;; ?types == [?types[0], ?types[1]]
; CHECK-NEXT: constraint (== ?types [?types[0],?types[1]])

;; ?values != [?x, ?y]
; CHECK-NEXT: constraint (!= ?values [?x,?y])

;; ?types == ["i32", "ptr"]
; CHECK-NEXT: constraint (== ?types ["i32","ptr"])

;; ?x == "%argument"
; CHECK-NEXT: constraint (== ?x "%argument")

;; ["add", "sub"][1] == "sub"
; CHECK-NEXT: constraint (== ["add","sub"][1] "sub")

;; lshr(?bits, 1) == 16
; CHECK-NEXT: constraint (== (lshr ?bits 1) 16)

;; ashr(-8, 1) == -4
; CHECK-NEXT: constraint (== (ashr (- 8) 1) (- 4))
; CHECK-NEXT: meta ?wrapped type=i1
; CHECK-NEXT: meta ?bits type=Nat
; CHECK-NEXT: meta ?x type=Value
; CHECK-NEXT: meta ?y type=Value
; CHECK-NEXT: meta ?predicate type=CmpPredicate
; CHECK-NEXT: meta ?intrinsic type=Intrinsic::ID
; CHECK-NEXT: meta ?types type=Type[]
; CHECK-NEXT: meta ?values type=Value[]
; CHECK-NOT: {{.}}
