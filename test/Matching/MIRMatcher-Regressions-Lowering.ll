; Lowering (composite inlining and metaflag desugaring) regressions.
; RUN: split-file %s %t
; RUN: %metaphir-match %t/nested-context.mpir %t/nonzero.ll | FileCheck %s --check-prefix=NESTED-CONTEXT
; RUN: %metaphir-match %t/not-context.mpir %t/nonzero.ll | FileCheck %s --check-prefix=NOT-CONTEXT
; RUN: %metaphir-match %t/hygiene.mpir %t/hygiene.ll | FileCheck %s --check-prefix=HYGIENE
; RUN: %metaphir-match %t/array-param.mpir %t/add.ll | FileCheck %s --check-prefix=ARRAY-PARAM
; RUN: %metaphir-match %t/flag-no-capture.mpir %t/add.ll | FileCheck %s --check-prefix=FLAG-NO-CAPTURE
; RUN: %metaphir-match %t/flag-renamed-capture.mpir %t/add.ll | FileCheck %s --check-prefix=FLAG-RENAMED
; RUN: %metaphir-match %t/nested-type.mpir %t/bitcast.ll | FileCheck %s --check-prefix=NESTED-TYPE
; RUN: %metaphir-match %t/concrete-width.mpir %t/signum.ll | FileCheck %s --check-prefix=CONCRETE-WIDTH
; RUN: %metaphir-match %t/nested-composite.mpir %t/nested-composite.ll | FileCheck %s --check-prefix=NESTED-COMPOSITE
; RUN: not %metaphir-match %t/meta-for-fixed.mpir %t/add.ll 2>&1 | FileCheck %s --check-prefix=META-FOR-FIXED
; RUN: not %metaphir-match %t/or-self-unbound.mpir %t/zext.ll 2>&1 | FileCheck %s --check-prefix=OR-SELF-UNBOUND
; RUN: %metaphir-match %t/or-self-unnamed.mpir %t/zext.ll | FileCheck %s --check-prefix=OR-SELF-UNNAMED
; RUN: not %metaphir-match %t/or-self-nested.mpir %t/zext.ll 2>&1 | FileCheck %s --check-prefix=OR-SELF-NESTED
; RUN: %metaphir-match %t/use-operand-flag.mpir %t/consts.ll | FileCheck %s --check-prefix=USE-OPERAND-FLAG
; RUN: %metaphir-match %t/nested-operand-flag.mpir %t/consts.ll | FileCheck %s --check-prefix=NESTED-OPERAND-FLAG

; A value-tracking operator nested inside a metaflag body is evaluated at the
; instruction the flag is written on, like a top-level one.
;--- nested-context.mpir
metaflag :nzAndTrue(?v) {
  isKnownNonZero(?v) && true
}
%r = add:?anch i32 ?x:nzAndTrue, ?y

;--- not-context.mpir
metaflag :nz(?v) {
  isKnownNonZero(?v)
}
%r = add:?anch i32 ?x:not(:nz), ?y

;--- nonzero.ll
define i32 @nonzero(i32 %a, i32 %b) {
  %x = or i32 %a, 1
  %r = add i32 %x, %b
  ret i32 %r
}
; NESTED-CONTEXT: target 0: @nonzero
; NESTED-CONTEXT-NEXT:   match 0:
; NESTED-CONTEXT-NEXT:     {?anch = %r, ?x = %x, ?y = %b}

; NOT-CONTEXT: target 0: @nonzero
; NOT-CONTEXT-NEXT:   no match
; NOT-CONTEXT-NEXT:   constraint not satisfied: (! (isKnownNonZero ?x))

