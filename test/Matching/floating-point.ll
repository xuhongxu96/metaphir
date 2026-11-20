; RUN: split-file %s %t
; RUN: %metaphir-match %t/fneg-like.mpir %t/input.ll | FileCheck %s --check-prefix=FNEG
; RUN: %metaphir-match %t/never-nan.mpir %t/input.ll | FileCheck %s --check-prefix=NONAN
; RUN: %metaphir-match %t/never-infinity.mpir %t/input.ll | FileCheck %s --check-prefix=NOINF
; RUN: %metaphir-match %t/never-inf-or-nan.mpir %t/input.ll | FileCheck %s --check-prefix=NOINFNAN
; RUN: %metaphir-match %t/not-negative-zero.mpir %t/input.ll | FileCheck %s --check-prefix=NONEGZERO
; RUN: %metaphir-match %t/not-ordered-negative.mpir %t/input.ll | FileCheck %s --check-prefix=NOTNEG
; RUN: %metaphir-match %t/pos-zero.mpir %t/input.ll | FileCheck %s --check-prefix=POSZERO
; RUN: %metaphir-match %t/neg-zero.mpir %t/input.ll | FileCheck %s --check-prefix=NEGZERO
; RUN: %metaphir-match %t/inf.mpir %t/input.ll | FileCheck %s --check-prefix=INF
; RUN: %metaphir-match %t/nan.mpir %t/input.ll | FileCheck %s --check-prefix=NAN

; Floating point: 'fnegLike' is m_FNeg (fneg, fsub -0.0 or, with nsz, any
; zero); FP constant classes named after their matchers; and value tracking
; named after LLVM's (isKnownNeverNaN, cannotBeNegativeZero, ...).

;--- fneg-like.mpir
%r = fnegLike:?anch float ?x

;--- never-nan.mpir
%r = fadd:?anch float ?x, ?c
;; isKnownNeverNaN(?x)

;--- never-infinity.mpir
%r = fadd:?anch float ?x, ?c
;; isKnownNeverInfinity(?x)

;--- never-inf-or-nan.mpir
%r = fadd:?anch float ?x, ?c
;; isKnownNeverInfOrNaN(?x)

;--- not-negative-zero.mpir
%r = fadd:?anch float ?x, ?c
;; cannotBeNegativeZero(?x)

;--- not-ordered-negative.mpir
%r = fadd:?anch float ?x, ?c
;; cannotBeOrderedLessThanZero(?x)

;--- pos-zero.mpir
%r = fadd:?anch float ?x, ?c:posZeroFP

;--- neg-zero.mpir
%r = fadd:?anch float ?x, ?c:negZeroFP

;--- inf.mpir
%r = fadd:?anch float ?x, ?c:inf

;--- nan.mpir
%r = fadd:?anch float ?x, ?c:nan

;--- input.ll
declare float @llvm.fabs.f32(float)

define float @fneg(float %x) {
  %r = fneg float %x
  ret float %r
}
; FNEG: target 0: @fneg
; FNEG-NEXT:   match 0:
; FNEG-NEXT:     {?anch = %r, ?x = %x}

; NONAN: target 0: @fneg
; NONAN-NEXT:   no match

; NOINF: target 0: @fneg
; NOINF-NEXT:   no match

; NOINFNAN: target 0: @fneg
; NOINFNAN-NEXT:   no match

; NONEGZERO: target 0: @fneg
; NONEGZERO-NEXT:   no match

; NOTNEG: target 0: @fneg
; NOTNEG-NEXT:   no match

; POSZERO: target 0: @fneg
; POSZERO-NEXT:   no match

; NEGZERO: target 0: @fneg
; NEGZERO-NEXT:   no match

; INF: target 0: @fneg
; INF-NEXT:   no match

; NAN: target 0: @fneg
; NAN-NEXT:   no match

