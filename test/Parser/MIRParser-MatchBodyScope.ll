; A 'match' body is a closed scope. A matcher is expanded at each of its uses,
; so its body may only refer to its own parameters -- never to the locals or
; meta variables of the pattern that happens to surround the declaration.
;
; The declarations below deliberately come *after* a pattern instruction, which
; is the only situation where the enclosing scope is non-empty and a leak is
; observable.

; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/captures-local.ll 2>&1 | FileCheck %s --check-prefix=LOCAL
; RUN: not %metaphir-parse %t/captures-block.ll 2>&1 | FileCheck %s --check-prefix=BLOCK
; RUN: %metaphir-parse %t/closed.ll | FileCheck %s --check-prefix=OK

; The body must not see '%outer' from the enclosing pattern.
;--- captures-local.ll
%outer = add i32 ?p, ?q

match leaky [] Binary (?ty ?x, ?y) {
	%ret = mul ?ty ?x, %outer
; LOCAL: undefined or forward local reference '%outer'

}

%r = leaky i32 ?a, ?b
; Nor an instruction defined earlier in the same enclosing pattern by label.
;--- captures-block.ll
%first = add i32 ?p, ?q
%second = mul i32 %first, ?p

match leaky2 [] Binary (?ty ?x, ?y) {
	%ret = sub ?ty %second, ?y
; BLOCK: undefined or forward local reference '%second'

}

%r = leaky2 i32 ?a, ?b
; A body that uses only its parameters is unaffected by the surrounding scope,
; and the enclosing pattern keeps its own names afterwards.
;--- closed.ll
%outer = add i32 ?p, ?q
; OK: pattern instructions=2 constraints=0
; OK-NEXT: %outer = add i32 ?p, ?q

match afterwards [] Binary (?ty ?x, ?y) {
	%ret = mul ?ty ?x, ?y
}

%r = afterwards i32 ?p, ?q
; OK-NEXT: %r = afterwards i32 ?p, ?q
; OK-NEXT: meta ?p type=Value
; OK-NEXT: meta ?q type=Value
