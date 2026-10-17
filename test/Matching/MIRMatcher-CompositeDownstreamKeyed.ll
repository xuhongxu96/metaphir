; RUN: split-file %s %t
; RUN: %metaphir-match %t/keyed.mpir %t/input.ll | FileCheck %s --check-prefix=KEYED
; RUN: %metaphir-match %t/noroot.mpir %t/input.ll | FileCheck %s --check-prefix=NOROOT
; RUN: %metaphir-match %t/same-name.mpir %t/same-name.ll | FileCheck %s --check-prefix=SAME-NAME

;--- keyed.mpir
%sum = addLike i32 ?x, ?y
%cmp = icmp:?anch eq i32 %sum, 0

;--- noroot.mpir
match addcustom [] Binary (?ty ?x, ?y) {
	%out = add ?ty ?x, ?y
}

%sum = addcustom i32 ?x, ?y
%cmp = icmp:?anch eq i32 %sum, 0

;--- same-name.mpir
; The branch parameter '?x' and the intermediate instruction '%x' are
; intentionally distinct values despite sharing a spelling.
match shadow [] Binary (?ty ?x, ?y) {
	%x = add ?ty ?x, ?y
	%ret = mul ?ty %x, ?y
}

%r = shadow i32 ?a, ?b

;--- input.ll
define i1 @match_eq(i32 %a, i32 %b) {
entry:
  %s = add i32 %a, %b
  %c = icmp eq i32 %s, 0
  ret i1 %c
}
; KEYED: target 0: @match_eq
; KEYED-NEXT:   match 0:
; KEYED-NEXT:     {?anch = %c, ?x = %a, ?y = %b}
; KEYED-NOT: {{.}}

; NOROOT: target 0: @match_eq
; NOROOT-NEXT:   match 0:
; NOROOT-NEXT:     {?anch = %c, ?x = %a, ?y = %b}
; NOROOT-NOT: {{.}}

;--- same-name.ll
define i32 @same_name(i32 %a, i32 %b) {
entry:
  %x = add i32 %a, %b
  %r = mul i32 %x, %b
  ret i32 %r
}
; SAME-NAME: target 0: @same_name
; SAME-NAME-NEXT:   match 0:
; SAME-NAME-NEXT:     {?a = %a, ?b = %b}

define i1 @no_mul(i32 %a, i32 %b) {
entry:
  %s = add i32 %a, %b
  %c = icmp ne i32 %s, 0
  ret i1 %c
}
; SAME-NAME-NEXT: target 1: @no_mul
; SAME-NAME-NEXT:   no match
; SAME-NAME-NOT: {{.}}
