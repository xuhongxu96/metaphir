// RUN: %metaphir-opt %s | FileCheck %s
// An enumeration out of range, which no verifier rejects, prints as invalid
// rather than crashing the printer (and does not parse back).

mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %k = "mpir.keyword"() <{keyword = 9999 : i32}> : () -> !mpir.sort<Value> loc("print-invalid.mlir":7:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword <invalid 9999> : <Value>
  %t = "mpir.type.prim"() <{kind = 9999 : i32}> : () -> !mpir.sort<Type> loc("print-invalid.mlir":9:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.prim <invalid 9999> : <Type>
  %a = "mpir.aggregate"() <{delimiter = 9999 : i32}> : () -> !mpir.sort<Value> loc("print-invalid.mlir":11:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate <invalid 9999>() : () -> !mpir.sort<Value>
  %s = "mpir.type.seq"(%t) <{kind = 9999 : i32, count = 4 : i64, operandSegmentSizes = array<i32: 1, 0>}> : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("print-invalid.mlir":13:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.seq <invalid 9999> 4 x %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %c = "mpir_expr.call"(%k, %k) <{op = 19 : i32, kind = 7 : i32, operandSegmentSizes = array<i32: 2, 0>}> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Integer> loc("print-invalid.mlir":15:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call <invalid 7> "udiv"(%[[KEYWORD_0]], %[[KEYWORD_0]]) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Integer>
} loc("print-invalid.mlir":17:1)
// CHECK:         }
