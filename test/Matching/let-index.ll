; A 'let' does not make the index skip what can match: a constraint that
; reads the variable it binds is no requirement of the corpus's functions.
; RUN: rm -rf %t && split-file %s %t && mkdir %t/corpus
; RUN: llvm-as %t/src/compares.ll -o %t/corpus/compares.bc
; RUN: %metaphir-index build %t/corpus -o %t/corpus.mpidx 2>&1 | FileCheck %s --check-prefix=BUILD
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/corpus > %t/plain
; RUN: %metaphir-match --matches-only --summary --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/indexed 2> %t/summary
; RUN: diff %t/plain %t/indexed
; RUN: FileCheck %s --check-prefix=MATCH < %t/indexed
; RUN: %metaphir-match --matches-only --trust-index --index %t/corpus.mpidx %t/pattern.mpir %t/corpus | diff %t/plain -

;--- pattern.mpir
%c = icmp:?anch ?pred i32 ?x, ?y
;; let ?swapped = swappedPredicate(?pred)
;; ?swapped == "sgt"

;--- src/compares.ll
define i1 @lt(i32 %a, i32 %b) {
  %c = icmp slt i32 %a, %b
  ret i1 %c
}
define i1 @gt(i32 %a, i32 %b) {
  %c = icmp sgt i32 %a, %b
  ret i1 %c
}

; BUILD: indexed 1 files
; BUILD-NOT: {{.}}

; MATCH: {{.*}}/corpus/compares.bc	@lt	{?anch = %c, ?pred = slt, ?swapped = sgt, ?x = %a, ?y = %b}
; MATCH-NOT: {{.}}
