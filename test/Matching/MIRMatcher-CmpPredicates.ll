; RUN: split-file %s %t
; RUN: %metaphir-match %t/equality.mpir %t/input.ll | FileCheck %s --check-prefix=EQUALITY
; RUN: %metaphir-match %t/signed.mpir %t/input.ll | FileCheck %s --check-prefix=SIGNED
; RUN: %metaphir-match %t/unsigned.mpir %t/input.ll | FileCheck %s --check-prefix=UNSIGNED
; RUN: %metaphir-match %t/lt.mpir %t/input.ll | FileCheck %s --check-prefix=LT
; RUN: %metaphir-match %t/ge.mpir %t/input.ll | FileCheck %s --check-prefix=GE
; RUN: %metaphir-match %t/swapped.mpir %t/input.ll | FileCheck %s --check-prefix=SWAPPED
; RUN: %metaphir-match %t/inverse.mpir %t/input.ll | FileCheck %s --check-prefix=INVERSE
; RUN: %metaphir-match %t/strict.mpir %t/input.ll | FileCheck %s --check-prefix=STRICT
; RUN: %metaphir-match %t/non-strict.mpir %t/input.ll | FileCheck %s --check-prefix=NONSTRICT
; RUN: %metaphir-match %t/flipped.mpir %t/input.ll | FileCheck %s --check-prefix=FLIPPED
; RUN: %metaphir-match %t/captured.mpir %t/input.ll | FileCheck %s --check-prefix=CAPTURED

; Operators on comparison predicates, named after CmpInst's: they take the
; string a '?pred' binds, or that 'predicate' reads off a captured compare.

;--- equality.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; isEquality(?pred)

;--- signed.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; isSigned(?pred)

;--- unsigned.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; isUnsigned(?pred)

;--- lt.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; isLT(?pred)

;--- ge.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; isGE(?pred)

;--- swapped.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; swappedPredicate(?pred) == "sgt"

;--- inverse.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; inversePredicate(?pred) == "sge"

;--- strict.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; strictPredicate(?pred) == "ult"

;--- non-strict.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; nonStrictPredicate(?pred) == "sle"

;--- flipped.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; flippedSignednessPredicate(?pred) == "ult"

;--- captured.mpir
%c = icmp:?cmp ?pred i32 ?x, ?y
;; predicate(?cmp) == "ne"

;--- input.ll

