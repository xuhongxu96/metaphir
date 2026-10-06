; RUN: split-file %s %t
; RUN: %metaphir-match %t/omitted.mpir %t/input.ll | FileCheck %s --check-prefix=OMITTED
; RUN: %metaphir-match %t/required.mpir %t/input.ll | FileCheck %s --check-prefix=REQUIRED
; RUN: %metaphir-match %t/negated.mpir %t/input.ll | FileCheck %s --check-prefix=NEGATED
; RUN: %metaphir-match %t/captured.mpir %t/input.ll | FileCheck %s --check-prefix=CAPTURED
; RUN: %metaphir-match %t/addlike-omitted.mpir %t/input.ll | FileCheck %s --check-prefix=ADDLIKE
; RUN: %metaphir-match %t/addlike-negated.mpir %t/input.ll | FileCheck %s --check-prefix=ADDLIKE-NOT-NSW
; RUN: %metaphir-match %t/fmf.mpir %t/fp.ll | FileCheck %s --check-prefix=FMF
; RUN: %metaphir-match %t/fmf-negated.mpir %t/fp.ll | FileCheck %s --check-prefix=FMF-NOT-NNAN

; An omitted flag matches whether or not the target has it.
;--- omitted.mpir
%r = add:?anch i32 ?x, ?y

; A written flag must be present.
;--- required.mpir
%r = add:?anch nsw i32 ?x, ?y

; A negated flag must be absent.
;--- negated.mpir
%r = add:?anch !nsw i32 ?x, ?y

;--- captured.mpir
%r = add:?anch nsw:?nsw i32 ?x, ?y

; A composite's omitted flag keeps every branch.
;--- addlike-omitted.mpir
%r = addLike:?anch i32 ?x, ?y

; '!nsw' drops the 'or disjoint' branch, which fixes nsw to true.
;--- addlike-negated.mpir
%r = addLike:?anch !nsw i32 ?x, ?y

;--- fmf.mpir
%r = fadd:?anch float ?x, ?y

;--- fmf-negated.mpir
%r = fadd:?anch !nnan float ?x, ?y

;--- input.ll
define i32 @plain(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
; OMITTED: target 0: @plain
; OMITTED-NEXT:   match 0:
; OMITTED-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; REQUIRED: target 0: @plain
; REQUIRED-NEXT:   no match
; NEGATED: target 0: @plain
; NEGATED-NEXT:   match 0:
; NEGATED-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; CAPTURED: target 0: @plain
; CAPTURED-NEXT:   match 0:
; CAPTURED-NEXT:     {?anch = %r, ?nsw = false, ?x = %a, ?y = %b}
; ADDLIKE: target 0: @plain
; ADDLIKE-NEXT:   match 0:
; ADDLIKE-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; ADDLIKE-NOT-NSW: target 0: @plain
; ADDLIKE-NOT-NSW-NEXT:   match 0:
; ADDLIKE-NOT-NSW-NEXT:     {?anch = %r, ?x = %a, ?y = %b}

define i32 @nsw_nuw(i32 %a, i32 %b) {
  %r = add nsw nuw i32 %a, %b
  ret i32 %r
}
; OMITTED-NEXT: target 1: @nsw_nuw
; OMITTED-NEXT:   match 0:
; OMITTED-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; REQUIRED-NEXT: target 1: @nsw_nuw
; REQUIRED-NEXT:   match 0:
; REQUIRED-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; NEGATED-NEXT: target 1: @nsw_nuw
; NEGATED-NEXT:   no match
; CAPTURED-NEXT: target 1: @nsw_nuw
; CAPTURED-NEXT:   match 0:
; CAPTURED-NEXT:     {?anch = %r, ?nsw = true, ?x = %a, ?y = %b}
; ADDLIKE-NEXT: target 1: @nsw_nuw
; ADDLIKE-NEXT:   match 0:
; ADDLIKE-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; ADDLIKE-NOT-NSW-NEXT: target 1: @nsw_nuw
; ADDLIKE-NOT-NSW-NEXT:   no match

; '!nsw' says nothing about nuw.
define i32 @nuw(i32 %a, i32 %b) {
  %r = add nuw i32 %a, %b
  ret i32 %r
}
; OMITTED-NEXT: target 2: @nuw
; OMITTED-NEXT:   match 0:
; REQUIRED-NEXT: target 2: @nuw
; REQUIRED-NEXT:   no match
; NEGATED-NEXT: target 2: @nuw
; NEGATED-NEXT:   match 0:
; NEGATED-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; ADDLIKE-NOT-NSW-NEXT: target 2: @nuw
; ADDLIKE-NOT-NSW-NEXT:   match 0:

define i32 @disjoint(i32 %a, i32 %b) {
  %r = or disjoint i32 %a, %b
  ret i32 %r
}
; ADDLIKE: target 3: @disjoint
; ADDLIKE-NEXT:   match 0:
; ADDLIKE-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; ADDLIKE-NOT-NSW: target 3: @disjoint
; ADDLIKE-NOT-NSW-NEXT:   no match

;--- fp.ll
define float @fast(float %a, float %b) {
  %r = fadd fast float %a, %b
  ret float %r
}
; FMF: target 0: @fast
; FMF-NEXT:   match 0:
; FMF-NEXT:     {?anch = %r, ?x = %a, ?y = %b}
; FMF-NOT-NNAN: target 0: @fast
; FMF-NOT-NNAN-NEXT:   no match

define float @nsz(float %a, float %b) {
  %r = fadd nsz float %a, %b
  ret float %r
}
; FMF-NEXT: target 1: @nsz
; FMF-NEXT:   match 0:
; FMF-NOT-NNAN-NEXT: target 1: @nsz
; FMF-NOT-NNAN-NEXT:   match 0:
