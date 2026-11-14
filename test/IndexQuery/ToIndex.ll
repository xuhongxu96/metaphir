; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; mpir-to-index: a variant per branch of a matcher's use, each requiring the
; instructions, edges, siblings and facts a match needs, typing the
; instructions it is sure to match, and assuming the constraints on the
; sites the pattern's values are at.
; RUN: %metaphir-parse --engine=mlir --emit=mlir %s | %metaphir-opt --mpir-lower --mpir-to-index | FileCheck %s

%d = udiv i?n ?x, 2
%r = shr i?n %d, ?y
;; isKnownNonZero(?y)

; One variant for lshr, one for ashr.
; CHECK:      mpir_index.query {
; CHECK-NEXT:   mpir_index.variant {
; CHECK-NEXT:     mpir_index.has_instruction <udiv>
; CHECK-NEXT:     mpir_index.has_instruction <lshr>
; CHECK-NEXT:     mpir_index.has_edge <lshr> -> <udiv>
; CHECK-NEXT:     mpir_index.has_fact 0, <udiv>, 2, 130
; CHECK-NEXT:     mpir_index.typing <udiv>
; CHECK-NEXT:     mpir_index.typing <lshr>
; CHECK:          %[[Y:.*]] = mpir_index.sites [{{\[}}1, {{[0-9]+}}, 2]] {var_name = "y"}
; CHECK-NEXT:     %[[READ:.*]] = mpir_expr.read %[[Y]]
; CHECK-NEXT:     %[[AT:.*]] = mpir_index.node 1
; CHECK-NEXT:     %[[C:.*]] = "mpir_expr.call"(%[[READ]], %[[AT]])
; CHECK-NEXT:     mpir_index.assume %[[C]]
; CHECK-NEXT:   }
; CHECK-NEXT:   mpir_index.variant {
; CHECK-NEXT:     mpir_index.has_instruction <udiv>
; CHECK-NEXT:     mpir_index.has_instruction <ashr>
; CHECK-NEXT:     mpir_index.has_edge <ashr> -> <udiv>
