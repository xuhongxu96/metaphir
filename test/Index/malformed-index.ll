; A damaged index is rejected, with what is wrong with it. Each is patched from
; a valid index of one module.
; RUN: split-file %s %t
; RUN: %metaphir-index build %t/corpus -o %t/valid.mpidx 2>/dev/null
; RUN: python3 %S/Inputs/patch_index.py magic %t/valid.mpidx %t/magic.mpidx
; RUN: not %metaphir-match --matches-only --index %t/magic.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=MAGIC
; RUN: python3 %S/Inputs/patch_index.py version %t/valid.mpidx %t/version.mpidx 9
; RUN: not %metaphir-match --matches-only --index %t/version.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=VERSION
; RUN: python3 %S/Inputs/patch_index.py llvm %t/valid.mpidx %t/llvm.mpidx
; RUN: not %metaphir-match --matches-only --index %t/llvm.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=LLVM
; RUN: python3 %S/Inputs/patch_index.py schema %t/valid.mpidx %t/schema.mpidx 1
; RUN: not %metaphir-match --matches-only --index %t/schema.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=SCHEMA
; RUN: python3 %S/Inputs/patch_index.py directory %t/valid.mpidx %t/directory.mpidx 999999
; RUN: not %metaphir-match --matches-only --index %t/directory.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=DIRECTORY
; RUN: echo garbage > %t/garbage.mpidx
; RUN: not %metaphir-match --matches-only --index %t/garbage.mpidx %t/pattern.mpir %t/corpus/a.ll 2>&1 | FileCheck %s --check-prefix=GARBAGE
; RUN: not %metaphir-index build %t/missing -o %t/none.mpidx 2>&1 | FileCheck %s --check-prefix=MISSING
; RUN: not %metaphir-index build %t/corpus/a.ll -o %t/none.mpidx 2>&1 | FileCheck %s --check-prefix=FILE

; MAGIC: not a MetaphIR index
; VERSION: index format version 9, expected 8
; LLVM: index built with LLVM x
; SCHEMA: index built for other instruction matchers
; DIRECTORY: directory size mismatch
; GARBAGE: not a MetaphIR index
; MISSING: {{.*}}missing{{.*}}
; FILE: {{.*}}Not a directory

;--- pattern.mpir
%r = add i32 ?x, ?y

;--- corpus/a.ll
define i32 @f(i32 %a, i32 %b) {
  %r = add i32 %a, %b
  ret i32 %r
}
