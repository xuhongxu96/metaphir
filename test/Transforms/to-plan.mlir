// RUN: %metaphir-opt --split-input-file --mpir-to-plan %s | FileCheck %s
// mpir-to-plan compiles a lowered pattern into an mpir_plan.matcher: from each
// root, over every instruction of the function, what to check and bind of it
// and of its operands, in order, then the pattern's constraints.

// Binary instruction matchers: each opcode, with its flags required ('nsw'),
// absent ('!nuw') and captured ('exact:?e'), and the instruction captured
// ('add:?sum').
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %nuw = mpir.var "nuw" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <sub> flags(%nuw) (%1, %i_a, %1, %2) <result_name = "b", flags = [1], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %prod = mpir.var "prod" : <Instruction>
  %3 = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <mul> capture %prod (%3, %i_b, %3, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.int 2 : ui2 : <Value>
  %i_d = mpir.inst <udiv> (%4, %i_c, %4, %5) <result_name = "d", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %e = mpir.var "e" : <Boolean>
  %6 = mpir.type.int 32 : <Type>
  %7 = mpir.int -3 : si3 : <Value>
  %i_e = mpir.inst <sdiv> flags(%e) (%6, %i_d, %6, %7) <result_name = "e", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type>
  %i_f = mpir.inst <urem> (%8, %i_e, %8, %y) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type>
  %i_g = mpir.inst <srem> (%9, %i_f, %9, %y) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type>
  %11 = mpir.int 1 : ui1 : <Value>
  %i_h = mpir.inst <shl> (%10, %i_g, %10, %11) <result_name = "h", flags = [0, 1], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.int 32 : <Type>
  %i_i = mpir.inst <lshr> (%12, %i_h, %12, %y) <result_name = "i", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type>
  %i_j = mpir.inst <ashr> (%13, %i_i, %13, %y) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type>
  %15 = mpir.int 255 : ui8 : <Value>
  %i_k = mpir.inst <and> (%14, %i_j, %14, %15) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %dj = mpir.var "dj" : <Boolean>
  %16 = mpir.type.int 32 : <Type>
  %i_l = mpir.inst <or> flags(%dj) (%16, %i_k, %16, %y) <result_name = "l", flags = [3], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type>
  %18 = mpir.int -1 : si1 : <Value>
  %i_m = mpir.inst <xor> (%17, %i_l, %17, %18) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.prim float : <Type>
  %fx = mpir.var "fx" : <Operand>
  %20 = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_n = mpir.inst <fadd> (%19, %fx, %19, %20) <result_name = "n", flags = [11, 12], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %21 = mpir.type.prim float : <Type>
  %i_o = mpir.inst <fsub> (%21, %i_n, %21, %fx) <result_name = "o", flags = [10], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %22 = mpir.type.prim float : <Type>
  %i_p = mpir.inst <fmul> (%22, %i_o, %22, %i_o) <result_name = "p", flags = [13, 14, 15, 16, 17], flag_modes = [0, 0, 0, 0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %23 = mpir.type.prim float : <Type>
  %24 = mpir.float 2.500000e+00 : f64 -> <Value>
  %i_q = mpir.inst <fdiv> (%23, %i_p, %23, %24) <result_name = "q", flags = [11], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %25 = mpir.type.prim float : <Type>
  %i_r = mpir.inst <frem> (%25, %i_q, %25, %fx) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim float : <Type>
  %i_s = mpir.inst <fneg> (%26, %i_r) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> flags(%[[VAR_2]]) (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [1], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_3:.*]] = mpir.var "prod" : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> capture %[[VAR_3]] (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[INST_3:.*]] = mpir.inst <udiv> (%[[TYPE_3]], %[[INST_2]], %[[TYPE_3]], %[[INT_1]]) <result_name = "d", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "e" : <Boolean>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_2:.*]] = mpir.int -3 : si3 : <Value>
// CHECK:           %[[INST_4:.*]] = mpir.inst <sdiv> flags(%[[VAR_4]]) (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_2]]) <result_name = "e", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_5:.*]] = mpir.inst <urem> (%[[TYPE_5]], %[[INST_4]], %[[TYPE_5]], %[[VAR_1]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_6:.*]] = mpir.inst <srem> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[VAR_1]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_7:.*]] = mpir.inst <shl> (%[[TYPE_7]], %[[INST_6]], %[[TYPE_7]], %[[INT_3]]) <result_name = "h", flags = [0, 1], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_8:.*]] = mpir.inst <lshr> (%[[TYPE_8]], %[[INST_7]], %[[TYPE_8]], %[[VAR_1]]) <result_name = "i", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_9:.*]] = mpir.inst <ashr> (%[[TYPE_9]], %[[INST_8]], %[[TYPE_9]], %[[VAR_1]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_4:.*]] = mpir.int 255 : ui8 : <Value>
// CHECK:           %[[INST_10:.*]] = mpir.inst <and> (%[[TYPE_10]], %[[INST_9]], %[[TYPE_10]], %[[INT_4]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_5:.*]] = mpir.var "dj" : <Boolean>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_11:.*]] = mpir.inst <or> flags(%[[VAR_5]]) (%[[TYPE_11]], %[[INST_10]], %[[TYPE_11]], %[[VAR_1]]) <result_name = "l", flags = [3], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_5:.*]] = mpir.int -1 : si1 : <Value>
// CHECK:           %[[INST_12:.*]] = mpir.inst <xor> (%[[TYPE_12]], %[[INST_11]], %[[TYPE_12]], %[[INT_5]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "fx" : <Operand>
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
// CHECK:           %[[INST_13:.*]] = mpir.inst <fadd> (%[[TYPE_13]], %[[VAR_6]], %[[TYPE_13]], %[[FLOAT_0]]) <result_name = "n", flags = [11, 12], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[INST_14:.*]] = mpir.inst <fsub> (%[[TYPE_14]], %[[INST_13]], %[[TYPE_14]], %[[VAR_6]]) <result_name = "o", flags = [10], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[INST_15:.*]] = mpir.inst <fmul> (%[[TYPE_15]], %[[INST_14]], %[[TYPE_15]], %[[INST_14]]) <result_name = "p", flags = [13, 14, 15, 16, 17], flag_modes = [0, 0, 0, 0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 2.500000e+00 : f64 -> <Value>
// CHECK:           %[[INST_16:.*]] = mpir.inst <fdiv> (%[[TYPE_16]], %[[INST_15]], %[[TYPE_16]], %[[FLOAT_1]]) <result_name = "q", flags = [11], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[INST_17:.*]] = mpir.inst <frem> (%[[TYPE_17]], %[[INST_16]], %[[TYPE_17]], %[[VAR_6]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[INST_18:.*]] = mpir.inst <fneg> (%[[TYPE_18]], %[[INST_17]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "y", "%a", "nuw", "%b", "prod", "%c", "%d", "e", "%e", "%f", "%g", "%h", "%i", "%j", "%k", "dj", "%l", "%m", "fx", "%n", "%o", "%p", "%q", "%r", "%s"], slot_kinds = [0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1], slot_sorts = [2, 2, 3, 7, 3, 3, 3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 7, 3, 3, 2, 3, 3, 3, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <xor>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 18
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <or>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 17
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[GET_OPERAND_0]][3]
// CHECK:           mpir_plan.bind %[[GET_FLAG_0]] -> 16
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <and>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 15
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 2
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <ashr>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 14
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_3]], <lshr>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 13
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_3]][2] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_3]], 2
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_4]], <shl>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 12
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_4]][0] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_4]][1] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_4]], 2
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_5]], <srem>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 11
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_5]], 2
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][0]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_6]], <urem>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 10
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_6]], 2
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_7]], <sdiv>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 9
// CHECK:           %[[GET_FLAG_1:.*]] = mpir_plan.get_flag %[[GET_OPERAND_7]][2]
// CHECK:           mpir_plan.bind %[[GET_FLAG_1]] -> 8
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_7]], 2
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_8]], <udiv>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_8]] -> 7
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_8]][2] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_8]], 2
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_8]][0]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_9]], <mul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 6
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 5
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_9]], 2
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_9]][0]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_10]], <sub>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 4
// CHECK:           %[[GET_FLAG_2:.*]] = mpir_plan.get_flag %[[GET_OPERAND_10]][1]
// CHECK:           mpir_plan.bind %[[GET_FLAG_2]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_10]], 2
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_11]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 2
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][0] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][1] is false
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_11]], 2
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][0]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_12]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_13]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][1]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_14]], 1 : ui1
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[GET_OPERAND_9]][1]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_15]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[GET_OPERAND_8]][1]
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_16]], 2 : ui2
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][1]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_17]], -3 : si3
// CHECK:           %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][1]
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_18]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][1]
// CHECK:           %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_19]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_19]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_20:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][1]
// CHECK:           %[[GET_TYPE_20:.*]] = mpir_plan.get_type %[[GET_OPERAND_20]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_20]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_20]], 1 : ui1
// CHECK:           %[[GET_OPERAND_21:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][1]
// CHECK:           %[[GET_TYPE_21:.*]] = mpir_plan.get_type %[[GET_OPERAND_21]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_21]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_21]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_22:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:           %[[GET_TYPE_22:.*]] = mpir_plan.get_type %[[GET_OPERAND_22]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_22]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_22]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_23:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:           %[[GET_TYPE_23:.*]] = mpir_plan.get_type %[[GET_OPERAND_23]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_23]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_23]], 255 : ui8
// CHECK:           %[[GET_OPERAND_24:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_24:.*]] = mpir_plan.get_type %[[GET_OPERAND_24]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_24]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_24]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_25:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_25:.*]] = mpir_plan.get_type %[[GET_OPERAND_25]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_25]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_25]], -1 : si1
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <fneg>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 25
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 1
// CHECK:           %[[GET_OPERAND_26:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_26:.*]] = mpir_plan.get_type %[[GET_OPERAND_26]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_26]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_26]], <frem>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_26]] -> 24
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_26]], 2
// CHECK:           %[[GET_OPERAND_27:.*]] = mpir_plan.get_operand %[[GET_OPERAND_26]][0]
// CHECK:           %[[GET_TYPE_27:.*]] = mpir_plan.get_type %[[GET_OPERAND_27]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_27]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_27]], <fdiv>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_27]] -> 23
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_27]][11] is false
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_27]], 2
// CHECK:           %[[GET_OPERAND_28:.*]] = mpir_plan.get_operand %[[GET_OPERAND_27]][0]
// CHECK:           %[[GET_TYPE_28:.*]] = mpir_plan.get_type %[[GET_OPERAND_28]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_28]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_28]], <fmul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_28]] -> 22
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][13] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][14] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][15] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][16] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][17] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_28]], 2
// CHECK:           %[[GET_OPERAND_29:.*]] = mpir_plan.get_operand %[[GET_OPERAND_28]][0]
// CHECK:           %[[GET_TYPE_29:.*]] = mpir_plan.get_type %[[GET_OPERAND_29]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_29]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_29]], <fsub>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_29]] -> 21
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_29]][10] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_29]], 2
// CHECK:           %[[GET_OPERAND_30:.*]] = mpir_plan.get_operand %[[GET_OPERAND_29]][0]
// CHECK:           %[[GET_TYPE_30:.*]] = mpir_plan.get_type %[[GET_OPERAND_30]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_30]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_30]], <fadd>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_30]] -> 20
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_30]][11] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_30]][12] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_30]], 2
// CHECK:           %[[GET_OPERAND_31:.*]] = mpir_plan.get_operand %[[GET_OPERAND_30]][0]
// CHECK:           %[[GET_TYPE_31:.*]] = mpir_plan.get_type %[[GET_OPERAND_31]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_31]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_31]] -> 19 <sort = 2>
// CHECK:           %[[GET_OPERAND_32:.*]] = mpir_plan.get_operand %[[GET_OPERAND_30]][1]
// CHECK:           %[[GET_TYPE_32:.*]] = mpir_plan.get_type %[[GET_OPERAND_32]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_32]], [0, 2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_32]], 1.000000e+00 : f64
// CHECK:           %[[GET_OPERAND_33:.*]] = mpir_plan.get_operand %[[GET_OPERAND_29]][1]
// CHECK:           %[[GET_TYPE_33:.*]] = mpir_plan.get_type %[[GET_OPERAND_33]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_33]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_33]] -> 19 <sort = 2>
// CHECK:           %[[GET_OPERAND_34:.*]] = mpir_plan.get_operand %[[GET_OPERAND_28]][1]
// CHECK:           %[[GET_TYPE_34:.*]] = mpir_plan.get_type %[[GET_OPERAND_34]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_34]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_34]] -> 21
// CHECK:           %[[GET_OPERAND_35:.*]] = mpir_plan.get_operand %[[GET_OPERAND_27]][1]
// CHECK:           %[[GET_TYPE_35:.*]] = mpir_plan.get_type %[[GET_OPERAND_35]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_35]], [0, 2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_35]], 2.500000e+00 : f64
// CHECK:           %[[GET_OPERAND_36:.*]] = mpir_plan.get_operand %[[GET_OPERAND_26]][1]
// CHECK:           %[[GET_TYPE_36:.*]] = mpir_plan.get_type %[[GET_OPERAND_36]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_36]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_36]] -> 19 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Calls: of a named function, of an intrinsic by name or by a variable
// part of its name, of a function variable with its type, with the rest
// of the arguments captured, with a label argument, and void calls.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %1 = mpir.global "callee" : <Value>
  %2 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %3 = mpir.type.int 8 : <Type>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <call> (%0, %1, %2, %x, %3, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.global "llvm.umax.i32" : <Value>
  %6 = mpir.type.int 32 : <Type>
  %7 = mpir.type.int 32 : <Type>
  %8 = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <call> (%4, %5, %6, %i_a, %7, %8) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat>
  %9 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %id = mpir.var "id" : <IntrinsicID>
  %10 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand>
  %11 = mpir.type.int 1 : <Type>
  %12 = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%9, %id, %10, %v, %11, %12) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type>
  %14 = mpir.type.int 32 : <Type>
  %15 = mpir.type.func %13(%14) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %f = mpir.var "f" : <Function>
  %16 = mpir.type.int 32 : <Type>
  %i_d = mpir.inst <call> (%15, %f, %16, %i_a) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %ret = mpir.var "ret" : <Type>
  %id2 = mpir.var "id2" : <IntrinsicID>
  %types = mpir.var "types" : <TypeArray>
  %values = mpir.var "values" : <ValueArray>
  %i_e = mpir.inst <call> (%ret, %id2, %types, %values) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type>
  %18 = mpir.global "first" : <Value>
  %19 = mpir.type.int 32 : <Type>
  %rest_types = mpir.var "rest_types" : <TypeArray>
  %rest_values = mpir.var "rest_values" : <ValueArray>
  %i_f = mpir.inst <call> (%17, %18, %19, %i_a, %rest_types, %rest_values) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %20 = mpir.type.prim void : <Type>
  %21 = mpir.global "take" : <Value>
  %22 = mpir.type.prim label : <Type>
  %target = mpir.var "target" : <BasicBlock>
  %i_lb = mpir.inst <call> (%20, %21, %22, %target) <result_name = "lb", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %23 = mpir.type.int 32 : <Type>
  %24 = mpir.global "0" : <Value>
  %25 = mpir.type.int 32 : <Type>
  %i_num = mpir.inst <call> (%23, %24, %25, %i_a) <result_name = "num", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim void : <Type>
  %27 = mpir.global "sink" : <Value>
  %28 = mpir.type.int 32 : <Type>
  %29 = mpir.inst <call> (%26, %27, %28, %i_f) <flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "callee" : <Value>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_1:.*]] = mpir.global "llvm.umax.i32" : <Value>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_3]], %[[GLOBAL_1]], %[[TYPE_4]], %[[INST_0]], %[[TYPE_5]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "id" : <IntrinsicID>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_6]], %[[VAR_3]], %[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[INT_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.func %[[TYPE_9]](%[[TYPE_10]]) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "f" : <Function>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <call> (%[[TYPE_11]], %[[VAR_5]], %[[TYPE_12]], %[[INST_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_6:.*]] = mpir.var "ret" : <Type>
// CHECK:           %[[VAR_7:.*]] = mpir.var "id2" : <IntrinsicID>
// CHECK:           %[[VAR_8:.*]] = mpir.var "types" : <TypeArray>
// CHECK:           %[[VAR_9:.*]] = mpir.var "values" : <ValueArray>
// CHECK:           %[[INST_4:.*]] = mpir.inst <call> (%[[VAR_6]], %[[VAR_7]], %[[VAR_8]], %[[VAR_9]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_2:.*]] = mpir.global "first" : <Value>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_10:.*]] = mpir.var "rest_types" : <TypeArray>
// CHECK:           %[[VAR_11:.*]] = mpir.var "rest_values" : <ValueArray>
// CHECK:           %[[INST_5:.*]] = mpir.inst <call> (%[[TYPE_13]], %[[GLOBAL_2]], %[[TYPE_14]], %[[INST_0]], %[[VAR_10]], %[[VAR_11]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim void : <Type>
// CHECK:           %[[GLOBAL_3:.*]] = mpir.global "take" : <Value>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim label : <Type>
// CHECK:           %[[VAR_12:.*]] = mpir.var "target" : <BasicBlock>
// CHECK:           %[[INST_6:.*]] = mpir.inst <call> (%[[TYPE_15]], %[[GLOBAL_3]], %[[TYPE_16]], %[[VAR_12]]) <result_name = "lb", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_4:.*]] = mpir.global "0" : <Value>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_7:.*]] = mpir.inst <call> (%[[TYPE_17]], %[[GLOBAL_4]], %[[TYPE_18]], %[[INST_0]]) <result_name = "num", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.prim void : <Type>
// CHECK:           %[[GLOBAL_5:.*]] = mpir.global "sink" : <Value>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_8:.*]] = mpir.inst <call> (%[[TYPE_19]], %[[GLOBAL_5]], %[[TYPE_20]], %[[INST_5]]) <flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "y", "%a", "%b", "n", "id", "v", "%c", "f", "%d", "ret", "id2", "types", "values", "%e", "rest_types", "rest_values", "%f", "target", "%lb", "%num", "call"], slot_kinds = [0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1], slot_sorts = [2, 2, 3, 3, 6, 11, 2, 3, 4, 3, 12, 11, 14, 15, 3, 14, 15, 3, 5, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 3
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_0]], "llvm.umax.i32"
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <call>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 2
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 3
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_2]], "callee"
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][2]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 8, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][2]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_5]], 1 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 7
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [2, 4, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 3
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 5 <sort = 11>
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [2, 4, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 6 <sort = 2>
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][2]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 1, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_8]], 0 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 9
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_2]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [7, 1, [1, 32, 0], [1, 32, 0]]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 2
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 8 <sort = 4>
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][1]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 2
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 14
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_3]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [3, 10]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 1 <at_least>
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 11 <sort = 11>
// CHECK:           %[[GET_OPERANDS_FROM_0:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_3]][1 :]
// CHECK:           mpir_plan.bind %[[GET_OPERANDS_FROM_0]] -> 13
// CHECK:           %[[GET_OPERANDS_FROM_1:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_3]][1 :] <types>
// CHECK:           mpir_plan.bind %[[GET_OPERANDS_FROM_1]] -> 12
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 19
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_4]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [0, 5]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 2
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_12]], "take"
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [0, 6]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_13]] -> 18 <sort = 5>
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 20
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_5]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 2
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_14]], "0"
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][1]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_15]] -> 2
// CHECK:           %[[FOREACH_INSTRUCTION_6:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_6]], <call>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_6]] -> 21
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_6]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [0, 5]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_6]], 2
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_16]], "sink"
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][1]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_17]], <call>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_17]] -> 17
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_17]], 2 <at_least>
// CHECK:           %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[GET_OPERAND_17]][0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_18]], "first"
// CHECK:           %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[GET_OPERAND_17]][1]
// CHECK:           %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_19]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_19]] -> 2
// CHECK:           %[[GET_OPERANDS_FROM_2:.*]] = mpir_plan.get_operands_from %[[GET_OPERAND_17]][2 :]
// CHECK:           mpir_plan.bind %[[GET_OPERANDS_FROM_2]] -> 16
// CHECK:           %[[GET_OPERANDS_FROM_3:.*]] = mpir_plan.get_operands_from %[[GET_OPERAND_17]][2 :] <types>
// CHECK:           mpir_plan.bind %[[GET_OPERANDS_FROM_3]] -> 15
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Casts: the source operand and the destination type, with 'nneg'.
mpir.pattern {
  %0 = mpir.type.int 64 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type>
  %i_t = mpir.inst <trunc> (%0, %x, %1) <result_name = "t", flags = [1], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.type.int 64 : <Type>
  %i_z = mpir.inst <zext> (%2, %i_t, %3) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %wide = mpir.var "wide" : <Nat>
  %5 = mpir.type.meta_int %wide : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %i_s = mpir.inst <sext> (%4, %i_t, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand>
  %7 = mpir.type.prim float : <Type>
  %i_ft = mpir.inst <fptrunc> (%6, %d, %7) <result_name = "ft", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim float : <Type>
  %9 = mpir.type.prim double : <Type>
  %i_fe = mpir.inst <fpext> (%8, %i_ft, %9) <result_name = "fe", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type>
  %11 = mpir.type.int 32 : <Type>
  %i_fu = mpir.inst <fptoui> (%10, %i_fe, %11) <result_name = "fu", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type>
  %13 = mpir.type.int 32 : <Type>
  %i_fs = mpir.inst <fptosi> (%12, %i_fe, %13) <result_name = "fs", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type>
  %15 = mpir.type.prim half : <Type>
  %i_uf = mpir.inst <uitofp> (%14, %i_fu, %15) <result_name = "uf", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %16 = mpir.type.int 32 : <Type>
  %17 = mpir.type.prim bfloat : <Type>
  %i_sf = mpir.inst <sitofp> (%16, %i_fs, %17) <result_name = "sf", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %18 = mpir.type.ptr : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand>
  %19 = mpir.type.int 64 : <Type>
  %i_pi = mpir.inst <ptrtoint> (%18, %p, %19) <result_name = "pi", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %20 = mpir.type.ptr : () -> !mpir.sort<Type>
  %21 = mpir.type.int 64 : <Type>
  %i_pa = mpir.inst <ptrtoaddr> (%20, %p, %21) <result_name = "pa", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %22 = mpir.type.int 64 : <Type>
  %23 = mpir.type.ptr : () -> !mpir.sort<Type>
  %i_ip = mpir.inst <inttoptr> (%22, %i_pi, %23) <result_name = "ip", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type>
  %25 = mpir.type.seq vector 2 x %24 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand>
  %26 = mpir.type.int 64 : <Type>
  %i_bc = mpir.inst <bitcast> (%25, %v, %26) <result_name = "bc", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %27 = mpir.type.int 32 : <Type>
  %i_fr = mpir.inst <freeze> (%27, %i_t) <result_name = "fr", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "t", flags = [1], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_3]]) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "wide" : <Nat>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[INST_2:.*]] = mpir.inst <sext> (%[[TYPE_4]], %[[INST_0]], %[[TYPE_5]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "d" : <Operand>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <fptrunc> (%[[TYPE_6]], %[[VAR_2]], %[[TYPE_7]]) <result_name = "ft", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[INST_4:.*]] = mpir.inst <fpext> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]]) <result_name = "fe", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_5:.*]] = mpir.inst <fptoui> (%[[TYPE_10]], %[[INST_4]], %[[TYPE_11]]) <result_name = "fu", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_6:.*]] = mpir.inst <fptosi> (%[[TYPE_12]], %[[INST_4]], %[[TYPE_13]]) <result_name = "fs", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim half : <Type>
