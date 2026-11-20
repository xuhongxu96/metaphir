; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; A corpus published with metaphir-index publish is matched with --packs as
; the files are, one function at a time, uses of globals in other functions
; included.
; RUN: rm -rf %t && split-file %s %t && mkdir %t/corpus
; RUN: llvm-as %t/src/uses.ll -o %t/corpus/uses.bc
; RUN: llvm-as %t/src/other.ll -o %t/corpus/other.bc
; RUN: %metaphir-index build %t/corpus -o %t/corpus.mpidx 2>/dev/null
; RUN: %metaphir-index publish %t/corpus.mpidx -o %t/published 2>/dev/null
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/corpus \
; RUN:   | sed 's|^.*/corpus/||' > %t/plain
; RUN: %metaphir-match --matches-only --packs %t/published -j 2 --summary \
; RUN:   %t/pattern.mpir > %t/packs 2> %t/summary
; RUN: diff %t/plain %t/packs
; RUN: FileCheck %s < %t/packs
; RUN: FileCheck %s --check-prefix=SUMMARY < %t/summary

; RUN: not %metaphir-match --matches-only --packs %t/published \
; RUN:   --index %t/corpus.mpidx %t/pattern.mpir 2>&1 \
; RUN:   | FileCheck %s --check-prefix=WITH-INDEX
; RUN: not %metaphir-match --packs %t/published %t/pattern.mpir 2>&1 \
; RUN:   | FileCheck %s --check-prefix=WITH-INDEX
; RUN: cp -r %t/published %t/broken
; RUN: echo broken > %t/broken/header.bin.zst
; RUN: not %metaphir-match --matches-only --packs %t/broken %t/pattern.mpir \
; RUN:   2>&1 | FileCheck %s --check-prefix=BROKEN

;--- pattern.mpir
%v = load i32, ptr ?p
;; hasOneUse(?p)

;--- src/uses.ll
@shared = global i32 0
@single = global i32 0

define i32 @load_shared() {
  %v = load i32, ptr @shared
  ret i32 %v
}

define void @store_shared() {
  store i32 1, ptr @shared
  ret void
}

define i32 @load_single() {
  %v = load i32, ptr @single
  ret i32 %v
}

;--- src/other.ll
@0 = global i32 0
@1 = global i32 0

define i32 @load_unnamed() {
  %v = load i32, ptr @1
  ret i32 %v
}

; CHECK:      other.bc	@load_unnamed	{?p = @1}
; CHECK-NEXT: uses.bc	@load_single	{?p = @single}
; CHECK-NOT:  {{.}}

; SUMMARY: matched 3 of 4 functions (3 on the posting lists)

; WITH-INDEX: error: --packs needs --matches-only, and no --index or input files

; BROKEN: error: published corpus header: not a zstd frame of known size
