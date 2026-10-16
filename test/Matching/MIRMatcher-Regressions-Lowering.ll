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

; NOT-CONTEXT-NEXT: target 1: @unknown
; NOT-CONTEXT-NEXT:   match 0:
; NOT-CONTEXT-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

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

;--- add.ll
define i32 @add(i32 %a, i32 %b) {
  %r = add nsw i32 %a, %b
  ret i32 %r
}
; ARRAY-PARAM: target 0: @add
; ARRAY-PARAM-NEXT:   match 0:
; ARRAY-PARAM-NEXT:     {?a = %a, ?anch = %r, ?b = %b}

; FLAG-NO-CAPTURE: target 0: @add
; FLAG-NO-CAPTURE-NEXT:   match 0:
; FLAG-NO-CAPTURE-NEXT:     {?a = %a, ?anch = %r, ?b = %b}

; FLAG-RENAMED: target 0: @add
; FLAG-RENAMED-NEXT:   match 0:
; FLAG-RENAMED-NEXT:     {?a = %a, ?anch = %r, ?b = %b, ?c = true}

; META-FOR-FIXED: meta-for-fixed.mpir:4:16: error: matcher 'addi8' requires type 'i8' for a parameter, but this use passes 'i?n'
; META-FOR-FIXED-NEXT: %r = addi8 i?n ?a, ?b
; META-FOR-FIXED-NEXT: {{^}}               ^
