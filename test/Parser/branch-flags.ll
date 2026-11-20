; RUN: split-file %s %t
; RUN: %metaphir-parse %t/ok.ll | FileCheck %s --check-prefix=OK
; RUN: not %metaphir-parse %t/undeclared.ll 2>&1 | FileCheck %s --check-prefix=UNDECLARED
; RUN: not %metaphir-parse %t/badval.ll 2>&1 | FileCheck %s --check-prefix=BADVAL

;--- ok.ll
match:c myadd [nsw, nuw] Binary (?ty ?x, ?y) {
%ret = add nsw:?nsw nuw:?nuw ?ty ?x, ?y
} or [nsw = true, nuw = true] {
%ret = or disjoint ?ty ?x, ?y
} or [nsw, nuw = false] {
%ret = sub ?ty ?x, ?y
}

%r = myadd i32 ?a, ?b
; OK: pattern instructions=1 constraints=0
; OK-NEXT: %r = myadd i32 ?a, ?b
; OK-NEXT: meta ?a type=Value
; OK-NEXT: meta ?b type=Value
; OK-NOT: {{.}}

;--- undeclared.ll
match:c badflags [nsw] Binary (?ty ?x, ?y) {
%ret = add ?ty ?x, ?y
} or [nuw = true] {
; UNDECLARED: flag 'nuw' is not declared in matcher's supported flags

%ret = or ?ty ?x, ?y
}
;--- badval.ll
match:c badval [nsw] Binary (?ty ?x, ?y) {
%ret = add ?ty ?x, ?y
} or [nsw = 123] {
; BADVAL: expected 'true' or 'false' after '='

%ret = or ?ty ?x, ?y
}
