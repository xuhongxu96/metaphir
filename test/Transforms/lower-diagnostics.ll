; The lowering passes' errors, as the tools print them: at the pattern's
; source, like the parser's.
; RUN: split-file %s %t
; RUN: not %metaphir-match %t/unbound.mpir %t/empty.ll 2>&1 | FileCheck %s --check-prefix=UNBOUND
; RUN: not %metaphir-match %t/unbound-branch.mpir %t/empty.ll 2>&1 | FileCheck %s --check-prefix=UNBOUND-BRANCH
; RUN: not %metaphir-match %t/fixed-type.mpir %t/empty.ll 2>&1 | FileCheck %s --check-prefix=FIXED-TYPE

;--- unbound.mpir
%a = add:o i32 ?x, ?y
%b = mul i32 %a, 3
;--- unbound-branch.mpir
; The use captures 'nsw', but the second branch has no instruction to capture
; it from.
match addish [nsw] Binary (?ty ?x, ?y) {
  %ret = add nsw:?f ?ty ?x, ?y
} or {
  %ret = or ?ty ?x, ?y
}
%r = addish nsw:?c i32 ?a, ?b
;--- fixed-type.mpir
match pick [] Nary (i1 ?c, ?ty ?t) {
  %ret = select i1 ?c, ?ty ?t, ?ty ?t
}
%r = pick ?any ?cond, i32 ?x
;--- empty.ll

; UNBOUND: error: meta variable '?y' is not bound by every alternative; name it '?_y' if it need not be bound
; UNBOUND-NEXT: %a = add:o i32 ?x, ?y
; UNBOUND-NEXT:                    ^
; UNBOUND-NOT: {{.}}

; UNBOUND-BRANCH: error: meta variable '?c' is not bound by every alternative; name it '?_c' if it need not be bound
; UNBOUND-BRANCH-NEXT: %r = addish nsw:?c i32 ?a, ?b
; UNBOUND-BRANCH-NEXT:                ^
; UNBOUND-BRANCH-NOT: {{.}}

; FIXED-TYPE: error: matcher 'pick' requires type 'i1' for a parameter, but this use passes '?any'
; FIXED-TYPE-NEXT: %r = pick ?any ?cond, i32 ?x
; FIXED-TYPE-NEXT:                ^
; FIXED-TYPE-NOT: {{.}}
