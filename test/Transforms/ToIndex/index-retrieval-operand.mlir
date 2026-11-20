// RUN: %metaphir-opt --split-input-file --mpir-index-retrieval --mpir-index-retrieval %s | FileCheck %s
// An ':o' whose operand alternative has no instruction of its own: a variant
// on that path needs no list, so it reads the universe. Running the pass on a
// query that already has its lookup replaces the lookup.

// ':o' on a use with no other instruction.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-retrieval-operand.mlir":9:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-retrieval-operand.mlir":11:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value> loc("index-retrieval-operand.mlir":13:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.alt {
    mpir.yield %x : <Operand> loc("index-retrieval-operand.mlir":17:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("index-retrieval-operand.mlir":21:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("index-retrieval-operand.mlir":23:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } <or_self_of = "add", or_self_region = 0, result_name = "a"> : <Instruction> loc("index-retrieval-operand.mlir":25:1)
// CHECK:           } <result_name = "a", or_self_of = "add", or_self_region = 0> : <Instruction>
} loc("index-retrieval-operand.mlir":27:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
  } loc("index-retrieval-operand.mlir":33:1)
// CHECK:           }
// CHECK:           mpir_index.retrieve {
} loc("index-retrieval-operand.mlir":36:1)
// CHECK:             %[[UNIVERSE_0:.*]] = mpir_index.universe
// CHECK:             mpir_index.result %[[UNIVERSE_0]]
// CHECK:           }
// CHECK:         }