// CHECK:           %[[INST_7:.*]] = mpir.inst <uitofp> (%[[TYPE_14]], %[[INST_5]], %[[TYPE_15]]) <result_name = "uf", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim bfloat : <Type>
// CHECK:           %[[INST_8:.*]] = mpir.inst <sitofp> (%[[TYPE_16]], %[[INST_6]], %[[TYPE_17]]) <result_name = "sf", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INST_9:.*]] = mpir.inst <ptrtoint> (%[[TYPE_18]], %[[VAR_3]], %[[TYPE_19]]) <result_name = "pi", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INST_10:.*]] = mpir.inst <ptrtoaddr> (%[[TYPE_20]], %[[VAR_3]], %[[TYPE_21]]) <result_name = "pa", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[INST_11:.*]] = mpir.inst <inttoptr> (%[[TYPE_22]], %[[INST_9]], %[[TYPE_23]]) <result_name = "ip", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_25:.*]] = mpir.type.seq vector 2 x %[[TYPE_24]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[TYPE_26:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INST_12:.*]] = mpir.inst <bitcast> (%[[TYPE_25]], %[[VAR_4]], %[[TYPE_26]]) <result_name = "bc", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[INST_0]]) <result_name = "fr", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%t", "%z", "wide", "%s", "d", "%ft", "%fe", "%fu", "%fs", "%uf", "%sf", "p", "%pi", "%pa", "%ip", "v", "%bc", "%fr"], slot_kinds = [0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1], slot_sorts = [2, 3, 3, 6, 3, 2, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <zext>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 64, 0]
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][8] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <trunc>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_0]][1] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 1
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 64, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <sext>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 4
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [2, 3, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 1
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 1
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <uitofp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 10
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_2]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [0, 0]
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_2]][8] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 1
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_3]], <fptoui>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 8
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_3]], 1
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][0]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [0, 3]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_4]], <fpext>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 7
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [0, 3]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_4]], 1
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_5]], <fptrunc>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 6
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [0, 2]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_5]], 1
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][0]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 5 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <sitofp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 11
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_3]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [0, 1]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 1
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_7]], <fptosi>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 9
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_7]], 1
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_8]] -> 7
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <ptrtoaddr>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 14
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_4]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [1, 64, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_19]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 12 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <inttoptr>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 15
// CHECK:           %[[GET_TYPE_20:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_5]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_20]], [4, -1, 1]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 1
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           %[[GET_TYPE_21:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_21]], [1, 64, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_10]], <ptrtoint>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 13
// CHECK:           %[[GET_TYPE_22:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_22]], [1, 64, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_10]], 1
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][0]
// CHECK:           %[[GET_TYPE_23:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_23]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 12 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_6:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_6]], <bitcast>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_6]] -> 17
// CHECK:           %[[GET_TYPE_24:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_6]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_24]], [1, 64, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_6]], 1
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][0]
// CHECK:           %[[GET_TYPE_25:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_25]], [5, 1, 2, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_12]] -> 16 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_7:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_7]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_7]] -> 18
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_7]], 1
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_7]][0]
// CHECK:           %[[GET_TYPE_26:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_26]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_13]] -> 1
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Comparisons with a written or a variable predicate, 'samesign', and
// selects with fast-math flags.
mpir.pattern {
  %0 = mpir.keyword eq : <Value>
  %1 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %2 = mpir.int 0 : ui1 : <Value>
  %i_c1 = mpir.inst <icmp> (%0, %1, %x, %1, %2) <result_name = "c1", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.keyword ult : <Value>
  %4 = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand>
  %i_c2 = mpir.inst <icmp> (%3, %4, %x, %4, %y) <result_name = "c2", flags = [9], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %pred = mpir.var "pred" : <CmpPredicate>
  %5 = mpir.type.int 32 : <Type>
  %i_c3 = mpir.inst <icmp> (%pred, %5, %x, %5, %y) <result_name = "c3", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.keyword olt : <Value>
  %7 = mpir.type.prim float : <Type>
  %f = mpir.var "f" : <Operand>
  %8 = mpir.float 0.000000e+00 : f64 -> <Value>
  %i_c4 = mpir.inst <fcmp> (%6, %7, %f, %7, %8) <result_name = "c4", flags = [11], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %fpred = mpir.var "fpred" : <CmpPredicate>
  %9 = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand>
  %e = mpir.var "e" : <Operand>
  %i_c5 = mpir.inst <fcmp> (%fpred, %9, %d, %9, %e) <result_name = "c5", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 1 : <Type>
  %11 = mpir.type.int 32 : <Type>
  %12 = mpir.type.int 32 : <Type>
  %i_s1 = mpir.inst <select> (%10, %i_c1, %11, %x, %12, %y) <result_name = "s1", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 1 : <Type>
  %14 = mpir.type.prim float : <Type>
  %15 = mpir.type.prim float : <Type>
  %16 = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_s2 = mpir.inst <select> (%13, %i_c4, %14, %f, %15, %16) <result_name = "s2", flags = [11], flag_modes = [0], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 1 : <Type>
  %18 = mpir.type.seq vector 2 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %mask = mpir.var "mask" : <Operand>
  %19 = mpir.type.int 32 : <Type>
  %20 = mpir.type.seq vector 2 x %19 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand>
  %21 = mpir.type.int 32 : <Type>
  %22 = mpir.type.seq vector 2 x %21 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %23 = mpir.keyword zeroinitializer : <Value>
  %i_s3 = mpir.inst <select> (%18, %mask, %20, %v, %22, %23) <result_name = "s3", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword eq : <Value>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "c1", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword ult : <Value>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "c2", flags = [9], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "pred" : <CmpPredicate>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_2]], %[[TYPE_2]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c3", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword olt : <Value>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "f" : <Operand>
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 0.000000e+00 : f64 -> <Value>
// CHECK:           %[[INST_3:.*]] = mpir.inst <fcmp> (%[[KEYWORD_2]], %[[TYPE_3]], %[[VAR_3]], %[[TYPE_3]], %[[FLOAT_0]]) <result_name = "c4", flags = [11], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "fpred" : <CmpPredicate>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "d" : <Operand>
// CHECK:           %[[VAR_6:.*]] = mpir.var "e" : <Operand>
// CHECK:           %[[INST_4:.*]] = mpir.inst <fcmp> (%[[VAR_4]], %[[TYPE_4]], %[[VAR_5]], %[[TYPE_4]], %[[VAR_6]]) <result_name = "c5", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[VAR_0]], %[[TYPE_7]], %[[VAR_1]]) <result_name = "s1", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
// CHECK:           %[[INST_6:.*]] = mpir.inst <select> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]], %[[VAR_3]], %[[TYPE_10]], %[[FLOAT_1]]) <result_name = "s2", flags = [11], flag_modes = [0], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 2 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_7:.*]] = mpir.var "mask" : <Operand>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq vector 2 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_8:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_12]], %[[VAR_7]], %[[TYPE_14]], %[[VAR_8]], %[[TYPE_16]], %[[KEYWORD_3]]) <result_name = "s3", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%c1", "y", "%c2", "pred", "%c3", "f", "%c4", "fpred", "d", "e", "%c5", "%s1", "%s2", "mask", "v", "%s3"], slot_kinds = [0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1], slot_sorts = [2, 3, 2, 3, 10, 3, 2, 3, 10, 2, 2, 3, 3, 3, 2, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][9] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_0]], 16 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 2 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <icmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 5
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 2
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_1]][5]
// CHECK:           mpir_plan.bind %[[GET_KEYED_1]] -> 4
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 2 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <fcmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 11
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 2
// CHECK:           %[[GET_KEYED_2:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_2]][5]
// CHECK:           mpir_plan.bind %[[GET_KEYED_2]] -> 8
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 9 <sort = 2>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][1]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 10 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 12
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 3
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 1, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_6]], <icmp>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_6]], 2
// CHECK:           %[[GET_KEYED_3:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_6]][5]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_3]], 20 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][1]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_8]], 0 : ui1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][1]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][2]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 2 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 13
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_4]][11] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 3
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 1, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_11]], <fcmp>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 7
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][11] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_11]], 2
// CHECK:           %[[GET_KEYED_4:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_11]][5]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_4]], 9 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][0]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_12]] -> 6 <sort = 2>
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [0, 2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_13]], 0.000000e+00 : f64
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_14]] -> 6 <sort = 2>
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][2]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [0, 2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_15]], 1.000000e+00 : f64
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 16
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 3
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [5, 1, 2, -1, [1, 1, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_16]] -> 14 <sort = 2>
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][1]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [5, 1, 2, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_17]] -> 15 <sort = 2>
// CHECK:           %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][2]
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [5, 1, 2, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_18]], 3 : i32 <keyword>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Constant operands: integers (wide ones too), floats, keywords, globals,
// and aggregates of each delimiter.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int -1 : si1 : <Value>
  %i_b = mpir.inst <add> (%2, %i_a, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 128 : <Type>
  %w = mpir.var "w" : <Operand>
  %5 = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value>
  %i_c = mpir.inst <add> (%4, %w, %4, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type>
  %bit = mpir.var "bit" : <Boolean>
  %7 = mpir.int 1 : ui1 : <Value>
  %i_d = mpir.inst <add> (%6, %bit, %6, %7) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 1 : <Type>
  %9 = mpir.int 0 : ui1 : <Value>
  %i_e = mpir.inst <add> (%8, %i_d, %8, %9) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type>
  %fx = mpir.var "fx" : <Operand>
  %11 = mpir.float 1.500000e-03 : f64 -> <Value>
  %i_f = mpir.inst <fadd> (%10, %fx, %10, %11) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type>
  %13 = mpir.float 0x7FF0000000000000 : f64 -> <Value>
  %i_g = mpir.inst <fadd> (%12, %i_f, %12, %13) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean>
  %15 = mpir.type.ptr : () -> !mpir.sort<Type>
  %16 = mpir.keyword null : <Value>
  %17 = mpir.type.ptr : () -> !mpir.sort<Type>
  %18 = mpir.global "global" : <Value>
  %i_h = mpir.inst <select> (%14, %c, %15, %16, %17, %18) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.int 1 : <Type>
  %20 = mpir.type.int 32 : <Type>
  %21 = mpir.keyword poison : <Value>
  %22 = mpir.type.int 32 : <Type>
  %23 = mpir.keyword undef : <Value>
  %i_i = mpir.inst <select> (%19, %c, %20, %21, %22, %23) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 1 : <Type>
  %25 = mpir.type.int 32 : <Type>
  %26 = mpir.type.seq vector 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.keyword zeroinitializer : <Value>
  %28 = mpir.type.int 32 : <Type>
  %29 = mpir.type.seq vector 2 x %28 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %30 = mpir.type.int 32 : <Type>
  %31 = mpir.int 1 : ui1 : <Value>
  %32 = mpir.type.int 32 : <Type>
  %33 = mpir.int 2 : ui2 : <Value>
  %34 = mpir.aggregate vector(%30, %31, %32, %33) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_j = mpir.inst <select> (%24, %c, %26, %27, %29, %34) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %35 = mpir.type.int 1 : <Type>
  %36 = mpir.type.int 8 : <Type>
  %37 = mpir.type.seq array 2 x %36 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %38 = mpir.type.int 8 : <Type>
  %39 = mpir.int 1 : ui1 : <Value>
  %40 = mpir.type.int 8 : <Type>
  %41 = mpir.int 2 : ui2 : <Value>
  %42 = mpir.aggregate array(%38, %39, %40, %41) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %43 = mpir.type.int 8 : <Type>
  %44 = mpir.type.seq array 2 x %43 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %arr = mpir.var "arr" : <Operand>
  %i_k = mpir.inst <select> (%35, %c, %37, %42, %44, %arr) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %45 = mpir.type.int 1 : <Type>
  %46 = mpir.type.int 32 : <Type>
  %47 = mpir.type.int 8 : <Type>
  %48 = mpir.type.struct{%46, %47} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %49 = mpir.type.int 32 : <Type>
  %50 = mpir.int 1 : ui1 : <Value>
  %51 = mpir.type.int 8 : <Type>
  %52 = mpir.int 2 : ui2 : <Value>
  %53 = mpir.aggregate struct(%49, %50, %51, %52) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %54 = mpir.type.int 32 : <Type>
  %55 = mpir.type.int 8 : <Type>
  %56 = mpir.type.struct{%54, %55} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %st = mpir.var "st" : <Operand>
  %i_l = mpir.inst <select> (%45, %c, %48, %53, %56, %st) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int -1 : si1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 128 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Operand>
// CHECK:           %[[INT_2:.*]] = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value>
// CHECK:           %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[VAR_1]], %[[TYPE_2]], %[[INT_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "bit" : <Boolean>
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[VAR_2]], %[[TYPE_3]], %[[INT_3]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[INT_4:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_4:.*]] = mpir.inst <add> (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_4]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "fx" : <Operand>
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.500000e-03 : f64 -> <Value>
// CHECK:           %[[INST_5:.*]] = mpir.inst <fadd> (%[[TYPE_5]], %[[VAR_3]], %[[TYPE_5]], %[[FLOAT_0]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 0x7FF0000000000000 : f64 -> <Value>
// CHECK:           %[[INST_6:.*]] = mpir.inst <fadd> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[FLOAT_1]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_4:.*]] = mpir.var "c" : <Boolean>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "global" : <Value>
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[KEYWORD_0]], %[[TYPE_9]], %[[GLOBAL_0]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword poison : <Value>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword undef : <Value>
// CHECK:           %[[INST_8:.*]] = mpir.inst <select> (%[[TYPE_10]], %[[VAR_4]], %[[TYPE_11]], %[[KEYWORD_1]], %[[TYPE_12]], %[[KEYWORD_2]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.seq vector 2 x %[[TYPE_14]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.seq vector 2 x %[[TYPE_16]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_6:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_18]], %[[INT_5]], %[[TYPE_19]], %[[INT_6]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[INST_9:.*]] = mpir.inst <select> (%[[TYPE_13]], %[[VAR_4]], %[[TYPE_15]], %[[KEYWORD_3]], %[[TYPE_17]], %[[AGGREGATE_0]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.seq array 2 x %[[TYPE_21]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[INT_8:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[AGGREGATE_1:.*]] = mpir.aggregate array(%[[TYPE_23]], %[[INT_7]], %[[TYPE_24]], %[[INT_8]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "arr" : <Operand>
// CHECK:           %[[INST_10:.*]] = mpir.inst <select> (%[[TYPE_20]], %[[VAR_4]], %[[TYPE_22]], %[[AGGREGATE_1]], %[[TYPE_26]], %[[VAR_5]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_28:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_30:.*]] = mpir.type.struct{%[[TYPE_28]], %[[TYPE_29]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_9:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[TYPE_32:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[INT_10:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[AGGREGATE_2:.*]] = mpir.aggregate struct(%[[TYPE_31]], %[[INT_9]], %[[TYPE_32]], %[[INT_10]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_34:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_35:.*]] = mpir.type.struct{%[[TYPE_33]], %[[TYPE_34]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "st" : <Operand>
// CHECK:           %[[INST_11:.*]] = mpir.inst <select> (%[[TYPE_27]], %[[VAR_4]], %[[TYPE_30]], %[[AGGREGATE_2]], %[[TYPE_35]], %[[VAR_6]]) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%a", "%b", "w", "%c", "bit", "%d", "%e", "fx", "%f", "%g", "c", "%h", "%i", "%j", "arr", "%k", "st", "%l"], slot_kinds = [0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1], slot_sorts = [2, 3, 3, 2, 3, 7, 3, 3, 2, 3, 3, 7, 3, 3, 3, 2, 3, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_2]], 0 : ui1
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_3]], -1 : si1
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 2
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 128, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 3 <sort = 2>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 128, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_5]], 170141183460469231731687303715884105727 : ui127
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 7
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 2
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 1, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_6]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 6
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_6]], 2
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 5 <sort = 7>
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][1]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 1, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_8]], 1 : ui1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][1]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [1, 1, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_9]], 0 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <fadd>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 10
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 2
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [0, 3]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_10]], <fadd>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 9
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_10]], 2
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 8 <sort = 2>
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][1]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [0, 3]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_12]], 1.500000e-03 : f64
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [0, 3]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_13]], 0x7FF0000000000000 : f64
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 12
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 3
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_14]] -> 11 <sort = 7>
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [4, -1, 1]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_15]], 0 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][2]
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [4, -1, 1]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_16]], "global"
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 13
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 3
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_17]] -> 11 <sort = 7>
// CHECK:           %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][1]
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_18]], 1 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][2]
// CHECK:           %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_19]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_19]], 2 : i32 <keyword>
// CHECK:           %[[FOREACH_INSTRUCTION_6:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_6]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_6]] -> 14
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_6]], 3
// CHECK:           %[[GET_OPERAND_20:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][0]
// CHECK:           %[[GET_TYPE_20:.*]] = mpir_plan.get_type %[[GET_OPERAND_20]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_20]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_20]] -> 11 <sort = 7>
// CHECK:           %[[GET_OPERAND_21:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][1]
// CHECK:           %[[GET_TYPE_21:.*]] = mpir_plan.get_type %[[GET_OPERAND_21]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_21]], [5, 1, 2, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_21]], 3 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_22:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][2]
// CHECK:           %[[GET_TYPE_22:.*]] = mpir_plan.get_type %[[GET_OPERAND_22]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_22]], [5, 1, 2, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_22]], 2, 2
// CHECK:           %[[GET_ELEMENT_0:.*]] = mpir_plan.get_element %[[GET_OPERAND_22]][0]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_0]], 1 : ui1
// CHECK:           %[[GET_ELEMENT_1:.*]] = mpir_plan.get_element %[[GET_OPERAND_22]][1]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_1]], 2 : ui2
// CHECK:           %[[FOREACH_INSTRUCTION_7:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_7]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_7]] -> 16
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_7]], 3
// CHECK:           %[[GET_OPERAND_23:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_7]][0]
// CHECK:           %[[GET_TYPE_23:.*]] = mpir_plan.get_type %[[GET_OPERAND_23]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_23]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_23]] -> 11 <sort = 7>
// CHECK:           %[[GET_OPERAND_24:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_7]][1]
// CHECK:           %[[GET_TYPE_24:.*]] = mpir_plan.get_type %[[GET_OPERAND_24]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_24]], [5, 0, 2, -1, [1, 8, 0]]
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_24]], 0, 2
// CHECK:           %[[GET_ELEMENT_2:.*]] = mpir_plan.get_element %[[GET_OPERAND_24]][0]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_2]], 1 : ui1
// CHECK:           %[[GET_ELEMENT_3:.*]] = mpir_plan.get_element %[[GET_OPERAND_24]][1]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_3]], 2 : ui2
// CHECK:           %[[GET_OPERAND_25:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_7]][2]
// CHECK:           %[[GET_TYPE_25:.*]] = mpir_plan.get_type %[[GET_OPERAND_25]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_25]], [5, 0, 2, -1, [1, 8, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_25]] -> 15 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_8:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_8]], <select>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_8]] -> 18
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_8]], 3
// CHECK:           %[[GET_OPERAND_26:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_8]][0]
// CHECK:           %[[GET_TYPE_26:.*]] = mpir_plan.get_type %[[GET_OPERAND_26]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_26]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_26]] -> 11 <sort = 7>
// CHECK:           %[[GET_OPERAND_27:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_8]][1]
// CHECK:           %[[GET_TYPE_27:.*]] = mpir_plan.get_type %[[GET_OPERAND_27]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_27]], [6, 0, [1, 32, 0], [1, 8, 0]]
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_27]], 1, 2
// CHECK:           %[[GET_ELEMENT_4:.*]] = mpir_plan.get_element %[[GET_OPERAND_27]][0]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_4]], 1 : ui1
// CHECK:           %[[GET_ELEMENT_5:.*]] = mpir_plan.get_element %[[GET_OPERAND_27]][1]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_5]], 2 : ui2
// CHECK:           %[[GET_OPERAND_28:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_8]][2]
// CHECK:           %[[GET_TYPE_28:.*]] = mpir_plan.get_type %[[GET_OPERAND_28]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_28]], [6, 0, [1, 32, 0], [1, 8, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_28]] -> 17 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Constraints: each kind of expression (literals, arrays and their
// elements, unary and binary operators by precedence, built-in calls with
// and without a context, calls of definitions), each anchored at the
// instruction it follows.
mpir.constraint_def @inRange <param_names = ["v", "lo", "hi"]> {
^bb0(%arg0: !mpir.sort<Unknown>, %arg1: !mpir.sort<Unknown>, %arg2: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg1 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %2 = mpir_expr.call call "ule"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %4 = mpir_expr.read %arg2 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %5 = mpir_expr.call call "ule"(%3, %4) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %6 : <Boolean>
}
mpir.pattern {
  %n = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand>
  %c = mpir.var "c" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %c) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %2 = mpir_expr.int 32 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %5 = mpir_expr.int 64 : ui64 : <Integer>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "||"(%3, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean>
  %8 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "isZero"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.call unary "!"(%9) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %11 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %12 = mpir_expr.int 1 : ui64 : <Integer>
  %13 = mpir_expr.int 8 : ui64 : <Integer>
  %14 = mpir_expr.apply @inRange(%11, %12, %13) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  %15 = mpir_expr.call binary "&&"(%10, %14) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %15 : <Boolean>
  %16 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.int 2 : ui64 : <Integer>
  %18 = mpir_expr.call binary "*"(%16, %17) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %19 = mpir_expr.int 1 : ui64 : <Integer>
  %20 = mpir_expr.call binary "+"(%18, %19) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %21 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %22 = mpir_expr.call binary "-"(%20, %21) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %23 = mpir_expr.int 3 : ui64 : <Integer>
  %24 = mpir_expr.call unary "-"(%23) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %25 = mpir_expr.call binary "!="(%22, %24) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 : <Boolean>
  %26 = mpir_expr.str "i8" : <String>
  %27 = mpir_expr.str "i16" : <String>
  %28 = mpir_expr.array %26, %27 : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
  %29 = mpir_expr.int 0 : ui64 : <Integer>
  %30 = mpir_expr.index %28[%29] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
  %31 = mpir_expr.str "i8" : <String>
  %32 = mpir_expr.call binary "=="(%30, %31) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %32 : <Boolean>
  %33 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %34 = mpir_expr.call call "bitWidth"(%33) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %35 = mpir_expr.int 32 : ui64 : <Integer>
  %36 = mpir_expr.call binary "=="(%34, %35) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %38 = mpir_expr.str "Argument" : <String>
  %39 = mpir_expr.call call "isa"(%37, %38) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.call binary "&&"(%36, %39) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %40 : <Boolean>
  %cmp = mpir.var "cmp" : <Instruction>
  %p = mpir.var "p" : <CmpPredicate>
  %41 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %42 = mpir.int 0 : ui1 : <Value>
  %i_b = mpir.inst <icmp> capture %cmp (%p, %41, %i_a, %41, %42) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %43 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %44 = mpir_expr.read %cmp : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %45 = mpir_expr.call call "isKnownNonZero"(%43, %44) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %46 = mpir_expr.read %p : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
  %47 = mpir_expr.str "eq" : <String>
  %48 = mpir_expr.call binary "=="(%46, %47) anchor %i_b : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %49 = mpir_expr.call binary "&&"(%45, %48) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %49 : <Boolean>
  %50 = mpir_expr.bool true : <Boolean>
  mpir.require %50 : <Boolean>
  %51 = mpir_expr.bool false : <Boolean>
  %52 = mpir_expr.call unary "!"(%51) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %52 : <Boolean>
}
// CHECK-LABEL:   mpir.constraint_def @inRange <param_names = ["v", "lo", "hi"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ule"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_2]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "ule"(%[[READ_2]], %[[READ_3]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "c" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 64 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call unary "!"(%[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 8 : ui64 : <Integer>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @inRange(%[[READ_3]], %[[INT_2]], %[[INT_3]]) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_5]] : <Boolean>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "*"(%[[READ_4]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "+"(%[[CALL_6]], %[[INT_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "-"(%[[CALL_7]], %[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call unary "-"(%[[INT_6]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_8]], %[[CALL_9]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "i8" : <String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "i16" : <String>
// CHECK:           %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:           %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_7]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "i8" : <String>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_11]] : <Boolean>
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[INT_8]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "Argument" : <String>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "isa"(%[[READ_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call binary "&&"(%[[CALL_13]], %[[CALL_14]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_15]] : <Boolean>
// CHECK:           %[[VAR_3:.*]] = mpir.var "cmp" : <Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "p" : <CmpPredicate>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[INT_9:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> capture %[[VAR_3]] (%[[VAR_4]], %[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_9]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_8]], %[[READ_9]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "eq" : <String>
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[READ_10]], %[[STR_4]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_18:.*]] = mpir_expr.call binary "&&"(%[[CALL_16]], %[[CALL_17]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_18]] : <Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           mpir.require %[[BOOL_0]] : <Boolean>
// CHECK:           %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:           %[[CALL_19:.*]] = mpir_expr.call unary "!"(%[[BOOL_1]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_19]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["n", "x", "c", "%a", "cmp", "p", "%b"], slot_kinds = [0, 0, 0, 1, 0, 0, 1], slot_sorts = [6, 2, 2, 3, 3, 10, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 6
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5]
// CHECK:           mpir_plan.bind %[[GET_KEYED_0]] -> 5
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [2, 0, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [2, 0, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [2, 0, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 2 <sort = 2>
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [2, 0, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_3]], 0 : ui1
// CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 0 {var_name = "n"} : <Nat>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:           %[[SLOT_1:.*]] = mpir_plan.slot 3 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[SLOT_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 64 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[SLOT_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[SLOT_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_2]] : <Boolean>
// CHECK:           %[[SLOT_2:.*]] = mpir_plan.slot 2 {var_name = "c"} : <Operand>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[SLOT_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_3:.*]] = mpir_plan.slot 3 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[SLOT_3]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call unary "!"(%[[CALL_3]]) anchor %[[SLOT_3]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[SLOT_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 8 : ui64 : <Integer>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @inRange(%[[READ_3]], %[[INT_2]], %[[INT_3]]) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) anchor %[[SLOT_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_5]] : <Boolean>
// CHECK:           %[[SLOT_4:.*]] = mpir_plan.slot 2 {var_name = "c"} : <Operand>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[SLOT_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:           %[[SLOT_5:.*]] = mpir_plan.slot 3 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "*"(%[[READ_4]], %[[INT_4]]) anchor %[[SLOT_5]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "+"(%[[CALL_6]], %[[INT_5]]) anchor %[[SLOT_5]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[SLOT_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "-"(%[[CALL_7]], %[[READ_5]]) anchor %[[SLOT_5]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call unary "-"(%[[INT_6]]) anchor %[[SLOT_5]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_8]], %[[CALL_9]]) anchor %[[SLOT_5]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_10]] : <Boolean>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "i8" : <String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "i16" : <String>
// CHECK:           %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:           %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_7]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "i8" : <String>
// CHECK:           %[[SLOT_6:.*]] = mpir_plan.slot 3 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_2]]) anchor %[[SLOT_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_11]] : <Boolean>
// CHECK:           %[[SLOT_7:.*]] = mpir_plan.slot 1 {var_name = "x"} : <Operand>
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[SLOT_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_8:.*]] = mpir_plan.slot 3 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[SLOT_8]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[INT_8]]) anchor %[[SLOT_8]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[SLOT_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "Argument" : <String>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "isa"(%[[READ_7]], %[[STR_3]]) anchor %[[SLOT_8]] : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call binary "&&"(%[[CALL_13]], %[[CALL_14]]) anchor %[[SLOT_8]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_15]] : <Boolean>
// CHECK:           %[[SLOT_9:.*]] = mpir_plan.slot 1 {var_name = "x"} : <Operand>
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[SLOT_9]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_10:.*]] = mpir_plan.slot 4 {var_name = "cmp"} : <Instruction>
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[SLOT_10]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_11:.*]] = mpir_plan.slot 6 {result_name = "b"} : <Instruction>
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_8]], %[[READ_9]]) anchor %[[SLOT_11]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[SLOT_12:.*]] = mpir_plan.slot 5 {var_name = "p"} : <CmpPredicate>
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[SLOT_12]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "eq" : <String>
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[READ_10]], %[[STR_4]]) anchor %[[SLOT_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_18:.*]] = mpir_expr.call binary "&&"(%[[CALL_16]], %[[CALL_17]]) anchor %[[SLOT_11]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_18]] : <Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           mpir_plan.check %[[BOOL_0]] : <Boolean>
// CHECK:           %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:           %[[SLOT_13:.*]] = mpir_plan.slot 6 {result_name = "b"} : <Instruction>
// CHECK:           %[[CALL_19:.*]] = mpir_expr.call unary "!"(%[[BOOL_1]]) anchor %[[SLOT_13]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_19]] : <Boolean>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Control flow: blocks written as labels, phis with their incoming blocks,
// branches and returns.
mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock>
  %0 = mpir.keyword ult : <Value>
  %1 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %2 = mpir.int 10 : ui4 : <Value>
  %i_c = mpir.inst <icmp> block %entry (%0, %1, %x, %1, %2) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 1 : <Type>
  %4 = mpir.type.prim label : <Type>
  %loop = mpir.var "loop" : <BasicBlock>
  %5 = mpir.type.prim label : <Type>
  %exit = mpir.var "exit" : <BasicBlock>
  %6 = mpir.inst <br> block %entry (%3, %i_c, %4, %loop, %5, %exit) <flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type>
  %8 = mpir.int 0 : ui1 : <Value>
  %n = mpir.var "n" : <Operand>
  %i_i = mpir.inst <phi> block %loop (%7, %8, %entry, %7, %n, %loop) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 1, 0, 1]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type>
  %10 = mpir.int 1 : ui1 : <Value>
  %i_next = mpir.inst <add> block %loop (%9, %i_i, %9, %10) <result_name = "next", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %11 = mpir.type.prim label : <Type>
  %12 = mpir.inst <br> block %loop (%11, %exit) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type>
  %14 = mpir.inst <ret> block %exit (%13, %i_next) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword ult : <Value>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 10 : ui4 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> block %[[VAR_0]] (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.prim label : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "loop" : <BasicBlock>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim label : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "exit" : <BasicBlock>
// CHECK:           %[[INST_1:.*]] = mpir.inst <br> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[VAR_4:.*]] = mpir.var "n" : <Operand>
// CHECK:           %[[INST_2:.*]] = mpir.inst <phi> block %[[VAR_2]] (%[[TYPE_4]], %[[INT_1]], %[[VAR_0]], %[[TYPE_4]], %[[VAR_4]], %[[VAR_2]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 1, 0, 1]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> block %[[VAR_2]] (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INT_2]]) <result_name = "next", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim label : <Type>
// CHECK:           %[[INST_4:.*]] = mpir.inst <br> block %[[VAR_2]] (%[[TYPE_6]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_5:.*]] = mpir.inst <ret> block %[[VAR_3]] (%[[TYPE_7]], %[[INST_3]]) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["entry", "x", "%c", "loop", "exit", "br", "n", "%i", "%next", "br", "ret"], slot_kinds = [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1], slot_sorts = [5, 2, 3, 5, 5, 3, 2, 3, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <br>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 5
// CHECK:           %[[GET_PARENT_BLOCK_0:.*]] = mpir_plan.get_parent_block %[[FOREACH_INSTRUCTION_0]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_0]] -> 0
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 3
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 1, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <icmp>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 2
// CHECK:           %[[GET_PARENT_BLOCK_1:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_1]] -> 0
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_0]][5]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_0]], 16 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_2]], 10 : ui4
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [0, 6]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 3 <sort = 5>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][2]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [0, 6]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 4 <sort = 5>
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <br>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 9
// CHECK:           %[[GET_PARENT_BLOCK_2:.*]] = mpir_plan.get_parent_block %[[FOREACH_INSTRUCTION_1]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_2]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 1
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [0, 6]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 4 <sort = 5>
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <ret>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 10
// CHECK:           %[[GET_PARENT_BLOCK_3:.*]] = mpir_plan.get_parent_block %[[FOREACH_INSTRUCTION_2]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_3]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 1
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_6]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 8
// CHECK:           %[[GET_PARENT_BLOCK_4:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_4]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_6]], 2
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_7]], <phi>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 7
// CHECK:           %[[GET_PARENT_BLOCK_5:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_5]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_7]], 4
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_8]], 0 : ui1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 0 <sort = 5>
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][2]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 6 <sort = 2>
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 3 <sort = 5>
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][1]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_12]], 1 : ui1
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// 'match' definitions: of each syntax, commutative, with branches that fix
// flags, with concrete parameter types, and their uses with flags, metaflags
// and captures.
mpir.pattern {
  %nsw = mpir.var "nsw" : <Boolean>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %_flag_a_disjoint = mpir.var "_flag$a$disjoint" : <Boolean>
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  }, {
    %i_a = mpir.inst <or> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %12 = mpir.int 0 : ui1 : <Value>
    mpir.bind %nsw, %12 : <Boolean>, <Value>
    mpir.yield %i_a : <Instruction>
  } attributes {result_name = "a"} : <Instruction>
  %neg = mpir.var "neg" : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %_flag_b_nsw = mpir.var "_flag$b$nsw" : <Boolean>
  %3 = mpir.alt {
    %12 = mpir.int 0 : ui1 : <Value>
    %i_b = mpir.inst <sub> capture %neg (%2, %12, %2, %1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction>
  }, {
    mpir.bind %neg, %1 : <Instruction>, <Instruction>
    mpir.yield %1 : <Instruction>
  } attributes {or_self_of = "negate", or_self_region = 1 : i32, result_name = "b"} : <Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.type.int 64 : <Type>
  %_flag_c_nneg = mpir.var "_flag$c$nneg" : <Boolean>
  %6 = mpir.alt {
    %i_c = mpir.inst <zext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction>
  }, {
    %i_c = mpir.inst <sext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction>
  } attributes {result_name = "c"} : <Instruction>
  %7 = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %8 = mpir.type.int 64 : <Type>
  %9 = mpir.type.int 64 : <Type>
  %10 = mpir.int 0 : ui1 : <Value>
  %11 = mpir.alt {
    %12 = mpir.type.int 1 : <Type>
    %i_d = mpir.inst <select> (%12, %cond, %8, %6, %8, %10) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_d : <Instruction>
  } attributes {result_name = "d"} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "nsw" : <Boolean>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[VAR_3:.*]] = mpir.var "_flag$a$disjoint" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "a"} : <Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "neg" : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "_flag$b$nsw" : <Boolean>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> capture %[[VAR_4]] (%[[TYPE_1]], %[[INT_1]], %[[TYPE_1]], %[[ALT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.bind %[[VAR_4]], %[[ALT_0]] : <Instruction>, <Instruction>
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "negate", or_self_region = 1 : i32, result_name = "b"} : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "_flag$c$nneg" : <Boolean>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
// CHECK:             %[[INST_3:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_4:.*]] = mpir.inst <sext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_4]] : <Instruction>
// CHECK:           } attributes {result_name = "c"} : <Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_7:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_3:.*]] = mpir.alt {
// CHECK:             %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_7]], %[[TYPE_5]], %[[ALT_2]], %[[TYPE_5]], %[[INT_2]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_5]] : <Instruction>
// CHECK:           } attributes {result_name = "d"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["nsw", "x", "y", "_flag$a$disjoint", "%a", "neg", "_flag$b$nsw", "%b", "_flag$c$nneg", "%c", "cond", "%d"], slot_kinds = [0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1], slot_sorts = [7, 2, 2, 7, 3, 3, 7, 3, 7, 3, 7, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <select>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 11
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 3
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 1, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 10 <sort = 7>
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 64, 0]
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_1]], <zext>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_1]] -> 9
// CHECK:               %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]] <operand_of>
// CHECK:               mpir_plan.check_type %[[GET_TYPE_2]], [1, 64, 0]
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_1]], 1
// CHECK:               %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:               %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_2]], <sub>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 7
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 5
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:                 %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:                 %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:                 mpir_plan.check_constant %[[GET_OPERAND_3]], 0 : ui1
// CHECK:                 %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:                 %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:                 mpir_plan.either {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_4]], <add>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_4]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_4]], 2
// CHECK:                   %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:                   %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_5]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][1]
// CHECK:                   %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_6]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.yield
// CHECK:                 }, {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_4]], <or>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_4]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_4]], 2
// CHECK:                   %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:                   %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_7]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][1]
// CHECK:                   %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_8]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.bind_constant false -> 0
// CHECK:                   mpir_plan.yield
// CHECK:                 }
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.either {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_2]], <add>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_2]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:                   %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:                   %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_9]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:                   %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_10]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.yield
// CHECK:                 }, {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_2]], <or>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_2]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:                   %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:                   %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_12]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_11]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:                   %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_13]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_12]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.bind_constant false -> 0
// CHECK:                   mpir_plan.yield
// CHECK:                 }
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 7
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 5
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_1]], <sext>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_1]] -> 9
// CHECK:               %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]] <operand_of>
// CHECK:               mpir_plan.check_type %[[GET_TYPE_14]], [1, 64, 0]
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_1]], 1
// CHECK:               %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:               %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_15]], [1, 32, 0]
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_13]], <sub>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_13]] -> 7
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_13]] -> 5
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_13]], 2
// CHECK:                 %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][0]
// CHECK:                 %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_16]], [1, 32, 0]
// CHECK:                 mpir_plan.check_constant %[[GET_OPERAND_14]], 0 : ui1
// CHECK:                 %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][1]
// CHECK:                 %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_17]], [1, 32, 0]
// CHECK:                 mpir_plan.either {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_15]], <add>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_15]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_15]], 2
// CHECK:                   %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[GET_OPERAND_15]][0]
// CHECK:                   %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_18]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_16]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[GET_OPERAND_15]][1]
// CHECK:                   %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_19]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_17]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.yield
// CHECK:                 }, {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_15]], <or>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_15]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_15]], 2
// CHECK:                   %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[GET_OPERAND_15]][0]
// CHECK:                   %[[GET_TYPE_20:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_20]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_18]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[GET_OPERAND_15]][1]
// CHECK:                   %[[GET_TYPE_21:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_21]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_19]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.bind_constant false -> 0
// CHECK:                   mpir_plan.yield
// CHECK:                 }
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.either {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_13]], <add>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_13]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_13]], 2
// CHECK:                   %[[GET_OPERAND_20:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][0]
// CHECK:                   %[[GET_TYPE_22:.*]] = mpir_plan.get_type %[[GET_OPERAND_20]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_22]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_20]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_21:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][1]
// CHECK:                   %[[GET_TYPE_23:.*]] = mpir_plan.get_type %[[GET_OPERAND_21]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_23]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_21]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.yield
// CHECK:                 }, {
// CHECK:                   mpir_plan.check_opcode %[[GET_OPERAND_13]], <or>
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_13]] -> 4
// CHECK:                   mpir_plan.check_operand_count %[[GET_OPERAND_13]], 2
// CHECK:                   %[[GET_OPERAND_22:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][0]
// CHECK:                   %[[GET_TYPE_24:.*]] = mpir_plan.get_type %[[GET_OPERAND_22]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_24]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_22]] -> 1 <sort = 2>
// CHECK:                   %[[GET_OPERAND_23:.*]] = mpir_plan.get_operand %[[GET_OPERAND_13]][1]
// CHECK:                   %[[GET_TYPE_25:.*]] = mpir_plan.get_type %[[GET_OPERAND_23]]
// CHECK:                   mpir_plan.check_type %[[GET_TYPE_25]], [1, 32, 0]
// CHECK:                   mpir_plan.bind %[[GET_OPERAND_23]] -> 2 <sort = 2>
// CHECK:                   mpir_plan.bind_constant false -> 0
// CHECK:                   mpir_plan.yield
// CHECK:                 }
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_13]] -> 7
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_13]] -> 5
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             %[[GET_OPERAND_24:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][2]
// CHECK:             %[[GET_TYPE_26:.*]] = mpir_plan.get_type %[[GET_OPERAND_24]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_26]], [1, 64, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_24]], 0 : ui1
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Memory: allocas with a count and alignment, volatile loads and stores
// with their alignment written or captured, and getelementptr with its
// flags, indices and address space.
mpir.pattern {
  %ia = mpir.var "ia" : <Boolean>
  %0 = mpir.type.int 32 : <Type>
  %1 = mpir.type.int 32 : <Type>
  %n = mpir.var "n" : <Nat>
  %2 = mpir.int 4 : ui3 : <Value>
  %i_slot = mpir.inst <alloca> flags(%ia) (%0, %1, %n, %2) <result_name = "slot", flags = [4], flag_modes = [2], operand_kinds = [2, 0, 6]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 64 : <Type>
  %4 = mpir.int 5 : ui3 : <Value>
  %i_slot2 = mpir.inst <alloca> (%3, %4) <result_name = "slot2", flags = [], flag_modes = [], operand_kinds = [2, 7]> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %5 = mpir.type.int 32 : <Type>
  %6 = mpir.type.ptr : () -> !mpir.sort<Type>
  %align = mpir.var "align" : <Nat>
  %i_v = mpir.inst <load> (%5, %6, %i_slot, %align) <result_name = "v", flags = [5], flag_modes = [0], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type>
  %8 = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand>
  %i_w = mpir.inst <load> (%7, %8, %p) <result_name = "w", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type>
  %10 = mpir.type.ptr : () -> !mpir.sort<Type>
  %11 = mpir.int 8 : ui4 : <Value>
  %i_st = mpir.inst <store> (%9, %i_v, %10, %i_slot, %11) <result_name = "st", flags = [], flag_modes = [], operand_kinds = [0, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %vol = mpir.var "vol" : <Boolean>
  %12 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %13 = mpir.type.ptr : () -> !mpir.sort<Type>
  %q = mpir.var "q" : <Operand>
  %i_st2 = mpir.inst <store> flags(%vol) (%12, %x, %13, %q) <result_name = "st2", flags = [5], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ib = mpir.var "ib" : <Boolean>
  %gn = mpir.var "gn" : <Boolean>
  %14 = mpir.type.int 8 : <Type>
  %15 = mpir.type.seq array 4 x %14 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %16 = mpir.type.ptr : () -> !mpir.sort<Type>
  %17 = mpir.type.int 64 : <Type>
  %18 = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 64 : <Type>
  %i = mpir.var "i" : <Operand>
  %i_g = mpir.inst <getelementptr> flags(%ib, %gn) (%15, %16, %i_slot, %17, %18, %19, %i) <result_name = "g", flags = [6, 7, 1], flag_modes = [2, 0, 2], operand_kinds = [2, 0, 0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %20 = mpir.type.int 8 : <Type>
  %21 = mpir.type.ptr : () -> !mpir.sort<Type>
  %22 = mpir.type.int 64 : <Type>
  %23 = mpir.int 4 : ui3 : <Value>
  %i_h = mpir.inst <getelementptr> (%20, %21, %q, %22, %23) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [2, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ia" : <Boolean>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[INT_0:.*]] = mpir.int 4 : ui3 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <alloca> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[TYPE_1]], %[[VAR_1]], %[[INT_0]]) <result_name = "slot", flags = [4], flag_modes = [2], operand_kinds = [2, 0, 6]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 5 : ui3 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <alloca> (%[[TYPE_2]], %[[INT_1]]) <result_name = "slot2", flags = [], flag_modes = [], operand_kinds = [2, 7]> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "align" : <Nat>
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> (%[[TYPE_3]], %[[TYPE_4]], %[[INST_0]], %[[VAR_2]]) <result_name = "v", flags = [5], flag_modes = [0], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
// CHECK:           %[[INST_3:.*]] = mpir.inst <load> (%[[TYPE_5]], %[[TYPE_6]], %[[VAR_3]]) <result_name = "w", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[INT_2:.*]] = mpir.int 8 : ui4 : <Value>
// CHECK:           %[[INST_4:.*]] = mpir.inst <store> (%[[TYPE_7]], %[[INST_2]], %[[TYPE_8]], %[[INST_0]], %[[INT_2]]) <result_name = "st", flags = [], flag_modes = [], operand_kinds = [0, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "vol" : <Boolean>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "q" : <Operand>
// CHECK:           %[[INST_5:.*]] = mpir.inst <store> flags(%[[VAR_4]]) (%[[TYPE_9]], %[[VAR_5]], %[[TYPE_10]], %[[VAR_6]]) <result_name = "st2", flags = [5], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_7:.*]] = mpir.var "ib" : <Boolean>
// CHECK:           %[[VAR_8:.*]] = mpir.var "gn" : <Boolean>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INT_3:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_9:.*]] = mpir.var "i" : <Operand>
// CHECK:           %[[INST_6:.*]] = mpir.inst <getelementptr> flags(%[[VAR_7]], %[[VAR_8]]) (%[[TYPE_12]], %[[TYPE_13]], %[[INST_0]], %[[TYPE_14]], %[[INT_3]], %[[TYPE_15]], %[[VAR_9]]) <result_name = "g", flags = [6, 7, 1], flag_modes = [2, 0, 2], operand_kinds = [2, 0, 0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INT_4:.*]] = mpir.int 4 : ui3 : <Value>
// CHECK:           %[[INST_7:.*]] = mpir.inst <getelementptr> (%[[TYPE_16]], %[[TYPE_17]], %[[VAR_6]], %[[TYPE_18]], %[[INT_4]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [2, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["ia", "n", "%slot", "%slot2", "align", "%v", "p", "%w", "%st", "vol", "x", "q", "%st2", "ib", "gn", "i", "%g", "%h"], slot_kinds = [0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1], slot_sorts = [7, 6, 3, 3, 6, 3, 2, 3, 3, 7, 2, 2, 3, 7, 7, 2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <alloca>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 64, 0]
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][7]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_0]], 5 : ui3
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 0
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <load>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 7
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 1
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [4, 1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 6 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <store>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 8
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_2]][6]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_1]], 8 : ui4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <load>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 5
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_1]][5] is true
// CHECK:           %[[GET_KEYED_2:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_1]][6]
// CHECK:           mpir_plan.bind %[[GET_KEYED_2]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 1
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [4, -1, 1]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <alloca>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 2
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[GET_OPERAND_2]][4]
// CHECK:           mpir_plan.bind %[[GET_FLAG_0]] -> 0
// CHECK:           %[[GET_KEYED_3:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_2]][6]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_3]], 4 : ui3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_2]], 1
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 1 <sort = 6>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][1]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 2
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <store>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 12
// CHECK:           %[[GET_FLAG_1:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_3]][5]
// CHECK:           mpir_plan.bind %[[GET_FLAG_1]] -> 9
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 2
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 10 <sort = 2>
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][1]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 11 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <getelementptr>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 16
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_4]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [5, 0, 4, -1, [1, 8, 0]]
// CHECK:           %[[GET_FLAG_2:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_4]][6]
// CHECK:           mpir_plan.bind %[[GET_FLAG_2]] -> 13
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_4]][7] is true
// CHECK:           %[[GET_FLAG_3:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           mpir_plan.bind %[[GET_FLAG_3]] -> 14
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 3
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 2
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [1, 64, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_8]], 0 : ui1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][2]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [1, 64, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 15 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <getelementptr>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 17
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_5]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [1, 8, 0]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 2
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 11 <sort = 2>
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][1]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [1, 64, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_11]], 4 : ui3
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Metaflags as written, kept for lowering: the built-in ones (':c', ':o'
// with and without an index, ':or' and ':not' of others), those defined in
// the file and in the standard library, with arguments, on instructions and
// on operands.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  }, {
    %i_a = mpir.inst <add> (%0, %y, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value>
  %4 = mpir.alt {
    mpir.yield %1 : <Instruction>
  }, {
    %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction>
  } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
  %5 = mpir.type.int 32 : <Type>
  %6 = mpir.int 0 : ui1 : <Value>
  %7 = mpir.alt {
    mpir.yield %4 : <Instruction>
  }, {
    %i_c = mpir.inst <sub> (%5, %6, %5, %4) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction>
  } attributes {or_self_of = "sub", or_self_region = 0 : i32, result_name = "c"} : <Instruction>
  %8 = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand>
  %i_d = mpir.inst <xor> (%8, %7, %8, %z) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type>
  %w = mpir.var "w" : <Operand>
  %i_e = mpir.inst <and> (%9, %i_d, %9, %w) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type>
  %u = mpir.var "u" : <Operand>
  %i_f = mpir.inst <or> (%10, %i_e, %10, %u) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir_expr.read %1 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %12 = mpir_expr.call call "hasOneUse"(%11) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %12 {from_metaflag} : <Boolean>
  %13 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %14 = mpir_expr.call call "isZero"(%13) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %14 {from_metaflag} : <Boolean>
  %15 = mpir_expr.int 1 : ui64 : <Integer>
  %16 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.call call "sle"(%15, %16) anchor %1 : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %19 = mpir_expr.int 10 : ui64 : <Integer>
  %20 = mpir_expr.call call "sle"(%18, %19) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %21 = mpir_expr.call binary "&&"(%17, %20) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %21 {from_metaflag} : <Boolean>
  %22 = mpir_expr.read %7 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %23 = mpir_expr.call call "opcode"(%22) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %24 = mpir_expr.str "add" : <String>
  %25 = mpir_expr.call binary "=="(%23, %24) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 {from_metaflag} : <Boolean>
  %26 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %27 = mpir_expr.call call "isZero"(%26) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %28 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %29 = mpir_expr.call call "isAllOnes"(%28) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %30 = mpir_expr.call binary "||"(%27, %29) anchor %i_d : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %30 {from_metaflag} : <Boolean>
  %31 = mpir_expr.read %w : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %32 = mpir_expr.call call "isPower2"(%31) anchor %i_e : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %33 = mpir_expr.call unary "!"(%32) anchor %i_e : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %33 {from_metaflag} : <Boolean>
  %34 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %35 = mpir_expr.call call "isZero"(%34) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %36 = mpir_expr.call unary "!"(%35) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.int 2 : ui64 : <Integer>
  %38 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %39 = mpir_expr.call call "sle"(%37, %38) anchor %i_f : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %41 = mpir_expr.int 4 : ui64 : <Integer>
  %42 = mpir_expr.call call "sle"(%40, %41) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %43 = mpir_expr.call binary "&&"(%39, %42) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %44 = mpir_expr.call binary "||"(%36, %43) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %44 {from_metaflag} : <Boolean>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INT_1]], %[[TYPE_2]], %[[ALT_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {or_self_of = "sub", or_self_region = 0 : i32, result_name = "c"} : <Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "z" : <Operand>
// CHECK:           %[[INST_4:.*]] = mpir.inst <xor> (%[[TYPE_3]], %[[ALT_2]], %[[TYPE_3]], %[[VAR_2]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "w" : <Operand>
// CHECK:           %[[INST_5:.*]] = mpir.inst <and> (%[[TYPE_4]], %[[INST_4]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_4:.*]] = mpir.var "u" : <Operand>
// CHECK:           %[[INST_6:.*]] = mpir.inst <or> (%[[TYPE_5]], %[[INST_5]], %[[TYPE_5]], %[[VAR_4]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[ALT_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "sle"(%[[INT_2]], %[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "sle"(%[[READ_3]], %[[INT_3]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_2]], %[[CALL_3]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[ALT_2]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[ALT_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_0]]) anchor %[[ALT_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_5]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_6]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[INST_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_9]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "isPower2"(%[[READ_7]]) anchor %[[INST_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call unary "!"(%[[CALL_10]]) anchor %[[INST_5]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_11]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "isZero"(%[[READ_8]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call unary "!"(%[[CALL_12]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "sle"(%[[INT_4]], %[[READ_9]]) anchor %[[INST_6]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 4 : ui64 : <Integer>
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "sle"(%[[READ_10]], %[[INT_5]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call binary "&&"(%[[CALL_14]], %[[CALL_15]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_13]], %[[CALL_16]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_17]] {from_metaflag} : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "y", "%a", "%b", "%c", "z", "%d", "w", "%e", "u", "%f"], slot_kinds = [0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1], slot_sorts = [2, 2, 3, 3, 3, 2, 3, 2, 3, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <or>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 10
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <and>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 8
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <xor>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 6
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 2
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_2]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:                 %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:                 %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_3]] -> 0 <sort = 2>
// CHECK:                 %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:                 %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_4]] -> 1 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_2]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_2]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:                 %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:                 %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_5]] -> 1 <sort = 2>
// CHECK:                 %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:                 %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_6]] -> 0 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               mpir_plan.bind %[[GET_OPERAND_2]] -> 3
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_2]], <mul>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_2]] -> 3
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:               %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:               %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_7]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_7]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_7]], 2
// CHECK:                 %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:                 %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_8]] -> 0 <sort = 2>
// CHECK:                 %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][1]
// CHECK:                 %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_9]] -> 1 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_7]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_7]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_7]], 2
// CHECK:                 %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:                 %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_10]] -> 1 <sort = 2>
// CHECK:                 %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][1]
// CHECK:                 %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_11]] -> 0 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:               %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_12]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_12]], 3 : ui2
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             mpir_plan.bind %[[GET_OPERAND_2]] -> 4
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_2]], <sub>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_2]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:             %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:             %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_13]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_13]], 0 : ui1
// CHECK:             %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:             %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_14]], [1, 32, 0]
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_14]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_14]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_14]], 2
// CHECK:                 %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][0]
// CHECK:                 %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_15]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_15]] -> 0 <sort = 2>
// CHECK:                 %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][1]
// CHECK:                 %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_16]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_16]] -> 1 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_14]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_14]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_14]], 2
// CHECK:                 %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][0]
// CHECK:                 %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_17]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_17]] -> 1 <sort = 2>
// CHECK:                 %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][1]
// CHECK:                 %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_18]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_18]] -> 0 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               mpir_plan.bind %[[GET_OPERAND_14]] -> 3
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_14]], <mul>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_14]] -> 3
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_14]], 2
// CHECK:               %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][0]
// CHECK:               %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_19]], [1, 32, 0]
// CHECK:               mpir_plan.either {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_19]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_19]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_19]], 2
// CHECK:                 %[[GET_OPERAND_20:.*]] = mpir_plan.get_operand %[[GET_OPERAND_19]][0]
// CHECK:                 %[[GET_TYPE_20:.*]] = mpir_plan.get_type %[[GET_OPERAND_20]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_20]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_20]] -> 0 <sort = 2>
// CHECK:                 %[[GET_OPERAND_21:.*]] = mpir_plan.get_operand %[[GET_OPERAND_19]][1]
// CHECK:                 %[[GET_TYPE_21:.*]] = mpir_plan.get_type %[[GET_OPERAND_21]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_21]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_21]] -> 1 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }, {
// CHECK:                 mpir_plan.check_opcode %[[GET_OPERAND_19]], <add>
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_19]] -> 2
// CHECK:                 mpir_plan.check_operand_count %[[GET_OPERAND_19]], 2
// CHECK:                 %[[GET_OPERAND_22:.*]] = mpir_plan.get_operand %[[GET_OPERAND_19]][0]
// CHECK:                 %[[GET_TYPE_22:.*]] = mpir_plan.get_type %[[GET_OPERAND_22]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_22]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_22]] -> 1 <sort = 2>
// CHECK:                 %[[GET_OPERAND_23:.*]] = mpir_plan.get_operand %[[GET_OPERAND_19]][1]
// CHECK:                 %[[GET_TYPE_23:.*]] = mpir_plan.get_type %[[GET_OPERAND_23]]
// CHECK:                 mpir_plan.check_type %[[GET_TYPE_23]], [1, 32, 0]
// CHECK:                 mpir_plan.bind %[[GET_OPERAND_23]] -> 0 <sort = 2>
// CHECK:                 mpir_plan.yield
// CHECK:               }
// CHECK:               %[[GET_OPERAND_24:.*]] = mpir_plan.get_operand %[[GET_OPERAND_14]][1]
// CHECK:               %[[GET_TYPE_24:.*]] = mpir_plan.get_type %[[GET_OPERAND_24]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_24]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_24]], 3 : ui2
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[GET_OPERAND_25:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:           %[[GET_TYPE_25:.*]] = mpir_plan.get_type %[[GET_OPERAND_25]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_25]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_25]] -> 5 <sort = 2>
// CHECK:           %[[GET_OPERAND_26:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_26:.*]] = mpir_plan.get_type %[[GET_OPERAND_26]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_26]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_26]] -> 7 <sort = 2>
// CHECK:           %[[GET_OPERAND_27:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_27:.*]] = mpir_plan.get_type %[[GET_OPERAND_27]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_27]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_27]] -> 9 <sort = 2>
// CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[SLOT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_1:.*]] = mpir_plan.slot 0 {var_name = "x"} : <Operand>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[SLOT_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_2:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[SLOT_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[SLOT_3:.*]] = mpir_plan.slot 1 {var_name = "y"} : <Operand>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[SLOT_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_4:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "sle"(%[[INT_0]], %[[READ_2]]) anchor %[[SLOT_4]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[SLOT_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "sle"(%[[READ_3]], %[[INT_1]]) anchor %[[SLOT_4]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_2]], %[[CALL_3]]) anchor %[[SLOT_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_4]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_5:.*]] = mpir_plan.slot 4 {result_name = "c"} : <Instruction>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[SLOT_5]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[SLOT_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_0]]) anchor %[[SLOT_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_6]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_6:.*]] = mpir_plan.slot 5 {var_name = "z"} : <Operand>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[SLOT_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_7:.*]] = mpir_plan.slot 6 {result_name = "d"} : <Instruction>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_5]]) anchor %[[SLOT_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[SLOT_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_6]]) anchor %[[SLOT_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[SLOT_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_9]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_8:.*]] = mpir_plan.slot 7 {var_name = "w"} : <Operand>
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[SLOT_8]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_9:.*]] = mpir_plan.slot 8 {result_name = "e"} : <Instruction>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "isPower2"(%[[READ_7]]) anchor %[[SLOT_9]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call unary "!"(%[[CALL_10]]) anchor %[[SLOT_9]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_11]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_10:.*]] = mpir_plan.slot 9 {var_name = "u"} : <Operand>
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[SLOT_10]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_11:.*]] = mpir_plan.slot 10 {result_name = "f"} : <Instruction>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "isZero"(%[[READ_8]]) anchor %[[SLOT_11]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call unary "!"(%[[CALL_12]]) anchor %[[SLOT_11]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[SLOT_10]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "sle"(%[[INT_2]], %[[READ_9]]) anchor %[[SLOT_11]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[SLOT_10]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 4 : ui64 : <Integer>
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "sle"(%[[READ_10]], %[[INT_3]]) anchor %[[SLOT_11]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call binary "&&"(%[[CALL_14]], %[[CALL_15]]) anchor %[[SLOT_11]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_13]], %[[CALL_16]]) anchor %[[SLOT_11]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_17]] <from_metaflag> : <Boolean>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Numbered results and labels; 'anyblock:' ends the block the instructions
// before it were required to share; a void return and a typed pointer.
mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_0 = mpir.inst <add> block %entry (%0, %x, %0, %1) <result_name = "0", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %i_1 = mpir.inst <mul> block %entry (%2, %i_0, %2, %i_0) <result_name = "1", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %_7 = mpir.var "7" : <BasicBlock>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.type.ptr %4 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand>
  %i_2 = mpir.inst <load> block %_7 (%3, %5, %p) <result_name = "2", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 32 : <Type>
  %i_3 = mpir.inst <sub> (%6, %i_2, %6, %i_1) <result_name = "3", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim void : <Type>
  %8 = mpir.inst <ret> (%7) <flags = [], flag_modes = [], operand_kinds = [2]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <result_name = "0", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INST_0]]) <result_name = "1", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "7" : <BasicBlock>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> block %[[VAR_2]] (%[[TYPE_2]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "2", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INST_1]]) <result_name = "3", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim void : <Type>