; Flipping signedness of an equality leaves it as it is.
define i1 @eq(i32 %a, i32 %b) {
  %c = icmp eq i32 %a, %b
  ret i1 %c
}
; EQUALITY: target 0: @eq
; EQUALITY-NEXT: match 0:
; EQUALITY-NEXT: {?anch = %c, ?pred = eq, ?x = %a, ?y = %b}
; SIGNED: target 0: @eq
; SIGNED-NEXT: no match
; SIGNED-NEXT: constraint not satisfied: (isSigned ?pred)
; UNSIGNED: target 0: @eq
; UNSIGNED-NEXT: no match
; UNSIGNED-NEXT: constraint not satisfied: (isUnsigned ?pred)
; LT: target 0: @eq
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE: target 0: @eq
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED: target 0: @eq
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE: target 0: @eq
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT: target 0: @eq
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT: target 0: @eq
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED: target 0: @eq
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED: target 0: @eq
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @ne(i32 %a, i32 %b) {
  %c = icmp ne i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 1: @ne
; EQUALITY-NEXT: match 0:
; EQUALITY-NEXT: {?anch = %c, ?pred = ne, ?x = %a, ?y = %b}
; SIGNED-NEXT: target 1: @ne
; SIGNED-NEXT: no match
; SIGNED-NEXT: constraint not satisfied: (isSigned ?pred)
; UNSIGNED-NEXT: target 1: @ne
; UNSIGNED-NEXT: no match
; UNSIGNED-NEXT: constraint not satisfied: (isUnsigned ?pred)
; LT-NEXT: target 1: @ne
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE-NEXT: target 1: @ne
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 1: @ne
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 1: @ne
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 1: @ne
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT-NEXT: target 1: @ne
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED-NEXT: target 1: @ne
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 1: @ne
; CAPTURED-NEXT: match 0:
; CAPTURED-NEXT: {?cmp = %c, ?pred = ne, ?x = %a, ?y = %b}

define i1 @slt(i32 %a, i32 %b) {
  %c = icmp slt i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 2: @slt
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 2: @slt
; SIGNED-NEXT: match 0:
; SIGNED-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; UNSIGNED-NEXT: target 2: @slt
; UNSIGNED-NEXT: no match
; UNSIGNED-NEXT: constraint not satisfied: (isUnsigned ?pred)
; LT-NEXT: target 2: @slt
; LT-NEXT: match 0:
; LT-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; GE-NEXT: target 2: @slt
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 2: @slt
; SWAPPED-NEXT: match 0:
; SWAPPED-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; INVERSE-NEXT: target 2: @slt
; INVERSE-NEXT: match 0:
; INVERSE-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; STRICT-NEXT: target 2: @slt
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT-NEXT: target 2: @slt
; NONSTRICT-NEXT: match 0:
; NONSTRICT-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; FLIPPED-NEXT: target 2: @slt
; FLIPPED-NEXT: match 0:
; FLIPPED-NEXT: {?anch = %c, ?pred = slt, ?x = %a, ?y = %b}
; CAPTURED-NEXT: target 2: @slt
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @sle(i32 %a, i32 %b) {
  %c = icmp sle i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 3: @sle
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 3: @sle
; SIGNED-NEXT: match 0:
; SIGNED-NEXT: {?anch = %c, ?pred = sle, ?x = %a, ?y = %b}
; UNSIGNED-NEXT: target 3: @sle
; UNSIGNED-NEXT: no match
; UNSIGNED-NEXT: constraint not satisfied: (isUnsigned ?pred)
; LT-NEXT: target 3: @sle
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE-NEXT: target 3: @sle
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 3: @sle
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 3: @sle
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 3: @sle
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT-NEXT: target 3: @sle
; NONSTRICT-NEXT: match 0:
; NONSTRICT-NEXT: {?anch = %c, ?pred = sle, ?x = %a, ?y = %b}
; FLIPPED-NEXT: target 3: @sle
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 3: @sle
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @ult(i32 %a, i32 %b) {
  %c = icmp ult i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 4: @ult
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 4: @ult
; SIGNED-NEXT: no match
; SIGNED-NEXT: constraint not satisfied: (isSigned ?pred)
; UNSIGNED-NEXT: target 4: @ult
; UNSIGNED-NEXT: match 0:
; UNSIGNED-NEXT: {?anch = %c, ?pred = ult, ?x = %a, ?y = %b}
; LT-NEXT: target 4: @ult
; LT-NEXT: match 0:
; LT-NEXT: {?anch = %c, ?pred = ult, ?x = %a, ?y = %b}
; GE-NEXT: target 4: @ult
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 4: @ult
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 4: @ult
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 4: @ult
; STRICT-NEXT: match 0:
; STRICT-NEXT: {?anch = %c, ?pred = ult, ?x = %a, ?y = %b}
; NONSTRICT-NEXT: target 4: @ult
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED-NEXT: target 4: @ult
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 4: @ult
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @ule(i32 %a, i32 %b) {
  %c = icmp ule i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 5: @ule
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 5: @ule
; SIGNED-NEXT: no match
; SIGNED-NEXT: constraint not satisfied: (isSigned ?pred)
; UNSIGNED-NEXT: target 5: @ule
; UNSIGNED-NEXT: match 0:
; UNSIGNED-NEXT: {?anch = %c, ?pred = ule, ?x = %a, ?y = %b}
; LT-NEXT: target 5: @ule
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE-NEXT: target 5: @ule
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 5: @ule
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 5: @ule
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 5: @ule
; STRICT-NEXT: match 0:
; STRICT-NEXT: {?anch = %c, ?pred = ule, ?x = %a, ?y = %b}
; NONSTRICT-NEXT: target 5: @ule
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED-NEXT: target 5: @ule
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 5: @ule
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @sge(i32 %a, i32 %b) {
  %c = icmp sge i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 6: @sge
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 6: @sge
; SIGNED-NEXT: match 0:
; SIGNED-NEXT: {?anch = %c, ?pred = sge, ?x = %a, ?y = %b}
; UNSIGNED-NEXT: target 6: @sge
; UNSIGNED-NEXT: no match
; UNSIGNED-NEXT: constraint not satisfied: (isUnsigned ?pred)
; LT-NEXT: target 6: @sge
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE-NEXT: target 6: @sge
; GE-NEXT: match 0:
; GE-NEXT: {?anch = %c, ?pred = sge, ?x = %a, ?y = %b}
; SWAPPED-NEXT: target 6: @sge
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 6: @sge
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 6: @sge
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT-NEXT: target 6: @sge
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED-NEXT: target 6: @sge
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 6: @sge
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")

define i1 @ugt(i32 %a, i32 %b) {
  %c = icmp ugt i32 %a, %b
  ret i1 %c
}
; EQUALITY-NEXT: target 7: @ugt
; EQUALITY-NEXT: no match
; EQUALITY-NEXT: constraint not satisfied: (isEquality ?pred)
; SIGNED-NEXT: target 7: @ugt
; SIGNED-NEXT: no match
; SIGNED-NEXT: constraint not satisfied: (isSigned ?pred)
; UNSIGNED-NEXT: target 7: @ugt
; UNSIGNED-NEXT: match 0:
; UNSIGNED-NEXT: {?anch = %c, ?pred = ugt, ?x = %a, ?y = %b}
; LT-NEXT: target 7: @ugt
; LT-NEXT: no match
; LT-NEXT: constraint not satisfied: (isLT ?pred)
; GE-NEXT: target 7: @ugt
; GE-NEXT: no match
; GE-NEXT: constraint not satisfied: (isGE ?pred)
; SWAPPED-NEXT: target 7: @ugt
; SWAPPED-NEXT: no match
; SWAPPED-NEXT: constraint not satisfied: (== (swappedPredicate ?pred) "sgt")
; INVERSE-NEXT: target 7: @ugt
; INVERSE-NEXT: no match
; INVERSE-NEXT: constraint not satisfied: (== (inversePredicate ?pred) "sge")
; STRICT-NEXT: target 7: @ugt
; STRICT-NEXT: no match
; STRICT-NEXT: constraint not satisfied: (== (strictPredicate ?pred) "ult")
; NONSTRICT-NEXT: target 7: @ugt
; NONSTRICT-NEXT: no match
; NONSTRICT-NEXT: constraint not satisfied: (== (nonStrictPredicate ?pred) "sle")
; FLIPPED-NEXT: target 7: @ugt
; FLIPPED-NEXT: no match
; FLIPPED-NEXT: constraint not satisfied: (== (flippedSignednessPredicate ?pred) "ult")
; CAPTURED-NEXT: target 7: @ugt
; CAPTURED-NEXT: no match
; CAPTURED-NEXT: constraint not satisfied: (== (predicate ?cmp) "ne")
