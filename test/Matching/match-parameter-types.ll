; A 'match' parameter list is parsed with the same routines as pattern
; operands, so a type position accepts any type. Leaving it open ('?ty') binds
; the caller's type, while writing a concrete one ('i8', 'i1') restricts the
; matcher to that type.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/fixed.mpir %t/input.ll | FileCheck %s --check-prefix=FIXED
; RUN: %metaphir-match %t/open.mpir %t/input.ll | FileCheck %s --check-prefix=OPEN
; RUN: %metaphir-match %t/use-fixed.mpir %t/input.ll | FileCheck %s --check-prefix=USEFIX
; RUN: %metaphir-match %t/use-metaint.mpir %t/input.ll | FileCheck %s --check-prefix=USEBITS
; RUN: %metaphir-match %t/nary.mpir %t/select.ll | FileCheck %s --check-prefix=NARY

;--- fixed.mpir
match addi8 [] Binary (i8 ?x, ?y) {
	%ret = add i8 ?x, ?y
}

%r = addi8:?anch i8 ?a, ?b

;--- open.mpir
match addany [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addany:?anch ?ty2 ?a, ?b

; An open parameter leaves the choice to the caller, which may fix the type for
; one particular use without restricting the matcher itself.
;--- use-fixed.mpir
match addany [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addany:?anch i32 ?a, ?b

; The caller may equally pass a width-parameterised type and bind the width.
;--- use-metaint.mpir
match addany [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
}

%r = addany:?anch i?bits ?a, ?b

;--- input.ll
define i8 @narrow(i8 %x, i8 %y) {
  %r = add i8 %x, %y
  ret i8 %r
}
; FIXED: target 0: @narrow
; FIXED-NEXT:   match 0:
; FIXED-NEXT:     {?a = %x, ?anch = %r, ?b = %y}

; OPEN: target 0: @narrow
; OPEN-NEXT:   match 0:
; OPEN-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?ty2 = i8}

; USEFIX: target 0: @narrow
; USEFIX-NEXT:   no match

; USEBITS: target 0: @narrow
; USEBITS-NEXT:   match 0:
; USEBITS-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?bits = 8}

define i32 @wide(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}
; FIXED-NEXT: target 1: @wide
; FIXED-NEXT:   no match
; FIXED-NOT: {{.}}

; OPEN-NEXT: target 1: @wide
; OPEN-NEXT:   match 0:
; OPEN-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?ty2 = i32}
; OPEN-NOT: {{.}}

; USEFIX-NEXT: target 1: @wide
; USEFIX-NEXT:   match 0:
; USEFIX-NEXT:     {?a = %x, ?anch = %r, ?b = %y}
; USEFIX-NOT: {{.}}

; USEBITS-NEXT: target 1: @wide
; USEBITS-NEXT:   match 0:
; USEBITS-NEXT:     {?a = %x, ?anch = %r, ?b = %y, ?bits = 32}
; USEBITS-NOT: {{.}}

; Nary operands are typed individually, so the list has a type before each.
;--- nary.mpir
match pick [] Nary (i1 ?c, ?ty ?t, ?ty ?f) {
	%ret = select i1 ?c, ?ty ?t, ?ty ?f
}

%r = pick:?anch i1 ?cond, i32 ?a, i32 ?b

;--- select.ll
define i32 @sel(i1 %c, i32 %a, i32 %b) {
  %r = select i1 %c, i32 %a, i32 %b
  ret i32 %r
}
; NARY: target 0: @sel
; NARY-NEXT:   match 0:
; NARY-NEXT:     {?a = %a, ?anch = %r, ?b = %b, ?cond = %c}
; NARY-NOT: {{.}}
