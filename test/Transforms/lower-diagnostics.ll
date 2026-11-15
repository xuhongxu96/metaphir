; The lowering passes' errors, as the tools print them: at the pattern's
; source, like the parser's.
; RUN: split-file %s %t
; RUN: not %metaphir-match %t/unbound.mpir %t/empty.ll 2>&1 | FileCheck %s --check-prefix=UNBOUND
; RUN: not %metaphir-match %t/fixed-type.mpir %t/empty.ll 2>&1 | FileCheck %s --check-prefix=FIXED-TYPE

;--- unbound.mpir
%a = add:o i32 ?x, ?y
%b = mul i32 %a, 3
;--- fixed-type.mpir
match pick [] Nary (i1 ?c, ?ty ?t) {
  %ret = select i1 ?c, ?ty ?t, ?ty ?t
}
%r = pick ?any ?cond, i32 ?x
;--- empty.ll

; UNBOUND: error: meta variable '?y' is not bound when ':o' lets 'add' match its operand; name it '?_y' if it need not be bound
; UNBOUND-NEXT: %a = add:o i32 ?x, ?y
; UNBOUND-NEXT:                    ^
; UNBOUND-NOT: {{.}}

; FIXED-TYPE: error: matcher 'pick' requires type 'i1' for a parameter, but this use passes '?any'
; FIXED-TYPE-NEXT: %r = pick ?any ?cond, i32 ?x
; FIXED-TYPE-NEXT:                ^
; FIXED-TYPE-NOT: {{.}}