define float @fsub_neg_zero(float %x) {
  %r = fsub float -0.0, %x
  ret float %r
}
; FNEG-NEXT: target 1: @fsub_neg_zero
; FNEG-NEXT:   match 0:
; FNEG-NEXT:     {?anch = %r, ?x = %x}

; NONAN-NEXT: target 1: @fsub_neg_zero
; NONAN-NEXT:   no match

; NOINF-NEXT: target 1: @fsub_neg_zero
; NOINF-NEXT:   no match

; NOINFNAN-NEXT: target 1: @fsub_neg_zero
; NOINFNAN-NEXT:   no match

; NONEGZERO-NEXT: target 1: @fsub_neg_zero
; NONEGZERO-NEXT:   no match

; NOTNEG-NEXT: target 1: @fsub_neg_zero
; NOTNEG-NEXT:   no match

; POSZERO-NEXT: target 1: @fsub_neg_zero
; POSZERO-NEXT:   no match

; NEGZERO-NEXT: target 1: @fsub_neg_zero
; NEGZERO-NEXT:   no match

; INF-NEXT: target 1: @fsub_neg_zero
; INF-NEXT:   no match

; NAN-NEXT: target 1: @fsub_neg_zero
; NAN-NEXT:   no match

; 0.0 - x is not -x without nsz: 0.0 - 0.0 is +0.0.
define float @fsub_pos_zero(float %x) {
  %r = fsub float 0.0, %x
  ret float %r
}
; FNEG-NEXT: target 2: @fsub_pos_zero
; FNEG-NEXT:   no match
; FNEG-NEXT:   constraint not satisfied: (isNegZeroFP ?_r$_zero)

; NONAN-NEXT: target 2: @fsub_pos_zero
; NONAN-NEXT:   no match

; NOINF-NEXT: target 2: @fsub_pos_zero
; NOINF-NEXT:   no match

; NOINFNAN-NEXT: target 2: @fsub_pos_zero
; NOINFNAN-NEXT:   no match

; NONEGZERO-NEXT: target 2: @fsub_pos_zero
; NONEGZERO-NEXT:   no match

; NOTNEG-NEXT: target 2: @fsub_pos_zero
; NOTNEG-NEXT:   no match

; POSZERO-NEXT: target 2: @fsub_pos_zero
; POSZERO-NEXT:   no match

; NEGZERO-NEXT: target 2: @fsub_pos_zero
; NEGZERO-NEXT:   no match

; INF-NEXT: target 2: @fsub_pos_zero
; INF-NEXT:   no match

; NAN-NEXT: target 2: @fsub_pos_zero
; NAN-NEXT:   no match

define float @fsub_nsz_pos_zero(float %x) {
  %r = fsub nsz float 0.0, %x
  ret float %r
}
; FNEG-NEXT: target 3: @fsub_nsz_pos_zero
; FNEG-NEXT:   match 0:
; FNEG-NEXT:     {?anch = %r, ?x = %x}

; NONAN-NEXT: target 3: @fsub_nsz_pos_zero
; NONAN-NEXT:   no match

; NOINF-NEXT: target 3: @fsub_nsz_pos_zero
; NOINF-NEXT:   no match

; NOINFNAN-NEXT: target 3: @fsub_nsz_pos_zero
; NOINFNAN-NEXT:   no match

; NONEGZERO-NEXT: target 3: @fsub_nsz_pos_zero
; NONEGZERO-NEXT:   no match

; NOTNEG-NEXT: target 3: @fsub_nsz_pos_zero
; NOTNEG-NEXT:   no match

; POSZERO-NEXT: target 3: @fsub_nsz_pos_zero
; POSZERO-NEXT:   no match

; NEGZERO-NEXT: target 3: @fsub_nsz_pos_zero
; NEGZERO-NEXT:   no match

; INF-NEXT: target 3: @fsub_nsz_pos_zero
; INF-NEXT:   no match

; NAN-NEXT: target 3: @fsub_nsz_pos_zero
; NAN-NEXT:   no match

