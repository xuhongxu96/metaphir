// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s
// The mpir_index dialect's operations print as they parse.

mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-roundtrip.mlir":8:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_edge <add> -> <mul> loc("index-roundtrip.mlir":10:1)
// CHECK:             mpir_index.has_edge <add> -> <mul>
    mpir_index.has_sibling <add>, <mul> loc("index-roundtrip.mlir":12:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_global "llvm.ctlz" loc("index-roundtrip.mlir":14:1)
// CHECK:             mpir_index.has_global "llvm.ctlz"
    mpir_index.has_shape <add>, 1, 2, 32 loc("index-roundtrip.mlir":16:1)
// CHECK:             mpir_index.has_shape <add>, 1, 2, 32
    mpir_index.has_fact 0, <add>, 2, 129 loc("index-roundtrip.mlir":18:1)
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], []], value_operand = [true, false]> loc("index-roundtrip.mlir":20:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], []], value_operand = [true, false]>
    mpir_index.typing <add> <present = 1, absent = 0, commutative, treat_int_as_vec, operand_types = [[0, 0]], value_operand = [true]> loc("index-roundtrip.mlir":22:1)
// CHECK:             mpir_index.typing <add> <present = 1, absent = 0, commutative, treat_int_as_vec, operand_types = {{\[\[}}0, 0]], value_operand = [true]>
    %s = mpir_index.sites [[0, 1, 1], [1, 13, 3]] {var_name = "x"} : !mpir.sort<Operand> loc("index-roundtrip.mlir":24:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1], [1, 13, 3]] {var_name = "x"} : <Operand>
    %t = mpir_index.type_var 0 : !mpir.sort<Type> loc("index-roundtrip.mlir":26:1)
// CHECK:             %[[TYPE_VAR_0:.*]] = mpir_index.type_var 0 : <Type>
    %n = mpir_index.node 0 : !mpir.sort<Instruction> loc("index-roundtrip.mlir":28:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %u = mpir_index.unknown : !mpir.sort<Value> loc("index-roundtrip.mlir":30:1)
// CHECK:             %[[UNKNOWN_0:.*]] = mpir_index.unknown : <Value>
    %r = mpir_expr.read %s : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-roundtrip.mlir":32:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %c = mpir_expr.call call "isZero"(%r) anchor %n : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-roundtrip.mlir":34:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %c : !mpir.sort<Boolean> loc("index-roundtrip.mlir":36:1)
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
    %ru = mpir_expr.call call "isZero"(%u) : (!mpir.sort<Value>) -> !mpir.sort<Boolean> loc("index-roundtrip.mlir":38:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[UNKNOWN_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
    mpir_index.assume %ru : !mpir.sort<Boolean> loc("index-roundtrip.mlir":40:1)
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
    %rt = mpir_expr.read %t : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("index-roundtrip.mlir":42:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  } loc("index-roundtrip.mlir":44:1)
// CHECK:           }
  mpir_index.variant <impossible> {
// CHECK:           mpir_index.variant <impossible> {
  } loc("index-roundtrip.mlir":48:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %a = mpir_index.postings 0, 13 : i64 loc("index-roundtrip.mlir":52:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 13 : i64
    %b = mpir_index.postings 1, 1234 : i64 loc("index-roundtrip.mlir":54:1)
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 1, 1234 : i64
    %c = mpir_index.postings 3, "llvm.ctlz" loc("index-roundtrip.mlir":56:1)
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 3, "llvm.ctlz"
    %i = mpir_index.intersect %a, %b loc("index-roundtrip.mlir":58:1)
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]]
    %u = mpir_index.universe loc("index-roundtrip.mlir":60:1)
// CHECK:             %[[UNIVERSE_0:.*]] = mpir_index.universe
    %j = mpir_index.union %i, %c, %u loc("index-roundtrip.mlir":62:1)
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[POSTINGS_2]], %[[UNIVERSE_0]]
    mpir_index.result %j loc("index-roundtrip.mlir":64:1)
// CHECK:             mpir_index.result %[[UNION_0]]
  } loc("index-roundtrip.mlir":66:1)
// CHECK:           }
} loc("index-roundtrip.mlir":68:1)
// CHECK:         }
