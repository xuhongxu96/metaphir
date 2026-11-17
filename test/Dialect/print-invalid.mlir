// RUN: %metaphir-opt %s | FileCheck %s
// An enumeration out of range, which no verifier rejects, prints as invalid
// rather than crashing the printer (and does not parse back).

mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %k = mpir.var "x" : !mpir.sort<Value> loc("print-invalid.mlir":7:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Value>
  %c = "mpir_expr.call"(%k, %k) <{op = 19 : i32, kind = 7 : i32, operandSegmentSizes = array<i32: 2, 0>}> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Integer> loc("print-invalid.mlir":9:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call <invalid 7> "udiv"(%[[VAR_0]], %[[VAR_0]]) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Integer>
} loc("print-invalid.mlir":11:1)
// CHECK:         }
