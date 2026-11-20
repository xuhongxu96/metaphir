; RUN: split-file %s %t
; RUN: %metaphir-match %t/predicate.mpir %t/compare.ll | FileCheck %s --check-prefix=PREDICATE
; RUN: %metaphir-match %t/integer.mpir %t/widths.ll | FileCheck %s --check-prefix=INTEGER
; RUN: %metaphir-match %t/agree.mpir %t/operands.ll | FileCheck %s --check-prefix=AGREE
; RUN: %metaphir-match %t/value.mpir %t/operands.ll | FileCheck %s --check-prefix=VALUE
; RUN: %metaphir-match %t/chain.mpir %t/widths.ll | FileCheck %s --check-prefix=CHAIN
; RUN: %metaphir-match %t/in-matcher.mpir %t/widths.ll | FileCheck %s --check-prefix=MATCHER
; RUN: %metaphir-match %t/in-alternative.mpir %t/mixed.ll | FileCheck %s --check-prefix=ALTERNATIVE
; RUN: %metaphir-match %t/unevaluable.mpir %t/widths.ll | FileCheck %s --check-prefix=UNEVALUABLE
; RUN: %metaphir-match %t/boolean.mpir %t/operands.ll | FileCheck %s --check-prefix=BOOLEAN
; RUN: %metaphir-match %t/width.mpir %t/widths.ll | FileCheck %s --check-prefix=WIDTH
; RUN: %metaphir-match %t/constant.mpir %t/constants.ll | FileCheck %s --check-prefix=CONSTANT
; RUN: %metaphir-match %t/type.mpir %t/widths.ll | FileCheck %s --check-prefix=TYPE
; RUN: not %metaphir-parse %t/wildcard.mpir 2>&1 | FileCheck %s --check-prefix=WILDCARD
; RUN: not %metaphir-parse %t/in-definition.mpir 2>&1 | FileCheck %s --check-prefix=IN-DEFINITION
; RUN: %metaphir-match %t/or-self.mpir %t/zexts.ll | FileCheck %s --check-prefix=OR-SELF
; RUN: not %metaphir-parse %t/twice.mpir 2>&1 | FileCheck %s --check-prefix=TWICE
; RUN: not %metaphir-parse %t/forward.mpir 2>&1 | FileCheck %s --check-prefix=FORWARD
; RUN: not %metaphir-parse %t/self.mpir 2>&1 | FileCheck %s --check-prefix=SELF
; RUN: not %metaphir-parse %t/cycle.mpir 2>&1 | FileCheck %s --check-prefix=CYCLE
; RUN: not %metaphir-parse %t/string.mpir 2>&1 | FileCheck %s --check-prefix=STRING
; RUN: not %metaphir-parse %t/no-variable.mpir 2>&1 | FileCheck %s --check-prefix=NO-VARIABLE
; RUN: not %metaphir-parse %t/no-expression.mpir 2>&1 | FileCheck %s --check-prefix=NO-EXPRESSION

; 'let ?v = expression' is a constraint that binds a meta variable to the
; value of an expression. If ?v is not bound yet it is bound to the value and
; the constraint holds; if it is, the constraint holds when the value is the
; one ?v is bound to. A variable is the target of at most one 'let', and an
; expression refers only to variables written before it.

;--- compare.ll
define i1 @slt(i32 %a, i32 %b) {
  %c = icmp slt i32 %a, %b
  ret i1 %c
}
; PREDICATE: target 0: @slt
; PREDICATE-NEXT:   match 0:
; PREDICATE-NEXT:     {?anch = %c, ?pred = slt, ?swapped = sgt, ?x = %a, ?y = %b}

define i1 @sgt(i32 %a, i32 %b) {
  %c = icmp sgt i32 %a, %b
  ret i1 %c
}
; PREDICATE-NEXT: target 1: @sgt
; PREDICATE-NEXT:   no match
; PREDICATE-NEXT:   constraint not satisfied: (== ?swapped "sgt")
; PREDICATE-NOT: {{.}}

