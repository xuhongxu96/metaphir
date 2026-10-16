; Inputs that once crashed the parser or matcher.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/composite-or-self-range.mpir 2>&1 | FileCheck %s --check-prefix=COMPOSITE-OR-SELF-RANGE
; RUN: %metaphir-parse %t/composite-or-self.mpir | FileCheck %s --check-prefix=COMPOSITE-OR-SELF
; RUN: not %metaphir-parse %t/empty-block.mpir 2>&1 | FileCheck %s --check-prefix=EMPTY-BLOCK
; RUN: %metaphir-parse %t/branch-target.mpir | FileCheck %s --check-prefix=BRANCH-TARGET

; ':o' on a composite matcher's use is checked against its operands, as on
; a built-in instruction.
;--- composite-or-self-range.mpir
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1
}
%r = m:o(1) i32 ?a
; COMPOSITE-OR-SELF-RANGE: metaflag ':o' operand index is out of range

;--- composite-or-self.mpir
match m [] Unary (?t ?x) {
  %ret = xor ?t ?x, -1
}
%r = m:o(0) i32 ?a
; COMPOSITE-OR-SELF: pattern instructions=1 constraints=0
; COMPOSITE-OR-SELF-NEXT: %r = m:o(0) i32 ?a
; COMPOSITE-OR-SELF-NEXT: meta ?a type=Value
; COMPOSITE-OR-SELF-NOT: {{.}}

; A block label with no instruction, which nothing refers to, binds nothing.
;--- empty-block.mpir
%d = sub i32 ?x, ?y
?a:
; EMPTY-BLOCK: block '?a' has no instruction, and no instruction refers to it

; One a branch refers to is bound by it.
;--- branch-target.mpir
?a:
; BRANCH-TARGET: pattern instructions=2 constraints=0
; BRANCH-TARGET-NEXT: ?a:

%d = sub i32 ?x, ?y
; BRANCH-TARGET-NEXT: %d = sub i32 ?x, ?y

br label ?b
; BRANCH-TARGET-NEXT: br label ?b
; BRANCH-TARGET-NEXT: meta ?a type=BasicBlock
; BRANCH-TARGET-NEXT: meta ?x type=Value
; BRANCH-TARGET-NEXT: meta ?y type=Value
; BRANCH-TARGET-NEXT: meta ?b type=BasicBlock
; BRANCH-TARGET-NOT: {{.}}

?b:
