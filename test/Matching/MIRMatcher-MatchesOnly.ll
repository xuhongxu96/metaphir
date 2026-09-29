; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; --matches-only prints a line per match and nothing else; -j matches files
; in parallel but prints them in order.
; RUN: split-file %s %t
; RUN: not %metaphir-match --matches-only %t/pattern.mpir %t/inputs > %t/out 2> %t/err
; RUN: FileCheck %s --check-prefix=OUT < %t/out
; RUN: FileCheck %s --check-prefix=ERR < %t/err
; RUN: not %metaphir-match --matches-only -j 4 %t/pattern.mpir %t/inputs > %t/out4 2> %t/err4
; RUN: diff %t/out %t/out4
; RUN: diff %t/err %t/err4
; RUN: not %metaphir-match -j 4 %t/pattern.mpir %t/inputs 2>&1 | FileCheck %s --check-prefix=JOBS

;--- pattern.mpir
%r = add:?anch i32 ?x, ?y

;--- inputs/a.ll
define i32 @two(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  %s = add i32 %r, %y
  ret i32 %s
}

define i32 @none(i32 %x, i32 %y) {
  %r = sub i32 %x, %y
  ret i32 %r
}

;--- inputs/b.ll
define i32 @broken( {

;--- inputs/c.ll
define i32 @one(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}

; OUT:      {{.*}}a.ll	@two	{?anch = %r, ?x = %x, ?y = %y}
; OUT-NEXT: {{.*}}a.ll	@two	{?anch = %s, ?x = %r, ?y = %y}
; OUT-NEXT: {{.*}}c.ll	@one	{?anch = %r, ?x = %x, ?y = 1}
; OUT-NOT:  {{.}}

; ERR: b.ll:{{[0-9]+:[0-9]+}}: error:

; JOBS: error: -j needs --matches-only
