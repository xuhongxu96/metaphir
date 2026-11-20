; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; With --index, functions the index rules out are not read, but their uses of
; globals still count for hasOneUse and hasOneUser.
; RUN: rm -rf %t && split-file %s %t && mkdir %t/corpus
; RUN: llvm-as %t/src/uses.ll -o %t/corpus/uses.bc
; RUN: %metaphir-index build %t/corpus -o %t/corpus.mpidx 2>/dev/null
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/corpus > %t/plain
; RUN: %metaphir-match --matches-only --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/indexed
; RUN: diff %t/plain %t/indexed
; RUN: FileCheck %s < %t/indexed

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

; CHECK:     {{.*}}uses.bc	@load_single	{?p = @single}
; CHECK-NOT: {{.}}
