; A value-tracking operator resolves its use-point from the instruction the
; constraint follows. Inside a 'match' body that instruction is a template, so
; expansion rewrites the context to the copy inlined for each variant; a
; constraint written outside the matcher and anchored on the composite
; instruction is likewise rewritten to that variant's root.
;
; The input below makes the answer depend on *which* instruction is the context,
; not merely on one being present: the two multiplies are identical, and '%y' is
; known non-zero only in the block dominated by the 'icmp ne %y, 0' branch. A
; context pointing anywhere else would match both multiplies or neither.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/plain.mpir %t/guarded.ll | FileCheck %s --check-prefix=PLAIN
; RUN: %metaphir-match %t/in-body.mpir %t/guarded.ll | FileCheck %s --check-prefix=BODY
; RUN: %metaphir-match %t/on-composite.mpir %t/guarded.ll | FileCheck %s --check-prefix=COMP
; RUN: %metaphir-match %t/branches.mpir %t/guarded.ll | FileCheck %s --check-prefix=BRANCH

; Without the constraint both multiplies match, so the filtering below is the
; constraint's doing rather than a structural difference.
;--- plain.mpir
%r = mul:?anch i32 ?a, ?b

;--- in-body.mpir
match nzmul [] Binary (?ty ?x, ?y) {
	%ret = mul ?ty ?x, ?y
	;; isKnownNonZero(?y)
}

%r = nzmul:?anch i32 ?a, ?b

; The same operator, anchored on the composite instruction from outside.
;--- on-composite.mpir
match plainmul [] Binary (?ty ?x, ?y) {
	%ret = mul ?ty ?x, ?y
}

%p = plainmul:?anch i32 ?a, ?b
;; isKnownNonZero(?b)

; Every branch carries its own context, so each variant resolves independently.
;--- branches.mpir
match nzop [] Binary (?ty ?x, ?y) {
	%ret = mul ?ty ?x, ?y
	;; isKnownNonZero(?y)
} or {
	%ret = udiv ?ty ?x, ?y
	;; isKnownNonZero(?y)
}

%r = nzop:?anch i32 ?a, ?b

;--- guarded.ll
define i32 @guarded(i32 %x, i32 %y) {
entry:
  %c = icmp ne i32 %y, 0
  br i1 %c, label %then, label %else

then:
  %rt = mul i32 %x, %y
  ret i32 %rt

else:
  %re = mul i32 %x, %y
  ret i32 %re
}
; PLAIN: target 0: @guarded
; PLAIN-NEXT:   match 0:
; PLAIN-NEXT:     {?a = %x, ?anch = %rt, ?b = %y}
; PLAIN-NEXT:   match 1:
; PLAIN-NEXT:     {?a = %x, ?anch = %re, ?b = %y}

; BODY: target 0: @guarded
; BODY-NEXT:   match 0:
; BODY-NEXT:     {?a = %x, ?anch = %rt, ?b = %y}

; COMP: target 0: @guarded
; COMP-NEXT:   match 0:
; COMP-NEXT:     {?a = %x, ?anch = %rt, ?b = %y}

; BRANCH: target 0: @guarded
; BRANCH-NEXT:   match 0:
; BRANCH-NEXT:     {?a = %x, ?anch = %rt, ?b = %y}

define i32 @guarded_udiv(i32 %x, i32 %y) {
entry:
  %c = icmp ne i32 %y, 0
  br i1 %c, label %then, label %else

then:
  %rt = udiv i32 %x, %y
  ret i32 %rt

else:
  %re = udiv i32 %x, %y
  ret i32 %re
}
; PLAIN-NEXT: target 1: @guarded_udiv
; PLAIN-NEXT:   no match

; BODY-NEXT: target 1: @guarded_udiv
; BODY-NEXT:   no match

; COMP-NEXT: target 1: @guarded_udiv
; COMP-NEXT:   no match

; BRANCH-NEXT: target 1: @guarded_udiv
; BRANCH-NEXT:   match 0:
; BRANCH-NEXT:     {?a = %x, ?anch = %rt, ?b = %y}