// CHECK:           %[[INST_4:.*]] = mpir.inst <ret> (%[[TYPE_6]]) <flags = [], flag_modes = [], operand_kinds = [2]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["entry", "x", "%0", "%1", "7", "p", "%2", "%3", "ret"], slot_kinds = [0, 0, 1, 1, 0, 0, 1, 1, 1], slot_sorts = [5, 2, 3, 3, 5, 2, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <sub>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 7
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <load>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 6
// CHECK:           %[[GET_PARENT_BLOCK_0:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_0]] -> 4
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 1
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [4, -1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 5 <sort = 2>
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <mul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 3
// CHECK:           %[[GET_PARENT_BLOCK_1:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_1]] -> 0
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_3]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 2
// CHECK:           %[[GET_PARENT_BLOCK_2:.*]] = mpir_plan.get_parent_block %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.bind %[[GET_PARENT_BLOCK_2]] -> 0
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_3]], 2
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][1]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_5]], 1 : ui1
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 2
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <ret>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 8
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [0, 5]
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 0
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Settings apply to the instructions after them; names with dots and
// hyphens are made printable; unnamed values and variables.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x_y = mpir.var "x.y" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_a_b = mpir.inst <add> (%0, %x_y, %0, %1) <result_name = "a.b", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %__0 = mpir.var "_$0" : <Operand>
  %i_c_d = mpir.inst <sub> (%2, %i_a_b, %2, %__0) <result_name = "c-d", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type>
  %__1 = mpir.var "_$1" : <Operand>
  %i_e = mpir.inst <mul> (%3, %i_c_d, %3, %__1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.inst <ret> (%4, %i_e) <flags = [], flag_modes = [], operand_kinds = [0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x.y" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a.b", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "_$0" : <Operand>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "c-d", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "_$1" : <Operand>
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_2]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <ret> (%[[TYPE_3]], %[[INST_2]]) <flags = [], flag_modes = [], operand_kinds = [0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x.y", "%a.b", "_$0", "%c-d", "_$1", "%e", "ret"], slot_kinds = [0, 1, 0, 1, 0, 1, 1], slot_sorts = [2, 3, 2, 3, 2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <ret>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 6
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <mul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 5
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <sub>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 2
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0] <treat_int_as_vec>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0] <treat_int_as_vec>
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_4]], 1 : ui1 <treat_int_as_vec>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 2 <sort = 2>
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 4 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Type patterns: integer and byte types of fixed and variable width,
// primitives, pointers, arrays and vectors of fixed and variable length,
// structs, and type variables.
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %a1 = mpir.var "a1" : <Boolean>
  %i_a = mpir.inst <freeze> (%0, %a1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 8 byte : <Type>
  %b1 = mpir.var "b1" : <Operand>
  %i_b = mpir.inst <freeze> (%1, %b1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat>
  %2 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %c1 = mpir.var "c1" : <Operand>
  %i_c = mpir.inst <freeze> (%2, %c1) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %m = mpir.var "m" : <Nat>
  %3 = mpir.type.meta_int %m byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %d1 = mpir.var "d1" : <Operand>
  %i_d = mpir.inst <freeze> (%3, %d1) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.prim half : <Type>
  %e1 = mpir.var "e1" : <Operand>
  %i_e = mpir.inst <freeze> (%4, %e1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %5 = mpir.type.prim bfloat : <Type>
  %f1 = mpir.var "f1" : <Operand>
  %i_f = mpir.inst <freeze> (%5, %f1) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim float : <Type>
  %g1 = mpir.var "g1" : <Operand>
  %i_g = mpir.inst <freeze> (%6, %g1) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim double : <Type>
  %h1 = mpir.var "h1" : <Operand>
  %i_h = mpir.inst <freeze> (%7, %h1) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim fp128 : <Type>
  %i1 = mpir.var "i1" : <Operand>
  %i_i = mpir.inst <freeze> (%8, %i1) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.ptr : () -> !mpir.sort<Type>
  %j1 = mpir.var "j1" : <Operand>
  %i_j = mpir.inst <freeze> (%9, %j1) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
  %k1 = mpir.var "k1" : <Operand>
  %i_k = mpir.inst <freeze> (%10, %k1) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir.type.int 8 : <Type>
  %12 = mpir.type.seq array 4 x %11 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %l1 = mpir.var "l1" : <Operand>
  %i_l = mpir.inst <freeze> (%12, %l1) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %len = mpir.var "len" : <Nat>
  %13 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %14 = mpir.type.seq array 0 x %13 count %len : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %m1 = mpir.var "m1" : <Operand>
  %i_m = mpir.inst <freeze> (%14, %m1) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %15 = mpir.type.prim float : <Type>
  %16 = mpir.type.seq vector 2 x %15 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %n1 = mpir.var "n1" : <Operand>
  %i_n = mpir.inst <freeze> (%16, %n1) <result_name = "n", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type>
  %18 = mpir.type.seq scalable 4 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %o1 = mpir.var "o1" : <Operand>
  %i_o = mpir.inst <freeze> (%18, %o1) <result_name = "o", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %lanes = mpir.var "lanes" : <Nat>
  %19 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %20 = mpir.type.seq vector 0 x %19 count %lanes : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %p1 = mpir.var "p1" : <Operand>
  %i_p = mpir.inst <freeze> (%20, %p1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %21 = mpir.type.int 32 : <Type>
  %22 = mpir.type.ptr : () -> !mpir.sort<Type>
  %23 = mpir.type.struct{%21, %22} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %q1 = mpir.var "q1" : <Operand>
  %i_q = mpir.inst <freeze> (%23, %q1) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 8 : <Type>
  %25 = mpir.type.int 16 : <Type>
  %26 = mpir.type.seq array 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.type.struct packed{%24, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %r1 = mpir.var "r1" : <Operand>
  %i_r = mpir.inst <freeze> (%27, %r1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %28 = mpir.type.struct{} : () -> !mpir.sort<Type>
  %s1 = mpir.var "s1" : <Operand>
  %i_s = mpir.inst <freeze> (%28, %s1) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ty = mpir.var "ty" : <Type>
  %t1 = mpir.var "t1" : <Operand>
  %i_t = mpir.inst <freeze> (%ty, %t1) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "a1" : <Boolean>
// CHECK:           %[[INST_0:.*]] = mpir.inst <freeze> (%[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 byte : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "b1" : <Operand>
// CHECK:           %[[INST_1:.*]] = mpir.inst <freeze> (%[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "c1" : <Operand>
// CHECK:           %[[INST_2:.*]] = mpir.inst <freeze> (%[[TYPE_2]], %[[VAR_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "m" : <Nat>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAR_4]] byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "d1" : <Operand>
// CHECK:           %[[INST_3:.*]] = mpir.inst <freeze> (%[[TYPE_3]], %[[VAR_5]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim half : <Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "e1" : <Operand>
// CHECK:           %[[INST_4:.*]] = mpir.inst <freeze> (%[[TYPE_4]], %[[VAR_6]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim bfloat : <Type>
// CHECK:           %[[VAR_7:.*]] = mpir.var "f1" : <Operand>
// CHECK:           %[[INST_5:.*]] = mpir.inst <freeze> (%[[TYPE_5]], %[[VAR_7]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[VAR_8:.*]] = mpir.var "g1" : <Operand>
// CHECK:           %[[INST_6:.*]] = mpir.inst <freeze> (%[[TYPE_6]], %[[VAR_8]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[VAR_9:.*]] = mpir.var "h1" : <Operand>
// CHECK:           %[[INST_7:.*]] = mpir.inst <freeze> (%[[TYPE_7]], %[[VAR_9]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim fp128 : <Type>
// CHECK:           %[[VAR_10:.*]] = mpir.var "i1" : <Operand>
// CHECK:           %[[INST_8:.*]] = mpir.inst <freeze> (%[[TYPE_8]], %[[VAR_10]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_11:.*]] = mpir.var "j1" : <Operand>
// CHECK:           %[[INST_9:.*]] = mpir.inst <freeze> (%[[TYPE_9]], %[[VAR_11]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_12:.*]] = mpir.var "k1" : <Operand>
// CHECK:           %[[INST_10:.*]] = mpir.inst <freeze> (%[[TYPE_10]], %[[VAR_12]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_13:.*]] = mpir.var "l1" : <Operand>
// CHECK:           %[[INST_11:.*]] = mpir.inst <freeze> (%[[TYPE_12]], %[[VAR_13]]) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_14:.*]] = mpir.var "len" : <Nat>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq array 0 x %[[TYPE_13]] count %[[VAR_14]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_15:.*]] = mpir.var "m1" : <Operand>
// CHECK:           %[[INST_12:.*]] = mpir.inst <freeze> (%[[TYPE_14]], %[[VAR_15]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_16:.*]] = mpir.var "n1" : <Operand>
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_16]], %[[VAR_16]]) <result_name = "n", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.seq scalable 4 x %[[TYPE_17]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_17:.*]] = mpir.var "o1" : <Operand>
// CHECK:           %[[INST_14:.*]] = mpir.inst <freeze> (%[[TYPE_18]], %[[VAR_17]]) <result_name = "o", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_18:.*]] = mpir.var "lanes" : <Nat>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.seq vector 0 x %[[TYPE_19]] count %[[VAR_18]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_19:.*]] = mpir.var "p1" : <Operand>
// CHECK:           %[[INST_15:.*]] = mpir.inst <freeze> (%[[TYPE_20]], %[[VAR_19]]) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.struct{%[[TYPE_21]], %[[TYPE_22]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_20:.*]] = mpir.var "q1" : <Operand>
// CHECK:           %[[INST_16:.*]] = mpir.inst <freeze> (%[[TYPE_23]], %[[VAR_20]]) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 16 : <Type>
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct packed{%[[TYPE_24]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_21:.*]] = mpir.var "r1" : <Operand>
// CHECK:           %[[INST_17:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[VAR_21]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_28:.*]] = mpir.type.struct{} : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_22:.*]] = mpir.var "s1" : <Operand>
// CHECK:           %[[INST_18:.*]] = mpir.inst <freeze> (%[[TYPE_28]], %[[VAR_22]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_23:.*]] = mpir.var "ty" : <Type>
// CHECK:           %[[VAR_24:.*]] = mpir.var "t1" : <Operand>
// CHECK:           %[[INST_19:.*]] = mpir.inst <freeze> (%[[VAR_23]], %[[VAR_24]]) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["a1", "%a", "b1", "%b", "n", "c1", "%c", "m", "d1", "%d", "e1", "%e", "f1", "%f", "g1", "%g", "h1", "%h", "i1", "%i", "j1", "%j", "k1", "%k", "l1", "%l", "len", "m1", "%m", "n1", "%n", "o1", "%o", "lanes", "p1", "%p", "q1", "%q", "r1", "%r", "s1", "%s", "ty", "t1", "%t"], slot_kinds = [0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1], slot_sorts = [7, 3, 2, 3, 6, 2, 3, 6, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 6, 2, 3, 2, 3, 2, 3, 6, 2, 3, 2, 3, 2, 3, 2, 3, 12, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 1, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 7>
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 1
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 8, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 2 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 6
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 1
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [2, 4, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 5 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 9
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 1
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [2, 7, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 8 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 11
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 1
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [0, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 10 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_5:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_5]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_5]] -> 13
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_5]], 1
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_5]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [0, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 12 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_6:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_6]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_6]] -> 15
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_6]], 1
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_6]][0]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [0, 2]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_6]] -> 14 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_7:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_7]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_7]] -> 17
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_7]], 1
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_7]][0]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [0, 3]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_7]] -> 16 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_8:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_8]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_8]] -> 19
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_8]], 1
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_8]][0]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [0, 4]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_8]] -> 18 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_9:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_9]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_9]] -> 21
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_9]], 1
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_9]][0]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [4, -1, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_9]] -> 20 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_10:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_10]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_10]] -> 23
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_10]], 1
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_10]][0]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [4, 3, 1]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_10]] -> 22 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_11:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_11]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_11]] -> 25
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_11]], 1
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_11]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [5, 0, 4, -1, [1, 8, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 24 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_12:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_12]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_12]] -> 28
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_12]], 1
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_12]][0]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [5, 0, 0, 26, [2, 4, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_12]] -> 27 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_13:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_13]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_13]] -> 30
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_13]], 1
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_13]][0]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [5, 1, 2, -1, [0, 2]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_13]] -> 29 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_14:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_14]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_14]] -> 32
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_14]], 1
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_14]][0]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_14]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [5, 2, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_14]] -> 31 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_15:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_15]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_15]] -> 35
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_15]], 1
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_15]][0]
// CHECK:           %[[GET_TYPE_15:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_15]], [5, 1, 0, 33, [2, 4, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_15]] -> 34 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_16:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_16]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_16]] -> 37
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_16]], 1
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_16]][0]
// CHECK:           %[[GET_TYPE_16:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_16]], [6, 0, [1, 32, 0], [4, -1, 1]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_16]] -> 36 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_17:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_17]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_17]] -> 39
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_17]], 1
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_17]][0]
// CHECK:           %[[GET_TYPE_17:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_17]], [6, 1, [1, 8, 0], [5, 0, 2, -1, [1, 16, 0]]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_17]] -> 38 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_18:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_18]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_18]] -> 41
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_18]], 1
// CHECK:           %[[GET_OPERAND_18:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_18]][0]
// CHECK:           %[[GET_TYPE_18:.*]] = mpir_plan.get_type %[[GET_OPERAND_18]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_18]], [6, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_18]] -> 40 <sort = 2>
// CHECK:           %[[FOREACH_INSTRUCTION_19:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_19]], <freeze>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_19]] -> 44
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_19]], 1
// CHECK:           %[[GET_OPERAND_19:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_19]][0]
// CHECK:           %[[GET_TYPE_19:.*]] = mpir_plan.get_type %[[GET_OPERAND_19]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_19]], [3, 42]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_19]] -> 43 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Vector and aggregate instructions: elements, shuffles, and fields by
// their indices or captured as an array.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %1 = mpir.type.seq vector 4 x %0 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand>
  %2 = mpir.type.int 64 : <Type>
  %idx = mpir.var "idx" : <Nat>
  %i_e = mpir.inst <extractelement> (%1, %v, %2, %idx) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.type.seq vector 4 x %3 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %5 = mpir.type.int 32 : <Type>
  %6 = mpir.type.int 64 : <Type>
  %7 = mpir.int 0 : ui1 : <Value>
  %i_i = mpir.inst <insertelement> (%4, %v, %5, %i_e, %6, %7) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type>
  %9 = mpir.type.seq vector 4 x %8 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %10 = mpir.type.int 32 : <Type>
  %11 = mpir.type.seq vector 4 x %10 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %12 = mpir.keyword poison : <Value>
  %13 = mpir.type.int 32 : <Type>
  %14 = mpir.type.seq vector 4 x %13 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %15 = mpir.type.int 32 : <Type>
  %16 = mpir.int 0 : ui1 : <Value>
  %17 = mpir.type.int 32 : <Type>
  %18 = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 32 : <Type>
  %20 = mpir.int 1 : ui1 : <Value>
  %21 = mpir.type.int 32 : <Type>
  %22 = mpir.int 1 : ui1 : <Value>
  %23 = mpir.aggregate vector(%15, %16, %17, %18, %19, %20, %21, %22) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_s = mpir.inst <shufflevector> (%9, %i_i, %11, %12, %14, %23) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type>
  %25 = mpir.type.int 8 : <Type>
  %26 = mpir.type.int 16 : <Type>
  %27 = mpir.type.struct{%25, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %28 = mpir.type.struct{%24, %27} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg = mpir.var "agg" : <Operand>
  %29 = mpir.int 1 : ui1 : <Value>
  %30 = mpir.int 0 : ui1 : <Value>
  %i_x = mpir.inst <extractvalue> (%28, %agg, %29, %30) <result_name = "x", flags = [], flag_modes = [], operand_kinds = [0, 1, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %31 = mpir.type.int 32 : <Type>
  %32 = mpir.type.prim float : <Type>
  %33 = mpir.type.struct{%31, %32} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg2 = mpir.var "agg2" : <Operand>
  %path = mpir.var "path" : <ValueArray>
  %i_y = mpir.inst <extractvalue> (%33, %agg2, %path) <result_name = "y", flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %34 = mpir.type.int 32 : <Type>
  %35 = mpir.type.prim float : <Type>
  %36 = mpir.type.struct{%34, %35} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %37 = mpir.type.prim float : <Type>
  %38 = mpir.float 1.000000e+00 : f64 -> <Value>
  %39 = mpir.int 1 : ui1 : <Value>
  %i_z = mpir.inst <insertvalue> (%36, %agg2, %37, %38, %39) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 0, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %40 = mpir.type.int 32 : <Type>
  %41 = mpir.type.seq scalable 4 x %40 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.var "a" : <Operand>
  %42 = mpir.type.int 32 : <Type>
  %43 = mpir.type.seq scalable 4 x %42 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %b = mpir.var "b" : <Operand>
  %44 = mpir.type.int 32 : <Type>
  %45 = mpir.type.seq scalable 4 x %44 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %46 = mpir.keyword zeroinitializer : <Value>
  %i_sv = mpir.inst <shufflevector> (%41, %a, %43, %b, %45, %46) <result_name = "sv", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.seq vector 4 x %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "idx" : <Nat>
// CHECK:           %[[INST_0:.*]] = mpir.inst <extractelement> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.seq vector 4 x %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <insertelement> (%[[TYPE_4]], %[[VAR_0]], %[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[INT_0]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.seq vector 4 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.seq vector 4 x %[[TYPE_9]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword poison : <Value>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_4:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_13]], %[[INT_1]], %[[TYPE_14]], %[[INT_2]], %[[TYPE_15]], %[[INT_3]], %[[TYPE_16]], %[[INT_4]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[INST_2:.*]] = mpir.inst <shufflevector> (%[[TYPE_8]], %[[INST_1]], %[[TYPE_10]], %[[KEYWORD_0]], %[[TYPE_12]], %[[AGGREGATE_0]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 16 : <Type>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.struct{%[[TYPE_18]], %[[TYPE_19]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.struct{%[[TYPE_17]], %[[TYPE_20]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "agg" : <Operand>
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INT_6:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_3:.*]] = mpir.inst <extractvalue> (%[[TYPE_21]], %[[VAR_2]], %[[INT_5]], %[[INT_6]]) <result_name = "x", flags = [], flag_modes = [], operand_kinds = [0, 1, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.struct{%[[TYPE_22]], %[[TYPE_23]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "agg2" : <Operand>
// CHECK:           %[[VAR_4:.*]] = mpir.var "path" : <ValueArray>
// CHECK:           %[[INST_4:.*]] = mpir.inst <extractvalue> (%[[TYPE_24]], %[[VAR_3]], %[[VAR_4]]) <result_name = "y", flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_26:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct{%[[TYPE_25]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_28:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_5:.*]] = mpir.inst <insertvalue> (%[[TYPE_27]], %[[VAR_3]], %[[TYPE_28]], %[[FLOAT_0]], %[[INT_7]]) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 0, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_30:.*]] = mpir.type.seq scalable 4 x %[[TYPE_29]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_32:.*]] = mpir.type.seq scalable 4 x %[[TYPE_31]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_34:.*]] = mpir.type.seq scalable 4 x %[[TYPE_33]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword zeroinitializer : <Value>
// CHECK:           %[[INST_6:.*]] = mpir.inst <shufflevector> (%[[TYPE_30]], %[[VAR_5]], %[[TYPE_32]], %[[VAR_6]], %[[TYPE_34]], %[[KEYWORD_1]]) <result_name = "sv", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["v", "idx", "%e", "%i", "%s", "agg", "%x", "agg2", "path", "%y", "%z", "a", "b", "%sv"], slot_kinds = [0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1], slot_sorts = [2, 6, 3, 3, 3, 2, 3, 2, 15, 3, 3, 2, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <shufflevector>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 3
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [5, 1, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <insertelement>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 3
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [5, 1, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <extractelement>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 2
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_2]], 2
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [5, 1, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_2]][1]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 64, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 1 <sort = 6>
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][2]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 64, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_5]], 0 : ui1
// CHECK:           %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [5, 1, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_6]], 1 : i32 <keyword>
// CHECK:           %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][2]
// CHECK:           %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_7]], [5, 1, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_7]], 2, 4
// CHECK:           %[[GET_ELEMENT_0:.*]] = mpir_plan.get_element %[[GET_OPERAND_7]][0]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_0]], 0 : ui1
// CHECK:           %[[GET_ELEMENT_1:.*]] = mpir_plan.get_element %[[GET_OPERAND_7]][1]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_1]], 0 : ui1
// CHECK:           %[[GET_ELEMENT_2:.*]] = mpir_plan.get_element %[[GET_OPERAND_7]][2]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_2]], 1 : ui1
// CHECK:           %[[GET_ELEMENT_3:.*]] = mpir_plan.get_element %[[GET_OPERAND_7]][3]
// CHECK:           mpir_plan.check_constant %[[GET_ELEMENT_3]], 1 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <extractvalue>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 6
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 3
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [6, 0, [1, 32, 0], [6, 0, [1, 8, 0], [1, 16, 0]]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_8]] -> 5 <sort = 2>
// CHECK:           %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_9]], 1 : ui1
// CHECK:           %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_10]], 0 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_2:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_2]], <extractvalue>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_2]] -> 9
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 1 <at_least>
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_9]], [6, 0, [1, 32, 0], [0, 2]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 7 <sort = 2>
// CHECK:           %[[GET_OPERANDS_FROM_0:.*]] = mpir_plan.get_operands_from %[[FOREACH_INSTRUCTION_2]][1 :]
// CHECK:           mpir_plan.bind %[[GET_OPERANDS_FROM_0]] -> 8
// CHECK:           %[[FOREACH_INSTRUCTION_3:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_3]], <insertvalue>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_3]] -> 10
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_3]], 3
// CHECK:           %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][0]
// CHECK:           %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_10]], [6, 0, [1, 32, 0], [0, 2]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_12]] -> 7 <sort = 2>
// CHECK:           %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][1]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [0, 2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_13]], 1.000000e+00 : f64
// CHECK:           %[[GET_OPERAND_14:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_3]][2]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_14]], 1 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_4:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_4]], <shufflevector>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_4]] -> 13
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 3
// CHECK:           %[[GET_OPERAND_15:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_15]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_12]], [5, 2, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_15]] -> 11 <sort = 2>
// CHECK:           %[[GET_OPERAND_16:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][1]
// CHECK:           %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_16]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_13]], [5, 2, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_16]] -> 12 <sort = 2>
// CHECK:           %[[GET_OPERAND_17:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][2]
// CHECK:           %[[GET_TYPE_14:.*]] = mpir_plan.get_type %[[GET_OPERAND_17]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_14]], [5, 2, 4, -1, [1, 32, 0]]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_17]], 3 : i32 <keyword>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Two roots: each is searched for among the instructions.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int 2 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %x, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[INT_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%a", "%b"], slot_kinds = [0, 1, 1], slot_sorts = [2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_1]], 1 : ui1
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <mul>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 2
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 2
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_constant %[[GET_OPERAND_3]], 2 : ui2
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// An instruction reached twice is matched once, then compared.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %i_a) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%2, %i_b, %2, %i_a) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INST_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[INST_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "y", "%a", "%b", "%c"], slot_kinds = [0, 0, 1, 1, 1], slot_sorts = [2, 2, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <sub>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <mul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 2
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 2
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_3]] -> 1 <sort = 2>
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 2
// CHECK:           %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_5]] -> 2
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// A variable bound twice is compared the second time.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%a"], slot_kinds = [0, 1], slot_sorts = [2, 3], slot_locs = [{{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 1
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// ':c' and ':o': alternatives of the plan.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %2 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  }, {
    %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction>
  %3 = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand>
  %4 = mpir.alt {
    mpir.yield %2 : <Instruction>
  }, {
    %i_b = mpir.inst <mul> (%3, %2, %3, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction>
  } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
  %5 = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%5, %4, %5, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%a", "y", "%b", "%c"], slot_kinds = [0, 1, 0, 1, 1], slot_sorts = [2, 3, 2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <sub>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_0]], <add>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:               %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:               %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:               %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:               %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_2]], 1 : ui1
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_0]], <add>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:               %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:               %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_3]], 1 : ui1
// CHECK:               %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:               %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_4]] -> 0 <sort = 2>
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 3
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <mul>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:             %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:             %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_5]], <add>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_5]] -> 1
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_5]], 2
// CHECK:               %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][0]
// CHECK:               %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_6]] -> 0 <sort = 2>
// CHECK:               %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][1]
// CHECK:               %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_7]], 1 : ui1
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_5]], <add>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_5]] -> 1
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_5]], 2
// CHECK:               %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][0]
// CHECK:               %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_8]], 1 : ui1
// CHECK:               %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][1]
// CHECK:               %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_9]] -> 0 <sort = 2>
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:             %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_10]] -> 2 <sort = 2>
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 2 <sort = 2>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// A matcher with branches, a flag one fixes, and a constraint in one.
mpir.pattern {
  %ex = mpir.var "ex" : <Boolean>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    %i_r = mpir.inst <lshr> flags(%ex) (%0, %x, %0, %y) <result_name = "r", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <ashr> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %7 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_expr.call call "isKnownNonNegative"(%7) anchor %i_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %8 : <Boolean>
    %9 = mpir.int 0 : ui1 : <Value>
    mpir.bind %ex, %9 : <Boolean>, <Value>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
  %2 = mpir_expr.read %ex : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.int 1 : ui64 : <Integer>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "||"(%2, %5) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ex" : <Boolean>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <ashr> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isKnownNonNegative"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[INT_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[READ_1]], %[[CALL_1]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["ex", "x", "y", "%r"], slot_kinds = [0, 0, 0, 1], slot_sorts = [7, 2, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <lshr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:             %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_0]][2]
// CHECK:             mpir_plan.bind %[[GET_FLAG_0]] -> 0
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 1 <sort = 2>
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_1]] -> 2 <sort = 2>
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <ashr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_2]] -> 1 <sort = 2>
// CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_3]] -> 2 <sort = 2>
// CHECK:             mpir_plan.bind_constant false -> 0
// CHECK:             %[[SLOT_0:.*]] = mpir_plan.slot 1 {var_name = "x"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[SLOT_1:.*]] = mpir_plan.slot 3 {result_name = "r"} : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isKnownNonNegative"(%[[READ_0]]) anchor %[[SLOT_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_plan.check %[[CALL_0]] : <Boolean>
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[SLOT_2:.*]] = mpir_plan.slot 0 {var_name = "ex"} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[SLOT_2]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           %[[SLOT_3:.*]] = mpir_plan.slot 2 {var_name = "y"} : <Operand>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[SLOT_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[SLOT_4:.*]] = mpir_plan.slot 3 {result_name = "r"} : <Instruction>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[INT_0]]) anchor %[[SLOT_4]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[READ_1]], %[[CALL_1]]) anchor %[[SLOT_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_2]] : <Boolean>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// Constraints from metaflags are checked before the pattern's own.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 1 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.read %i_a : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %5 = mpir_expr.call call "hasOneUse"(%4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 {from_metaflag} : <Boolean>
  %6 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "isZero"(%6) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 {from_metaflag} : <Boolean>
  mpir.require %3 : <Boolean>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "y", "%a"], slot_kinds = [0, 0, 1], slot_sorts = [2, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 0 <sort = 2>
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 1 <sort = 2>
// CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[SLOT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_1:.*]] = mpir_plan.slot 0 {var_name = "x"} : <Operand>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[SLOT_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[SLOT_2:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[SLOT_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[SLOT_3:.*]] = mpir_plan.slot 1 {var_name = "y"} : <Operand>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[SLOT_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[SLOT_4:.*]] = mpir_plan.slot 2 {result_name = "a"} : <Instruction>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[INT_0]]) anchor %[[SLOT_4]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir_plan.check %[[CALL_2]] : <Boolean>
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// An instruction one branch reaches and another does not: where it is
// reached again, it is compared if bound, and matched if not.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_p = mpir.inst <shl> (%0, %x, %0, %1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand>
  %3 = mpir.int 1 : ui1 : <Value>
  %i_q = mpir.inst <lshr> (%2, %z, %2, %3) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.alt {
    %i_r = mpir.inst <add> (%4, %i_p, %4, %i_q) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <sub> (%4, %i_p, %4, %i_p) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
  %6 = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <mul> (%6, %5, %6, %i_q) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <shl> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "z" : <Operand>
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[INT_1]]) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_4:.*]] = mpir.inst <mul> (%[[TYPE_3]], %[[ALT_0]], %[[TYPE_3]], %[[INST_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%p", "z", "%q", "%r", "%s"], slot_kinds = [0, 1, 0, 1, 1, 1], slot_sorts = [2, 3, 2, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <mul>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 5
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <add>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_1]], <shl>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_1]] -> 1
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_1]], 2
// CHECK:             %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:             %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_2]] -> 0 <sort = 2>
// CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][1]
// CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_3]], 1 : ui1
// CHECK:             %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:             %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_4]], <lshr>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_4]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_4]], 2
// CHECK:             %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:             %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_5]] -> 2 <sort = 2>
// CHECK:             %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][1]
// CHECK:             %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_6]], 1 : ui1
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <sub>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:             %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:             %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_7]], <shl>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_7]] -> 1
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_7]], 2
// CHECK:             %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:             %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_8]] -> 0 <sort = 2>
// CHECK:             %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][1]
// CHECK:             %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_9]], 1 : ui1
// CHECK:             %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:             %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_10]] -> 1
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_bound 3 is true
// CHECK:             mpir_plan.bind %[[GET_OPERAND_11]] -> 3
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_bound 3 is false
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_11]], <lshr>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_11]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_11]], 2
// CHECK:             %[[GET_OPERAND_12:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][0]
// CHECK:             %[[GET_TYPE_12:.*]] = mpir_plan.get_type %[[GET_OPERAND_12]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_12]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_12]] -> 2 <sort = 2>
// CHECK:             %[[GET_OPERAND_13:.*]] = mpir_plan.get_operand %[[GET_OPERAND_11]][1]
// CHECK:             %[[GET_TYPE_13:.*]] = mpir_plan.get_type %[[GET_OPERAND_13]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_13]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_13]], 1 : ui1
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// An instruction only one branch reaches, and nothing else: after the
// root, it is compared where that branch matched, and searched for where
// it did not.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_p = mpir.inst <shl> (%0, %x, %0, %1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand>
  %3 = mpir.int 1 : ui1 : <Value>
  %i_q = mpir.inst <lshr> (%2, %z, %2, %3) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.alt {
    %i_r = mpir.inst <add> (%4, %i_p, %4, %i_q) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <sub> (%4, %i_p, %4, %i_p) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <shl> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "z" : <Operand>
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[INT_1]]) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%p", "z", "%q", "%r"], slot_kinds = [0, 1, 0, 1, 1], slot_sorts = [2, 3, 2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <shl>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:             %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:             %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_2]], 1 : ui1
// CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_3]], <lshr>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_3]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_3]], 2
// CHECK:             %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][0]
// CHECK:             %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_4]] -> 2 <sort = 2>
// CHECK:             %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][1]
// CHECK:             %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_5]], 1 : ui1
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <sub>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_6]], <shl>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_6]] -> 1
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_6]], 2
// CHECK:             %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][0]
// CHECK:             %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_7]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_7]] -> 0 <sort = 2>
// CHECK:             %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_6]][1]
// CHECK:             %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_8]], 1 : ui1
// CHECK:             %[[GET_OPERAND_9:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_9:.*]] = mpir_plan.get_type %[[GET_OPERAND_9]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_9]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_9]] -> 1
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_bound 3 is true
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_bound 3 is false
// CHECK:             %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_bound 3 is true
// CHECK:               mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 3
// CHECK:               mpir_plan.yield
// CHECK:             }, {
// CHECK:               mpir_plan.check_bound 3 is false
// CHECK:               mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <lshr>
// CHECK:               mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 3
// CHECK:               mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 2
// CHECK:               %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:               %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_10]] -> 2 <sort = 2>
// CHECK:               %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:               %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_11]], 1 : ui1
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// A use no branch fits matches nothing; with ':o' and no name, it is its
// operand.
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand>
  %2 = mpir.type.int 64 : <Type>
  %b = mpir.var "b" : <Operand>
  %3 = mpir.alt  attributes {result_name = "r"} : <Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.int 1 : ui1 : <Value>
  %i_s = mpir.inst <add> (%4, %3, %4, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type>
  %7 = mpir.type.int 32 : <Type>
  %8 = mpir.type.int 64 : <Type>
  %9 = mpir.alt {
    mpir.yield %i_s : <Instruction>
  } attributes {or_self_of = "pick", or_self_region = 0 : i32} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt  attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[ALT_0]], %[[TYPE_3]], %[[INT_0]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "pick", or_self_region = 0 : i32} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["cond", "a", "b", "%r", "%s", ""], slot_kinds = [0, 0, 0, 1, 1, 1], slot_sorts = [7, 2, 2, 3, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.check_bound 3 is true
// CHECK:             mpir_plan.check_bound 3 is false
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_1]], 1 : ui1
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 5
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_bound 3 is true
// CHECK:           mpir_plan.check_bound 3 is false
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// With treatIntAsVec, the types of a cast are compared by their elements;
// a commuted comparison reads the swapped predicate.
mpir.pattern {
  %0 = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type>
  %i_z = mpir.inst <zext> (%0, %x, %1) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 2], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %p = mpir.var "p" : <CmpPredicate>
  %2 = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand>
  %3 = mpir.alt {
    %i_c = mpir.inst <icmp> (%p, %2, %i_z, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction>
  }, {
    %i_c = mpir.inst <icmp> (%p, %2, %y, %2, %i_z) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate, treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction>
  } attributes {commuted, result_name = "c"} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_0:.*]] = mpir.inst <zext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 2], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_1:.*]] = mpir.var "p" : <CmpPredicate>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_1:.*]] = mpir.inst <icmp> (%[[VAR_1]], %[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[VAR_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_1]], %[[TYPE_2]], %[[VAR_2]], %[[TYPE_2]], %[[INST_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate, treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "c"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%z", "p", "y", "%c"], slot_kinds = [0, 1, 0, 0, 1], slot_sorts = [2, 3, 10, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5]
// CHECK:             mpir_plan.bind %[[GET_KEYED_0]] -> 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <zext>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]] <operand_of>
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 1
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:             %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_2]], [1, 8, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:             %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_2]] -> 3 <sort = 2>
// CHECK:             mpir_plan.yield
// CHECK:           }, {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][5] <swapped>
// CHECK:             mpir_plan.bind %[[GET_KEYED_1]] -> 2
// CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_3]] -> 3 <sort = 2>
// CHECK:             %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_5]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_4]], <zext>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_4]] -> 1
// CHECK:             %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]] <operand_of>
// CHECK:             mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_4]], 1
// CHECK:             %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[GET_OPERAND_4]][0]
// CHECK:             %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_7]], [1, 8, 0] <treat_int_as_vec>
// CHECK:             mpir_plan.bind %[[GET_OPERAND_5]] -> 0 <sort = 2>
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// What a use binds a parameter to, read by the branch's constraints: a
// width, a flag the use requires, and a constant operand.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 3 : ui2 : <Value>
  %2 = mpir.int 32 : ui64 : <Value>
  %3 = mpir.int 1 : ui1 : <Value>
  %4 = mpir.alt {
    %i_r = mpir.inst <lshr> (%0, %x, %0, %1) <result_name = "r", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.read %2 : (!mpir.sort<Value>) -> !mpir.sort<Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_r : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.read %3 : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.read %1 : (!mpir.sort<Value>) -> !mpir.sort<Value>
    %16 = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_r : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
  %5 = mpir.type.int 32 : <Type>
  %6 = mpir.int -4 : si3 : <Value>
  %7 = mpir.int 32 : ui64 : <Value>
  %8 = mpir.int 0 : ui1 : <Value>
  %9 = mpir.alt {
    %i_s = mpir.inst <lshr> (%5, %4, %5, %6) <result_name = "s", flags = [2], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.read %7 : (!mpir.sort<Value>) -> !mpir.sort<Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_s : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.read %8 : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.read %6 : (!mpir.sort<Value>) -> !mpir.sort<Value>
    %16 = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_s : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean>
    mpir.yield %i_s : <Instruction>
  } attributes {result_name = "s"} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[INT_1:.*]] = mpir.int 32 : ui64 : <Value>
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "r", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[INT_1]] : (!mpir.sort<Value>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_3]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[INT_2]] : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[INT_0]] : (!mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[READ_2]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_3]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_5:.*]] = mpir.int -4 : si3 : <Value>
// CHECK:           %[[INT_6:.*]] = mpir.int 32 : ui64 : <Value>
// CHECK:           %[[INT_7:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_5]]) <result_name = "s", flags = [2], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[INT_6]] : (!mpir.sort<Value>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[INT_8]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[INT_7]] : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[READ_4]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[INT_5]] : (!mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:             %[[INT_9:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[READ_5]], %[[INT_9]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_7]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_names = ["x", "%r", "%s"], slot_kinds = [0, 1, 1], slot_sorts = [2, 3, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <lshr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:             mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][2] is false
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_0]], <lshr>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:               mpir_plan.check_flag %[[GET_OPERAND_0]][2] is true
// CHECK:               mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
// CHECK:               %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
// CHECK:               %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:               mpir_plan.bind %[[GET_OPERAND_1]] -> 0 <sort = 2>
// CHECK:               %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
// CHECK:               %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:               mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:               mpir_plan.check_constant %[[GET_OPERAND_2]], 3 : ui2
// CHECK:               %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:               %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:               %[[SLOT_0:.*]] = mpir_plan.slot 1 {result_name = "r"} : <Instruction>
// CHECK:               %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[SLOT_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:               %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:               %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[SLOT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:               %[[INT_2:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:               %[[INT_3:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:               %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_2]], %[[INT_3]]) anchor %[[SLOT_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:               %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[SLOT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:               mpir_plan.check %[[CALL_3]] : <Boolean>
// CHECK:               mpir_plan.yield
// CHECK:             }
// CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_3]], -4 : si3
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[SLOT_1:.*]] = mpir_plan.slot 2 {result_name = "s"} : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_4]], %[[INT_5]]) anchor %[[SLOT_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[SLOT_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_6:.*]] = mpir_expr.int -4 : si64 : <Integer>
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_6]], %[[INT_7]]) anchor %[[SLOT_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[SLOT_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_plan.check %[[CALL_7]] : <Boolean>
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }
