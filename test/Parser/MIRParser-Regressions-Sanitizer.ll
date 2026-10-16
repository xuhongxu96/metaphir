; Inputs that once crashed the parser or matcher.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/composite-or-self-range.mpir 2>&1 | FileCheck %s --check-prefix=COMPOSITE-OR-SELF-RANGE
; RUN: %metaphir-parse %t/composite-or-self.mpir | FileCheck %s --check-prefix=COMPOSITE-OR-SELF

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
