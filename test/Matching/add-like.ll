; RUN: split-file %s %t
; RUN: %metaphir-match %t/addlike-flags.mpir %t/input.ll | FileCheck %s --check-prefix=FLAGS
; RUN: %metaphir-match %t/addlike-plain.mpir %t/input.ll | FileCheck %s --check-prefix=PLAIN
; RUN: %metaphir-match %t/addlike-negated.mpir %t/input.ll | FileCheck %s --check-prefix=NEG
; RUN: %metaphir-match %t/addlike-captured.mpir %t/input.ll | FileCheck %s --check-prefix=CAP
; RUN: %metaphir-match %t/addlike-nsw.mpir %t/input.ll | FileCheck %s --check-prefix=NSW
; RUN: %metaphir-match %t/ordinary-plain.mpir %t/input.ll | FileCheck %s --check-prefix=ORDINARY
; RUN: %metaphir-match %t/ordinary-negated.mpir %t/input.ll | FileCheck %s --check-prefix=ORDINARY-NEG

;--- addlike-flags.mpir
%r = addLike:?anch nsw nuw i32 ?x, ?y

; Omitted flags match either way, including the 'or disjoint' branch.
;--- addlike-plain.mpir
%r = addLike:?anch i32 ?x, ?y

; '!flag' requires the flag to be absent, so the 'or disjoint' branch, which
; fixes both flags to true, is dropped.
;--- addlike-negated.mpir
%r = addLike:?anch !nsw !nuw i32 ?x, ?y

;--- addlike-captured.mpir
%r = addLike:?anch nsw:?mynsw nuw:?mynuw i32 ?x, ?y

;--- addlike-nsw.mpir
%r = addLike:?anch nsw i32 ?x, ?y

; An ordinary instruction also matches regardless of omitted flags.
;--- ordinary-plain.mpir
%r = add:?anch i32 ?x, ?y

;--- ordinary-negated.mpir
%r = add:?anch !nsw !nuw i32 ?x, ?y

;--- input.ll
define i32 @f_add_flags(i32 %a, i32 %b) {
entry:
  %r = add nsw nuw i32 %a, %b
  ret i32 %r
}
; FLAGS: target 0: @f_add_flags
; FLAGS-NEXT:   match 0:
; FLAGS-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; PLAIN: target 0: @f_add_flags
; PLAIN-NEXT:   match 0:
; PLAIN-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; NEG: target 0: @f_add_flags
; NEG-NEXT:   no match

; CAP: target 0: @f_add_flags
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = true, ?x = %a, ?y = %b}

; NSW: target 0: @f_add_flags
; NSW-NEXT:   match 0:
; NSW-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; ORDINARY: target 0: @f_add_flags
; ORDINARY-NEXT:   match 0:
; ORDINARY-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; ORDINARY-NEG: target 0: @f_add_flags
; ORDINARY-NEG-NEXT:   no match

define i32 @f_or_disjoint(i32 %a, i32 %b) {
entry:
  %r = or disjoint i32 %a, %b
  ret i32 %r
}
; FLAGS-NEXT: target 1: @f_or_disjoint
; FLAGS-NEXT:   match 0:
; FLAGS-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; PLAIN-NEXT: target 1: @f_or_disjoint
; PLAIN-NEXT:   match 0:
; PLAIN-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; NEG-NEXT: target 1: @f_or_disjoint
; NEG-NEXT:   no match

; CAP-NEXT: target 1: @f_or_disjoint
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = true, ?x = %a, ?y = %b}

; NSW-NEXT: target 1: @f_or_disjoint
; NSW-NEXT:   match 0:
; NSW-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; ORDINARY-NEXT: target 1: @f_or_disjoint
; ORDINARY-NEXT:   no match

; ORDINARY-NEG-NEXT: target 1: @f_or_disjoint
; ORDINARY-NEG-NEXT:   no match

define i32 @f_add_plain(i32 %a, i32 %b) {
entry:
  %r = add i32 %a, %b
  ret i32 %r
}
; FLAGS-NEXT: target 2: @f_add_plain
; FLAGS-NEXT:   no match

; PLAIN-NEXT: target 2: @f_add_plain
; PLAIN-NEXT:   match 0:
; PLAIN-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; NEG-NEXT: target 2: @f_add_plain
; NEG-NEXT:   match 0:
; NEG-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; CAP-NEXT: target 2: @f_add_plain
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = false, ?mynuw = false, ?x = %a, ?y = %b}

; NSW-NEXT: target 2: @f_add_plain
; NSW-NEXT:   no match

; ORDINARY-NEXT: target 2: @f_add_plain
; ORDINARY-NEXT:   match 0:
; ORDINARY-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; ORDINARY-NEG-NEXT: target 2: @f_add_plain
; ORDINARY-NEG-NEXT:   match 0:
; ORDINARY-NEG-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

define i32 @f_add_nsw(i32 %a, i32 %b) {
entry:
  %r = add nsw i32 %a, %b
  ret i32 %r
}
; FLAGS-NEXT: target 3: @f_add_nsw
; FLAGS-NEXT:   no match
; FLAGS-NOT: {{.}}

; PLAIN-NEXT: target 3: @f_add_nsw
; PLAIN-NEXT:   match 0:
; PLAIN-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; PLAIN-NOT: {{.}}

; NEG-NEXT: target 3: @f_add_nsw
; NEG-NEXT:   no match
; NEG-NOT: {{.}}

; CAP-NEXT: target 3: @f_add_nsw
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = false, ?x = %a, ?y = %b}
; CAP-NOT: {{.}}

; NSW-NEXT: target 3: @f_add_nsw
; NSW-NEXT:   match 0:
; NSW-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; NSW-NOT: {{.}}

; ORDINARY-NEXT: target 3: @f_add_nsw
; ORDINARY-NEXT:   match 0:
; ORDINARY-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; ORDINARY-NOT: {{.}}

; ORDINARY-NEG-NEXT: target 3: @f_add_nsw
; ORDINARY-NEG-NEXT:   no match
; ORDINARY-NEG-NOT: {{.}}
