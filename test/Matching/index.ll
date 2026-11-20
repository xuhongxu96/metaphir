; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; --index skips the files and functions whose indexed features rule out a
; match, and matches files that are not indexed as they are in full.
; RUN: rm -rf %t && split-file %s %t && mkdir %t/corpus
; RUN: llvm-as %t/src/adds.ll -o %t/corpus/adds.bc
; RUN: llvm-as %t/src/subs.ll -o %t/corpus/subs.bc
; RUN: llvm-as %t/src/mixed.ll -o %t/corpus/mixed.bc
; RUN: %metaphir-index build %t/corpus -o %t/corpus.mpidx 2>&1 | FileCheck %s --check-prefix=BUILD
; RUN: %metaphir-index dump %t/corpus.mpidx | FileCheck %s --check-prefix=DUMP
; RUN: %metaphir-match --matches-only %t/pattern.mpir %t/corpus > %t/plain
; RUN: %metaphir-match --matches-only --summary --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/indexed 2> %t/summary
; RUN: diff %t/plain %t/indexed
; RUN: FileCheck %s --check-prefix=MATCH < %t/indexed
; RUN: FileCheck %s --check-prefix=SUMMARY < %t/summary
; RUN: %metaphir-match --matches-only -j 3 --index %t/corpus.mpidx %t/pattern.mpir %t/corpus | diff %t/plain -
; RUN: %metaphir-match --matches-only --trust-index --summary --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/trusted 2> %t/trusted-summary
; RUN: diff %t/plain %t/trusted
; RUN: FileCheck %s --check-prefix=TRUSTED-SUMMARY < %t/trusted-summary

; A file changed since indexing, and one never indexed, are matched in full.
; RUN: llvm-as %t/src/adds-changed.ll -o %t/corpus/adds.bc
; RUN: cp %t/src/extra.ll %t/corpus/extra.ll
; RUN: %metaphir-match --matches-only --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/stale 2> %t/stale-err
; RUN: FileCheck %s --check-prefix=STALE < %t/stale
; RUN: FileCheck %s --check-prefix=STALE-ERR < %t/stale-err

; Trusting the index, a changed candidate file is still matched in full, but
; files that are not indexed are not looked for.
; RUN: %metaphir-match --matches-only --trust-index --index %t/corpus.mpidx %t/pattern.mpir %t/corpus > %t/trusted-stale 2> %t/trusted-stale-err
; RUN: FileCheck %s --check-prefix=TRUSTED-STALE < %t/trusted-stale
; RUN: FileCheck %s --check-prefix=TRUSTED-STALE-ERR < %t/trusted-stale-err

; RUN: not %metaphir-match --index %t/corpus.mpidx %t/pattern.mpir %t/corpus 2>&1 | FileCheck %s --check-prefix=NEEDS-MATCHES-ONLY
; RUN: not %metaphir-match --matches-only --trust-index %t/pattern.mpir %t/corpus 2>&1 | FileCheck %s --check-prefix=NEEDS-INDEX
; RUN: not %metaphir-match --matches-only --index %t/missing.mpidx %t/pattern.mpir %t/corpus 2>&1 | FileCheck %s --check-prefix=NO-INDEX

;--- pattern.mpir
%a = add:?anch i32 ?x, ?y
%m = mul i32 %a, ?z

;--- src/adds.ll
define i32 @add_mul(i32 %x, i32 %y) {
  %a = add i32 %x, %y
  %m = mul i32 %a, %y
  ret i32 %m
}

define i32 @add_only(i32 %x, i32 %y) {
  %a = add i32 %x, %y
  ret i32 %a
}

;--- src/subs.ll
define i32 @sub_only(i32 %x, i32 %y) {
  %s = sub i32 %x, %y
  ret i32 %s
}

;--- src/mixed.ll
define i32 @apart(i32 %x, i32 %y) {
  %a = add i32 %x, %y
  %m = mul i32 %x, %y
  %s = sub i32 %a, %m
  ret i32 %s
}

define i32 @second(i32 %x, i32 %y) {
  %a = add i32 %y, %x
  %m = mul i32 %a, %a
  ret i32 %m
}

;--- src/adds-changed.ll
define i32 @renamed(i32 %x, i32 %y) {
  %a = add i32 %x, %y
  %m = mul i32 %a, %x
  ret i32 %m
}

;--- src/extra.ll
define i32 @extra(i32 %x) {
  %a = add i32 %x, 1
  %m = mul i32 %a, 2
  ret i32 %m
}

; BUILD: indexed 3 files

; DUMP:      module adds.bc: add mul ret; mul-add ret-add ret-mul; 0 globals
; DUMP-NEXT:   0: add mul ret; mul-add ret-mul; 0 globals
; DUMP-NEXT:   1: add ret; ret-add; 0 globals
; DUMP-NEXT: module mixed.bc: add sub mul ret; sub-add sub-mul mul-add ret-sub ret-mul; 0 globals
; DUMP-NEXT:   0: add sub mul ret; sub-add sub-mul ret-sub; 0 globals
; DUMP-NEXT:   1: add mul ret; mul-add ret-mul; 0 globals
; DUMP-NEXT: module subs.bc: sub ret; ret-sub; 0 globals
; DUMP-NEXT:   0: sub ret; ret-sub; 0 globals

; MATCH:      {{.*}}adds.bc	@add_mul	{?anch = %a, ?x = %x, ?y = %y, ?z = %y}
; MATCH-NEXT: {{.*}}mixed.bc	@second	{?anch = %a, ?x = %y, ?y = %x, ?z = %a}
; MATCH-NOT:  {{.}}

; SUMMARY: matched 2 of 5 functions (in 2 of 3 files)

; STALE:      {{.*}}adds.bc	@renamed	{?anch = %a, ?x = %x, ?y = %y, ?z = %x}
; STALE-NEXT: {{.*}}extra.ll	@extra	{?anch = %a, ?x = %x, ?y = 1, ?z = 2}
; STALE-NEXT: {{.*}}mixed.bc	@second

; STALE-ERR-DAG: warning: {{.*}}adds.bc: changed since indexed; matching it in full
; STALE-ERR-DAG: warning: {{.*}}extra.ll: not indexed; matching it in full

; TRUSTED-SUMMARY: matched 2 of 4 functions (in 2 of 2 files)

; TRUSTED-STALE:      {{.*}}adds.bc	@renamed	{?anch = %a, ?x = %x, ?y = %y, ?z = %x}
; TRUSTED-STALE-NEXT: {{.*}}mixed.bc	@second
; TRUSTED-STALE-NOT:  extra.ll

; TRUSTED-STALE-ERR: warning: {{.*}}adds.bc: changed since indexed; matching it in full
; TRUSTED-STALE-ERR-NOT: extra.ll

; NEEDS-MATCHES-ONLY: error: --index needs --matches-only

; NEEDS-INDEX: error: --trust-index needs --index

; NO-INDEX: error: '{{.*}}missing.mpidx': No such file or directory
