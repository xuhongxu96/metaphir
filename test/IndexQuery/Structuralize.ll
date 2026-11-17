; mpir-index-structuralize: what constraints say of an intrinsic's name or an
; instruction's kind becomes features the corpus index looks up.
; RUN: split-file %s %t
; RUN: %metaphir-parse --emit=mlir --mlir-print-debuginfo %t/callee.mpir | %metaphir-opt --mpir-lower --mpir-to-index --mpir-index-structuralize | FileCheck %s --check-prefix=CALLEE
; RUN: %metaphir-parse --emit=mlir --mlir-print-debuginfo %t/either.mpir | %metaphir-opt --mpir-lower --mpir-to-index --mpir-index-structuralize | FileCheck %s --check-prefix=EITHER
; RUN: %metaphir-parse --emit=mlir --mlir-print-debuginfo %t/opcode.mpir | %metaphir-opt --mpir-lower --mpir-to-index --mpir-index-structuralize | FileCheck %s --check-prefix=OPCODE

;--- callee.mpir
%c = call i?n @llvm.?id(i?n ?x, i1 ?z)
;; ?id == "llvm.ctlz"
; '@llvm.?id' is the intrinsic the constraint names.
; CALLEE:      mpir_index.variant {
; CALLEE-NEXT:   mpir_index.has_global "llvm.ctlz" {derived}
; CALLEE-NEXT:   mpir_index.has_instruction <call>

;--- either.mpir
%m = call:?mm i32 @llvm.?id(i32 ?a, i32 ?b)
;; intrinsic(?mm) == "llvm.smax" || intrinsic(?mm) == "llvm.umin"
; A variant per intrinsic.
; EITHER:      mpir_index.variant {
; EITHER-NEXT:   mpir_index.has_global "llvm.smax" {derived}
; EITHER:      mpir_index.variant {
; EITHER-NEXT:   mpir_index.has_global "llvm.umin" {derived}
; EITHER-NOT:  mpir_index.variant

;--- opcode.mpir
%e = zextOrSext:?ext i8 ?x to i32
;; opcode(?ext) == "sext"
; In the zext branch the constraint cannot hold.
; OPCODE:      mpir_index.variant <impossible> {
; OPCODE-NEXT:   mpir_index.has_instruction <zext>
; OPCODE:      mpir_index.variant {
; OPCODE-NEXT:   mpir_index.has_instruction <sext> {derived}
; OPCODE-NEXT:   mpir_index.has_instruction <sext>