define float @uitofp(i8 %a) {
  %x = uitofp i8 %a to float
  %r = fadd float %x, 0.0
  ret float %r
}
; FNEG-NEXT: target 4: @uitofp
; FNEG-NEXT:   no match

; NONAN-NEXT: target 4: @uitofp
; NONAN-NEXT:   match 0:
; NONAN-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; NOINF-NEXT: target 4: @uitofp
; NOINF-NEXT:   match 0:
; NOINF-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; NOINFNAN-NEXT: target 4: @uitofp
; NOINFNAN-NEXT:   match 0:
; NOINFNAN-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; NONEGZERO-NEXT: target 4: @uitofp
; NONEGZERO-NEXT:   match 0:
; NONEGZERO-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; NOTNEG-NEXT: target 4: @uitofp
; NOTNEG-NEXT:   match 0:
; NOTNEG-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; POSZERO-NEXT: target 4: @uitofp
; POSZERO-NEXT:   match 0:
; POSZERO-NEXT:     {?anch = %r, ?c = 0.000000e+00, ?x = %x}

; NEGZERO-NEXT: target 4: @uitofp
; NEGZERO-NEXT:   no match
; NEGZERO-NEXT:   constraint not satisfied: (isNegZeroFP ?c)

; INF-NEXT: target 4: @uitofp
; INF-NEXT:   no match
; INF-NEXT:   constraint not satisfied: (isInf ?c)

; NAN-NEXT: target 4: @uitofp
; NAN-NEXT:   no match
; NAN-NEXT:   constraint not satisfied: (isNaN ?c)

; sitofp can be negative, but never -0.0.
define float @sitofp(i8 %a) {
  %x = sitofp i8 %a to float
  %r = fadd float %x, -0.0
  ret float %r
}
; FNEG-NEXT: target 5: @sitofp
; FNEG-NEXT:   no match

; NONAN-NEXT: target 5: @sitofp
; NONAN-NEXT:   match 0:
; NONAN-NEXT:     {?anch = %r, ?c = -0.000000e+00, ?x = %x}

; NOINF-NEXT: target 5: @sitofp
; NOINF-NEXT:   match 0:
; NOINF-NEXT:     {?anch = %r, ?c = -0.000000e+00, ?x = %x}

; NOINFNAN-NEXT: target 5: @sitofp
; NOINFNAN-NEXT:   match 0:
; NOINFNAN-NEXT:     {?anch = %r, ?c = -0.000000e+00, ?x = %x}

; NONEGZERO-NEXT: target 5: @sitofp
; NONEGZERO-NEXT:   match 0:
; NONEGZERO-NEXT:     {?anch = %r, ?c = -0.000000e+00, ?x = %x}

; NOTNEG-NEXT: target 5: @sitofp
; NOTNEG-NEXT:   no match
; NOTNEG-NEXT:   constraint not satisfied: (cannotBeOrderedLessThanZero ?x)

; POSZERO-NEXT: target 5: @sitofp
; POSZERO-NEXT:   no match
; POSZERO-NEXT:   constraint not satisfied: (isPosZeroFP ?c)

; NEGZERO-NEXT: target 5: @sitofp
; NEGZERO-NEXT:   match 0:
; NEGZERO-NEXT:     {?anch = %r, ?c = -0.000000e+00, ?x = %x}

; INF-NEXT: target 5: @sitofp
; INF-NEXT:   no match
; INF-NEXT:   constraint not satisfied: (isInf ?c)

; NAN-NEXT: target 5: @sitofp
; NAN-NEXT:   no match
; NAN-NEXT:   constraint not satisfied: (isNaN ?c)

; fabs may be NaN or infinite.
define float @fabs(float %a) {
  %x = call float @llvm.fabs.f32(float %a)
  %r = fadd float %x, 0x7FF0000000000000
  ret float %r
}
; FNEG-NEXT: target 6: @fabs
; FNEG-NEXT:   no match

