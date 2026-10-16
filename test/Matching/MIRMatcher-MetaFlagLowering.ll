; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s
; RUN: not %metaphir-match %t/invalid-not.mpir %t/match.ll 2>&1 | FileCheck %s --check-prefix=NOT-ERROR
; RUN: not %metaphir-match %t/invalid-or.mpir %t/match.ll 2>&1 | FileCheck %s --check-prefix=OR-ERROR
; RUN: not %metaphir-match %t/invalid-nested.mpir %t/match.ll 2>&1 | FileCheck %s --check-prefix=NESTED-ERROR

; Exercise lowering of nested :or and :not metaflags through the command-line
; matcher, rather than only checking the generated constraint objects in C++.

;--- pattern.mpir
%r = add i32 ?x:or(:s, :su), ?y:not(:s)

;--- match.ll
define i32 @nested_flags_match(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  %extra = add i32 %y, 1
  ret i32 %r
}
; CHECK: target 0: @nested_flags_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?x = %x, ?y = %y}

;--- no-match.ll
define i32 @nested_flags_no_match(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}
; CHECK-NEXT: target 1: @nested_flags_no_match
; CHECK-NEXT:   no match
; CHECK-NEXT:   constraint not satisfied: (! (hasOneUse ?y))
; CHECK-NOT: {{.}}

; Malformed nested flags are diagnosed instead of being silently preserved.

;--- invalid-not.mpir
%r = add i32 ?x:not(), ?y
;--- invalid-or.mpir
%r = add i32 ?x:or(), ?y
;--- invalid-nested.mpir
%r = add i32 ?x:or(:c), ?y

; NOT-ERROR: error: invalid number of arguments for metaflag ':not'
; NOT-ERROR-NEXT: %r = add i32 ?x:not(), ?y
; NOT-ERROR-NEXT:                ^
; NOT-ERROR-NOT: {{.}}

; OR-ERROR: error: invalid number of arguments for metaflag ':or'
; OR-ERROR-NEXT: %r = add i32 ?x:or(), ?y
; OR-ERROR-NEXT:                ^
; OR-ERROR-NOT: {{.}}

; NESTED-ERROR: error: metaflag ':c' is not valid as a nested metaflag
; NESTED-ERROR-NEXT: %r = add i32 ?x:or(:c), ?y
; NESTED-ERROR-NEXT:                    ^
; NESTED-ERROR-NOT: {{.}}
