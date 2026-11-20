; RUN: split-file %s %t
; RUN: %metaphir-match %t/neg.mpir %t/input.ll | FileCheck %s --check-prefix=NEG
; RUN: %metaphir-match %t/neg-nsw.mpir %t/input.ll | FileCheck %s --check-prefix=NSW
; RUN: %metaphir-match %t/neg-not-nsw.mpir %t/input.ll | FileCheck %s --check-prefix=NOTNSW
; RUN: %metaphir-match %t/neg-vec.mpir %t/input.ll | FileCheck %s --check-prefix=VEC

; 'neg' is m_Neg and 'neg nsw' is m_NSWNeg; '!nsw' requires the flag to be
; absent. The zero may be a vector splat with poison lanes.

;--- neg.mpir
%r = neg:?anch i32 ?x

;--- neg-nsw.mpir
%r = neg:?anch nsw i32 ?x

;--- neg-not-nsw.mpir
%r = neg:?anch !nsw i32 ?x

;--- neg-vec.mpir
%r = neg:?anch <2 x i32> ?x

;--- input.ll

define i32 @plain(i32 %a) {
  %r = sub i32 0, %a
  ret i32 %r
}
; NEG: target 0: @plain
; NEG-NEXT:   match 0:
; NEG-NEXT:     {?anch = %r, ?x = %a}

; NSW: target 0: @plain
; NSW-NEXT:   no match

; NOTNSW: target 0: @plain
; NOTNSW-NEXT:   match 0:
; NOTNSW-NEXT:     {?anch = %r, ?x = %a}

; VEC: target 0: @plain
; VEC-NEXT:   no match

define i32 @nsw(i32 %a) {
  %r = sub nsw i32 0, %a
  ret i32 %r
}
; NEG-NEXT: target 1: @nsw
; NEG-NEXT:   match 0:
; NEG-NEXT:     {?anch = %r, ?x = %a}

; NSW-NEXT: target 1: @nsw
; NSW-NEXT:   match 0:
; NSW-NEXT:     {?anch = %r, ?x = %a}

; NOTNSW-NEXT: target 1: @nsw
; NOTNSW-NEXT:   no match

; VEC-NEXT: target 1: @nsw
; VEC-NEXT:   no match

; nuw is ignored, as by m_Neg.
define i32 @nuw(i32 %a) {
  %r = sub nuw i32 0, %a
  ret i32 %r
}
; NEG-NEXT: target 2: @nuw
; NEG-NEXT:   match 0:
; NEG-NEXT:     {?anch = %r, ?x = %a}

; NSW-NEXT: target 2: @nuw
; NSW-NEXT:   no match

; NOTNSW-NEXT: target 2: @nuw
; NOTNSW-NEXT:   match 0:
; NOTNSW-NEXT:     {?anch = %r, ?x = %a}

; VEC-NEXT: target 2: @nuw
; VEC-NEXT:   no match

define i32 @not_zero(i32 %a) {
  %r = sub i32 1, %a
  ret i32 %r
}
; NEG-NEXT: target 3: @not_zero
; NEG-NEXT:   no match
; NEG-NEXT:   constraint not satisfied: (isZero ?_r$_zero)

; NSW-NEXT: target 3: @not_zero
; NSW-NEXT:   no match

; NOTNSW-NEXT: target 3: @not_zero
; NOTNSW-NEXT:   no match
; NOTNSW-NEXT:   constraint not satisfied: (isZero ?_r$_zero)

; VEC-NEXT: target 3: @not_zero
; VEC-NEXT:   no match

; Vectors match without 'treatIntAsVec'.
define <2 x i32> @vec_zero(<2 x i32> %a) {
  %r = sub <2 x i32> zeroinitializer, %a
  ret <2 x i32> %r
}
; NEG-NEXT: target 4: @vec_zero
; NEG-NEXT:   no match

; NSW-NEXT: target 4: @vec_zero
; NSW-NEXT:   no match

; NOTNSW-NEXT: target 4: @vec_zero
; NOTNSW-NEXT:   no match

; VEC-NEXT: target 4: @vec_zero
; VEC-NEXT:   match 0:
; VEC-NEXT:     {?anch = %r, ?x = %a}

define <2 x i32> @vec_poison(<2 x i32> %a) {
  %r = sub <2 x i32> <i32 0, i32 poison>, %a
  ret <2 x i32> %r
}
; NEG-NEXT: target 5: @vec_poison
; NEG-NEXT:   no match
; NEG-NOT: {{.}}

; NSW-NEXT: target 5: @vec_poison
; NSW-NEXT:   no match
; NSW-NOT: {{.}}

; NOTNSW-NEXT: target 5: @vec_poison
; NOTNSW-NEXT:   no match
; NOTNSW-NOT: {{.}}

; VEC-NEXT: target 5: @vec_poison
; VEC-NEXT:   match 0:
; VEC-NEXT:     {?anch = %r, ?x = %a}
; VEC-NOT: {{.}}
