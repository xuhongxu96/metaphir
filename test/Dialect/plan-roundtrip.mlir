// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s
// The mpir_plan dialect's operations print as they parse.

mpir_plan.matcher <slot_names = ["x", "%r", "t", "blk"], slot_kinds = [0, 1, 0, 0], slot_sorts = [2, 3, 1, 7], slot_locs = [loc(unknown), loc(unknown), loc(unknown), loc(unknown)]> {
  %i = mpir_plan.foreach_instruction
  mpir_plan.check_opcode %i, <call>
  mpir_plan.bind %i -> 1
  %b = mpir_plan.get_parent_block %i
  mpir_plan.bind %b -> 3 <sort = 7>
  mpir_plan.check_operand_count %i, 2
  mpir_plan.check_operand_count %i, 1 <at_least>
  %o = mpir_plan.get_operand %i[0]
  %t = mpir_plan.get_type %o
  %rt = mpir_plan.get_type %i <operand_of>
  mpir_plan.check_type %t, [1, 32, 0]
  mpir_plan.check_type %rt, [1, 32, 0] <treat_int_as_vec>
  mpir_plan.bind %t -> 2
  %rest = mpir_plan.get_operands_from %i[1:]
  %tys = mpir_plan.get_operands_from %i[1:] <types>
  %flag = mpir_plan.get_flag %i[0]
  mpir_plan.check_flag %i[1] is false
  %k = mpir_plan.get_keyed %i[5]
  %ks = mpir_plan.get_keyed %i[5] <swapped>
  %e = mpir_plan.get_element %rest[0]
  mpir_plan.check_constant %o, 7 : ui3
  mpir_plan.check_constant %o, 0 : i32 <keyword>
  mpir_plan.check_constant %o, 1.0 : f64 <treat_int_as_vec>
  mpir_plan.check_aggregate %o, 0, 2
  mpir_plan.check_bound 0 is false
  %r:2 = mpir_plan.either {
    mpir_plan.bind %o -> 0 <sort = 2>
    mpir_plan.bind_constant true -> 3
    mpir_plan.yield %o, %k : !mpir_plan.reg, !mpir_plan.reg
  }, {
    mpir_plan.yield %e, %ks : !mpir_plan.reg, !mpir_plan.reg
  } : !mpir_plan.reg, !mpir_plan.reg
  mpir_plan.either {
    mpir_plan.yield
  }, {
    mpir_plan.check_bound 0 is true
    mpir_plan.yield
  }
  %s = mpir_plan.slot 0 : !mpir.sort<Value>
  %z = mpir_expr.call call "isZero"(%s) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
  mpir_plan.check %z : !mpir.sort<Boolean>
  mpir_plan.check %z <from_metaflag> : !mpir.sort<Boolean>
  mpir_plan.emit
}
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%r", "t", "blk"], slot_kinds = [0, 1, 0, 0], slot_sorts = [2, 3, 1, 7], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 1
// CHECK:           %[[GET_PARENT_BLOCK_0:.*]] = mpir_plan.get_parent_block %[[FOREACH_INSTRUCTION_0]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_0]] -> 3 <sort = 7>
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1 <at_least>
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0] <treat_int_as_vec>
// CHECK:           mpir_plan.bind %[[GET_TYPE_0]] -> 2
// CHECK:           %[[GET_OPERANDS_FROM_0:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_0]][1 :]
// CHECK:           %[[GET_OPERANDS_FROM_1:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_0]][1 :] <types>
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][1] is false
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5]
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5] <swapped>
// CHECK:           %[[GET_ELEMENT_0:.*]] = mpir_plan.get_element %[[GET_OPERANDS_FROM_0]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 7 : ui3
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 0 : i32 <keyword>
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], 1.000000e+00 : f64 <treat_int_as_vec>
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_0]], 0, 2
// CHECK:           mpir_plan.check_bound 0 is false
// CHECK:           %[[EITHER_0:.*]]:2 = mpir_plan.either {
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
// CHECK:             mpir_plan.bind_constant true -> 3
// CHECK:             mpir_plan.yield %[[GET_OPERAND_0]], %[[GET_KEYED_0]] : !mpir_plan.reg, !mpir_plan.reg
// CHECK:           }, {
// CHECK:             mpir_plan.yield %[[GET_ELEMENT_0]], %[[GET_KEYED_1]] : !mpir_plan.reg, !mpir_plan.reg
// CHECK:           } : !mpir_plan.reg, !mpir_plan.reg
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_bound 0 is true
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 0 : <Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[SLOT_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_0]] : <Boolean>
// CHECK:           mpir_plan.check %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           mpir_plan.emit
// CHECK:         }
