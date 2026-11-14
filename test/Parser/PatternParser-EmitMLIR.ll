; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; The parser of the mpir dialect: definitions become symbols of the module,
; the pattern an mpir.pattern, constraints mpir_expr operations.
; RUN: %metaphir-parse --engine=mlir --emit=mlir %s | FileCheck %s

constraint small(?v) {
  ult(?v, 8)
}
%d = udiv i?n ?x, 2
%s = add:c i?n %d, ?y:zero
;; small(?y)

; Each 'i?n' is a type pattern of its own, of the one width variable.
; CHECK: mpir.matcher @addLike <commutative,
; CHECK: mpir.constraint_def @small <param_names = ["v"]> {
; CHECK: mpir.pattern {
; CHECK:   %n = mpir.var "n" : <Nat>
; CHECK:   %[[TY:.*]] = "mpir.type.meta_int"(%n)
; CHECK:   %x = mpir.var "x" : <Operand>
; CHECK:   %i_d = "mpir.inst"(%[[TY]], %x, %[[TY]], %{{.*}}) <{{{.*}}opcode = #mpir.opcode<udiv>
; CHECK:   %[[TY2:.*]] = "mpir.type.meta_int"(%n)
; CHECK:   %i_s = "mpir.inst"(%[[TY2]], %i_d, %[[TY2]], %y) <{{{.*}}metaflags = [#mpir.metaflag<"c"{{.*}}opcode = #mpir.opcode<add>, operandSegmentSizes{{.*}}operand_metaflags = {{\[\[\], \[}}#mpir.metaflag<"zero"
; CHECK:   %[[READ:.*]] = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:   %[[C:.*]] = mpir_expr.apply @small(%[[READ]])
; CHECK:   mpir.require %[[C]] : <Boolean>
