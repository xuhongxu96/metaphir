; RUN: split-file %s %t
; RUN: %metaphir-match %t/addlike-flags.mpir %t/input.ll | FileCheck %s --check-prefix=FLAGS
; RUN: %metaphir-match %t/addlike-plain.mpir %t/input.ll | FileCheck %s --check-prefix=PLAIN
; RUN: %metaphir-match %t/addlike-wildcard.mpir %t/input.ll | FileCheck %s --check-prefix=WILD
; RUN: %metaphir-match %t/addlike-captured.mpir %t/input.ll | FileCheck %s --check-prefix=CAP
; RUN: %metaphir-match %t/addlike-nsw.mpir %t/input.ll | FileCheck %s --check-prefix=NSW
; RUN: %metaphir-match %t/ordinary-plain.mpir %t/input.ll | FileCheck %s --check-prefix=ORDINARY
; RUN: %metaphir-match %t/ordinary-wildcard.mpir %t/input.ll | FileCheck %s --check-prefix=OPTIONAL

;--- addlike-flags.mpir
%r = addLike:?anch nsw nuw i32 ?x, ?y

;--- addlike-plain.mpir
%r = addLike:?anch i32 ?x, ?y

;--- addlike-wildcard.mpir
%r = addLike:?anch nsw:?_ nuw:?_ i32 ?x, ?y

;--- addlike-captured.mpir
%r = addLike:?anch nsw:?mynsw nuw:?mynuw i32 ?x, ?y

;--- addlike-nsw.mpir
%r = addLike:?anch nsw i32 ?x, ?y

; An ordinary instruction also requires omitted supported flags to be absent.
; Use '?_' to explicitly make a flag optional.
;--- ordinary-plain.mpir
%r = add:?anch i32 ?x, ?y

;--- ordinary-wildcard.mpir
%r = add:?anch nsw:?_ nuw:?_ i32 ?x, ?y

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
; PLAIN-NEXT:   no match

; WILD: target 0: @f_add_flags
; WILD-NEXT:   match 0:
; WILD-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; CAP: target 0: @f_add_flags
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = true, ?x = %a, ?y = %b}

; NSW: target 0: @f_add_flags
; NSW-NEXT:   no match

; ORDINARY: target 0: @f_add_flags
; ORDINARY-NEXT:   no match

; OPTIONAL: target 0: @f_add_flags
; OPTIONAL-NEXT:   match 0:
; OPTIONAL-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

define i32 @f_or_disjoint(i32 %a, i32 %b) {
entry:
  %r = or disjoint i32 %a, %b
  ret i32 %r
}
; FLAGS-NEXT: target 1: @f_or_disjoint
; FLAGS-NEXT:   match 0:
; FLAGS-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; PLAIN-NEXT: target 1: @f_or_disjoint
; PLAIN-NEXT:   no match

; WILD-NEXT: target 1: @f_or_disjoint
; WILD-NEXT:   match 0:
; WILD-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; CAP-NEXT: target 1: @f_or_disjoint
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = true, ?x = %a, ?y = %b}

; NSW-NEXT: target 1: @f_or_disjoint
; NSW-NEXT:   no match

; ORDINARY-NEXT: target 1: @f_or_disjoint
; ORDINARY-NEXT:   no match

; OPTIONAL-NEXT: target 1: @f_or_disjoint
; OPTIONAL-NEXT:   no match

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

; WILD-NEXT: target 2: @f_add_plain
; WILD-NEXT:   match 0:
; WILD-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; CAP-NEXT: target 2: @f_add_plain
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = false, ?mynuw = false, ?x = %a, ?y = %b}

; NSW-NEXT: target 2: @f_add_plain
; NSW-NEXT:   no match

; ORDINARY-NEXT: target 2: @f_add_plain
; ORDINARY-NEXT:   match 0:
; ORDINARY-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; OPTIONAL-NEXT: target 2: @f_add_plain
; OPTIONAL-NEXT:   match 0:
; OPTIONAL-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

define i32 @f_add_nsw(i32 %a, i32 %b) {
entry:
  %r = add nsw i32 %a, %b
  ret i32 %r
}
; FLAGS-NEXT: target 3: @f_add_nsw
; FLAGS-NEXT:   no match

; PLAIN-NEXT: target 3: @f_add_nsw
; PLAIN-NEXT:   no match

; WILD-NEXT: target 3: @f_add_nsw
; WILD-NEXT:   match 0:
; WILD-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; CAP-NEXT: target 3: @f_add_nsw
; CAP-NEXT:   match 0:
; CAP-NEXT:     {?anch = %r, ?mynsw = true, ?mynuw = false, ?x = %a, ?y = %b}

; NSW-NEXT: target 3: @f_add_nsw
; NSW-NEXT:   match 0:
; NSW-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

; ORDINARY-NEXT: target 3: @f_add_nsw
; ORDINARY-NEXT:   no match

; OPTIONAL-NEXT: target 3: @f_add_nsw
; OPTIONAL-NEXT:   match 0:
; OPTIONAL-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