;--- predicate.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; let ?swapped = swappedPredicate(?pred)
;; ?swapped == "sgt"
;--- widths.ll
define i32 @i32(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
; INTEGER: target 0: @i32
; INTEGER-NEXT:   match 0:
; INTEGER-NEXT:     {?anch = %r, ?bits = 32, ?double = 64, ?x = %a, ?y = %b}

; CHAIN: target 0: @i32
; CHAIN-NEXT:   match 0:
; CHAIN-NEXT:     {?anch = %r, ?bits = 32, ?double = 64, ?quad = 128, ?x = %a, ?y = %b}

; MATCHER: target 0: @i32
; MATCHER-NEXT:   match 0:
; MATCHER-NEXT:     {?a = %a, ?anch = %r, ?r$double = 64, ?r$k = %b, ?w = 32}

; UNEVALUABLE: target 0: @i32
; UNEVALUABLE-NEXT:   no match
; UNEVALUABLE-NEXT:   constraint not satisfied: (== ?q (udiv ?bits 0)) (cannot evaluate: division by zero)

; WIDTH: target 0: @i32
; WIDTH-NEXT:   match 0:
; WIDTH-NEXT:     {?anch = %r, ?bits = 32, ?x = %a, ?y = %b}

; TYPE: target 0: @i32
; TYPE-NEXT:   match 0:
; TYPE-NEXT:     {?anch = %r, ?same = i32, ?ty = i32, ?x = %a, ?y = %b}

define i64 @i64(i64 %a, i64 %b) {
  %r = add i64 %a, %b
  ret i64 %r
}
; INTEGER-NEXT: target 1: @i64
; INTEGER-NEXT:   no match
; INTEGER-NEXT:   constraint not satisfied: (== ?double 64)
; INTEGER-NOT: {{.}}

; CHAIN-NEXT: target 1: @i64
; CHAIN-NEXT:   no match
; CHAIN-NEXT:   constraint not satisfied: (== ?quad 128)
; CHAIN-NOT: {{.}}

; MATCHER-NEXT: target 1: @i64
; MATCHER-NEXT:   no match
; MATCHER-NEXT:   constraint not satisfied: (== ?r$double 64)
; MATCHER-NOT: {{.}}

; UNEVALUABLE-NEXT: target 1: @i64
; UNEVALUABLE-NEXT:   no match
; UNEVALUABLE-NEXT:   constraint not satisfied: (== ?q (udiv ?bits 0)) (cannot evaluate: division by zero)
; UNEVALUABLE-NOT: {{.}}

; WIDTH-NEXT: target 1: @i64
; WIDTH-NEXT:   no match
; WIDTH-NEXT:   constraint not satisfied: (== ?bits 32)
; WIDTH-NOT: {{.}}

; TYPE-NEXT: target 1: @i64
; TYPE-NEXT:   match 0:
; TYPE-NEXT:     {?anch = %r, ?same = i64, ?ty = i64, ?x = %a, ?y = %b}
; TYPE-NOT: {{.}}

;--- integer.mpir
%r = add:?anch i?bits ?x, ?y
;; let ?double = ?bits * 2
;; ?double == 64
; A 'let' may read a variable another 'let' bound.
;--- chain.mpir
%r = add:?anch i?bits ?x, ?y
;; let ?double = ?bits * 2
;; let ?quad = ?double * 2
;; ?quad == 128
;--- operands.ll
define i32 @same(i32 %a) {
  %r = add i32 %a, %a
  ret i32 %r
}
; AGREE: target 0: @same
; AGREE-NEXT:   match 0:
; AGREE-NEXT:     {?anch = %r, ?x = %a, ?y = %a}

; VALUE: target 0: @same
; VALUE-NEXT:   match 0:
; VALUE-NEXT:     {?anch = %r, ?x = %a, ?y = %a, ?z = %a}

; BOOLEAN: target 0: @same
; BOOLEAN-NEXT:   match 0:
; BOOLEAN-NEXT:     {?anch = %r, ?same = true, ?x = %a, ?y = %a}

define i32 @different(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
; AGREE-NEXT: target 1: @different
; AGREE-NEXT:   no match
; AGREE-NEXT:   constraint not satisfied: (== ?y ?x)
; AGREE-NOT: {{.}}

; VALUE-NEXT: target 1: @different
; VALUE-NEXT:   no match
; VALUE-NEXT:   constraint not satisfied: (== ?z ?y)
; VALUE-NOT: {{.}}

; BOOLEAN-NEXT: target 1: @different
; BOOLEAN-NEXT:   no match
; BOOLEAN-NEXT:   constraint not satisfied: ?same
; BOOLEAN-NOT: {{.}}

; A variable the match already bound must agree with the expression.
;--- agree.mpir
%r = add:?anch i32 ?x, ?y
;; let ?y = ?x
;--- value.mpir
%r = add:?anch i32 ?x, ?y
;; let ?z = ?x
;; ?z == ?y
; A 'let' in a matcher's branch is the use's, with its variables renamed.
;--- in-matcher.mpir
match doubled [] Unary (i?bits ?x) {
  %ret = add i?bits ?x, ?k
  ;; let ?double = ?bits * 2
  ;; ?double == 64
}
%r = doubled:?anch i?w ?a
;--- mixed.ll
define i32 @adds(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
; ALTERNATIVE: target 0: @adds
; ALTERNATIVE-NEXT:   match 0:
; ALTERNATIVE-NEXT:     {?a = %a, ?anch = %r, ?b = %b, ?r$tag = 1}

define i32 @subs(i32 %a, i32 %b) {
  %r = sub i32 %a, %b
  ret i32 %r
}
; ALTERNATIVE-NEXT: target 1: @subs
; ALTERNATIVE-NEXT:   match 0:
; ALTERNATIVE-NEXT:     {?a = %a, ?anch = %r, ?b = %b, ?r$tag = 2}
; ALTERNATIVE-NOT: {{.}}

; A 'let' in one branch binds its variable in that alternative only.
;--- in-alternative.mpir
match kind [] Binary (?ty ?x, ?y) {
  %ret = add ?ty ?x, ?y
  ;; let ?tag = 1
} or {
  %ret = sub ?ty ?x, ?y
  ;; let ?tag = 2
}
%r = kind:?anch i32 ?a, ?b
; An expression that cannot be evaluated rejects the match.
;--- unevaluable.mpir
%r = add:?anch i?bits ?x, ?y
;; let ?q = udiv(?bits, 0)
;; ?q == 0
;--- boolean.mpir
%r = add:?anch i32 ?x, ?y
;; let ?same = ?x == ?y
;; ?same
; A variable the match bound from a type is compared with the value, which
; is what '==' compares.
;--- width.mpir
%r = add:?anch i?bits ?x, ?y
;; let ?bits = 32
;--- constants.ll
define i32 @plus2(i32 %a) {
  %r = add i32 %a, 2
  ret i32 %r
}
; CONSTANT: target 0: @plus2
; CONSTANT-NEXT:   match 0:
; CONSTANT-NEXT:     {?anch = %r, ?x = %a, ?y = 2}

define i32 @plus3(i32 %a) {
  %r = add i32 %a, 3
  ret i32 %r
}
; CONSTANT-NEXT: target 1: @plus3
; CONSTANT-NEXT:   no match
; CONSTANT-NEXT:   constraint not satisfied: (== ?y 2)
; CONSTANT-NOT: {{.}}

; An operand bound to a constant is compatible with the number it equals.
;--- constant.mpir
%r = add:?anch i32 ?x, ?y
;; let ?y = 2
;--- type.mpir
%r = add:?anch ?ty ?x, ?y
;; let ?same = ?ty
;; ?same == ?ty
;--- wildcard.mpir
%r = add i32 ?x, ?y
;; let ?_ = ?x
; WILDCARD: 'let' cannot bind '?_'

; A definition's body is an expression; it has no 'let'.
;--- in-definition.mpir
constraint same(?a, ?b) {
  let ?c = ?a
; IN-DEFINITION: expected constraint expression

}
; ':o' lets 'add' match its operand, which leaves '?y' unbound; a 'let' binds
; it either way.
;--- zexts.ll
define i32 @adds(i32 %a) {
  %r = add i32 %a, 5
  ret i32 %r
}
; OR-SELF: target 0: @adds
; OR-SELF-NEXT:   match 0:
; OR-SELF-NEXT:     {?anch = %r, ?x = %r, ?y = 5}
; OR-SELF-NEXT:   match 1:
; OR-SELF-NEXT:     {?anch = %r, ?x = %a, ?y = 5}
; OR-SELF-NEXT:   match 2:
; OR-SELF-NEXT:     {?anch = <badref>, ?x = <badref>, ?y = 5}

define i32 @alone(i32 %a) {
  ret i32 %a
}
; OR-SELF-NEXT: target 1: @alone
; OR-SELF-NEXT:   match 0:
; OR-SELF-NEXT:     {?anch = <badref>, ?x = <badref>, ?y = 5}
; OR-SELF-NOT: {{.}}

;--- or-self.mpir
%r = add:?anch:o i32 ?x, ?y
;; let ?y = 5

; Matching the operand binds '?y' by the 'let' only, in every match.
;--- twice.mpir
%r = add i32 ?x, ?y
;; let ?z = ?x
;; let ?z = ?y
; TWICE: meta variable '?z' is already bound by a 'let'

;--- forward.mpir
%r = add i32 ?x, ?y
;; let ?z = ?later
; FORWARD: constraint references unknown meta variable '?later'

%s = mul i32 %r, ?later
;--- self.mpir
%r = add i32 ?x, ?y
;; let ?z = ?z + 1
; SELF: constraint references unknown meta variable '?z'

; Two 'let's cannot read each other: the second would have to come first.
;--- cycle.mpir
%r = add i32 ?x, ?y
;; let ?a = ?b + 1
; CYCLE: constraint references unknown meta variable '?b'

;; let ?b = ?a + 1
; The variable gets the expression's sort; a string cannot be a binding.
;--- string.mpir
%r = add i32 ?x, ?y
;; let ?s = "add"
; STRING: 'let' cannot bind a string

;--- no-variable.mpir
%r = add i32 ?x, ?y
;; let 1 = ?x
; NO-VARIABLE: expected a meta variable after 'let'

;--- no-expression.mpir
%r = add i32 ?x, ?y
;; let ?z
; NO-EXPRESSION: expected '=' after the variable of 'let' (got end of line)
