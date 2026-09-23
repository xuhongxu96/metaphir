; A 'metaflag' definition takes one parameter per position: the first is the
; subject the flag is written on, and the rest are the arguments a use supplies,
; so ':between(5, 8)' is declared with three parameters.
;
; A placement mark on the keyword says where the flag may appear -- 'metaflag:i'
; on an instruction, 'metaflag:o' on an operand, 'metaflag:i:o' on either. With
; no mark the flag is operand-only.

; RUN: split-file %s %t
; RUN: %metaphir-match %t/args.mpir %t/consts.ll | FileCheck %s --check-prefix=ARGS
; RUN: %metaphir-match %t/instr.mpir %t/add.ll | FileCheck %s --check-prefix=INSTR
; RUN: %metaphir-match %t/instr-fails.mpir %t/add.ll | FileCheck %s --check-prefix=FAILS
; RUN: %metaphir-match %t/both.mpir %t/add.ll | FileCheck %s --check-prefix=BOTH
; RUN: %metaphir-match %t/no-capture.mpir %t/add.ll | FileCheck %s --check-prefix=NOCAP

; Two arguments beyond the subject.
;--- args.mpir
metaflag :between(?v, ?lo, ?hi) {
	sle(?lo, ?v) && sle(?v, ?hi)
}

%r = add:?anch i32 ?x, ?c:between(5, 8)

;--- consts.ll
define i32 @in_range(i32 %x) {
  %r = add i32 %x, 8
  ret i32 %r
}
; ARGS: target 0: @in_range
; ARGS-NEXT:   match 0:
; ARGS-NEXT:     {?anch = %r, ?c = 8, ?x = %x}

define i32 @out_of_range(i32 %x) {
  %r = add i32 %x, 9
  ret i32 %r
}
; ARGS-NEXT: target 1: @out_of_range
; ARGS-NEXT:   no match
; ARGS-NEXT:   constraint not satisfied: (&& (sle 5 ?c) (sle ?c 8))

; The pattern need not name the instruction: lowering uses the instruction
; directly as the flag's subject, avoiding any synthetic capture variable.
;--- no-capture.mpir
metaflag:i :ismulop(?i) {
	opcode(?i) == "mul"
}

%r = add:ismulop i32 ?x, ?y

; An instruction-placement flag takes the instruction as its subject, named
; through the instruction's capture.
;--- instr.mpir
metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

%r = add:?anch:isaddop i32 ?x, ?y

;--- instr-fails.mpir
metaflag:i :ismulop(?i) {
	opcode(?i) == "mul"
}

%r = add:?anch:ismulop i32 ?x, ?y

; ':i:o' allows either position; here the same flag is used on both.
;--- both.mpir
metaflag:i:o :anyvalue(?v) {
	isa(?v, "Value")
}

%r = add:?anch:anyvalue i32 ?x, ?y:anyvalue

;--- add.ll
define i32 @is_add(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}
; INSTR: target 0: @is_add
; INSTR-NEXT:   match 0:
; INSTR-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; FAILS: target 0: @is_add
; FAILS-NEXT:   no match
; FAILS-NEXT:   constraint not satisfied: (== (opcode ?anch) "mul")

; BOTH: target 0: @is_add
; BOTH-NEXT:   match 0:
; BOTH-NEXT:     {?anch = %r, ?x = %x, ?y = %y}

; NOCAP: target 0: @is_add
; NOCAP-NEXT:   no match
; NOCAP-NEXT:   constraint not satisfied: (== (opcode %r) "mul")
