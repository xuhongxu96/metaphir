; Operand metaflags may be used inside a 'match' body. Expanding the composite
; matcher inlines those instructions, so PatternLowering desugars each expanded
; variant as well -- otherwise the inlined flags would reach matching without
; having been turned into constraints.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/one-branch.mpir %t/input.ll | FileCheck %s --check-prefix=ONE
; RUN: %metaphir-match %t/two-branch.mpir %t/two-branch.ll | FileCheck %s --check-prefix=TWO
; RUN: %metaphir-match %t/literal-arg.mpir %t/input.ll | FileCheck %s --check-prefix=LIT
; RUN: %metaphir-match %t/instruction-flag.mpir %t/input.ll | FileCheck %s --check-prefix=INSTRUCTION
; RUN: %metaphir-match %t/instruction-flag-fails.mpir %t/input.ll | FileCheck %s --check-prefix=INSTRUCTION-FAILS
; RUN: %metaphir-match %t/instruction-flag-nonroot.mpir %t/instruction-chain.ll | FileCheck %s --check-prefix=NONROOT
; RUN: %metaphir-match %t/instruction-flag-both.mpir %t/instruction-chain.ll | FileCheck %s --check-prefix=BOTH-INSTRUCTIONS
; RUN: %metaphir-match %t/instruction-flag-nonroot-fails.mpir %t/instruction-chain.ll | FileCheck %s --check-prefix=NONROOT-FAILS

;--- one-branch.mpir
match addzero [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y:zero
}

%r = addzero:?anch i32 ?a, ?b

; Instruction meta flags in a match body are lowered after the body is
; inlined, against that instruction's capture.
;--- instruction-flag.mpir
metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

match addop [] Binary (?ty ?x, ?y) {
	%ret = add:isaddop ?ty ?x, ?y
}

%r = addop:?anch i32 ?a, ?b

;--- instruction-flag-fails.mpir
metaflag:i :ismulop(?i) {
	opcode(?i) == "mul"
}

match incorrectly_tagged [] Binary (?ty ?x, ?y) {
	%ret = add:ismulop ?ty ?x, ?y
}

%r = incorrectly_tagged:?anch i32 ?a, ?b

;--- instruction-flag-nonroot.mpir
metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

match add_then_mul [] Binary (?ty ?x, ?y) {
	%tmp = add:isaddop ?ty ?x, ?y
	%ret = mul ?ty %tmp, ?y
}

%r = add_then_mul:?anch i32 ?a, ?b

;--- instruction-flag-nonroot-fails.mpir
metaflag:i :ismulop(?i) {
	opcode(?i) == "mul"
}

match add_then_mul_bad [] Binary (?ty ?x, ?y) {
	%tmp = add:?inner:ismulop ?ty ?x, ?y
	%ret = mul ?ty %tmp, ?y
}

%r = add_then_mul_bad:?anch i32 ?a, ?b

;--- instruction-flag-both.mpir
metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}
metaflag:i :ismulop(?i) {
	opcode(?i) == "mul"
}

match add_then_mul [] Binary (?ty ?x, ?y) {
	%tmp = add:isaddop ?ty ?x, ?y
	%ret = mul:ismulop ?ty %tmp, ?y
}

%r = add_then_mul:?anch i32 ?a, ?b
; A literal passed for the flagged parameter becomes a constant operand of the
; lowered constraint.
;--- literal-arg.mpir
match addzero [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y:zero
}

%r = addzero:?anch i32 ?a, 0
; Each branch is desugared independently, so branches may carry different flags.
;--- two-branch.mpir
match twobranch [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y:zero
} or {
	%ret = mul ?ty ?x, ?y:power2
}

%r = twobranch:?anch i32 ?a, ?b

;--- input.ll
define i32 @zero_rhs(i32 %x) {
  %r = add i32 %x, 0
  ret i32 %r
}
; ONE: target 0: @zero_rhs
; ONE-NEXT:   match 0:
; ONE-NEXT:     {?a = %x, ?anch = %r, ?b = 0}

; LIT: target 0: @zero_rhs
; LIT-NEXT:   match 0:
; LIT-NEXT:     {?a = %x, ?anch = %r}

; INSTRUCTION: target 0: @zero_rhs
; INSTRUCTION-NEXT:   match 0:
; INSTRUCTION-NEXT:     {?a = %x, ?anch = %r, ?b = 0}

; INSTRUCTION-FAILS: target 0: @zero_rhs
; INSTRUCTION-FAILS-NEXT:   no match
; INSTRUCTION-FAILS-NEXT:   constraint not satisfied: (== (opcode ?anch) "mul")

define i32 @nonzero_rhs(i32 %x) {
  %r = add i32 %x, 7
  ret i32 %r
}
; ONE-NEXT: target 1: @nonzero_rhs
; ONE-NEXT:   no match
; ONE-NEXT:   constraint not satisfied: (isZero ?b)

; LIT-NEXT: target 1: @nonzero_rhs
; LIT-NEXT:   no match

; INSTRUCTION-NEXT: target 1: @nonzero_rhs
; INSTRUCTION-NEXT:   match 0:
; INSTRUCTION-NEXT:     {?a = %x, ?anch = %r, ?b = 7}

; INSTRUCTION-FAILS-NEXT: target 1: @nonzero_rhs
; INSTRUCTION-FAILS-NEXT:   no match
; INSTRUCTION-FAILS-NEXT:   constraint not satisfied: (== (opcode ?anch) "mul")

;--- instruction-chain.ll
define i32 @chain(i32 %x, i32 %y) {
  %a = add i32 %x, %y
  %r = mul i32 %a, %y
  ret i32 %r
}
; NONROOT: target 0: @chain
; NONROOT-NEXT:   match 0:
; NONROOT-NEXT:     {?a = %x, ?anch = %r, ?b = %y}

; BOTH-INSTRUCTIONS: target 0: @chain
; BOTH-INSTRUCTIONS-NEXT:   match 0:
; BOTH-INSTRUCTIONS-NEXT:     {?a = %x, ?anch = %r, ?b = %y}

; NONROOT-FAILS: target 0: @chain
; NONROOT-FAILS-NEXT:   no match
; NONROOT-FAILS-NEXT:   constraint not satisfied: (== (opcode ?r$inner) "mul")

;--- two-branch.ll
define i32 @add_zero(i32 %x) {
  %r = add i32 %x, 0
  ret i32 %r
}
; TWO: target 0: @add_zero
; TWO-NEXT:   match 0:
; TWO-NEXT:     {?a = %x, ?anch = %r, ?b = 0}

define i32 @mul_pow2(i32 %x) {
  %r = mul i32 %x, 8
  ret i32 %r
}
; TWO-NEXT: target 1: @mul_pow2
; TWO-NEXT:   match 0:
; TWO-NEXT:     {?a = %x, ?anch = %r, ?b = 8}

define i32 @mul_three(i32 %x) {
  %r = mul i32 %x, 3
  ret i32 %r
}
; TWO-NEXT: target 2: @mul_three
; TWO-NEXT:   no match
; TWO-NEXT:   constraint not satisfied: (isPower2 ?b)
