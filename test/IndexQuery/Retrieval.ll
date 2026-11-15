; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; mpir-index-retrieval and mpir-index-factor: the functions to check are
; those on the lists of some variant's features; a list every variant needs
; is read once, for all.
; RUN: %metaphir-parse --emit=mlir %s | %metaphir-opt --mpir-lower --mpir-to-index --mpir-index-retrieval --mpir-index-factor | FileCheck %s

%r = shr i32 ?x, ?y
%t = trunc i32 %r to i8

; Both variants (lshr and ashr) need a trunc, which is intersected once with
; what either needs besides.
; CHECK:      mpir_index.retrieve {
; CHECK:        %[[LSHR:.*]] = mpir_index.intersect
; CHECK-NEXT:   %[[ASHR:.*]] = mpir_index.intersect
; CHECK-NEXT:   %[[EITHER:.*]] = mpir_index.union %[[LSHR]], %[[ASHR]]
; CHECK-NEXT:   %[[ALL:.*]] = mpir_index.intersect %{{.*}}, %[[EITHER]]
; CHECK-NEXT:   mpir_index.result %[[ALL]]
