// RUN: %metaphir-opt --split-input-file --mpir-to-plan %s | FileCheck %s
// mpir-to-plan compiles a lowered pattern into an mpir_plan.matcher: from each
// root, over every instruction of the function, what to check and bind of it
// and of its operands, in order, then the pattern's constraints.

// Binary instruction matchers: each opcode, with its flags required ('nsw'),
// absent ('!nuw') and captured ('exact:?e'), and the instruction captured
// ('add:?sum').
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":11:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":13:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":15:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [nsw, nuw], flag_modes = [required, negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":17:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [required, negated], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %nuw = mpir.var "nuw" : <Boolean> loc("to-plan.mlir":19:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":21:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %2 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":23:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <sub> flags(%nuw) (%1, %i_a, %1, %2) <result_name = "b", flags = [nuw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":25:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> flags(%[[VAR_2]]) (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_0]]) <flags = [nuw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %prod = mpir.var "prod" : <Instruction> loc("to-plan.mlir":27:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "prod" : <Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-plan.mlir":29:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <mul> capture %prod (%3, %i_b, %3, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":31:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> capture %[[VAR_3]] (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":33:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.int 2 : ui2 : <Value> loc("to-plan.mlir":35:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
  %i_d = mpir.inst <udiv> (%4, %i_c, %4, %5) <result_name = "d", flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":37:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <udiv> (%[[TYPE_3]], %[[INST_2]], %[[TYPE_3]], %[[INT_1]]) <flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %e = mpir.var "e" : <Boolean> loc("to-plan.mlir":39:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "e" : <Boolean>
  %6 = mpir.type.int 32 : <Type> loc("to-plan.mlir":41:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %7 = mpir.int -3 : si3 : <Value> loc("to-plan.mlir":43:1)
// CHECK:           %[[INT_2:.*]] = mpir.int -3 : si3 : <Value>
  %i_e = mpir.inst <sdiv> flags(%e) (%6, %i_d, %6, %7) <result_name = "e", flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":45:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <sdiv> flags(%[[VAR_4]]) (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_2]]) <flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "e"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-plan.mlir":47:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %i_f = mpir.inst <urem> (%8, %i_e, %8, %y) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":49:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <urem> (%[[TYPE_5]], %[[INST_4]], %[[TYPE_5]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-plan.mlir":51:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
  %i_g = mpir.inst <srem> (%9, %i_f, %9, %y) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":53:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <srem> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "g"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type> loc("to-plan.mlir":55:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %11 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":57:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %i_h = mpir.inst <shl> (%10, %i_g, %10, %11) <result_name = "h", flags = [nsw, nuw], flag_modes = [required, required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":59:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <shl> (%[[TYPE_7]], %[[INST_6]], %[[TYPE_7]], %[[INT_3]]) <flags = [nsw, nuw], flag_modes = [required, required], operand_kinds = [typed_value, typed_value], result_name = "h"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.int 32 : <Type> loc("to-plan.mlir":61:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 32 : <Type>
  %i_i = mpir.inst <lshr> (%12, %i_h, %12, %y) <result_name = "i", flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":63:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <lshr> (%[[TYPE_8]], %[[INST_7]], %[[TYPE_8]], %[[VAR_1]]) <flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "i"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-plan.mlir":65:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %i_j = mpir.inst <ashr> (%13, %i_i, %13, %y) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":67:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <ashr> (%[[TYPE_9]], %[[INST_8]], %[[TYPE_9]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "j"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type> loc("to-plan.mlir":69:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.int 255 : ui8 : <Value> loc("to-plan.mlir":71:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 255 : ui8 : <Value>
  %i_k = mpir.inst <and> (%14, %i_j, %14, %15) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":73:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <and> (%[[TYPE_10]], %[[INST_9]], %[[TYPE_10]], %[[INT_4]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "k"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %dj = mpir.var "dj" : <Boolean> loc("to-plan.mlir":75:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "dj" : <Boolean>
  %16 = mpir.type.int 32 : <Type> loc("to-plan.mlir":77:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %i_l = mpir.inst <or> flags(%dj) (%16, %i_k, %16, %y) <result_name = "l", flags = [disjoint], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":79:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <or> flags(%[[VAR_5]]) (%[[TYPE_11]], %[[INST_10]], %[[TYPE_11]], %[[VAR_1]]) <flags = [disjoint], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "l"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-plan.mlir":81:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.int -1 : si1 : <Value> loc("to-plan.mlir":83:1)
// CHECK:           %[[INT_5:.*]] = mpir.int -1 : si1 : <Value>
  %i_m = mpir.inst <xor> (%17, %i_l, %17, %18) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":85:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <xor> (%[[TYPE_12]], %[[INST_11]], %[[TYPE_12]], %[[INT_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.prim float : <Type> loc("to-plan.mlir":87:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.prim float : <Type>
  %fx = mpir.var "fx" : <Operand> loc("to-plan.mlir":89:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "fx" : <Operand>
  %20 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-plan.mlir":91:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_n = mpir.inst <fadd> (%19, %fx, %19, %20) <result_name = "n", flags = [nnan, ninf], flag_modes = [required, required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":93:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <fadd> (%[[TYPE_13]], %[[VAR_6]], %[[TYPE_13]], %[[FLOAT_0]]) <flags = [nnan, ninf], flag_modes = [required, required], operand_kinds = [typed_value, typed_value], result_name = "n"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %21 = mpir.type.prim float : <Type> loc("to-plan.mlir":95:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.prim float : <Type>
  %i_o = mpir.inst <fsub> (%21, %i_n, %21, %fx) <result_name = "o", flags = [fast], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":97:1)
// CHECK:           %[[INST_14:.*]] = mpir.inst <fsub> (%[[TYPE_14]], %[[INST_13]], %[[TYPE_14]], %[[VAR_6]]) <flags = [fast], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "o"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %22 = mpir.type.prim float : <Type> loc("to-plan.mlir":99:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
  %i_p = mpir.inst <fmul> (%22, %i_o, %22, %i_o) <result_name = "p", flags = [nsz, arcp, contract, afn, reassoc], flag_modes = [required, required, required, required, required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":101:1)
// CHECK:           %[[INST_15:.*]] = mpir.inst <fmul> (%[[TYPE_15]], %[[INST_14]], %[[TYPE_15]], %[[INST_14]]) <flags = [nsz, arcp, contract, afn, reassoc], flag_modes = [required, required, required, required, required], operand_kinds = [typed_value, typed_value], result_name = "p"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %23 = mpir.type.prim float : <Type> loc("to-plan.mlir":103:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim float : <Type>
  %24 = mpir.float 2.500000e+00 : f64 -> <Value> loc("to-plan.mlir":105:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 2.500000e+00 : f64 -> <Value>
  %i_q = mpir.inst <fdiv> (%23, %i_p, %23, %24) <result_name = "q", flags = [nnan], flag_modes = [negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":107:1)
// CHECK:           %[[INST_16:.*]] = mpir.inst <fdiv> (%[[TYPE_16]], %[[INST_15]], %[[TYPE_16]], %[[FLOAT_1]]) <flags = [nnan], flag_modes = [negated], operand_kinds = [typed_value, typed_value], result_name = "q"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %25 = mpir.type.prim float : <Type> loc("to-plan.mlir":109:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim float : <Type>
  %i_r = mpir.inst <frem> (%25, %i_q, %25, %fx) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":111:1)
// CHECK:           %[[INST_17:.*]] = mpir.inst <frem> (%[[TYPE_17]], %[[INST_16]], %[[TYPE_17]], %[[VAR_6]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim float : <Type> loc("to-plan.mlir":113:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.prim float : <Type>
  %i_s = mpir.inst <fneg> (%26, %i_r) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":115:1)
// CHECK:           %[[INST_18:.*]] = mpir.inst <fneg> (%[[TYPE_18]], %[[INST_17]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":117:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, variable, instruction, variable, instruction, instruction, variable, instruction, instruction, instruction, instruction, instruction, instruction, instruction, variable, instruction, instruction, variable, instruction, instruction, instruction, instruction, instruction, instruction], slot_sorts = [Value, Value, Instruction, Boolean, Instruction, Instruction, Instruction, Instruction, Boolean, Instruction, Instruction, Instruction, Instruction, Instruction, Instruction, Instruction, Boolean, Instruction, Instruction, Value, Instruction, Instruction, Instruction, Instruction, Instruction, Instruction], slot_names = ["x", "y", "%a", "nuw", "%b", "prod", "%c", "%d", "e", "%e", "%f", "%g", "%h", "%i", "%j", "%k", "dj", "%l", "%m", "fx", "%n", "%o", "%p", "%q", "%r", "%s"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <xor>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 18
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <or>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 17
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[GET_OPERAND_0]][disjoint]
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
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_3]][exact] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_3]], 2
// CHECK:           %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[GET_OPERAND_3]][0]
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_4]], <shl>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_4]] -> 12
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_4]][nsw] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_4]][nuw] is true
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
// CHECK:           %[[GET_FLAG_1:.*]] = mpir_plan.get_flag %[[GET_OPERAND_7]][exact]
// CHECK:           mpir_plan.bind %[[GET_FLAG_1]] -> 8
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_7]], 2
// CHECK:           %[[GET_OPERAND_8:.*]] = mpir_plan.get_operand %[[GET_OPERAND_7]][0]
// CHECK:           %[[GET_TYPE_8:.*]] = mpir_plan.get_type %[[GET_OPERAND_8]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_8]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_8]], <udiv>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_8]] -> 7
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_8]][exact] is true
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
// CHECK:           %[[GET_FLAG_2:.*]] = mpir_plan.get_flag %[[GET_OPERAND_10]][nuw]
// CHECK:           mpir_plan.bind %[[GET_FLAG_2]] -> 3
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_10]], 2
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[GET_OPERAND_10]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_11]], <add>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 2
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][nsw] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][nuw] is false
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
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_27]][nnan] is false
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_27]], 2
// CHECK:           %[[GET_OPERAND_28:.*]] = mpir_plan.get_operand %[[GET_OPERAND_27]][0]
// CHECK:           %[[GET_TYPE_28:.*]] = mpir_plan.get_type %[[GET_OPERAND_28]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_28]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_28]], <fmul>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_28]] -> 22
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][nsz] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][arcp] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][contract] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][afn] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_28]][reassoc] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_28]], 2
// CHECK:           %[[GET_OPERAND_29:.*]] = mpir_plan.get_operand %[[GET_OPERAND_28]][0]
// CHECK:           %[[GET_TYPE_29:.*]] = mpir_plan.get_type %[[GET_OPERAND_29]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_29]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_29]], <fsub>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_29]] -> 21
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_29]][fast] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_29]], 2
// CHECK:           %[[GET_OPERAND_30:.*]] = mpir_plan.get_operand %[[GET_OPERAND_29]][0]
// CHECK:           %[[GET_TYPE_30:.*]] = mpir_plan.get_type %[[GET_OPERAND_30]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_30]], [0, 2]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_30]], <fadd>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_30]] -> 20
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_30]][nnan] is true
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_30]][ninf] is true
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":342:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.global "callee" : <Value> loc("to-plan.mlir":344:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "callee" : <Value>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":346:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":348:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %3 = mpir.type.int 8 : <Type> loc("to-plan.mlir":350:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 8 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":352:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <call> (%0, %1, %2, %x, %3, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":354:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":356:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.global "llvm.umax.i32" : <Value> loc("to-plan.mlir":358:1)
// CHECK:           %[[GLOBAL_1:.*]] = mpir.global "llvm.umax.i32" : <Value>
  %6 = mpir.type.int 32 : <Type> loc("to-plan.mlir":360:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %7 = mpir.type.int 32 : <Type> loc("to-plan.mlir":362:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":364:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <call> (%4, %5, %6, %i_a, %7, %8) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":366:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_3]], %[[GLOBAL_1]], %[[TYPE_4]], %[[INST_0]], %[[TYPE_5]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat> loc("to-plan.mlir":368:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %9 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":370:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %id = mpir.var "id" : <IntrinsicID> loc("to-plan.mlir":372:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "id" : <IntrinsicID>
  %10 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":374:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-plan.mlir":376:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
  %11 = mpir.type.int 1 : <Type> loc("to-plan.mlir":378:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
  %12 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":380:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%9, %id, %10, %v, %11, %12) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":382:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_6]], %[[VAR_3]], %[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-plan.mlir":384:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.type.int 32 : <Type> loc("to-plan.mlir":386:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.type.func %13(%14) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":388:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.func %[[TYPE_9]](%[[TYPE_10]]) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %f = mpir.var "f" : <Function> loc("to-plan.mlir":390:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "f" : <Function>
  %16 = mpir.type.int 32 : <Type> loc("to-plan.mlir":392:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %i_d = mpir.inst <call> (%15, %f, %16, %i_a) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":394:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <call> (%[[TYPE_11]], %[[VAR_5]], %[[TYPE_12]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %ret = mpir.var "ret" : <Type> loc("to-plan.mlir":396:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "ret" : <Type>
  %id2 = mpir.var "id2" : <IntrinsicID> loc("to-plan.mlir":398:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "id2" : <IntrinsicID>
  %types = mpir.var "types" : <TypeArray> loc("to-plan.mlir":400:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "types" : <TypeArray>
  %values = mpir.var "values" : <ValueArray> loc("to-plan.mlir":402:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "values" : <ValueArray>
  %i_e = mpir.inst <call> (%ret, %id2, %types, %values) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value_array]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-plan.mlir":404:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <call> (%[[VAR_6]], %[[VAR_7]], %[[VAR_8]], %[[VAR_9]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value_array], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-plan.mlir":406:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.global "first" : <Value> loc("to-plan.mlir":408:1)
// CHECK:           %[[GLOBAL_2:.*]] = mpir.global "first" : <Value>
  %19 = mpir.type.int 32 : <Type> loc("to-plan.mlir":410:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %rest_types = mpir.var "rest_types" : <TypeArray> loc("to-plan.mlir":412:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "rest_types" : <TypeArray>
  %rest_values = mpir.var "rest_values" : <ValueArray> loc("to-plan.mlir":414:1)
// CHECK:           %[[VAR_11:.*]] = mpir.var "rest_values" : <ValueArray>
  %i_f = mpir.inst <call> (%17, %18, %19, %i_a, %rest_types, %rest_values) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value_array]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-plan.mlir":416:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <call> (%[[TYPE_13]], %[[GLOBAL_2]], %[[TYPE_14]], %[[INST_0]], %[[VAR_10]], %[[VAR_11]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value_array], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %20 = mpir.type.prim void : <Type> loc("to-plan.mlir":418:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim void : <Type>
  %21 = mpir.global "take" : <Value> loc("to-plan.mlir":420:1)
// CHECK:           %[[GLOBAL_3:.*]] = mpir.global "take" : <Value>
  %22 = mpir.type.prim label : <Type> loc("to-plan.mlir":422:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim label : <Type>
  %target = mpir.var "target" : <BasicBlock> loc("to-plan.mlir":424:1)
// CHECK:           %[[VAR_12:.*]] = mpir.var "target" : <BasicBlock>
  %i_lb = mpir.inst <call> (%20, %21, %22, %target) <result_name = "lb", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-plan.mlir":426:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <call> (%[[TYPE_15]], %[[GLOBAL_3]], %[[TYPE_16]], %[[VAR_12]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value], result_name = "lb"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %23 = mpir.type.int 32 : <Type> loc("to-plan.mlir":428:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %24 = mpir.global "0" : <Value> loc("to-plan.mlir":430:1)
// CHECK:           %[[GLOBAL_4:.*]] = mpir.global "0" : <Value>
  %25 = mpir.type.int 32 : <Type> loc("to-plan.mlir":432:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
  %i_num = mpir.inst <call> (%23, %24, %25, %i_a) <result_name = "num", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":434:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <call> (%[[TYPE_17]], %[[GLOBAL_4]], %[[TYPE_18]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value], result_name = "num"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim void : <Type> loc("to-plan.mlir":436:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.prim void : <Type>
  %27 = mpir.global "sink" : <Value> loc("to-plan.mlir":438:1)
// CHECK:           %[[GLOBAL_5:.*]] = mpir.global "sink" : <Value>
  %28 = mpir.type.int 32 : <Type> loc("to-plan.mlir":440:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 32 : <Type>
  %29 = mpir.inst <call> (%26, %27, %28, %i_f) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":442:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <call> (%[[TYPE_19]], %[[GLOBAL_5]], %[[TYPE_20]], %[[INST_5]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":444:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, variable, variable, variable, instruction, variable, instruction, variable, variable, variable, variable, instruction, variable, variable, instruction, variable, instruction, instruction, instruction], slot_sorts = [Value, Value, Instruction, Instruction, Nat, IntrinsicID, Value, Instruction, Function, Instruction, Type, IntrinsicID, TypeArray, ValueArray, Instruction, TypeArray, ValueArray, Instruction, BasicBlock, Instruction, Instruction, Instruction], slot_names = ["x", "y", "%a", "%b", "n", "id", "v", "%c", "f", "%d", "ret", "id2", "types", "values", "%e", "rest_types", "rest_values", "%f", "target", "%lb", "%num", "call"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 64 : <Type> loc("to-plan.mlir":575:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 64 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":577:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":579:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_t = mpir.inst <trunc> (%0, %x, %1) <result_name = "t", flags = [nuw], flag_modes = [required], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":581:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <flags = [nuw], flag_modes = [required], operand_kinds = [typed_value, type_only], result_name = "t"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":583:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.type.int 64 : <Type> loc("to-plan.mlir":585:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
  %i_z = mpir.inst <zext> (%2, %i_t, %3) <result_name = "z", flags = [nneg], flag_modes = [required], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":587:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_3]]) <flags = [nneg], flag_modes = [required], operand_kinds = [typed_value, type_only], result_name = "z"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":589:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %wide = mpir.var "wide" : <Nat> loc("to-plan.mlir":591:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "wide" : <Nat>
  %5 = mpir.type.meta_int %wide : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":593:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %i_s = mpir.inst <sext> (%4, %i_t, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":595:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <sext> (%[[TYPE_4]], %[[INST_0]], %[[TYPE_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim double : <Type> loc("to-plan.mlir":597:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand> loc("to-plan.mlir":599:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "d" : <Operand>
  %7 = mpir.type.prim float : <Type> loc("to-plan.mlir":601:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim float : <Type>
  %i_ft = mpir.inst <fptrunc> (%6, %d, %7) <result_name = "ft", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":603:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <fptrunc> (%[[TYPE_6]], %[[VAR_2]], %[[TYPE_7]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "ft"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim float : <Type> loc("to-plan.mlir":605:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim float : <Type>
  %9 = mpir.type.prim double : <Type> loc("to-plan.mlir":607:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim double : <Type>
  %i_fe = mpir.inst <fpext> (%8, %i_ft, %9) <result_name = "fe", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":609:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <fpext> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "fe"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type> loc("to-plan.mlir":611:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim double : <Type>
  %11 = mpir.type.int 32 : <Type> loc("to-plan.mlir":613:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %i_fu = mpir.inst <fptoui> (%10, %i_fe, %11) <result_name = "fu", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":615:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <fptoui> (%[[TYPE_10]], %[[INST_4]], %[[TYPE_11]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "fu"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type> loc("to-plan.mlir":617:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.prim double : <Type>
  %13 = mpir.type.int 32 : <Type> loc("to-plan.mlir":619:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %i_fs = mpir.inst <fptosi> (%12, %i_fe, %13) <result_name = "fs", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":621:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <fptosi> (%[[TYPE_12]], %[[INST_4]], %[[TYPE_13]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "fs"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type> loc("to-plan.mlir":623:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.type.prim half : <Type> loc("to-plan.mlir":625:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim half : <Type>
  %i_uf = mpir.inst <uitofp> (%14, %i_fu, %15) <result_name = "uf", flags = [nneg], flag_modes = [required], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":627:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <uitofp> (%[[TYPE_14]], %[[INST_5]], %[[TYPE_15]]) <flags = [nneg], flag_modes = [required], operand_kinds = [typed_value, type_only], result_name = "uf"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %16 = mpir.type.int 32 : <Type> loc("to-plan.mlir":629:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %17 = mpir.type.prim bfloat : <Type> loc("to-plan.mlir":631:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim bfloat : <Type>
  %i_sf = mpir.inst <sitofp> (%16, %i_fs, %17) <result_name = "sf", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":633:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <sitofp> (%[[TYPE_16]], %[[INST_6]], %[[TYPE_17]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "sf"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %18 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":635:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-plan.mlir":637:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %19 = mpir.type.int 64 : <Type> loc("to-plan.mlir":639:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 64 : <Type>
  %i_pi = mpir.inst <ptrtoint> (%18, %p, %19) <result_name = "pi", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":641:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <ptrtoint> (%[[TYPE_18]], %[[VAR_3]], %[[TYPE_19]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "pi"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %20 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":643:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %21 = mpir.type.int 64 : <Type> loc("to-plan.mlir":645:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 64 : <Type>
  %i_pa = mpir.inst <ptrtoaddr> (%20, %p, %21) <result_name = "pa", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":647:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <ptrtoaddr> (%[[TYPE_20]], %[[VAR_3]], %[[TYPE_21]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "pa"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %22 = mpir.type.int 64 : <Type> loc("to-plan.mlir":649:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 64 : <Type>
  %23 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":651:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %i_ip = mpir.inst <inttoptr> (%22, %i_pi, %23) <result_name = "ip", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":653:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <inttoptr> (%[[TYPE_22]], %[[INST_9]], %[[TYPE_23]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "ip"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type> loc("to-plan.mlir":655:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 32 : <Type>
  %25 = mpir.type.seq vector 2 x %24 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":657:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.seq vector 2 x %[[TYPE_24]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-plan.mlir":659:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
  %26 = mpir.type.int 64 : <Type> loc("to-plan.mlir":661:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.int 64 : <Type>
  %i_bc = mpir.inst <bitcast> (%25, %v, %26) <result_name = "bc", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":663:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <bitcast> (%[[TYPE_25]], %[[VAR_4]], %[[TYPE_26]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "bc"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %27 = mpir.type.int 32 : <Type> loc("to-plan.mlir":665:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 32 : <Type>
  %i_fr = mpir.inst <freeze> (%27, %i_t) <result_name = "fr", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":667:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "fr"> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":669:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, instruction, variable, instruction, variable, instruction, instruction, instruction, instruction, instruction, instruction, variable, instruction, instruction, instruction, variable, instruction, instruction], slot_sorts = [Value, Instruction, Instruction, Nat, Instruction, Value, Instruction, Instruction, Instruction, Instruction, Instruction, Instruction, Value, Instruction, Instruction, Instruction, Value, Instruction, Instruction], slot_names = ["x", "%t", "%z", "wide", "%s", "d", "%ft", "%fe", "%fu", "%fs", "%uf", "%sf", "p", "%pi", "%pa", "%ip", "v", "%bc", "%fr"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <zext>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 64, 0]
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][nneg] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 1
// CHECK:           %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:           %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_0]], <trunc>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:           %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_2]], [1, 32, 0]
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_0]][nuw] is true
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
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_2]][nneg] is true
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.keyword eq : <Value> loc("to-plan.mlir":810:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword eq : <Value>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":812:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":814:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":816:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c1 = mpir.inst <icmp> (%0, %1, %x, %1, %2) <result_name = "c1", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":818:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c1"> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.keyword ult : <Value> loc("to-plan.mlir":820:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword ult : <Value>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":822:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":824:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_c2 = mpir.inst <icmp> (%3, %4, %x, %4, %y) <result_name = "c2", flags = [samesign], flag_modes = [required], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":826:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [samesign], flag_modes = [required], operand_kinds = [predicate, typed_value, typed_value], result_name = "c2"> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %pred = mpir.var "pred" : <CmpPredicate> loc("to-plan.mlir":828:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "pred" : <CmpPredicate>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":830:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c3 = mpir.inst <icmp> (%pred, %5, %x, %5, %y) <result_name = "c3", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":832:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_2]], %[[TYPE_2]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c3"> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.keyword olt : <Value> loc("to-plan.mlir":834:1)
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword olt : <Value>
  %7 = mpir.type.prim float : <Type> loc("to-plan.mlir":836:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim float : <Type>
  %f = mpir.var "f" : <Operand> loc("to-plan.mlir":838:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "f" : <Operand>
  %8 = mpir.float 0.000000e+00 : f64 -> <Value> loc("to-plan.mlir":840:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 0.000000e+00 : f64 -> <Value>
  %i_c4 = mpir.inst <fcmp> (%6, %7, %f, %7, %8) <result_name = "c4", flags = [nnan], flag_modes = [required], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":842:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <fcmp> (%[[KEYWORD_2]], %[[TYPE_3]], %[[VAR_3]], %[[TYPE_3]], %[[FLOAT_0]]) <flags = [nnan], flag_modes = [required], operand_kinds = [predicate, typed_value, typed_value], result_name = "c4"> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %fpred = mpir.var "fpred" : <CmpPredicate> loc("to-plan.mlir":844:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "fpred" : <CmpPredicate>
  %9 = mpir.type.prim double : <Type> loc("to-plan.mlir":846:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand> loc("to-plan.mlir":848:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "d" : <Operand>
  %e = mpir.var "e" : <Operand> loc("to-plan.mlir":850:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "e" : <Operand>
  %i_c5 = mpir.inst <fcmp> (%fpred, %9, %d, %9, %e) <result_name = "c5", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":852:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <fcmp> (%[[VAR_4]], %[[TYPE_4]], %[[VAR_5]], %[[TYPE_4]], %[[VAR_6]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c5"> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 1 : <Type> loc("to-plan.mlir":854:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 1 : <Type>
  %11 = mpir.type.int 32 : <Type> loc("to-plan.mlir":856:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
  %12 = mpir.type.int 32 : <Type> loc("to-plan.mlir":858:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %i_s1 = mpir.inst <select> (%10, %i_c1, %11, %x, %12, %y) <result_name = "s1", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":860:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[VAR_0]], %[[TYPE_7]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "s1"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 1 : <Type> loc("to-plan.mlir":862:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
  %14 = mpir.type.prim float : <Type> loc("to-plan.mlir":864:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim float : <Type>
  %15 = mpir.type.prim float : <Type> loc("to-plan.mlir":866:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim float : <Type>
  %16 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-plan.mlir":868:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_s2 = mpir.inst <select> (%13, %i_c4, %14, %f, %15, %16) <result_name = "s2", flags = [nnan], flag_modes = [required], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":870:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <select> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]], %[[VAR_3]], %[[TYPE_10]], %[[FLOAT_1]]) <flags = [nnan], flag_modes = [required], operand_kinds = [typed_value, typed_value, typed_value], result_name = "s2"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 1 : <Type> loc("to-plan.mlir":872:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 1 : <Type>
  %18 = mpir.type.seq vector 2 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":874:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 2 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %mask = mpir.var "mask" : <Operand> loc("to-plan.mlir":876:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "mask" : <Operand>
  %19 = mpir.type.int 32 : <Type> loc("to-plan.mlir":878:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %20 = mpir.type.seq vector 2 x %19 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":880:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq vector 2 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-plan.mlir":882:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "v" : <Operand>
  %21 = mpir.type.int 32 : <Type> loc("to-plan.mlir":884:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.type.seq vector 2 x %21 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":886:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %23 = mpir.keyword zeroinitializer : <Value> loc("to-plan.mlir":888:1)
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
  %i_s3 = mpir.inst <select> (%18, %mask, %20, %v, %22, %23) <result_name = "s3", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":890:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_12]], %[[VAR_7]], %[[TYPE_14]], %[[VAR_8]], %[[TYPE_16]], %[[KEYWORD_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "s3"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":892:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, variable, variable, instruction, instruction, instruction, variable, variable, instruction], slot_sorts = [Value, Instruction, Value, Instruction, CmpPredicate, Instruction, Value, Instruction, CmpPredicate, Value, Value, Instruction, Instruction, Instruction, Value, Value, Instruction], slot_names = ["x", "%c1", "y", "%c2", "pred", "%c3", "f", "%c4", "fpred", "d", "e", "%c5", "%s1", "%s2", "mask", "v", "%s3"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][samesign] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate]
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
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_1]][predicate]
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
// CHECK:           %[[GET_KEYED_2:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_2]][predicate]
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
// CHECK:           %[[GET_KEYED_3:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_6]][predicate]
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
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_4]][nnan] is true
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_4]], 3
// CHECK:           %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_4]][0]
// CHECK:           %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_11]], [1, 1, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_11]], <fcmp>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_11]] -> 7
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_11]][nnan] is true
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_11]], 2
// CHECK:           %[[GET_KEYED_4:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_11]][predicate]
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1021:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":1023:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1025:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1027:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1029:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int -1 : si1 : <Value> loc("to-plan.mlir":1031:1)
// CHECK:           %[[INT_1:.*]] = mpir.int -1 : si1 : <Value>
  %i_b = mpir.inst <add> (%2, %i_a, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1033:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 128 : <Type> loc("to-plan.mlir":1035:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 128 : <Type>
  %w = mpir.var "w" : <Operand> loc("to-plan.mlir":1037:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Operand>
  %5 = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value> loc("to-plan.mlir":1039:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value>
  %i_c = mpir.inst <add> (%4, %w, %4, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1041:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[VAR_1]], %[[TYPE_2]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1043:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
  %bit = mpir.var "bit" : <Boolean> loc("to-plan.mlir":1045:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "bit" : <Boolean>
  %7 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":1047:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %i_d = mpir.inst <add> (%6, %bit, %6, %7) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1049:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[VAR_2]], %[[TYPE_3]], %[[INT_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1051:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %9 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1053:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 0 : ui1 : <Value>
  %i_e = mpir.inst <add> (%8, %i_d, %8, %9) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1055:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <add> (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_4]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type> loc("to-plan.mlir":1057:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim double : <Type>
  %fx = mpir.var "fx" : <Operand> loc("to-plan.mlir":1059:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "fx" : <Operand>
  %11 = mpir.float 1.500000e-03 : f64 -> <Value> loc("to-plan.mlir":1061:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.500000e-03 : f64 -> <Value>
  %i_f = mpir.inst <fadd> (%10, %fx, %10, %11) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1063:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <fadd> (%[[TYPE_5]], %[[VAR_3]], %[[TYPE_5]], %[[FLOAT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type> loc("to-plan.mlir":1065:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
  %13 = mpir.float 0x7FF0000000000000 : f64 -> <Value> loc("to-plan.mlir":1067:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 0x7FF0000000000000 : f64 -> <Value>
  %i_g = mpir.inst <fadd> (%12, %i_f, %12, %13) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1069:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <fadd> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[FLOAT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "g"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1071:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean> loc("to-plan.mlir":1073:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "c" : <Boolean>
  %15 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":1075:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %16 = mpir.keyword null : <Value> loc("to-plan.mlir":1077:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
  %17 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":1079:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %18 = mpir.global "global" : <Value> loc("to-plan.mlir":1081:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "global" : <Value>
  %i_h = mpir.inst <select> (%14, %c, %15, %16, %17, %18) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1083:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[KEYWORD_0]], %[[TYPE_9]], %[[GLOBAL_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "h"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1085:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 1 : <Type>
  %20 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1087:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %21 = mpir.keyword poison : <Value> loc("to-plan.mlir":1089:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword poison : <Value>
  %22 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1091:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %23 = mpir.keyword undef : <Value> loc("to-plan.mlir":1093:1)
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword undef : <Value>
  %i_i = mpir.inst <select> (%19, %c, %20, %21, %22, %23) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1095:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <select> (%[[TYPE_10]], %[[VAR_4]], %[[TYPE_11]], %[[KEYWORD_1]], %[[TYPE_12]], %[[KEYWORD_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "i"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1097:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 1 : <Type>
  %25 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1099:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %26 = mpir.type.seq vector 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1101:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.seq vector 2 x %[[TYPE_14]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.keyword zeroinitializer : <Value> loc("to-plan.mlir":1103:1)
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
  %28 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1105:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %29 = mpir.type.seq vector 2 x %28 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1107:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.seq vector 2 x %[[TYPE_16]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %30 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1109:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
  %31 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":1111:1)
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
  %32 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1113:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 32 : <Type>
  %33 = mpir.int 2 : ui2 : <Value> loc("to-plan.mlir":1115:1)
// CHECK:           %[[INT_6:.*]] = mpir.int 2 : ui2 : <Value>
  %34 = mpir.aggregate vector(%30, %31, %32, %33) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-plan.mlir":1117:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_18]], %[[INT_5]], %[[TYPE_19]], %[[INT_6]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_j = mpir.inst <select> (%24, %c, %26, %27, %29, %34) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1119:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <select> (%[[TYPE_13]], %[[VAR_4]], %[[TYPE_15]], %[[KEYWORD_3]], %[[TYPE_17]], %[[AGGREGATE_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "j"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %35 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1121:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 1 : <Type>
  %36 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1123:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 8 : <Type>
  %37 = mpir.type.seq array 2 x %36 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1125:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.seq array 2 x %[[TYPE_21]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %38 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1127:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.int 8 : <Type>
  %39 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":1129:1)
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
  %40 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1131:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
  %41 = mpir.int 2 : ui2 : <Value> loc("to-plan.mlir":1133:1)
// CHECK:           %[[INT_8:.*]] = mpir.int 2 : ui2 : <Value>
  %42 = mpir.aggregate array(%38, %39, %40, %41) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-plan.mlir":1135:1)
// CHECK:           %[[AGGREGATE_1:.*]] = mpir.aggregate array(%[[TYPE_23]], %[[INT_7]], %[[TYPE_24]], %[[INT_8]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %43 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1137:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 8 : <Type>
  %44 = mpir.type.seq array 2 x %43 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1139:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %arr = mpir.var "arr" : <Operand> loc("to-plan.mlir":1141:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "arr" : <Operand>
  %i_k = mpir.inst <select> (%35, %c, %37, %42, %44, %arr) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1143:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <select> (%[[TYPE_20]], %[[VAR_4]], %[[TYPE_22]], %[[AGGREGATE_1]], %[[TYPE_26]], %[[VAR_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "k"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %45 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1145:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 1 : <Type>
  %46 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1147:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.int 32 : <Type>
  %47 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1149:1)
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 8 : <Type>
  %48 = mpir.type.struct{%46, %47} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1151:1)
// CHECK:           %[[TYPE_30:.*]] = mpir.type.struct{%[[TYPE_28]], %[[TYPE_29]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %49 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1153:1)
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
  %50 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":1155:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 1 : ui1 : <Value>
  %51 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1157:1)
// CHECK:           %[[TYPE_32:.*]] = mpir.type.int 8 : <Type>
  %52 = mpir.int 2 : ui2 : <Value> loc("to-plan.mlir":1159:1)
// CHECK:           %[[INT_10:.*]] = mpir.int 2 : ui2 : <Value>
  %53 = mpir.aggregate struct(%49, %50, %51, %52) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-plan.mlir":1161:1)
// CHECK:           %[[AGGREGATE_2:.*]] = mpir.aggregate struct(%[[TYPE_31]], %[[INT_9]], %[[TYPE_32]], %[[INT_10]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %54 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1163:1)
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
  %55 = mpir.type.int 8 : <Type> loc("to-plan.mlir":1165:1)
// CHECK:           %[[TYPE_34:.*]] = mpir.type.int 8 : <Type>
  %56 = mpir.type.struct{%54, %55} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":1167:1)
// CHECK:           %[[TYPE_35:.*]] = mpir.type.struct{%[[TYPE_33]], %[[TYPE_34]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %st = mpir.var "st" : <Operand> loc("to-plan.mlir":1169:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "st" : <Operand>
  %i_l = mpir.inst <select> (%45, %c, %48, %53, %56, %st) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1171:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <select> (%[[TYPE_27]], %[[VAR_4]], %[[TYPE_30]], %[[AGGREGATE_2]], %[[TYPE_35]], %[[VAR_6]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "l"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":1173:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, instruction, variable, instruction, variable, instruction, instruction, variable, instruction, instruction, variable, instruction, instruction, instruction, variable, instruction, variable, instruction], slot_sorts = [Value, Instruction, Instruction, Value, Instruction, Boolean, Instruction, Instruction, Value, Instruction, Instruction, Boolean, Instruction, Instruction, Instruction, Value, Instruction, Value, Instruction], slot_names = ["x", "%a", "%b", "w", "%c", "bit", "%d", "%e", "fx", "%f", "%g", "c", "%h", "%i", "%j", "arr", "%k", "st", "%l"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_22]], vector, 2
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
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_24]], array, 2
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
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_27]], struct, 2
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
// CHECK-LABEL:   mpir.constraint_def @inRange <param_names = ["v", "lo", "hi"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>, %arg1: !mpir.sort<Unknown>, %arg2: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg1 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-plan.mlir":1359:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-plan.mlir":1361:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %2 = mpir_expr.call call "ule"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1363:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ule"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-plan.mlir":1365:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %4 = mpir_expr.read %arg2 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-plan.mlir":1367:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_2]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %5 = mpir_expr.call call "ule"(%3, %4) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1369:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "ule"(%[[READ_2]], %[[READ_3]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1371:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %6 : <Boolean> loc("to-plan.mlir":1373:1)
// CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
} loc("to-plan.mlir":1375:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %n = mpir.var "n" : <Nat> loc("to-plan.mlir":1379:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":1381:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":1383:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %c = mpir.var "c" : <Operand> loc("to-plan.mlir":1385:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "c" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %c) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1387:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("to-plan.mlir":1389:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %2 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":1391:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1393:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("to-plan.mlir":1395:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %5 = mpir_expr.int 64 : ui64 : <Integer> loc("to-plan.mlir":1397:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 64 : ui64 : <Integer>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1399:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "||"(%3, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1401:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("to-plan.mlir":1403:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
  %8 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1405:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "isZero"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1407:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.call unary "!"(%9) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1409:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call unary "!"(%[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %11 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1411:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %12 = mpir_expr.int 1 : ui64 : <Integer> loc("to-plan.mlir":1413:1)
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %13 = mpir_expr.int 8 : ui64 : <Integer> loc("to-plan.mlir":1415:1)
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 8 : ui64 : <Integer>
  %14 = mpir_expr.apply @inRange(%11, %12, %13) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1417:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @inRange(%[[READ_3]], %[[INT_2]], %[[INT_3]]) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  %15 = mpir_expr.call binary "&&"(%10, %14) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1419:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %15 : <Boolean> loc("to-plan.mlir":1421:1)
// CHECK:           mpir.require %[[CALL_5]] : <Boolean>
  %16 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1423:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.int 2 : ui64 : <Integer> loc("to-plan.mlir":1425:1)
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %18 = mpir_expr.call binary "*"(%16, %17) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-plan.mlir":1427:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "*"(%[[READ_4]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %19 = mpir_expr.int 1 : ui64 : <Integer> loc("to-plan.mlir":1429:1)
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %20 = mpir_expr.call binary "+"(%18, %19) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-plan.mlir":1431:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "+"(%[[CALL_6]], %[[INT_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %21 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1433:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %22 = mpir_expr.call binary "-"(%20, %21) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-plan.mlir":1435:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "-"(%[[CALL_7]], %[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %23 = mpir_expr.int 3 : ui64 : <Integer> loc("to-plan.mlir":1437:1)
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
  %24 = mpir_expr.call unary "-"(%23) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-plan.mlir":1439:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call unary "-"(%[[INT_6]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %25 = mpir_expr.call binary "!="(%22, %24) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1441:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_8]], %[[CALL_9]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 : <Boolean> loc("to-plan.mlir":1443:1)
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
  %26 = mpir_expr.str "i8" : <String> loc("to-plan.mlir":1445:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "i8" : <String>
  %27 = mpir_expr.str "i16" : <String> loc("to-plan.mlir":1447:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "i16" : <String>
  %28 = mpir_expr.array %26, %27 : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray> loc("to-plan.mlir":1449:1)
// CHECK:           %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
  %29 = mpir_expr.int 0 : ui64 : <Integer> loc("to-plan.mlir":1451:1)
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
  %30 = mpir_expr.index %28[%29] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String> loc("to-plan.mlir":1453:1)
// CHECK:           %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_7]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
  %31 = mpir_expr.str "i8" : <String> loc("to-plan.mlir":1455:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "i8" : <String>
  %32 = mpir_expr.call binary "=="(%30, %31) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1457:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %32 : <Boolean> loc("to-plan.mlir":1459:1)
// CHECK:           mpir.require %[[CALL_11]] : <Boolean>
  %33 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1461:1)
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %34 = mpir_expr.call call "bitWidth"(%33) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-plan.mlir":1463:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %35 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":1465:1)
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %36 = mpir_expr.call binary "=="(%34, %35) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1467:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[INT_8]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1469:1)
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %38 = mpir_expr.str "Argument" : <String> loc("to-plan.mlir":1471:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "Argument" : <String>
  %39 = mpir_expr.call call "isa"(%37, %38) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1473:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "isa"(%[[READ_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.call binary "&&"(%36, %39) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1475:1)
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call binary "&&"(%[[CALL_13]], %[[CALL_14]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %40 : <Boolean> loc("to-plan.mlir":1477:1)
// CHECK:           mpir.require %[[CALL_15]] : <Boolean>
  %cmp = mpir.var "cmp" : <Instruction> loc("to-plan.mlir":1479:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "cmp" : <Instruction>
  %p = mpir.var "p" : <CmpPredicate> loc("to-plan.mlir":1481:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "p" : <CmpPredicate>
  %41 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":1483:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %42 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1485:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 0 : ui1 : <Value>
  %i_b = mpir.inst <icmp> capture %cmp (%p, %41, %i_a, %41, %42) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1487:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> capture %[[VAR_3]] (%[[VAR_4]], %[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_9]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "b"> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %43 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":1489:1)
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %44 = mpir_expr.read %cmp : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-plan.mlir":1491:1)
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %45 = mpir_expr.call call "isKnownNonZero"(%43, %44) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1493:1)
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_8]], %[[READ_9]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %46 = mpir_expr.read %p : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String> loc("to-plan.mlir":1495:1)
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
  %47 = mpir_expr.str "eq" : <String> loc("to-plan.mlir":1497:1)
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "eq" : <String>
  %48 = mpir_expr.call binary "=="(%46, %47) anchor %i_b : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1499:1)
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[READ_10]], %[[STR_4]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %49 = mpir_expr.call binary "&&"(%45, %48) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1501:1)
// CHECK:           %[[CALL_18:.*]] = mpir_expr.call binary "&&"(%[[CALL_16]], %[[CALL_17]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %49 : <Boolean> loc("to-plan.mlir":1503:1)
// CHECK:           mpir.require %[[CALL_18]] : <Boolean>
  %50 = mpir_expr.bool true : <Boolean> loc("to-plan.mlir":1505:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
  mpir.require %50 : <Boolean> loc("to-plan.mlir":1507:1)
// CHECK:           mpir.require %[[BOOL_0]] : <Boolean>
  %51 = mpir_expr.bool false : <Boolean> loc("to-plan.mlir":1509:1)
// CHECK:           %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
  %52 = mpir_expr.call unary "!"(%51) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":1511:1)
// CHECK:           %[[CALL_19:.*]] = mpir_expr.call unary "!"(%[[BOOL_1]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %52 : <Boolean> loc("to-plan.mlir":1513:1)
// CHECK:           mpir.require %[[CALL_19]] : <Boolean>
} loc("to-plan.mlir":1515:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, variable, instruction, variable, variable, instruction], slot_sorts = [Nat, Value, Value, Instruction, Instruction, CmpPredicate, Instruction], slot_names = ["n", "x", "c", "%a", "cmp", "p", "%b"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 6
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate]
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
// CHECK-LABEL:   mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock> loc("to-plan.mlir":1624:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
  %0 = mpir.keyword ult : <Value> loc("to-plan.mlir":1626:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword ult : <Value>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1628:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":1630:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.int 10 : ui4 : <Value> loc("to-plan.mlir":1632:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 10 : ui4 : <Value>
  %i_c = mpir.inst <icmp> block %entry (%0, %1, %x, %1, %2) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1634:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> block %[[VAR_0]] (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c"> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1636:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
  %4 = mpir.type.prim label : <Type> loc("to-plan.mlir":1638:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.prim label : <Type>
  %loop = mpir.var "loop" : <BasicBlock> loc("to-plan.mlir":1640:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "loop" : <BasicBlock>
  %5 = mpir.type.prim label : <Type> loc("to-plan.mlir":1642:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim label : <Type>
  %exit = mpir.var "exit" : <BasicBlock> loc("to-plan.mlir":1644:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "exit" : <BasicBlock>
  %6 = mpir.inst <br> block %entry (%3, %i_c, %4, %loop, %5, %exit) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1646:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <br> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1648:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1650:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %n = mpir.var "n" : <Operand> loc("to-plan.mlir":1652:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "n" : <Operand>
  %i_i = mpir.inst <phi> block %loop (%7, %8, %entry, %7, %n, %loop) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [typed_value, value, typed_value, value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1654:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <phi> block %[[VAR_2]] (%[[TYPE_4]], %[[INT_1]], %[[VAR_0]], %[[TYPE_4]], %[[VAR_4]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, value, typed_value, value], result_name = "i"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1656:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %10 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":1658:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
  %i_next = mpir.inst <add> block %loop (%9, %i_i, %9, %10) <result_name = "next", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1660:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> block %[[VAR_2]] (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "next"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %11 = mpir.type.prim label : <Type> loc("to-plan.mlir":1662:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim label : <Type>
  %12 = mpir.inst <br> block %loop (%11, %exit) <flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1664:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <br> block %[[VAR_2]] (%[[TYPE_6]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1666:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.inst <ret> block %exit (%13, %i_next) <flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1668:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <ret> block %[[VAR_3]] (%[[TYPE_7]], %[[INST_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":1670:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, variable, variable, instruction, variable, instruction, instruction, instruction, instruction], slot_sorts = [BasicBlock, Value, Instruction, BasicBlock, BasicBlock, Instruction, Value, Instruction, Instruction, Instruction, Instruction], slot_names = ["entry", "x", "%c", "loop", "exit", "br", "n", "%i", "%next", "br", "ret"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_0]][predicate]
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
// CHECK-LABEL:   mpir.pattern {
  %nsw = mpir.var "nsw" : <Boolean> loc("to-plan.mlir":1763:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "nsw" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1765:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":1767:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":1769:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %_flag_a_disjoint = mpir.var "_flag$a$disjoint" : <Boolean> loc("to-plan.mlir":1771:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "_flag$a$disjoint" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1775:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":1777:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <or> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1781:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %12 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1783:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
    mpir.bind %nsw, %12 : <Boolean>, <Value> loc("to-plan.mlir":1785:1)
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":1787:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "a"> : <Instruction> loc("to-plan.mlir":1789:1)
// CHECK:           } <result_name = "a"> : <Instruction>
  %neg = mpir.var "neg" : <Instruction> loc("to-plan.mlir":1791:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "neg" : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1793:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %_flag_b_nsw = mpir.var "_flag$b$nsw" : <Boolean> loc("to-plan.mlir":1795:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "_flag$b$nsw" : <Boolean>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %3 = mpir.alt {
    %12 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1799:1)
// CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
    %i_b = mpir.inst <sub> capture %neg (%2, %12, %2, %1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1801:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> capture %[[VAR_4]] (%[[TYPE_1]], %[[INT_1]], %[[TYPE_1]], %[[ALT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-plan.mlir":1803:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  }, {
// CHECK:           }, {
    mpir.bind %neg, %1 : <Instruction>, <Instruction> loc("to-plan.mlir":1807:1)
// CHECK:             mpir.bind %[[VAR_4]], %[[ALT_0]] : <Instruction>, <Instruction>
    mpir.yield %1 : <Instruction> loc("to-plan.mlir":1809:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  } <result_name = "b"> : <Instruction> loc("to-plan.mlir":1811:1)
// CHECK:           } <result_name = "b"> : <Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":1813:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.type.int 64 : <Type> loc("to-plan.mlir":1815:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
  %_flag_c_nneg = mpir.var "_flag$c$nneg" : <Boolean> loc("to-plan.mlir":1817:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "_flag$c$nneg" : <Boolean>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
  %6 = mpir.alt {
    %i_c = mpir.inst <zext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1821:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-plan.mlir":1823:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_c = mpir.inst <sext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1827:1)
// CHECK:             %[[INST_4:.*]] = mpir.inst <sext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-plan.mlir":1829:1)
// CHECK:             mpir.yield %[[INST_4]] : <Instruction>
  } <result_name = "c"> : <Instruction> loc("to-plan.mlir":1831:1)
// CHECK:           } <result_name = "c"> : <Instruction>
  %7 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1833:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("to-plan.mlir":1835:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "cond" : <Boolean>
  %8 = mpir.type.int 64 : <Type> loc("to-plan.mlir":1837:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 64 : <Type>
  %9 = mpir.type.int 64 : <Type> loc("to-plan.mlir":1839:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
  %10 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":1841:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
  %11 = mpir.alt {
// CHECK:           %[[ALT_3:.*]] = mpir.alt {
    %12 = mpir.type.int 1 : <Type> loc("to-plan.mlir":1845:1)
// CHECK:             %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
    %i_d = mpir.inst <select> (%12, %cond, %8, %6, %8, %10) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":1847:1)
// CHECK:             %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_7]], %[[TYPE_5]], %[[ALT_2]], %[[TYPE_5]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_d : <Instruction> loc("to-plan.mlir":1849:1)
// CHECK:             mpir.yield %[[INST_5]] : <Instruction>
  } <result_name = "d"> : <Instruction> loc("to-plan.mlir":1851:1)
// CHECK:           } <result_name = "d"> : <Instruction>
} loc("to-plan.mlir":1853:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, variable, variable, instruction, variable, variable, instruction, variable, instruction, variable, instruction], slot_sorts = [Boolean, Value, Value, Boolean, Instruction, Instruction, Boolean, Instruction, Boolean, Instruction, Boolean, Instruction], slot_names = ["nsw", "x", "y", "_flag$a$disjoint", "%a", "neg", "_flag$b$nsw", "%b", "_flag$c$nneg", "%c", "cond", "%d"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %ia = mpir.var "ia" : <Boolean> loc("to-plan.mlir":2053:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ia" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2055:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2057:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %n = mpir.var "n" : <Nat> loc("to-plan.mlir":2059:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "n" : <Nat>
  %2 = mpir.int 4 : ui3 : <Value> loc("to-plan.mlir":2061:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 4 : ui3 : <Value>
  %i_slot = mpir.inst <alloca> flags(%ia) (%0, %1, %n, %2) <result_name = "slot", flags = [inalloca], flag_modes = [captured], operand_kinds = [type_only, typed_value, alignment]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2063:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <alloca> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[TYPE_1]], %[[VAR_1]], %[[INT_0]]) <flags = [inalloca], flag_modes = [captured], operand_kinds = [type_only, typed_value, alignment], result_name = "slot"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 64 : <Type> loc("to-plan.mlir":2065:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %4 = mpir.int 5 : ui3 : <Value> loc("to-plan.mlir":2067:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 5 : ui3 : <Value>
  %i_slot2 = mpir.inst <alloca> (%3, %4) <result_name = "slot2", flags = [], flag_modes = [], operand_kinds = [type_only, address_space]> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2069:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <alloca> (%[[TYPE_2]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [type_only, address_space], result_name = "slot2"> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2071:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2073:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %align = mpir.var "align" : <Nat> loc("to-plan.mlir":2075:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "align" : <Nat>
  %i_v = mpir.inst <load> (%5, %6, %i_slot, %align) <result_name = "v", flags = [volatile], flag_modes = [required], operand_kinds = [type_only, typed_value, alignment]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2077:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> (%[[TYPE_3]], %[[TYPE_4]], %[[INST_0]], %[[VAR_2]]) <flags = [volatile], flag_modes = [required], operand_kinds = [type_only, typed_value, alignment], result_name = "v"> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2079:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type> loc("to-plan.mlir":2081:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-plan.mlir":2083:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %i_w = mpir.inst <load> (%7, %8, %p) <result_name = "w", flags = [], flag_modes = [], operand_kinds = [type_only, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2085:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <load> (%[[TYPE_5]], %[[TYPE_6]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [type_only, typed_value], result_name = "w"> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2087:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %10 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2089:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %11 = mpir.int 8 : ui4 : <Value> loc("to-plan.mlir":2091:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 8 : ui4 : <Value>
  %i_st = mpir.inst <store> (%9, %i_v, %10, %i_slot, %11) <result_name = "st", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, alignment]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2093:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <store> (%[[TYPE_7]], %[[INST_2]], %[[TYPE_8]], %[[INST_0]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, alignment], result_name = "st"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %vol = mpir.var "vol" : <Boolean> loc("to-plan.mlir":2095:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "vol" : <Boolean>
  %12 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2097:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":2099:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "x" : <Operand>
  %13 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2101:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %q = mpir.var "q" : <Operand> loc("to-plan.mlir":2103:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "q" : <Operand>
  %i_st2 = mpir.inst <store> flags(%vol) (%12, %x, %13, %q) <result_name = "st2", flags = [volatile], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2105:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <store> flags(%[[VAR_4]]) (%[[TYPE_9]], %[[VAR_5]], %[[TYPE_10]], %[[VAR_6]]) <flags = [volatile], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "st2"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ib = mpir.var "ib" : <Boolean> loc("to-plan.mlir":2107:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "ib" : <Boolean>
  %gn = mpir.var "gn" : <Boolean> loc("to-plan.mlir":2109:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "gn" : <Boolean>
  %14 = mpir.type.int 8 : <Type> loc("to-plan.mlir":2111:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
  %15 = mpir.type.seq array 4 x %14 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2113:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %16 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2115:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %17 = mpir.type.int 64 : <Type> loc("to-plan.mlir":2117:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 64 : <Type>
  %18 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":2119:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 64 : <Type> loc("to-plan.mlir":2121:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 64 : <Type>
  %i = mpir.var "i" : <Operand> loc("to-plan.mlir":2123:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "i" : <Operand>
  %i_g = mpir.inst <getelementptr> flags(%ib, %gn) (%15, %16, %i_slot, %17, %18, %19, %i) <result_name = "g", flags = [inbounds, nusw, nuw], flag_modes = [captured, required, captured], operand_kinds = [type_only, typed_value, typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2125:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <getelementptr> flags(%[[VAR_7]], %[[VAR_8]]) (%[[TYPE_12]], %[[TYPE_13]], %[[INST_0]], %[[TYPE_14]], %[[INT_3]], %[[TYPE_15]], %[[VAR_9]]) <flags = [inbounds, nusw, nuw], flag_modes = [captured, required, captured], operand_kinds = [type_only, typed_value, typed_value, typed_value], result_name = "g"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %20 = mpir.type.int 8 : <Type> loc("to-plan.mlir":2127:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 8 : <Type>
  %21 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2129:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %22 = mpir.type.int 64 : <Type> loc("to-plan.mlir":2131:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 64 : <Type>
  %23 = mpir.int 4 : ui3 : <Value> loc("to-plan.mlir":2133:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 4 : ui3 : <Value>
  %i_h = mpir.inst <getelementptr> (%20, %21, %q, %22, %23) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2135:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <getelementptr> (%[[TYPE_16]], %[[TYPE_17]], %[[VAR_6]], %[[TYPE_18]], %[[INT_4]]) <flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, typed_value], result_name = "h"> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":2137:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, variable, instruction, variable, instruction, instruction, variable, variable, variable, instruction, variable, variable, variable, instruction, instruction], slot_sorts = [Boolean, Nat, Instruction, Instruction, Nat, Instruction, Value, Instruction, Instruction, Boolean, Value, Value, Instruction, Boolean, Boolean, Value, Instruction, Instruction], slot_names = ["ia", "n", "%slot", "%slot2", "align", "%v", "p", "%w", "%st", "vol", "x", "q", "%st2", "ib", "gn", "i", "%g", "%h"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <alloca>
// CHECK:           mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:           %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[FOREACH_INSTRUCTION_0]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_0]], [1, 64, 0]
// CHECK:           %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][address_space]
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
// CHECK:           %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_2]][alignment]
// CHECK:           mpir_plan.check_constant %[[GET_KEYED_1]], 8 : ui4
// CHECK:           mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_2]], 2
// CHECK:           %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_2]][0]
// CHECK:           %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_3]], [1, 32, 0]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_1]], <load>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_1]] -> 5
// CHECK:           %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_4]], [1, 32, 0]
// CHECK:           mpir_plan.check_flag %[[GET_OPERAND_1]][volatile] is true
// CHECK:           %[[GET_KEYED_2:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_1]][alignment]
// CHECK:           mpir_plan.bind %[[GET_KEYED_2]] -> 4
// CHECK:           mpir_plan.check_operand_count %[[GET_OPERAND_1]], 1
// CHECK:           %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_1]][0]
// CHECK:           %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
// CHECK:           mpir_plan.check_type %[[GET_TYPE_5]], [4, -1, 1]
// CHECK:           mpir_plan.check_opcode %[[GET_OPERAND_2]], <alloca>
// CHECK:           mpir_plan.bind %[[GET_OPERAND_2]] -> 2
// CHECK:           %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]] <operand_of>
// CHECK:           mpir_plan.check_type %[[GET_TYPE_6]], [1, 32, 0]
// CHECK:           %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[GET_OPERAND_2]][inalloca]
// CHECK:           mpir_plan.bind %[[GET_FLAG_0]] -> 0
// CHECK:           %[[GET_KEYED_3:.*]] = mpir_plan.get_keyed %[[GET_OPERAND_2]][alignment]
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
// CHECK:           %[[GET_FLAG_1:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_3]][volatile]
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
// CHECK:           %[[GET_FLAG_2:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_4]][inbounds]
// CHECK:           mpir_plan.bind %[[GET_FLAG_2]] -> 13
// CHECK:           mpir_plan.check_flag %[[FOREACH_INSTRUCTION_4]][nusw] is true
// CHECK:           %[[GET_FLAG_3:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_4]][nuw]
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2257:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":2259:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":2261:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2265:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":2267:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %y, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2271:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":2273:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "a"> : <Instruction> loc("to-plan.mlir":2275:1)
// CHECK:           } <result_name = "a"> : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2277:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value> loc("to-plan.mlir":2279:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %4 = mpir.alt {
    mpir.yield %1 : <Instruction> loc("to-plan.mlir":2283:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2287:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-plan.mlir":2289:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } <result_name = "b"> : <Instruction> loc("to-plan.mlir":2291:1)
// CHECK:           } <result_name = "b"> : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2293:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":2295:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
  %7 = mpir.alt {
    mpir.yield %4 : <Instruction> loc("to-plan.mlir":2299:1)
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_c = mpir.inst <sub> (%5, %6, %5, %4) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2303:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INT_1]], %[[TYPE_2]], %[[ALT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-plan.mlir":2305:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } <result_name = "c"> : <Instruction> loc("to-plan.mlir":2307:1)
// CHECK:           } <result_name = "c"> : <Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2309:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand> loc("to-plan.mlir":2311:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "z" : <Operand>
  %i_d = mpir.inst <xor> (%8, %7, %8, %z) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2313:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <xor> (%[[TYPE_3]], %[[ALT_2]], %[[TYPE_3]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2315:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %w = mpir.var "w" : <Operand> loc("to-plan.mlir":2317:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "w" : <Operand>
  %i_e = mpir.inst <and> (%9, %i_d, %9, %w) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2319:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <and> (%[[TYPE_4]], %[[INST_4]], %[[TYPE_4]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2321:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %u = mpir.var "u" : <Operand> loc("to-plan.mlir":2323:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "u" : <Operand>
  %i_f = mpir.inst <or> (%10, %i_e, %10, %u) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2325:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <or> (%[[TYPE_5]], %[[INST_5]], %[[TYPE_5]], %[[VAR_4]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir_expr.read %1 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-plan.mlir":2327:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[ALT_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %12 = mpir_expr.call call "hasOneUse"(%11) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2329:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %12 <from_metaflag> : <Boolean> loc("to-plan.mlir":2331:1)
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
  %13 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2333:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %14 = mpir_expr.call call "isZero"(%13) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2335:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %14 <from_metaflag> : <Boolean> loc("to-plan.mlir":2337:1)
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
  %15 = mpir_expr.int 1 : ui64 : <Integer> loc("to-plan.mlir":2339:1)
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %16 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2341:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.call call "sle"(%15, %16) anchor %1 : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2343:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "sle"(%[[INT_2]], %[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2345:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %19 = mpir_expr.int 10 : ui64 : <Integer> loc("to-plan.mlir":2347:1)
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 10 : ui64 : <Integer>
  %20 = mpir_expr.call call "sle"(%18, %19) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2349:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "sle"(%[[READ_3]], %[[INT_3]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %21 = mpir_expr.call binary "&&"(%17, %20) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2351:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_2]], %[[CALL_3]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %21 <from_metaflag> : <Boolean> loc("to-plan.mlir":2353:1)
// CHECK:           mpir.require %[[CALL_4]] <from_metaflag> : <Boolean>
  %22 = mpir_expr.read %7 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-plan.mlir":2355:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[ALT_2]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %23 = mpir_expr.call call "opcode"(%22) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-plan.mlir":2357:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[ALT_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %24 = mpir_expr.str "add" : <String> loc("to-plan.mlir":2359:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
  %25 = mpir_expr.call binary "=="(%23, %24) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2361:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_0]]) anchor %[[ALT_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 <from_metaflag> : <Boolean> loc("to-plan.mlir":2363:1)
// CHECK:           mpir.require %[[CALL_6]] <from_metaflag> : <Boolean>
  %26 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2365:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %27 = mpir_expr.call call "isZero"(%26) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2367:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_5]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %28 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2369:1)
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %29 = mpir_expr.call call "isAllOnes"(%28) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2371:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_6]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %30 = mpir_expr.call binary "||"(%27, %29) anchor %i_d : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2373:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[INST_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %30 <from_metaflag> : <Boolean> loc("to-plan.mlir":2375:1)
// CHECK:           mpir.require %[[CALL_9]] <from_metaflag> : <Boolean>
  %31 = mpir_expr.read %w : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2377:1)
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %32 = mpir_expr.call call "isPower2"(%31) anchor %i_e : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2379:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "isPower2"(%[[READ_7]]) anchor %[[INST_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %33 = mpir_expr.call unary "!"(%32) anchor %i_e : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2381:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call unary "!"(%[[CALL_10]]) anchor %[[INST_5]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %33 <from_metaflag> : <Boolean> loc("to-plan.mlir":2383:1)
// CHECK:           mpir.require %[[CALL_11]] <from_metaflag> : <Boolean>
  %34 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2385:1)
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %35 = mpir_expr.call call "isZero"(%34) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2387:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "isZero"(%[[READ_8]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %36 = mpir_expr.call unary "!"(%35) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2389:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call unary "!"(%[[CALL_12]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.int 2 : ui64 : <Integer> loc("to-plan.mlir":2391:1)
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %38 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2393:1)
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %39 = mpir_expr.call call "sle"(%37, %38) anchor %i_f : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2395:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "sle"(%[[INT_4]], %[[READ_9]]) anchor %[[INST_6]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":2397:1)
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %41 = mpir_expr.int 4 : ui64 : <Integer> loc("to-plan.mlir":2399:1)
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 4 : ui64 : <Integer>
  %42 = mpir_expr.call call "sle"(%40, %41) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2401:1)
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "sle"(%[[READ_10]], %[[INT_5]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %43 = mpir_expr.call binary "&&"(%39, %42) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2403:1)
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call binary "&&"(%[[CALL_14]], %[[CALL_15]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %44 = mpir_expr.call binary "||"(%36, %43) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":2405:1)
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_13]], %[[CALL_16]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %44 <from_metaflag> : <Boolean> loc("to-plan.mlir":2407:1)
// CHECK:           mpir.require %[[CALL_17]] <from_metaflag> : <Boolean>
} loc("to-plan.mlir":2409:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, instruction, variable, instruction, variable, instruction, variable, instruction], slot_sorts = [Value, Value, Instruction, Instruction, Instruction, Value, Instruction, Value, Instruction, Value, Instruction], slot_names = ["x", "y", "%a", "%b", "%c", "z", "%d", "w", "%e", "u", "%f"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock> loc("to-plan.mlir":2661:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2663:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":2665:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":2667:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_0 = mpir.inst <add> block %entry (%0, %x, %0, %1) <result_name = "0", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2669:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "0"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2671:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_1 = mpir.inst <mul> block %entry (%2, %i_0, %2, %i_0) <result_name = "1", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2673:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "1"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %_7 = mpir.var "7" : <BasicBlock> loc("to-plan.mlir":2675:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "7" : <BasicBlock>
  %3 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2677:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2679:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.type.ptr %4 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2681:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-plan.mlir":2683:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %i_2 = mpir.inst <load> block %_7 (%3, %5, %p) <result_name = "2", flags = [], flag_modes = [], operand_kinds = [type_only, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2685:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> block %[[VAR_2]] (%[[TYPE_2]], %[[TYPE_4]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [type_only, typed_value], result_name = "2"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2687:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %i_3 = mpir.inst <sub> (%6, %i_2, %6, %i_1) <result_name = "3", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2689:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INST_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "3"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim void : <Type> loc("to-plan.mlir":2691:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim void : <Type>
  %8 = mpir.inst <ret> (%7) <flags = [], flag_modes = [], operand_kinds = [type_only]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2693:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <ret> (%[[TYPE_6]]) <flags = [], flag_modes = [], operand_kinds = [type_only]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":2695:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, variable, variable, instruction, instruction, instruction], slot_sorts = [BasicBlock, Value, Instruction, Instruction, BasicBlock, Value, Instruction, Instruction, Instruction], slot_names = ["entry", "x", "%0", "%1", "7", "p", "%2", "%3", "ret"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2759:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x_y = mpir.var "x.y" : <Operand> loc("to-plan.mlir":2761:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x.y" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":2763:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_a_b = mpir.inst <add> (%0, %x_y, %0, %1) <result_name = "a.b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2765:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a.b", treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2767:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %__0 = mpir.var "_$0" : <Operand> loc("to-plan.mlir":2769:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "_$0" : <Operand>
  %i_c_d = mpir.inst <sub> (%2, %i_a_b, %2, %__0) <result_name = "c-d", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2771:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c-d", treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2773:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %__1 = mpir.var "_$1" : <Operand> loc("to-plan.mlir":2775:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "_$1" : <Operand>
  %i_e = mpir.inst <mul> (%3, %i_c_d, %3, %__1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2777:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "e", treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2779:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.inst <ret> (%4, %i_e) <flags = [], flag_modes = [], operand_kinds = [typed_value], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2781:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <ret> (%[[TYPE_3]], %[[INST_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":2783:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, variable, instruction, instruction], slot_sorts = [Value, Instruction, Value, Instruction, Value, Instruction, Instruction], slot_names = ["x.y", "%a.b", "_$0", "%c-d", "_$1", "%e", "ret"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("to-plan.mlir":2834:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %a1 = mpir.var "a1" : <Boolean> loc("to-plan.mlir":2836:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "a1" : <Boolean>
  %i_a = mpir.inst <freeze> (%0, %a1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2838:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <freeze> (%[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 8 byte : <Type> loc("to-plan.mlir":2840:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 byte : <Type>
  %b1 = mpir.var "b1" : <Operand> loc("to-plan.mlir":2842:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "b1" : <Operand>
  %i_b = mpir.inst <freeze> (%1, %b1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2844:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <freeze> (%[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat> loc("to-plan.mlir":2846:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %2 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2848:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %c1 = mpir.var "c1" : <Operand> loc("to-plan.mlir":2850:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "c1" : <Operand>
  %i_c = mpir.inst <freeze> (%2, %c1) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2852:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <freeze> (%[[TYPE_2]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %m = mpir.var "m" : <Nat> loc("to-plan.mlir":2854:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "m" : <Nat>
  %3 = mpir.type.meta_int %m byte : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2856:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAR_4]] byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %d1 = mpir.var "d1" : <Operand> loc("to-plan.mlir":2858:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "d1" : <Operand>
  %i_d = mpir.inst <freeze> (%3, %d1) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2860:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <freeze> (%[[TYPE_3]], %[[VAR_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.prim half : <Type> loc("to-plan.mlir":2862:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim half : <Type>
  %e1 = mpir.var "e1" : <Operand> loc("to-plan.mlir":2864:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "e1" : <Operand>
  %i_e = mpir.inst <freeze> (%4, %e1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2866:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <freeze> (%[[TYPE_4]], %[[VAR_6]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %5 = mpir.type.prim bfloat : <Type> loc("to-plan.mlir":2868:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim bfloat : <Type>
  %f1 = mpir.var "f1" : <Operand> loc("to-plan.mlir":2870:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "f1" : <Operand>
  %i_f = mpir.inst <freeze> (%5, %f1) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2872:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <freeze> (%[[TYPE_5]], %[[VAR_7]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim float : <Type> loc("to-plan.mlir":2874:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim float : <Type>
  %g1 = mpir.var "g1" : <Operand> loc("to-plan.mlir":2876:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "g1" : <Operand>
  %i_g = mpir.inst <freeze> (%6, %g1) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2878:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <freeze> (%[[TYPE_6]], %[[VAR_8]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "g"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim double : <Type> loc("to-plan.mlir":2880:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim double : <Type>
  %h1 = mpir.var "h1" : <Operand> loc("to-plan.mlir":2882:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "h1" : <Operand>
  %i_h = mpir.inst <freeze> (%7, %h1) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2884:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <freeze> (%[[TYPE_7]], %[[VAR_9]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "h"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim fp128 : <Type> loc("to-plan.mlir":2886:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim fp128 : <Type>
  %i1 = mpir.var "i1" : <Operand> loc("to-plan.mlir":2888:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "i1" : <Operand>
  %i_i = mpir.inst <freeze> (%8, %i1) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2890:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <freeze> (%[[TYPE_8]], %[[VAR_10]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "i"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2892:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %j1 = mpir.var "j1" : <Operand> loc("to-plan.mlir":2894:1)
// CHECK:           %[[VAR_11:.*]] = mpir.var "j1" : <Operand>
  %i_j = mpir.inst <freeze> (%9, %j1) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2896:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <freeze> (%[[TYPE_9]], %[[VAR_11]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "j"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type> loc("to-plan.mlir":2898:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
  %k1 = mpir.var "k1" : <Operand> loc("to-plan.mlir":2900:1)
// CHECK:           %[[VAR_12:.*]] = mpir.var "k1" : <Operand>
  %i_k = mpir.inst <freeze> (%10, %k1) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2902:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <freeze> (%[[TYPE_10]], %[[VAR_12]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "k"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir.type.int 8 : <Type> loc("to-plan.mlir":2904:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
  %12 = mpir.type.seq array 4 x %11 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2906:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %l1 = mpir.var "l1" : <Operand> loc("to-plan.mlir":2908:1)
// CHECK:           %[[VAR_13:.*]] = mpir.var "l1" : <Operand>
  %i_l = mpir.inst <freeze> (%12, %l1) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2910:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <freeze> (%[[TYPE_12]], %[[VAR_13]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "l"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %len = mpir.var "len" : <Nat> loc("to-plan.mlir":2912:1)
// CHECK:           %[[VAR_14:.*]] = mpir.var "len" : <Nat>
  %13 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2914:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %14 = mpir.type.seq array 0 x %13 count %len : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2916:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq array 0 x %[[TYPE_13]] count %[[VAR_14]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %m1 = mpir.var "m1" : <Operand> loc("to-plan.mlir":2918:1)
// CHECK:           %[[VAR_15:.*]] = mpir.var "m1" : <Operand>
  %i_m = mpir.inst <freeze> (%14, %m1) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2920:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <freeze> (%[[TYPE_14]], %[[VAR_15]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %15 = mpir.type.prim float : <Type> loc("to-plan.mlir":2922:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
  %16 = mpir.type.seq vector 2 x %15 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2924:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %n1 = mpir.var "n1" : <Operand> loc("to-plan.mlir":2926:1)
// CHECK:           %[[VAR_16:.*]] = mpir.var "n1" : <Operand>
  %i_n = mpir.inst <freeze> (%16, %n1) <result_name = "n", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2928:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_16]], %[[VAR_16]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "n"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2930:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.type.seq scalable 4 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2932:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.seq scalable 4 x %[[TYPE_17]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %o1 = mpir.var "o1" : <Operand> loc("to-plan.mlir":2934:1)
// CHECK:           %[[VAR_17:.*]] = mpir.var "o1" : <Operand>
  %i_o = mpir.inst <freeze> (%18, %o1) <result_name = "o", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2936:1)
// CHECK:           %[[INST_14:.*]] = mpir.inst <freeze> (%[[TYPE_18]], %[[VAR_17]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "o"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %lanes = mpir.var "lanes" : <Nat> loc("to-plan.mlir":2938:1)
// CHECK:           %[[VAR_18:.*]] = mpir.var "lanes" : <Nat>
  %19 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2940:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %20 = mpir.type.seq vector 0 x %19 count %lanes : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-plan.mlir":2942:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.seq vector 0 x %[[TYPE_19]] count %[[VAR_18]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %p1 = mpir.var "p1" : <Operand> loc("to-plan.mlir":2944:1)
// CHECK:           %[[VAR_19:.*]] = mpir.var "p1" : <Operand>
  %i_p = mpir.inst <freeze> (%20, %p1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2946:1)
// CHECK:           %[[INST_15:.*]] = mpir.inst <freeze> (%[[TYPE_20]], %[[VAR_19]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "p"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %21 = mpir.type.int 32 : <Type> loc("to-plan.mlir":2948:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-plan.mlir":2950:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %23 = mpir.type.struct{%21, %22} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2952:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.struct{%[[TYPE_21]], %[[TYPE_22]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %q1 = mpir.var "q1" : <Operand> loc("to-plan.mlir":2954:1)
// CHECK:           %[[VAR_20:.*]] = mpir.var "q1" : <Operand>
  %i_q = mpir.inst <freeze> (%23, %q1) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2956:1)
// CHECK:           %[[INST_16:.*]] = mpir.inst <freeze> (%[[TYPE_23]], %[[VAR_20]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "q"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 8 : <Type> loc("to-plan.mlir":2958:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
  %25 = mpir.type.int 16 : <Type> loc("to-plan.mlir":2960:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 16 : <Type>
  %26 = mpir.type.seq array 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2962:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.type.struct packed{%24, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":2964:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct packed{%[[TYPE_24]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %r1 = mpir.var "r1" : <Operand> loc("to-plan.mlir":2966:1)
// CHECK:           %[[VAR_21:.*]] = mpir.var "r1" : <Operand>
  %i_r = mpir.inst <freeze> (%27, %r1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2968:1)
// CHECK:           %[[INST_17:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[VAR_21]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %28 = mpir.type.struct{} : () -> !mpir.sort<Type> loc("to-plan.mlir":2970:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.struct{} : () -> !mpir.sort<Type>
  %s1 = mpir.var "s1" : <Operand> loc("to-plan.mlir":2972:1)
// CHECK:           %[[VAR_22:.*]] = mpir.var "s1" : <Operand>
  %i_s = mpir.inst <freeze> (%28, %s1) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2974:1)
// CHECK:           %[[INST_18:.*]] = mpir.inst <freeze> (%[[TYPE_28]], %[[VAR_22]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ty = mpir.var "ty" : <Type> loc("to-plan.mlir":2976:1)
// CHECK:           %[[VAR_23:.*]] = mpir.var "ty" : <Type>
  %t1 = mpir.var "t1" : <Operand> loc("to-plan.mlir":2978:1)
// CHECK:           %[[VAR_24:.*]] = mpir.var "t1" : <Operand>
  %i_t = mpir.inst <freeze> (%ty, %t1) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":2980:1)
// CHECK:           %[[INST_19:.*]] = mpir.inst <freeze> (%[[VAR_23]], %[[VAR_24]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "t"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":2982:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, variable, variable, instruction, variable, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, variable, instruction, variable, instruction, variable, instruction, variable, variable, instruction, variable, instruction, variable, instruction, variable, instruction, variable, variable, instruction], slot_sorts = [Boolean, Instruction, Value, Instruction, Nat, Value, Instruction, Nat, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Nat, Value, Instruction, Value, Instruction, Value, Instruction, Nat, Value, Instruction, Value, Instruction, Value, Instruction, Value, Instruction, Type, Value, Instruction], slot_names = ["a1", "%a", "b1", "%b", "n", "c1", "%c", "m", "d1", "%d", "e1", "%e", "f1", "%f", "g1", "%g", "h1", "%h", "i1", "%i", "j1", "%j", "k1", "%k", "l1", "%l", "len", "m1", "%m", "n1", "%n", "o1", "%o", "lanes", "p1", "%p", "q1", "%q", "r1", "%r", "s1", "%s", "ty", "t1", "%t"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3154:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.type.seq vector 4 x %0 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3156:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.seq vector 4 x %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-plan.mlir":3158:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "v" : <Operand>
  %2 = mpir.type.int 64 : <Type> loc("to-plan.mlir":3160:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %idx = mpir.var "idx" : <Nat> loc("to-plan.mlir":3162:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "idx" : <Nat>
  %i_e = mpir.inst <extractelement> (%1, %v, %2, %idx) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3164:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <extractelement> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3166:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.type.seq vector 4 x %3 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3168:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.seq vector 4 x %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3170:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.type.int 64 : <Type> loc("to-plan.mlir":3172:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
  %7 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":3174:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_i = mpir.inst <insertelement> (%4, %v, %5, %i_e, %6, %7) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3176:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <insertelement> (%[[TYPE_4]], %[[VAR_0]], %[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "i"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3178:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %9 = mpir.type.seq vector 4 x %8 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3180:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.seq vector 4 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %10 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3182:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %11 = mpir.type.seq vector 4 x %10 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3184:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.seq vector 4 x %[[TYPE_9]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %12 = mpir.keyword poison : <Value> loc("to-plan.mlir":3186:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword poison : <Value>
  %13 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3188:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.type.seq vector 4 x %13 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3190:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %15 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3192:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %16 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":3194:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %17 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3196:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":3198:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3200:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
  %20 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3202:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %21 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3204:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3206:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 1 : ui1 : <Value>
  %23 = mpir.aggregate vector(%15, %16, %17, %18, %19, %20, %21, %22) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-plan.mlir":3208:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_13]], %[[INT_1]], %[[TYPE_14]], %[[INT_2]], %[[TYPE_15]], %[[INT_3]], %[[TYPE_16]], %[[INT_4]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_s = mpir.inst <shufflevector> (%9, %i_i, %11, %12, %14, %23) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3210:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <shufflevector> (%[[TYPE_8]], %[[INST_1]], %[[TYPE_10]], %[[KEYWORD_0]], %[[TYPE_12]], %[[AGGREGATE_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3212:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %25 = mpir.type.int 8 : <Type> loc("to-plan.mlir":3214:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 8 : <Type>
  %26 = mpir.type.int 16 : <Type> loc("to-plan.mlir":3216:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 16 : <Type>
  %27 = mpir.type.struct{%25, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3218:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.struct{%[[TYPE_18]], %[[TYPE_19]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %28 = mpir.type.struct{%24, %27} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3220:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.struct{%[[TYPE_17]], %[[TYPE_20]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg = mpir.var "agg" : <Operand> loc("to-plan.mlir":3222:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "agg" : <Operand>
  %29 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3224:1)
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
  %30 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":3226:1)
// CHECK:           %[[INT_6:.*]] = mpir.int 0 : ui1 : <Value>
  %i_x = mpir.inst <extractvalue> (%28, %agg, %29, %30) <result_name = "x", flags = [], flag_modes = [], operand_kinds = [typed_value, value, value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3228:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <extractvalue> (%[[TYPE_21]], %[[VAR_2]], %[[INT_5]], %[[INT_6]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, value, value], result_name = "x"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %31 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3230:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 32 : <Type>
  %32 = mpir.type.prim float : <Type> loc("to-plan.mlir":3232:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.prim float : <Type>
  %33 = mpir.type.struct{%31, %32} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3234:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.struct{%[[TYPE_22]], %[[TYPE_23]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg2 = mpir.var "agg2" : <Operand> loc("to-plan.mlir":3236:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "agg2" : <Operand>
  %path = mpir.var "path" : <ValueArray> loc("to-plan.mlir":3238:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "path" : <ValueArray>
  %i_y = mpir.inst <extractvalue> (%33, %agg2, %path) <result_name = "y", flags = [], flag_modes = [], operand_kinds = [typed_value, value_array]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3240:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <extractvalue> (%[[TYPE_24]], %[[VAR_3]], %[[VAR_4]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, value_array], result_name = "y"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %34 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3242:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 32 : <Type>
  %35 = mpir.type.prim float : <Type> loc("to-plan.mlir":3244:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.prim float : <Type>
  %36 = mpir.type.struct{%34, %35} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3246:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct{%[[TYPE_25]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %37 = mpir.type.prim float : <Type> loc("to-plan.mlir":3248:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.prim float : <Type>
  %38 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-plan.mlir":3250:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %39 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3252:1)
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
  %i_z = mpir.inst <insertvalue> (%36, %agg2, %37, %38, %39) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3254:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <insertvalue> (%[[TYPE_27]], %[[VAR_3]], %[[TYPE_28]], %[[FLOAT_0]], %[[INT_7]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, value], result_name = "z"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %40 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3256:1)
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 32 : <Type>
  %41 = mpir.type.seq scalable 4 x %40 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3258:1)
// CHECK:           %[[TYPE_30:.*]] = mpir.type.seq scalable 4 x %[[TYPE_29]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.var "a" : <Operand> loc("to-plan.mlir":3260:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "a" : <Operand>
  %42 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3262:1)
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
  %43 = mpir.type.seq scalable 4 x %42 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3264:1)
// CHECK:           %[[TYPE_32:.*]] = mpir.type.seq scalable 4 x %[[TYPE_31]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %b = mpir.var "b" : <Operand> loc("to-plan.mlir":3266:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "b" : <Operand>
  %44 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3268:1)
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
  %45 = mpir.type.seq scalable 4 x %44 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-plan.mlir":3270:1)
// CHECK:           %[[TYPE_34:.*]] = mpir.type.seq scalable 4 x %[[TYPE_33]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %46 = mpir.keyword zeroinitializer : <Value> loc("to-plan.mlir":3272:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword zeroinitializer : <Value>
  %i_sv = mpir.inst <shufflevector> (%41, %a, %43, %b, %45, %46) <result_name = "sv", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3274:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <shufflevector> (%[[TYPE_30]], %[[VAR_5]], %[[TYPE_32]], %[[VAR_6]], %[[TYPE_34]], %[[KEYWORD_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "sv"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3276:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, instruction, variable, instruction, variable, variable, instruction, instruction, variable, variable, instruction], slot_sorts = [Value, Nat, Instruction, Instruction, Instruction, Value, Instruction, Value, ValueArray, Instruction, Instruction, Value, Value, Instruction], slot_names = ["v", "idx", "%e", "%i", "%s", "agg", "%x", "agg2", "path", "%y", "%z", "a", "b", "%sv"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK:           mpir_plan.check_aggregate %[[GET_OPERAND_7]], vector, 4
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3387:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3389:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3391:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3393:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3395:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int 2 : ui2 : <Value> loc("to-plan.mlir":3397:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %x, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3399:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3401:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, instruction], slot_sorts = [Value, Instruction, Instruction], slot_names = ["x", "%a", "%b"], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3436:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3438:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":3440:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3442:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3444:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %i_a) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3446:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3448:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%2, %i_b, %2, %i_a) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3450:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3452:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction, instruction, instruction], slot_sorts = [Value, Value, Instruction, Instruction, Instruction], slot_names = ["x", "y", "%a", "%b", "%c"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3495:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3497:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3499:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3501:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction], slot_sorts = [Value, Instruction], slot_names = ["x", "%a"], slot_locs = [{{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3524:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3526:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3528:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3532:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":3534:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3538:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-plan.mlir":3540:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "a"> : <Instruction> loc("to-plan.mlir":3542:1)
// CHECK:           } <result_name = "a"> : <Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3544:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":3546:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %4 = mpir.alt {
    mpir.yield %2 : <Instruction> loc("to-plan.mlir":3550:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_b = mpir.inst <mul> (%3, %2, %3, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3554:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-plan.mlir":3556:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } <result_name = "b"> : <Instruction> loc("to-plan.mlir":3558:1)
// CHECK:           } <result_name = "b"> : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3560:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%5, %4, %5, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3562:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3564:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, instruction], slot_sorts = [Value, Instruction, Value, Instruction, Instruction], slot_names = ["x", "%a", "y", "%b", "%c"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %ex = mpir.var "ex" : <Boolean> loc("to-plan.mlir":3656:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ex" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3658:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3660:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":3662:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <lshr> flags(%ex) (%0, %x, %0, %y) <result_name = "r", flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3666:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3668:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <ashr> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3672:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <ashr> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %7 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":3674:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_expr.call call "isKnownNonNegative"(%7) anchor %i_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3676:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isKnownNonNegative"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %8 : <Boolean> loc("to-plan.mlir":3678:1)
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
    %9 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":3680:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
    mpir.bind %ex, %9 : <Boolean>, <Value> loc("to-plan.mlir":3682:1)
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3684:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-plan.mlir":3686:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir_expr.read %ex : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3688:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":3690:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.int 1 : ui64 : <Integer> loc("to-plan.mlir":3692:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3694:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[INT_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "||"(%2, %5) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3696:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[READ_1]], %[[CALL_1]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("to-plan.mlir":3698:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
} loc("to-plan.mlir":3700:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, variable, instruction], slot_sorts = [Boolean, Value, Value, Instruction], slot_names = ["ex", "x", "y", "%r"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <lshr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 3
// CHECK:             %[[GET_FLAG_0:.*]] = mpir_plan.get_flag %[[FOREACH_INSTRUCTION_0]][exact]
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3756:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3758:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":3760:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3762:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":3764:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 1 : ui64 : <Integer> loc("to-plan.mlir":3766:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3768:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.read %i_a : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-plan.mlir":3770:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %5 = mpir_expr.call call "hasOneUse"(%4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3772:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 <from_metaflag> : <Boolean> loc("to-plan.mlir":3774:1)
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
  %6 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-plan.mlir":3776:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "isZero"(%6) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":3778:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 <from_metaflag> : <Boolean> loc("to-plan.mlir":3780:1)
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
  mpir.require %3 : <Boolean> loc("to-plan.mlir":3782:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
} loc("to-plan.mlir":3784:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, instruction], slot_sorts = [Value, Value, Instruction], slot_names = ["x", "y", "%a"], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3823:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3825:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3827:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_p = mpir.inst <shl> (%0, %x, %0, %1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3829:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <shl> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "p"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3831:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand> loc("to-plan.mlir":3833:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "z" : <Operand>
  %3 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3835:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
  %i_q = mpir.inst <lshr> (%2, %z, %2, %3) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3837:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "q"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3839:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %5 = mpir.alt {
    %i_r = mpir.inst <add> (%4, %i_p, %4, %i_q) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3843:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3845:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%4, %i_p, %4, %i_p) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3849:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3851:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-plan.mlir":3853:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %6 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3855:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <mul> (%6, %5, %6, %i_q) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3857:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <mul> (%[[TYPE_3]], %[[ALT_0]], %[[TYPE_3]], %[[INST_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-plan.mlir":3859:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, instruction, instruction], slot_sorts = [Value, Instruction, Value, Instruction, Instruction, Instruction], slot_names = ["x", "%p", "z", "%q", "%r", "%s"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3958:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":3960:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3962:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_p = mpir.inst <shl> (%0, %x, %0, %1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3964:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <shl> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "p"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3966:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand> loc("to-plan.mlir":3968:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "z" : <Operand>
  %3 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":3970:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
  %i_q = mpir.inst <lshr> (%2, %z, %2, %3) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3972:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "q"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":3974:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %5 = mpir.alt {
    %i_r = mpir.inst <add> (%4, %i_p, %4, %i_q) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3978:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3980:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%4, %i_p, %4, %i_p) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":3984:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":3986:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-plan.mlir":3988:1)
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("to-plan.mlir":3990:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, instruction, instruction], slot_sorts = [Value, Instruction, Value, Instruction, Instruction], slot_names = ["x", "%p", "z", "%q", "%r"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
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
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_1]], <lshr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_1]] -> 3
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_1]], 2
// CHECK:             %[[GET_OPERAND_10:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][0]
// CHECK:             %[[GET_TYPE_10:.*]] = mpir_plan.get_type %[[GET_OPERAND_10]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_10]], [1, 32, 0]
// CHECK:             mpir_plan.bind %[[GET_OPERAND_10]] -> 2 <sort = 2>
// CHECK:             %[[GET_OPERAND_11:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_1]][1]
// CHECK:             %[[GET_TYPE_11:.*]] = mpir_plan.get_type %[[GET_OPERAND_11]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_11]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_11]], 1 : ui1
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// A use no branch fits matches nothing; with ':o' and no name, it is its
// operand.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("to-plan.mlir":4079:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("to-plan.mlir":4081:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4083:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand> loc("to-plan.mlir":4085:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %2 = mpir.type.int 64 : <Type> loc("to-plan.mlir":4087:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %b = mpir.var "b" : <Operand> loc("to-plan.mlir":4089:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
  %3 = mpir.alt <result_name = "r"> : <Instruction> loc("to-plan.mlir":4091:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt  <result_name = "r"> : <Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4093:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":4095:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_s = mpir.inst <add> (%4, %3, %4, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4097:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[ALT_0]], %[[TYPE_3]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type> loc("to-plan.mlir":4099:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %7 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4101:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.type.int 64 : <Type> loc("to-plan.mlir":4103:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
  %9 = mpir.alt {
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
    mpir.yield %i_s : <Instruction> loc("to-plan.mlir":4107:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } : <Instruction> loc("to-plan.mlir":4109:1)
// CHECK:           } : <Instruction>
} loc("to-plan.mlir":4111:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, variable, variable, instruction, instruction, instruction], slot_sorts = [Boolean, Value, Value, Instruction, Instruction, Instruction], slot_names = ["cond", "a", "b", "%r", "%s", ""], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.fail
// CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
// CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [1, 32, 0]
// CHECK:             mpir_plan.check_constant %[[GET_OPERAND_1]], 1 : ui1
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 5
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           %[[FOREACH_INSTRUCTION_1:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.fail
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// With treatIntAsVec, the types of a cast are compared by their elements;
// a commuted comparison matches a fresh predicate, and '?p' is bound to its
// swapped one by a let.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 8 : <Type> loc("to-plan.mlir":4142:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":4144:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4146:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_z = mpir.inst <zext> (%0, %x, %1) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4148:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <zext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "z", treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %p = mpir.var "p" : <CmpPredicate> loc("to-plan.mlir":4150:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "p" : <CmpPredicate>
  %2 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4152:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-plan.mlir":4154:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %3 = mpir.alt {
    %i_c = mpir.inst <icmp> (%p, %2, %i_z, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4158:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <icmp> (%[[VAR_1]], %[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c", treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-plan.mlir":4160:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  }, {
// CHECK:           }, {
    %q = mpir.var "_swapped$p" : <CmpPredicate> loc("to-plan.mlir":4164:1)
// CHECK:             %[[VAR_3:.*]] = mpir.var "_swapped$p" : <CmpPredicate>
    %i_c = mpir.inst <icmp> (%q, %2, %y, %2, %i_z) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4166:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_3]], %[[TYPE_2]], %[[VAR_2]], %[[TYPE_2]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c", treat_int_as_vec = true> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    %r = mpir_expr.read %q : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String> loc("to-plan.mlir":4168:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
    %s = mpir_expr.call call "swappedPredicate"(%r) : (!mpir.sort<String>) -> !mpir.sort<CmpPredicate> loc("to-plan.mlir":4170:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "swappedPredicate"(%[[READ_0]]) : (!mpir.sort<String>) -> !mpir.sort<CmpPredicate>
    mpir.let %p, %s : <CmpPredicate>, <CmpPredicate> loc("to-plan.mlir":4172:1)
// CHECK:             mpir.let %[[VAR_1]], %[[CALL_0]] : <CmpPredicate>, <CmpPredicate>
    mpir.yield %i_c : <Instruction> loc("to-plan.mlir":4174:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } <result_name = "c"> : <Instruction> loc("to-plan.mlir":4176:1)
// CHECK:           } <result_name = "c"> : <Instruction>
} loc("to-plan.mlir":4178:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, variable, variable, instruction, variable], slot_sorts = [Value, Instruction, CmpPredicate, Value, Instruction, CmpPredicate], slot_names = ["x", "%z", "p", "y", "%c", "_swapped$p"], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <icmp>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_KEYED_0:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate]
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
// CHECK:             %[[GET_KEYED_1:.*]] = mpir_plan.get_keyed %[[FOREACH_INSTRUCTION_0]][predicate]
// CHECK:             mpir_plan.bind %[[GET_KEYED_1]] -> 5
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
// CHECK:             %[[SLOT_0:.*]] = mpir_plan.slot 5 {var_name = "_swapped$p"} : <CmpPredicate>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "swappedPredicate"(%[[READ_0]]) : (!mpir.sort<String>) -> !mpir.sort<CmpPredicate>
// CHECK:             %[[SLOT_1:.*]] = mpir_plan.slot 2 {var_name = "p"} : <CmpPredicate>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SLOT_1]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[CALL_0]]) : (!mpir.sort<String>, !mpir.sort<CmpPredicate>) -> !mpir.sort<Boolean>
// CHECK:             mpir_plan.let 2, %[[CALL_0]], %[[CALL_1]] : <CmpPredicate>, <Boolean>
// CHECK:             mpir_plan.yield
// CHECK:           }
// CHECK:           mpir_plan.emit
// CHECK:         }

// -----

// What a use binds a parameter to, read by the branch's constraints: a
// width, a flag the use requires, and a constant operand.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4245:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-plan.mlir":4247:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 3 : ui2 : <Value> loc("to-plan.mlir":4249:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
  %2 = mpir.int 32 : ui64 : <Value> loc("to-plan.mlir":4251:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 32 : ui64 : <Value>
  %3 = mpir.int 1 : ui1 : <Value> loc("to-plan.mlir":4253:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
  %4 = mpir.alt {
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
    %i_r = mpir.inst <lshr> (%0, %x, %0, %1) <result_name = "r", flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4257:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":4259:1)
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":4261:1)
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_r : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4263:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_3]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.bool true : <Boolean> loc("to-plan.mlir":4265:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4267:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.int 3 : ui64 : <Integer> loc("to-plan.mlir":4269:1)
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 3 : ui64 : <Integer>
    %16 = mpir_expr.int 0 : ui64 : <Integer> loc("to-plan.mlir":4271:1)
// CHECK:             %[[INT_6:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_r : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4273:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_5]], %[[INT_6]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4275:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean> loc("to-plan.mlir":4277:1)
// CHECK:             mpir.require %[[CALL_3]] : <Boolean>
    mpir.yield %i_r : <Instruction> loc("to-plan.mlir":4279:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-plan.mlir":4281:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-plan.mlir":4283:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.int -4 : si3 : <Value> loc("to-plan.mlir":4285:1)
// CHECK:           %[[INT_7:.*]] = mpir.int -4 : si3 : <Value>
  %7 = mpir.int 32 : ui64 : <Value> loc("to-plan.mlir":4287:1)
// CHECK:           %[[INT_8:.*]] = mpir.int 32 : ui64 : <Value>
  %8 = mpir.int 0 : ui1 : <Value> loc("to-plan.mlir":4289:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 0 : ui1 : <Value>
  %9 = mpir.alt {
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
    %i_s = mpir.inst <lshr> (%5, %4, %5, %6) <result_name = "s", flags = [exact], flag_modes = [negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-plan.mlir":4293:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_7]]) <flags = [exact], flag_modes = [negated], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":4295:1)
// CHECK:             %[[INT_10:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer> loc("to-plan.mlir":4297:1)
// CHECK:             %[[INT_11:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_s : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4299:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_10]], %[[INT_11]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.bool false : <Boolean> loc("to-plan.mlir":4301:1)
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4303:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.int -4 : si64 : <Integer> loc("to-plan.mlir":4305:1)
// CHECK:             %[[INT_12:.*]] = mpir_expr.int -4 : si64 : <Integer>
    %16 = mpir_expr.int 0 : ui64 : <Integer> loc("to-plan.mlir":4307:1)
// CHECK:             %[[INT_13:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_s : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4309:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_12]], %[[INT_13]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-plan.mlir":4311:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean> loc("to-plan.mlir":4313:1)
// CHECK:             mpir.require %[[CALL_7]] : <Boolean>
    mpir.yield %i_s : <Instruction> loc("to-plan.mlir":4315:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "s"> : <Instruction> loc("to-plan.mlir":4317:1)
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("to-plan.mlir":4319:1)
// CHECK:         }
// CHECK-LABEL:   mpir_plan.matcher <slot_kinds = [variable, instruction, instruction], slot_sorts = [Value, Instruction, Instruction], slot_names = ["x", "%r", "%s"], slot_locs = [{{.*}}, {{.*}}, {{.*}}]> {
// CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
// CHECK:           mpir_plan.either {
// CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <lshr>
// CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 2
// CHECK:             mpir_plan.check_flag %[[FOREACH_INSTRUCTION_0]][exact] is false
// CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
// CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
// CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
// CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [1, 32, 0]
// CHECK:             mpir_plan.either {
// CHECK:               mpir_plan.check_opcode %[[GET_OPERAND_0]], <lshr>
// CHECK:               mpir_plan.bind %[[GET_OPERAND_0]] -> 1
// CHECK:               mpir_plan.check_flag %[[GET_OPERAND_0]][exact] is true
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
