; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; The files an index covers: the IR and bitcode under a directory, followed
; through symbolic links, and nothing else. A path that does not exist is
; reported; one outside the index is matched in full, with a warning.
; RUN: split-file %s %t
; RUN: ln -sf %t/tree/a.ll %t/tree/link.ll
; RUN: llvm-as %t/tree/b.ll -o %t/tree/sub.bc
; RUN: %metaphir-index build %t/tree -o %t/index.mpidx 2>&1 | FileCheck %s --check-prefix=BUILD
; RUN: %metaphir-match --matches-only --index %t/index.mpidx %t/pattern.mpir %t/tree | FileCheck %s --check-prefix=MATCH
; RUN: not %metaphir-match --matches-only %t/pattern.mpir %t/nowhere 2>&1 | FileCheck %s --check-prefix=MISSING
; RUN: %metaphir-match --matches-only --index %t/index.mpidx --trust-index %t/pattern.mpir %t/elsewhere 2>&1 | FileCheck %s --check-prefix=OUTSIDE

; BUILD: indexed {{[0-9]+}} files
; MATCH-DAG: a.ll{{.*}}@f
; MATCH-DAG: link.ll{{.*}}@f
; MATCH-DAG: sub.bc{{.*}}@g
; MATCH-NOT: note.txt
; MISSING: nowhere{{.*}}
; OUTSIDE: not indexed; matching it in full
; OUTSIDE: @k

;--- pattern.mpir
%r = add i32 ?x, ?y

;--- tree/a.ll
define i32 @f(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}

;--- tree/b.ll
define i32 @g(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}

;--- tree/note.txt
define i32 @h(i32 %a) {
  %r = add i32 %a, 1
  ret i32 %r
}

;--- elsewhere/c.ll
define i32 @k(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
