// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s
// The mpir_index dialect's operations print as they parse.

mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_edge <add> -> <mul>
    mpir_index.has_sibling <add>, <mul>
    mpir_index.has_global "llvm.ctlz"
    mpir_index.has_shape <add>, 1, 2, 32
    mpir_index.has_fact 0, <add>, 2, 129
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], []], value_operand = [true, false]>
    mpir_index.typing <add> <present = 1, absent = 0, commutative, treat_int_as_vec, operand_types = [[0, 0]], value_operand = [true]>
    %s = mpir_index.sites [[0, 1, 1], [1, 13, 3]] {var_name = "x"} : !mpir.sort<Operand>
    %t = mpir_index.type_var 0 : !mpir.sort<Type>
    %n = mpir_index.node 0 : !mpir.sort<Instruction>
    %u = mpir_index.unknown : !mpir.sort<Value>
    %r = mpir_expr.read %s : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %c = mpir_expr.call call "isZero"(%r) anchor %n : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %c : !mpir.sort<Boolean>
    %ru = mpir_expr.call call "isZero"(%u) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
    mpir_index.assume %ru : !mpir.sort<Boolean>
    %rt = mpir_expr.read %t : (!mpir.sort<Type>) -> !mpir.sort<Type>
  }
  mpir_index.variant <impossible> {
  }
  mpir_index.retrieve {
    %a = mpir_index.postings 0, 13 : i64
    %b = mpir_index.postings 1, 1234 : i64
    %c = mpir_index.postings 3, "llvm.ctlz"
    %i = mpir_index.intersect %a, %b
    %u = mpir_index.universe
    %j = mpir_index.union %i, %c, %u
    mpir_index.result %j
  }
}
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_edge <add> -> <mul>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_global "llvm.ctlz"
// CHECK:             mpir_index.has_shape <add>, 1, 2, 32
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], []], value_operand = [true, false]>
// CHECK:             mpir_index.typing <add> <present = 1, absent = 0, commutative, treat_int_as_vec, operand_types = {{\[\[}}0, 0]], value_operand = [true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1], [1, 13, 3]] {var_name = "x"} : <Operand>
// CHECK:             %[[TYPE_VAR_0:.*]] = mpir_index.type_var 0 : <Type>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[UNKNOWN_0:.*]] = mpir_index.unknown : <Value>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[UNKNOWN_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           }
// CHECK:           mpir_index.variant <impossible> {
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 13 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 1, 1234 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 3, "llvm.ctlz"
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]]
// CHECK:             %[[UNIVERSE_0:.*]] = mpir_index.universe
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[POSTINGS_2]], %[[UNIVERSE_0]]
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }
