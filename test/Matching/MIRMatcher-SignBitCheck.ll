; RUN: split-file %s %t
; RUN: %metaphir-match %t/check.mpir %t/input.ll | FileCheck %s --check-prefix=CHECK
; RUN: %metaphir-match %t/true-if-signed.mpir %t/input.ll | FileCheck %s --check-prefix=SET
; RUN: %metaphir-match %t/vector.mpir %t/input.ll | FileCheck %s --check-prefix=VEC

; 'signBitCheck' is a compare that isSignBitCheck accepts, and
; 'trueIfSigned' on its capture is isSignBitCheck's TrueIfSigned.

;--- check.mpir
%c = signBitCheck:?anch i8 ?x

;--- true-if-signed.mpir
%c = signBitCheck:?anch i8 ?x
;; trueIfSigned(?anch)

;--- vector.mpir
%c = signBitCheck:?anch <2 x i8> ?x

;--- input.ll

define i1 @slt_0(i8 %a) {
  %c = icmp slt i8 %a, 0
  ret i1 %c
}
; CHECK: target 0: @slt_0
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET: target 0: @slt_0
; SET-NEXT:   match 0:
; SET-NEXT:     {?anch = %c, ?x = %a}

; VEC: target 0: @slt_0
; VEC-NEXT:   no match

define i1 @sle_m1(i8 %a) {
  %c = icmp sle i8 %a, -1
  ret i1 %c
}
; CHECK-NEXT: target 1: @sle_m1
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 1: @sle_m1
; SET-NEXT:   match 0:
; SET-NEXT:     {?anch = %c, ?x = %a}

; VEC-NEXT: target 1: @sle_m1
; VEC-NEXT:   no match

define i1 @sgt_m1(i8 %a) {
  %c = icmp sgt i8 %a, -1
  ret i1 %c
}
; CHECK-NEXT: target 2: @sgt_m1
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 2: @sgt_m1
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (trueIfSigned ?anch)

; VEC-NEXT: target 2: @sgt_m1
; VEC-NEXT:   no match

define i1 @sge_0(i8 %a) {
  %c = icmp sge i8 %a, 0
  ret i1 %c
}
; CHECK-NEXT: target 3: @sge_0
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 3: @sge_0
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (trueIfSigned ?anch)

; VEC-NEXT: target 3: @sge_0
; VEC-NEXT:   no match

define i1 @ugt_127(i8 %a) {
  %c = icmp ugt i8 %a, 127
  ret i1 %c
}
; CHECK-NEXT: target 4: @ugt_127
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 4: @ugt_127
; SET-NEXT:   match 0:
; SET-NEXT:     {?anch = %c, ?x = %a}

; VEC-NEXT: target 4: @ugt_127
; VEC-NEXT:   no match

define i1 @uge_m128(i8 %a) {
  %c = icmp uge i8 %a, -128
  ret i1 %c
}
; CHECK-NEXT: target 5: @uge_m128
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 5: @uge_m128
; SET-NEXT:   match 0:
; SET-NEXT:     {?anch = %c, ?x = %a}

; VEC-NEXT: target 5: @uge_m128
; VEC-NEXT:   no match

define i1 @ult_m128(i8 %a) {
  %c = icmp ult i8 %a, -128
  ret i1 %c
}
; CHECK-NEXT: target 6: @ult_m128
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 6: @ult_m128
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (trueIfSigned ?anch)

; VEC-NEXT: target 6: @ult_m128
; VEC-NEXT:   no match

define i1 @ule_127(i8 %a) {
  %c = icmp ule i8 %a, 127
  ret i1 %c
}
; CHECK-NEXT: target 7: @ule_127
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %c, ?x = %a}

; SET-NEXT: target 7: @ule_127
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (trueIfSigned ?anch)

; VEC-NEXT: target 7: @ule_127
; VEC-NEXT:   no match

; Not a sign-bit test.
define i1 @slt_1(i8 %a) {
  %c = icmp slt i8 %a, 1
  ret i1 %c
}
; CHECK-NEXT: target 8: @slt_1
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (isZero ?_c$_c)

; SET-NEXT: target 8: @slt_1
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (isZero ?_c$_c)

; VEC-NEXT: target 8: @slt_1
; VEC-NEXT:   no match

define i1 @ugt_126(i8 %a) {
  %c = icmp ugt i8 %a, 126
  ret i1 %c
}
; CHECK-NEXT: target 9: @ugt_126
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (isMaxSignedValue ?_c$_c)

; SET-NEXT: target 9: @ugt_126
; SET-NEXT:   no match
; SET-NEXT:   constraint not satisfied: (isMaxSignedValue ?_c$_c)

; VEC-NEXT: target 9: @ugt_126
; VEC-NEXT:   no match

define <2 x i1> @vec_slt(<2 x i8> %a) {
  %c = icmp slt <2 x i8> %a, zeroinitializer
  ret <2 x i1> %c
}
; CHECK-NEXT: target 10: @vec_slt
; CHECK-NEXT:   no match

; SET-NEXT: target 10: @vec_slt
; SET-NEXT:   no match

; VEC-NEXT: target 10: @vec_slt
; VEC-NEXT:   match 0:
; VEC-NEXT:     {?anch = %c, ?x = %a}

; The constant is m_APInt, with no poison lanes.
define <2 x i1> @vec_poison(<2 x i8> %a) {
  %c = icmp slt <2 x i8> %a, <i8 0, i8 poison>
  ret <2 x i1> %c
}
; CHECK-NEXT: target 11: @vec_poison
; CHECK-NEXT:   no match

; SET-NEXT: target 11: @vec_poison
; SET-NEXT:   no match

; VEC-NEXT: target 11: @vec_poison
; VEC-NEXT:   no match
; VEC-NEXT:   constraint not satisfied: (isAPInt ?_c$_c)
