// RUN: %metaphir-opt --split-input-file --mpir-index-retrieval --mpir-index-retrieval %s | FileCheck %s
// An ':o' whose operand alternative has no instruction of its own: a variant
// on that path needs no list, so it reads the universe. Running the pass on a
// query that already has its lookup replaces the lookup.

// ':o' on a use with no other instruction.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value>
  %2 = mpir.alt {
    mpir.yield %x : <Operand>
  }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
}
mpir_index.query {
  mpir_index.variant {
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[UNIVERSE_0:.*]] = mpir_index.universe
// CHECK:             mpir_index.result %[[UNIVERSE_0]]
// CHECK:           }
// CHECK:         }