; NONAN-NEXT: target 6: @fabs
; NONAN-NEXT:   no match
; NONAN-NEXT:   constraint not satisfied: (isKnownNeverNaN ?x)

; NOINF-NEXT: target 6: @fabs
; NOINF-NEXT:   no match
; NOINF-NEXT:   constraint not satisfied: (isKnownNeverInfinity ?x)

; NOINFNAN-NEXT: target 6: @fabs
; NOINFNAN-NEXT:   no match
; NOINFNAN-NEXT:   constraint not satisfied: (isKnownNeverInfOrNaN ?x)

; NONEGZERO-NEXT: target 6: @fabs
; NONEGZERO-NEXT:   match 0:
; NONEGZERO-NEXT:     {?anch = %r, ?c = +inf, ?x = %x}

; NOTNEG-NEXT: target 6: @fabs
; NOTNEG-NEXT:   match 0:
; NOTNEG-NEXT:     {?anch = %r, ?c = +inf, ?x = %x}

; POSZERO-NEXT: target 6: @fabs
; POSZERO-NEXT:   no match
; POSZERO-NEXT:   constraint not satisfied: (isPosZeroFP ?c)

; NEGZERO-NEXT: target 6: @fabs
; NEGZERO-NEXT:   no match
; NEGZERO-NEXT:   constraint not satisfied: (isNegZeroFP ?c)

; INF-NEXT: target 6: @fabs
; INF-NEXT:   match 0:
; INF-NEXT:     {?anch = %r, ?c = +inf, ?x = %x}

; NAN-NEXT: target 6: @fabs
; NAN-NEXT:   no match
; NAN-NEXT:   constraint not satisfied: (isNaN ?c)

define float @argument(float %x) {
  %r = fadd float %x, 0x7FF8000000000000
  ret float %r
}
; FNEG-NEXT: target 7: @argument
; FNEG-NEXT:   no match
; FNEG-NOT: {{.}}

; NONAN-NEXT: target 7: @argument
; NONAN-NEXT:   no match
; NONAN-NEXT:   constraint not satisfied: (isKnownNeverNaN ?x)
; NONAN-NOT: {{.}}

; NOINF-NEXT: target 7: @argument
; NOINF-NEXT:   no match
; NOINF-NEXT:   constraint not satisfied: (isKnownNeverInfinity ?x)
; NOINF-NOT: {{.}}

; NOINFNAN-NEXT: target 7: @argument
; NOINFNAN-NEXT:   no match
; NOINFNAN-NEXT:   constraint not satisfied: (isKnownNeverInfOrNaN ?x)
; NOINFNAN-NOT: {{.}}

; NONEGZERO-NEXT: target 7: @argument
; NONEGZERO-NEXT:   no match
; NONEGZERO-NEXT:   constraint not satisfied: (cannotBeNegativeZero ?x)
; NONEGZERO-NOT: {{.}}

; NOTNEG-NEXT: target 7: @argument
; NOTNEG-NEXT:   no match
; NOTNEG-NEXT:   constraint not satisfied: (cannotBeOrderedLessThanZero ?x)
; NOTNEG-NOT: {{.}}

; POSZERO-NEXT: target 7: @argument
; POSZERO-NEXT:   no match
; POSZERO-NEXT:   constraint not satisfied: (isPosZeroFP ?c)
; POSZERO-NOT: {{.}}

; NEGZERO-NEXT: target 7: @argument
; NEGZERO-NEXT:   no match
; NEGZERO-NEXT:   constraint not satisfied: (isNegZeroFP ?c)
; NEGZERO-NOT: {{.}}

; INF-NEXT: target 7: @argument
; INF-NEXT:   no match
; INF-NEXT:   constraint not satisfied: (isInf ?c)
; INF-NOT: {{.}}

; NAN-NEXT: target 7: @argument
; NAN-NEXT:   match 0:
; NAN-NEXT:     {?anch = %r, ?c = +qnan, ?x = %x}
; NAN-NOT: {{.}}
