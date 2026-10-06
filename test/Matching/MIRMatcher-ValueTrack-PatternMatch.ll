; RUN: split-file %s %t
; RUN: %metaphir-match %t/known-power-of-two.mpir %t/input.ll | FileCheck %s --check-prefix=P2
; RUN: %metaphir-match %t/known-power-of-two-or-zero.mpir %t/input.ll | FileCheck %s --check-prefix=P2Z
; RUN: %metaphir-match %t/not-poison.mpir %t/input.ll | FileCheck %s --check-prefix=NP
; RUN: %metaphir-match %t/not-undef-or-poison.mpir %t/input.ll | FileCheck %s --check-prefix=NUP
; RUN: %metaphir-match %t/divisor-not-poison.mpir %t/input.ll | FileCheck %s --check-prefix=NPDIV
; RUN: %metaphir-match %t/unsigned-range.mpir %t/input.ll | FileCheck %s --check-prefix=URANGE
; RUN: %metaphir-match %t/signed-range.mpir %t/input.ll | FileCheck %s --check-prefix=SRANGE

; A divisor is never poison at its udiv, as that would be undefined behavior,
; so '?y:notPoison' holds for every udiv here.
; Value tracking: isKnownPowerOfTwoOrZero (isKnownToBeAPowerOfTwo with
; OrZero), isGuaranteedNotToBePoison, isGuaranteedNotToBeUndefOrPoison and
; inUnsignedRange (computeConstantRange, unsigned).

;--- known-power-of-two.mpir
%r = udiv:?anch i32 ?x, ?y:knownPowerOfTwo

;--- known-power-of-two-or-zero.mpir
%r = udiv:?anch i32 ?x, ?y:knownPowerOfTwoOrZero

;--- not-poison.mpir
%r = udiv:?anch i32 ?x:notPoison, ?y

;--- not-undef-or-poison.mpir
%r = udiv:?anch i32 ?x:notUndefOrPoison, ?y

;--- divisor-not-poison.mpir
%r = udiv:?anch i32 ?x, ?y:notPoison

;--- unsigned-range.mpir
%r = udiv:?anch i32 ?x, ?y
;; inUnsignedRange(?y, 1, 15)

;--- signed-range.mpir
%r = udiv:?anch i32 ?x, ?y
;; inSignedRange(?y, 1, 15)

;--- input.ll

; 1 << s is a power of two (or poison).
define i32 @shl_one(i32 %x, i32 %s) {
  %y = shl i32 1, %s
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2: target 0: @shl_one
; P2-NEXT:   match 0:
; P2-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; P2Z: target 0: @shl_one
; P2Z-NEXT:   match 0:
; P2Z-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NP: target 0: @shl_one
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP: target 0: @shl_one
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV: target 0: @shl_one
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE: target 0: @shl_one
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE: target 0: @shl_one
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

; a & 8 is 8 or 0.
define i32 @masked_power(i32 %x, i32 %a) {
  %y = and i32 %a, 8
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 1: @masked_power
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 1: @masked_power
; P2Z-NEXT:   match 0:
; P2Z-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NP-NEXT: target 1: @masked_power
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP-NEXT: target 1: @masked_power
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV-NEXT: target 1: @masked_power
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 1: @masked_power
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 1: @masked_power
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

define i32 @noundef_arg(i32 noundef %x, i32 %y) {
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 2: @noundef_arg
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 2: @noundef_arg
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 2: @noundef_arg
; NP-NEXT:   match 0:
; NP-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NUP-NEXT: target 2: @noundef_arg
; NUP-NEXT:   match 0:
; NUP-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NPDIV-NEXT: target 2: @noundef_arg
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 2: @noundef_arg
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 2: @noundef_arg
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

define i32 @frozen(i32 %a, i32 %y) {
  %x = freeze i32 %a
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 3: @frozen
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 3: @frozen
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 3: @frozen
; NP-NEXT:   match 0:
; NP-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NUP-NEXT: target 3: @frozen
; NUP-NEXT:   match 0:
; NUP-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NPDIV-NEXT: target 3: @frozen
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 3: @frozen
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 3: @frozen
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

define i32 @plain_arg(i32 %x, i32 %y) {
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 4: @plain_arg
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 4: @plain_arg
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 4: @plain_arg
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP-NEXT: target 4: @plain_arg
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV-NEXT: target 4: @plain_arg
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 4: @plain_arg
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 4: @plain_arg
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

; [1, 15] both ways.
define i32 @small(i32 %x, i32 range(i32 1, 16) %y) {
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 5: @small
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 5: @small
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 5: @small
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP-NEXT: target 5: @small
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV-NEXT: target 5: @small
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 5: @small
; URANGE-NEXT:   match 0:
; URANGE-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; SRANGE-NEXT: target 5: @small
; SRANGE-NEXT:   match 0:
; SRANGE-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; 16 is out of range.
define i32 @wide(i32 %x, i32 range(i32 1, 17) %y) {
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 6: @wide
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 6: @wide
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 6: @wide
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP-NEXT: target 6: @wide
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV-NEXT: target 6: @wide
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 6: @wide
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 6: @wide
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)

; [-2, 2] is neither: unsigned, it wraps.
define i32 @negative(i32 %x, i32 range(i32 -2, 3) %y) {
  %r = udiv i32 %x, %y
  ret i32 %r
}
; P2-NEXT: target 7: @negative
; P2-NEXT:   no match
; P2-NEXT:   constraint not satisfied: (isKnownPowerOfTwo ?y)

; P2Z-NEXT: target 7: @negative
; P2Z-NEXT:   no match
; P2Z-NEXT:   constraint not satisfied: (isKnownPowerOfTwoOrZero ?y)

; NP-NEXT: target 7: @negative
; NP-NEXT:   no match
; NP-NEXT:   constraint not satisfied: (isGuaranteedNotToBePoison ?x)

; NUP-NEXT: target 7: @negative
; NUP-NEXT:   no match
; NUP-NEXT:   constraint not satisfied: (isGuaranteedNotToBeUndefOrPoison ?x)

; NPDIV-NEXT: target 7: @negative
; NPDIV-NEXT:   match 0:
; NPDIV-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; URANGE-NEXT: target 7: @negative
; URANGE-NEXT:   no match
; URANGE-NEXT:   constraint not satisfied: (inUnsignedRange ?y 1 15)

; SRANGE-NEXT: target 7: @negative
; SRANGE-NEXT:   no match
; SRANGE-NEXT:   constraint not satisfied: (inSignedRange ?y 1 15)
