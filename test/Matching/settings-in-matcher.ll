; A pattern setting applies to the instructions that follow it, so an
; instruction inlined from a 'match' body takes the setting active at the *use*
; site. A body may write a setting of its own, which overrides the use site;
; anything the body leaves alone is inherited.
;
; 'treatIntAsVec' is the observable setting here: with it on, the scalar
; 'i?bits' also matches the vector '<2 x i32>' below.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/none.mpir %t/vec.ll | FileCheck %s --check-prefix=NONE
; RUN: %metaphir-match %t/at-use.mpir %t/vec.ll | FileCheck %s --check-prefix=USE
; RUN: %metaphir-match %t/in-body.mpir %t/vec.ll | FileCheck %s --check-prefix=BODY
; RUN: %metaphir-match %t/body-overrides.mpir %t/vec.ll | FileCheck %s --check-prefix=OVERRIDE
; RUN: %metaphir-match %t/off-at-use.mpir %t/vec.ll | FileCheck %s --check-prefix=OFFUSE
; RUN: %metaphir-match %t/declaration-only.mpir %t/vec.ll | FileCheck %s --check-prefix=DECL

; Baseline: without the setting a scalar type does not match a vector.
;--- none.mpir
match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addm:?anch i?bits ?a, ?b
; The body says nothing, so the use site's setting is inherited.
;--- at-use.mpir
match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

;; treatIntAsVec(true)
%r = addm:?anch i?bits ?a, ?b
; A body may require the setting even when the use site is silent.
;--- in-body.mpir
match addm [] Binary (?ty ?x, ?y) {
	;; treatIntAsVec(true)
	%ret = add ?ty ?x, ?y
}

%r = addm:?anch i?bits ?a, ?b
; What the body writes wins over the use site.
;--- body-overrides.mpir
match addm [] Binary (?ty ?x, ?y) {
	;; treatIntAsVec(false)
	%ret = add ?ty ?x, ?y
}

;; treatIntAsVec(true)
%r = addm:?anch i?bits ?a, ?b
; Turning the setting off at the use site is inherited just as turning it on is.
;--- off-at-use.mpir
match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

;; treatIntAsVec(false)
%r = addm:?anch i?bits ?a, ?b
; The declaration must not capture whatever setting happened to be active
; around it: on at the declaration, off at the use.
;--- declaration-only.mpir
;; treatIntAsVec(true)

match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

;; treatIntAsVec(false)
%r = addm:?anch i?bits ?a, ?b
;--- vec.ll
define <2 x i32> @vec(<2 x i32> %x, <2 x i32> %y) {
  %r = add <2 x i32> %x, %y
  ret <2 x i32> %r
}
; NONE: target 0: @vec
; NONE-NEXT:   no match
; NONE-NOT: {{.}}

; USE: target 0: @vec
; USE-NEXT:   match 0:
; USE-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?bits = 32}
; USE-NOT: {{.}}

; BODY: target 0: @vec
; BODY-NEXT:   match 0:
; BODY-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?bits = 32}
; BODY-NOT: {{.}}

; OVERRIDE: target 0: @vec
; OVERRIDE-NEXT:   no match
; OVERRIDE-NOT: {{.}}

; OFFUSE: target 0: @vec
; OFFUSE-NEXT:   no match
; OFFUSE-NOT: {{.}}

; DECL: target 0: @vec
; DECL-NEXT:   no match
; DECL-NOT: {{.}}