define i32 @unknown(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
; NESTED-CONTEXT-NEXT: target 1: @unknown
; NESTED-CONTEXT-NEXT:   no match
; NESTED-CONTEXT-NEXT:   constraint not satisfied: (&& (isKnownNonZero ?x) true)
; NESTED-CONTEXT-NOT: {{.}}

; NOT-CONTEXT-NEXT: target 1: @unknown
; NOT-CONTEXT-NEXT:   match 0:
; NOT-CONTEXT-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; NOT-CONTEXT-NOT: {{.}}

; Each use of a matcher gets its own copy of the branch's local meta
; variables: the two uses below bind '?k' independently.
;--- hygiene.mpir
match addk [] Unary (?t ?x) {
  %ret = add ?t ?x, ?k
}
%a = addk i32 ?p
%b = addk:?anch i32 %a

;--- hygiene.ll
define i32 @different_constants(i32 %p) {
  %a = add i32 %p, 1
  %b = add i32 %a, 2
  ret i32 %b
}
; HYGIENE: target 0: @different_constants
; HYGIENE-NEXT:   match 0:
; HYGIENE-NEXT:     {?a$k = 1, ?anch = %b, ?b$k = 2, ?p = %p}
; HYGIENE-NOT: {{.}}

; Parameters are substituted inside array constraints too.
;--- array-param.mpir
match addarr [] Binary (?t ?x, ?y) {
  %ret = add nsw ?t ?x, ?y
  ;; [?x, ?y][1] == ?y
}
%r = addarr:?anch i32 ?a, ?b

; A flag the use requires without a capture makes the branch's capture true.
;--- flag-no-capture.mpir
match addnsw [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?nsw ?ty ?x, ?y
  ;; ?nsw
}
%r = addnsw:?anch nsw i32 ?a, ?b

; The branch's flag capture is replaced by the use's capture whatever it is
; called.
;--- flag-renamed-capture.mpir
match addnsw [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?f ?ty ?x, ?y
  ;; ?f
}
%r = addnsw:?anch nsw:?c i32 ?a, ?b

; Meta types are substituted inside derived types.
;--- nested-type.mpir
match castv [] Cast (?t ?x to ?u) {
  %ret = bitcast ?t ?x to <2 x ?u>
}
%r = castv:?anch i64 ?a to i32

;--- bitcast.ll
define <2 x i32> @to_int(i64 %a) {
  %r = bitcast i64 %a to <2 x i32>
  ret <2 x i32> %r
}
; NESTED-TYPE: target 0: @to_int
; NESTED-TYPE-NEXT:   match 0:
; NESTED-TYPE-NEXT:     {?a = %a, ?anch = %r}

define <2 x float> @to_float(i64 %a) {
  %r = bitcast i64 %a to <2 x float>
  ret <2 x float> %r
}
; NESTED-TYPE-NEXT: target 1: @to_float
; NESTED-TYPE-NEXT:   no match
; NESTED-TYPE-NOT: {{.}}

; A concrete integer type binds the width of an 'i?bits' parameter, which the
; branch's constraints can use.
;--- concrete-width.mpir
%r = signum:?anch i32 ?x

;--- signum.ll
define i32 @signum_i32(i32 %x) {
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %r = or i32 %lhs, %rhs
  ret i32 %r
}
; CONCRETE-WIDTH: target 0: @signum_i32
; CONCRETE-WIDTH-NEXT:   match 0:
; CONCRETE-WIDTH-NEXT:     {?anch = %r, ?x = %x}
; CONCRETE-WIDTH-NOT: {{.}}

; A use cannot pass a meta type where the matcher fixes a concrete one.
;--- meta-for-fixed.mpir
match addi8 [] Binary (i8 ?x, ?y) {
  %ret = add i8 ?x, ?y
}
%r = addi8 i?n ?a, ?b
;--- nested-composite.mpir
; A matcher's body may itself use a matcher.
match addmul [] Binary (?t ?x, ?y) {
  %s = addLike ?t ?x, ?y
  %ret = mul ?t %s, 2
}
%r = addmul:?anch i32 ?a, ?b

;--- nested-composite.ll
define i32 @nested(i32 %a, i32 %b) {
  %s = add i32 %a, %b
  %r = mul i32 %s, 2
  ret i32 %r
}
; NESTED-COMPOSITE: target 0: @nested
; NESTED-COMPOSITE-NEXT:   match 0:
; NESTED-COMPOSITE-NEXT:     {?a = %a, ?anch = %r, ?b = %b}
; NESTED-COMPOSITE-NOT: {{.}}

;--- add.ll
define i32 @add(i32 %a, i32 %b) {
  %r = add nsw i32 %a, %b
  ret i32 %r
}
; ARRAY-PARAM: target 0: @add
; ARRAY-PARAM-NEXT:   match 0:
; ARRAY-PARAM-NEXT:     {?a = %a, ?anch = %r, ?b = %b}
; ARRAY-PARAM-NOT: {{.}}

; FLAG-NO-CAPTURE: target 0: @add
; FLAG-NO-CAPTURE-NEXT:   match 0:
; FLAG-NO-CAPTURE-NEXT:     {?a = %a, ?anch = %r, ?b = %b}
; FLAG-NO-CAPTURE-NOT: {{.}}

; FLAG-RENAMED: target 0: @add
; FLAG-RENAMED-NEXT:   match 0:
; FLAG-RENAMED-NEXT:     {?a = %a, ?anch = %r, ?b = %b, ?c = true}
; FLAG-RENAMED-NOT: {{.}}

; When ':o' lets an instruction match its operand, the variables only its
; other parts bind would be left unbound: such a variable must be given a
; '_'-prefixed name (e.g. '?_n').
;--- or-self-unbound.mpir
%z = zext:o i?n ?x to i32
%r = add i32 %z, 1
; Also those of an operand instruction it would match.
;--- or-self-nested.mpir
%y = mul i32 ?c, ?d
%x = add:o(1) i32 %y, ?b
%r = sub i32 %x, 1
; A '_'-prefixed name may be left unbound.
;--- or-self-unnamed.mpir
%z = zext:o i?_n ?x to i32
%r = add i32 %z, 1

;--- zext.ll
define i32 @g(i8 %x) {
  %z = zext i8 %x to i32
  %r = add i32 %z, 1
  ret i32 %r
}
; OR-SELF-UNNAMED: target 0: @g
; OR-SELF-UNNAMED-NEXT:   match 0:
; OR-SELF-UNNAMED-NEXT:     {?x = %z}
; OR-SELF-UNNAMED-NEXT:   match 1:
; OR-SELF-UNNAMED-NEXT:     {?x = %x}
; OR-SELF-UNNAMED-NOT: {{.}}

; A metaflag on an operand of a composite matcher's use constrains the value
; passed there, as on a primitive instruction, also when the use is in
; another matcher's body.
;--- use-operand-flag.mpir
%r = addLike i32 ?x, ?c:allOnes

;--- nested-operand-flag.mpir
match outer [] Binary (?ty ?p, ?q) {
  %ret = addLike ?ty ?p, ?q:allOnes
}
%r = outer i32 ?x, ?c

;--- consts.ll
define i32 @add_m1(i32 %x) {
  %r = add i32 %x, -1
  ret i32 %r
}
; USE-OPERAND-FLAG: target 0: @add_m1
; USE-OPERAND-FLAG-NEXT:   match 0:
; USE-OPERAND-FLAG-NEXT:     {?c = -1, ?x = %x}

; NESTED-OPERAND-FLAG: target 0: @add_m1
; NESTED-OPERAND-FLAG-NEXT:   match 0:
; NESTED-OPERAND-FLAG-NEXT:     {?c = -1, ?x = %x}

define i32 @add_5(i32 %x) {
  %r = add i32 %x, 5
  ret i32 %r
}
; USE-OPERAND-FLAG-NEXT: target 1: @add_5
; USE-OPERAND-FLAG-NEXT:   no match
; USE-OPERAND-FLAG-NEXT:   constraint not satisfied: (isAllOnes ?c)
; USE-OPERAND-FLAG-NOT: {{.}}

; NESTED-OPERAND-FLAG-NEXT: target 1: @add_5
; NESTED-OPERAND-FLAG-NEXT:   no match
; NESTED-OPERAND-FLAG-NEXT:   constraint not satisfied: (isAllOnes ?c)
; NESTED-OPERAND-FLAG-NOT: {{.}}

; META-FOR-FIXED: error: matcher 'addi8' requires type 'i8' for a parameter, but this use passes 'i?n'
; META-FOR-FIXED-NEXT: %r = addi8 i?n ?a, ?b
; META-FOR-FIXED-NEXT:                ^
; META-FOR-FIXED-NOT: {{.}}

; OR-SELF-UNBOUND: error: meta variable '?n' is not bound when ':o' lets 'zext' match its operand; name it '?_n' if it need not be bound
; OR-SELF-UNBOUND-NEXT: %z = zext:o i?n ?x to i32
; OR-SELF-UNBOUND-NEXT:             ^
; OR-SELF-UNBOUND-NOT: {{.}}

; OR-SELF-NESTED: error: meta variable '?c' is not bound when ':o' lets 'add' match its operand; name it '?_c' if it need not be bound
; OR-SELF-NESTED-NEXT: %y = mul i32 ?c, ?d
; OR-SELF-NESTED-NEXT:              ^
; OR-SELF-NESTED-NOT: {{.}}
