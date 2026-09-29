; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; metaphir-match reports an input it cannot read, keeps matching the others,
; and exits with an error.
; RUN: split-file %s %t
; RUN: not %metaphir-match %t/pattern.mpir %t/broken.ll %t/good.ll > %t/out 2> %t/err
; RUN: FileCheck %s --check-prefix=OUT < %t/out
; RUN: FileCheck %s --check-prefix=ERR < %t/err
; RUN: %metaphir-match --help | FileCheck %s --check-prefix=HELP

;--- pattern.mpir
%r = add:?anch i32 ?x, ?y

;--- broken.ll
define i32 @broken( {

;--- good.ll
define i32 @good(i32 %x, i32 %y) {
  %r = add i32 %x, %y
  ret i32 %r
}
; OUT: target 0: @good
; OUT-NEXT:   match 0:
; ERR: broken.ll:{{[0-9]+:[0-9]+}}: error:

; HELP: USAGE: metaphir-match [options] <pattern> <llvm-ir file or directory>...
