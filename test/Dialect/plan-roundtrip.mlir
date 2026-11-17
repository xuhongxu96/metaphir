// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s
// The mpir_plan dialect's operations print as they parse.

mpir_plan.matcher <slot_names = ["x", "%r", "t", "blk"], slot_kinds = [variable, instruction, variable, variable], slot_sorts = [Value, Instruction, Operand, Boolean], slot_locs = [loc("plan-roundtrip.mlir":4:1), loc("plan-roundtrip.mlir":4:1), loc("plan-roundtrip.mlir":4:1), loc("plan-roundtrip.mlir":4:1)]> {
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, variable], slot_sorts = [Value, Instruction, Operand, Boolean], slot_names = ["x", "%r", "t", "blk"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
  %i = mpir_plan.foreach_instruction loc("plan-roundtrip.mlir":6:1)
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
  mpir_plan.check_opcode %i, <call> loc("plan-roundtrip.mlir":8:1)
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <call>
  mpir_plan.bind %i -> 1 loc("plan-roundtrip.mlir":10:1)
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 1
  %b = mpir_plan.get_parent_block %i loc("plan-roundtrip.mlir":12:1)
// CHECK:           %[[GET_PARENT_BLOCK_0:.*]] = mpir_plan.get_parent_block %[[FOREACH_INSTRUCTION_0]]
  mpir_plan.bind %b -> 3 <sort = 7> loc("plan-roundtrip.mlir":14:1)
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_0]] -> 3 <sort = 7>
  mpir_plan.check_operand_count %i, 2 loc("plan-roundtrip.mlir":16:1)
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
  mpir_plan.check_operand_count %i, 1 <at_least> loc("plan-roundtrip.mlir":18:1)
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1 <at_least>
  %o = mpir_plan.get_operand %i[0] loc("plan-roundtrip.mlir":20:1)
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
  %t = mpir_plan.get_type %o loc("plan-roundtrip.mlir":22:1)
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
  %rt = mpir_plan.get_type %i <operand_of> loc("plan-roundtrip.mlir":24:1)
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
  mpir_plan.check_type %t, [1, 32, 0] loc("plan-roundtrip.mlir":26:1)
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
  mpir_plan.check_type %rt, [1, 32, 0] <treat_int_as_vec> loc("plan-roundtrip.mlir":28:1)
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0] <treat_int_as_vec>
  mpir_plan.bind %t -> 2 loc("plan-roundtrip.mlir":30:1)
// CHECK:           mpir_plan.bind %[[GET_TYPE_0]] -> 2
  %rest = mpir_plan.get_operands_from %i[1:] loc("plan-roundtrip.mlir":32:1)
// CHECK:           %[[GET_OPERANDS_FROM_0:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_0]][1 :]
  %tys = mpir_plan.get_operands_from %i[1:] <types> loc("plan-roundtrip.mlir":34:1)
// CHECK:           %[[GET_OPERANDS_FROM_1:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_0]][1 :] <types>
  %flag = mpir_plan.get_flag %i[nsw] loc("plan-roundtrip.mlir":36:1)
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_0]][nsw]
  mpir_plan.check_flag %i[nuw] is false loc("plan-roundtrip.mlir":38:1)
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][nuw] is false
  %k = mpir_plan.get_keyed %i[predicate] loc("plan-roundtrip.mlir":40:1)
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate]
  %ks = mpir_plan.get_keyed %i[predicate] <swapped> loc("plan-roundtrip.mlir":42:1)
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate] <swapped>
  %e = mpir_plan.get_element %rest[0] loc("plan-roundtrip.mlir":44:1)
// CHECK:           %[[GET_ELEMENT_0:.*]] = mpir_plan.get_element %[[GET_OPERANDS_FROM_0]][0]
  mpir_plan.check_constant %o, 7 : ui3 loc("plan-roundtrip.mlir":46:1)
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 7 : ui3
  mpir_plan.check_constant %o, 0 : i32 <keyword> loc("plan-roundtrip.mlir":48:1)
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 0 : i32 <keyword>
  mpir_plan.check_constant %o, 1.0 : f64 <treat_int_as_vec> loc("plan-roundtrip.mlir":50:1)
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 1.000000e+00 : f64 <treat_int_as_vec>
  mpir_plan.check_aggregate %o, array, 2 loc("plan-roundtrip.mlir":52:1)
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_0]], array, 2
  mpir_plan.check_bound 0 is false loc("plan-roundtrip.mlir":54:1)
// CHECK:           mpir_plan.check_bound 0 is false
// CHECK:           %[[EITHER_0:.*]]:2 = mpir_plan.either {
  %r:2 = mpir_plan.either {
    mpir_plan.bind %o -> 0 <sort = 2> loc("plan-roundtrip.mlir":58:1)
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
    mpir_plan.bind_constant true -> 3 loc("plan-roundtrip.mlir":60:1)
// CHECK:             mpir_plan.bind_constant true -> 3
    mpir_plan.yield %o, %k : !mpir_plan.reg, !mpir_plan.reg loc("plan-roundtrip.mlir":62:1)
// CHECK:             mpir_plan.yield %[[GET_OPERAND_0]], %[[GET_KEYED_0]] : !mpir_plan.reg, !mpir_plan.reg
  }, {
// CHECK:           }, {
    mpir_plan.yield %e, %ks : !mpir_plan.reg, !mpir_plan.reg loc("plan-roundtrip.mlir":66:1)
// CHECK:             mpir_plan.yield %[[GET_ELEMENT_0]], %[[GET_KEYED_1]] : !mpir_plan.reg, !mpir_plan.reg
  } : !mpir_plan.reg, !mpir_plan.reg loc("plan-roundtrip.mlir":68:1)
// CHECK:           } : !mpir_plan.reg, !mpir_plan.reg
// CHECK:           mpir_plan.either {
  mpir_plan.either {
    mpir_plan.yield loc("plan-roundtrip.mlir":72:1)
// CHECK:             mpir_plan.yield
  }, {
// CHECK:           }, {
    mpir_plan.check_bound 0 is true loc("plan-roundtrip.mlir":76:1)
// CHECK:             mpir_plan.check_bound 0 is true
    mpir_plan.yield loc("plan-roundtrip.mlir":78:1)
// CHECK:             mpir_plan.yield
  } loc("plan-roundtrip.mlir":80:1)
// CHECK:           }
  %s = mpir_plan.slot 0 : !mpir.sort<Value> loc("plan-roundtrip.mlir":82:1)
// CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 0 : <Value>
  %z = mpir_expr.call call "isZero"(%s) : (!mpir.sort<Value>) -> !mpir.sort<Boolean> loc("plan-roundtrip.mlir":84:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[SLOT_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
  mpir_plan.check %z : !mpir.sort<Boolean> loc("plan-roundtrip.mlir":86:1)
// CHECK:           mpir_plan.check %[[CALL_0]] : <Boolean>
  mpir_plan.check %z <from_metaflag> : !mpir.sort<Boolean> loc("plan-roundtrip.mlir":88:1)
// CHECK:           mpir_plan.check %[[CALL_0]] <from_metaflag> : <Boolean>
  mpir_plan.emit loc("plan-roundtrip.mlir":90:1)
// CHECK:           mpir_plan.emit
} loc("plan-roundtrip.mlir":92:1)
// CHECK:         }
