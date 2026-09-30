; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; --print-instructions adds the instructions each match matched: for every
; pattern instruction, named by its result (or opcode) and pattern line, the
; position of the IR instruction it matched in its function. Or-self matchers
; stand for the value they matched in place of themselves. Published corpora
; (--packs) list them alike.
; RUN: split-file %s %t
; RUN: %metaphir-match --matches-only --print-instructions %t/pattern.mpir \
; RUN:   %t/input.ll | FileCheck %s
; RUN: %metaphir-match --matches-only --print-instructions %t/composite.mpir \
; RUN:   %t/signum.ll | FileCheck %s --check-prefix=COMPOSITE
; RUN: %metaphir-match --matches-only --print-instructions %t/defined.mpir \
; RUN:   %t/double.ll | FileCheck %s --check-prefix=DEFINED
; RUN: %metaphir-match --matches-only --print-instructions %t/nested.mpir \
; RUN:   %t/thrice.ll | FileCheck %s --check-prefix=NESTED
; RUN: rm -rf %t/corpus && mkdir %t/corpus
; RUN: llvm-as %t/input.ll -o %t/corpus/input.bc
; RUN: %metaphir-index build %t/corpus -o %t/corpus.mpidx 2>/dev/null
; RUN: %metaphir-index publish %t/corpus.mpidx -o %t/published 2>/dev/null
; RUN: %metaphir-match --matches-only --print-instructions --packs %t/published \
; RUN:   %t/pattern.mpir | FileCheck %s
; RUN: not %metaphir-match --print-instructions %t/pattern.mpir %t/input.ll \
; RUN:   2>&1 | FileCheck %s --check-prefix=ONLY

;--- pattern.mpir
%difference = sub i32 ?x, ?y
; A comment line between instructions.
%sum = add:o i32 %difference, 1
store i32 %sum, ptr ?p

; Instructions expanded from a composite matcher (from a library) are traced
; to the pattern's instruction that uses it.
;--- composite.mpir
%s = signum i32 ?x
%n = neg i32 %s

;--- signum.ll
define i32 @signum(i32 %x) {
  %neg = sub i32 0, %x
  %lhs = ashr i32 %x, 31
  %rhs = lshr i32 %neg, 31
  %ret = or i32 %lhs, %rhs
  %n = sub i32 0, %ret
  ret i32 %n
}

; COMPOSITE: signum.ll	@signum	{{[{].*[}]}}	{%s@1 = #3, %s$lhs@1 = #1, %s$neg@1 = #0, %s$rhs@1 = #2, %n@2 = #4}

; A composite defined in the pattern's own file is traced to its use too,
; not to its definition.
;--- defined.mpir
match twice [] Unary (?ty ?x) {
	%ret = shl ?ty ?x, 1
}
%d = twice i32 ?x
%r = add i32 %d, 1

;--- double.ll
define i32 @double(i32 %x) {
  %d = shl i32 %x, 1
  %r = add i32 %d, 1
  ret i32 %r
}

; DEFINED: double.ll	@double	{?x = %x}	{%d@4 = #0, %r@5 = #1}

; Composites using composites, three deep (negThrice, negTwice and the
; library's neg): every instruction expanded is traced to the outermost use.
;--- nested.mpir
match negTwice [] Unary (?ty ?x) {
	%inner = neg ?ty ?x
	%ret = neg ?ty %inner
}
match negThrice [] Unary (?ty ?x) {
	%twice = negTwice ?ty ?x
	%ret = neg ?ty %twice
}
%a = add i32 ?x, 1
%r = negThrice i32 %a

;--- thrice.ll
define i32 @thrice(i32 %x) {
  %a = add i32 %x, 1
  %n1 = sub i32 0, %a
  %n2 = sub i32 0, %n1
  %r = sub i32 0, %n2
  ret i32 %r
}

; NESTED: thrice.ll	@thrice	{?x = %x}	{%a@9 = #0, %r@10 = #3, %r$twice@10 = #2, %r$twice$inner@10 = #1}

;--- input.ll
define void @self(i32 %x, i32 %y, ptr %p) {
  %difference = sub i32 %x, %y
  store i32 %difference, ptr %p
  ret void
}

define void @wrapper(i32 %x, i32 %y, ptr %p) {
entry:
  %unrelated = mul i32 %x, %y
  br label %next
next:
  %difference = sub i32 %x, %y
  %result = add i32 %difference, 1
  store i32 %result, ptr %p
  ret void
}

; CHECK:      input.{{ll|bc}}	@self	{?p = %p, ?x = %x, ?y = %y}	{%difference@1 = #0, %sum@3 = #0, store@4 = #1}
; CHECK-NEXT: input.{{ll|bc}}	@wrapper	{?p = %p, ?x = %x, ?y = %y}	{%difference@1 = #2, %sum@3 = #3, store@4 = #4}
; CHECK-NOT:  {{.}}

; ONLY: error: --print-instructions needs --matches-only
