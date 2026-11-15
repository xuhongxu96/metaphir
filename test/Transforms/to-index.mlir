// RUN: %metaphir-opt --split-input-file --mpir-to-index %s | FileCheck %s
// mpir-to-index compiles a lowered pattern into an mpir_index.query: for each
// way its matchers' branches can be chosen, a variant with the features a
// function needs (instructions, edges, siblings, globals, shapes, facts), the
// typings of its instructions, and its constraints on the sites of its
// values.

// Binary instruction matchers: each opcode, with its flags required ('nsw'),
// absent ('!nuw') and captured ('exact:?e'), and the instruction captured
// ('add:?sum').
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":13:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":15:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":17:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":19:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %nuw = mpir.var "nuw" : <Boolean> loc("to-index.mlir":21:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":23:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %2 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":25:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <sub> flags(%nuw) (%1, %i_a, %1, %2) <result_name = "b", flags = [1], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":27:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> flags(%[[VAR_2]]) (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [1], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %prod = mpir.var "prod" : <Instruction> loc("to-index.mlir":29:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "prod" : <Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-index.mlir":31:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <mul> capture %prod (%3, %i_b, %3, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":33:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> capture %[[VAR_3]] (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":35:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.int 2 : ui2 : <Value> loc("to-index.mlir":37:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
  %i_d = mpir.inst <udiv> (%4, %i_c, %4, %5) <result_name = "d", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":39:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <udiv> (%[[TYPE_3]], %[[INST_2]], %[[TYPE_3]], %[[INT_1]]) <result_name = "d", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %e = mpir.var "e" : <Boolean> loc("to-index.mlir":41:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "e" : <Boolean>
  %6 = mpir.type.int 32 : <Type> loc("to-index.mlir":43:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %7 = mpir.int -3 : si3 : <Value> loc("to-index.mlir":45:1)
// CHECK:           %[[INT_2:.*]] = mpir.int -3 : si3 : <Value>
  %i_e = mpir.inst <sdiv> flags(%e) (%6, %i_d, %6, %7) <result_name = "e", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":47:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <sdiv> flags(%[[VAR_4]]) (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_2]]) <result_name = "e", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-index.mlir":49:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %i_f = mpir.inst <urem> (%8, %i_e, %8, %y) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":51:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <urem> (%[[TYPE_5]], %[[INST_4]], %[[TYPE_5]], %[[VAR_1]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-index.mlir":53:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
  %i_g = mpir.inst <srem> (%9, %i_f, %9, %y) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":55:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <srem> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[VAR_1]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type> loc("to-index.mlir":57:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %11 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":59:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %i_h = mpir.inst <shl> (%10, %i_g, %10, %11) <result_name = "h", flags = [0, 1], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":61:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <shl> (%[[TYPE_7]], %[[INST_6]], %[[TYPE_7]], %[[INT_3]]) <result_name = "h", flags = [0, 1], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.int 32 : <Type> loc("to-index.mlir":63:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 32 : <Type>
  %i_i = mpir.inst <lshr> (%12, %i_h, %12, %y) <result_name = "i", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":65:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <lshr> (%[[TYPE_8]], %[[INST_7]], %[[TYPE_8]], %[[VAR_1]]) <result_name = "i", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-index.mlir":67:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %i_j = mpir.inst <ashr> (%13, %i_i, %13, %y) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":69:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <ashr> (%[[TYPE_9]], %[[INST_8]], %[[TYPE_9]], %[[VAR_1]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type> loc("to-index.mlir":71:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.int 255 : ui8 : <Value> loc("to-index.mlir":73:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 255 : ui8 : <Value>
  %i_k = mpir.inst <and> (%14, %i_j, %14, %15) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":75:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <and> (%[[TYPE_10]], %[[INST_9]], %[[TYPE_10]], %[[INT_4]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %dj = mpir.var "dj" : <Boolean> loc("to-index.mlir":77:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "dj" : <Boolean>
  %16 = mpir.type.int 32 : <Type> loc("to-index.mlir":79:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %i_l = mpir.inst <or> flags(%dj) (%16, %i_k, %16, %y) <result_name = "l", flags = [3], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":81:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <or> flags(%[[VAR_5]]) (%[[TYPE_11]], %[[INST_10]], %[[TYPE_11]], %[[VAR_1]]) <result_name = "l", flags = [3], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-index.mlir":83:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.int -1 : si1 : <Value> loc("to-index.mlir":85:1)
// CHECK:           %[[INT_5:.*]] = mpir.int -1 : si1 : <Value>
  %i_m = mpir.inst <xor> (%17, %i_l, %17, %18) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":87:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <xor> (%[[TYPE_12]], %[[INST_11]], %[[TYPE_12]], %[[INT_5]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.prim float : <Type> loc("to-index.mlir":89:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.prim float : <Type>
  %fx = mpir.var "fx" : <Operand> loc("to-index.mlir":91:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "fx" : <Operand>
  %20 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-index.mlir":93:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_n = mpir.inst <fadd> (%19, %fx, %19, %20) <result_name = "n", flags = [11, 12], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":95:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <fadd> (%[[TYPE_13]], %[[VAR_6]], %[[TYPE_13]], %[[FLOAT_0]]) <result_name = "n", flags = [11, 12], flag_modes = [0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %21 = mpir.type.prim float : <Type> loc("to-index.mlir":97:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.prim float : <Type>
  %i_o = mpir.inst <fsub> (%21, %i_n, %21, %fx) <result_name = "o", flags = [10], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":99:1)
// CHECK:           %[[INST_14:.*]] = mpir.inst <fsub> (%[[TYPE_14]], %[[INST_13]], %[[TYPE_14]], %[[VAR_6]]) <result_name = "o", flags = [10], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %22 = mpir.type.prim float : <Type> loc("to-index.mlir":101:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
  %i_p = mpir.inst <fmul> (%22, %i_o, %22, %i_o) <result_name = "p", flags = [13, 14, 15, 16, 17], flag_modes = [0, 0, 0, 0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":103:1)
// CHECK:           %[[INST_15:.*]] = mpir.inst <fmul> (%[[TYPE_15]], %[[INST_14]], %[[TYPE_15]], %[[INST_14]]) <result_name = "p", flags = [13, 14, 15, 16, 17], flag_modes = [0, 0, 0, 0, 0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %23 = mpir.type.prim float : <Type> loc("to-index.mlir":105:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim float : <Type>
  %24 = mpir.float 2.500000e+00 : f64 -> <Value> loc("to-index.mlir":107:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 2.500000e+00 : f64 -> <Value>
  %i_q = mpir.inst <fdiv> (%23, %i_p, %23, %24) <result_name = "q", flags = [11], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":109:1)
// CHECK:           %[[INST_16:.*]] = mpir.inst <fdiv> (%[[TYPE_16]], %[[INST_15]], %[[TYPE_16]], %[[FLOAT_1]]) <result_name = "q", flags = [11], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %25 = mpir.type.prim float : <Type> loc("to-index.mlir":111:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim float : <Type>
  %i_r = mpir.inst <frem> (%25, %i_q, %25, %fx) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":113:1)
// CHECK:           %[[INST_17:.*]] = mpir.inst <frem> (%[[TYPE_17]], %[[INST_16]], %[[TYPE_17]], %[[VAR_6]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim float : <Type> loc("to-index.mlir":115:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.prim float : <Type>
  %i_s = mpir.inst <fneg> (%26, %i_r) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":117:1)
// CHECK:           %[[INST_18:.*]] = mpir.inst <fneg> (%[[TYPE_18]], %[[INST_17]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":119:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <fneg>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <fadd>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <fsub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <fmul>
// CHECK:             mpir_index.has_instruction <udiv>
// CHECK:             mpir_index.has_instruction <sdiv>
// CHECK:             mpir_index.has_instruction <fdiv>
// CHECK:             mpir_index.has_instruction <urem>
// CHECK:             mpir_index.has_instruction <srem>
// CHECK:             mpir_index.has_instruction <frem>
// CHECK:             mpir_index.has_instruction <shl>
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_instruction <ashr>
// CHECK:             mpir_index.has_instruction <and>
// CHECK:             mpir_index.has_instruction <or>
// CHECK:             mpir_index.has_instruction <xor>
// CHECK:             mpir_index.has_edge <fneg> -> <frem>
// CHECK:             mpir_index.has_edge <sub> -> <add>
// CHECK:             mpir_index.has_edge <fsub> -> <fadd>
// CHECK:             mpir_index.has_edge <mul> -> <sub>
// CHECK:             mpir_index.has_edge <fmul> -> <fsub>
// CHECK:             mpir_index.has_edge <udiv> -> <mul>
// CHECK:             mpir_index.has_edge <sdiv> -> <udiv>
// CHECK:             mpir_index.has_edge <fdiv> -> <fmul>
// CHECK:             mpir_index.has_edge <urem> -> <sdiv>
// CHECK:             mpir_index.has_edge <srem> -> <urem>
// CHECK:             mpir_index.has_edge <frem> -> <fdiv>
// CHECK:             mpir_index.has_edge <shl> -> <srem>
// CHECK:             mpir_index.has_edge <lshr> -> <shl>
// CHECK:             mpir_index.has_edge <ashr> -> <lshr>
// CHECK:             mpir_index.has_edge <and> -> <ashr>
// CHECK:             mpir_index.has_edge <or> -> <and>
// CHECK:             mpir_index.has_edge <xor> -> <or>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_sibling <add>, <urem>
// CHECK:             mpir_index.has_sibling <add>, <srem>
// CHECK:             mpir_index.has_sibling <add>, <lshr>
// CHECK:             mpir_index.has_sibling <add>, <ashr>
// CHECK:             mpir_index.has_sibling <add>, <or>
// CHECK:             mpir_index.has_sibling <fadd>, <fsub>
// CHECK:             mpir_index.has_sibling <fadd>, <frem>
// CHECK:             mpir_index.has_sibling <fsub>, <frem>
// CHECK:             mpir_index.has_sibling <mul>, <urem>
// CHECK:             mpir_index.has_sibling <mul>, <srem>
// CHECK:             mpir_index.has_sibling <mul>, <lshr>
// CHECK:             mpir_index.has_sibling <mul>, <ashr>
// CHECK:             mpir_index.has_sibling <mul>, <or>
// CHECK:             mpir_index.has_sibling <urem>, <srem>
// CHECK:             mpir_index.has_sibling <urem>, <lshr>
// CHECK:             mpir_index.has_sibling <urem>, <ashr>
// CHECK:             mpir_index.has_sibling <urem>, <or>
// CHECK:             mpir_index.has_sibling <srem>, <lshr>
// CHECK:             mpir_index.has_sibling <srem>, <ashr>
// CHECK:             mpir_index.has_sibling <srem>, <or>
// CHECK:             mpir_index.has_sibling <lshr>, <ashr>
// CHECK:             mpir_index.has_sibling <lshr>, <or>
// CHECK:             mpir_index.has_sibling <ashr>, <or>
// CHECK:             mpir_index.has_shape <add>, 1, 2, 32
// CHECK:             mpir_index.has_shape <fadd>, 6144, 0, 0
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <fsub>, 1024, 0, 0
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_shape <fmul>, 253952, 0, 0
// CHECK:             mpir_index.has_shape <udiv>, 4, 0, 32
// CHECK:             mpir_index.has_shape <sdiv>, 0, 0, 32
// CHECK:             mpir_index.has_shape <fdiv>, 0, 2048, 0
// CHECK:             mpir_index.has_shape <urem>, 0, 0, 32
// CHECK:             mpir_index.has_shape <srem>, 0, 0, 32
// CHECK:             mpir_index.has_shape <shl>, 3, 0, 32
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 32
// CHECK:             mpir_index.has_shape <ashr>, 0, 0, 32
// CHECK:             mpir_index.has_shape <and>, 0, 0, 32
// CHECK:             mpir_index.has_shape <or>, 0, 0, 32
// CHECK:             mpir_index.has_shape <xor>, 0, 0, 32
// CHECK:             mpir_index.has_fact 1, <sub>, 2, 129
// CHECK:             mpir_index.has_fact 3, <udiv>, 2, 130
// CHECK:             mpir_index.has_fact 4, <sdiv>, 2, 125
// CHECK:             mpir_index.has_fact 7, <shl>, 2, 129
// CHECK:             mpir_index.has_fact 12, <xor>, 2, 127
// CHECK:             mpir_index.typing <add> <present = 1, absent = 2, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <udiv> <present = 4, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sdiv> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <urem> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <srem> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <shl> <present = 3, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <ashr> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <and> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <or> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <xor> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fadd> <present = 6144, absent = 0, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fsub> <present = 1024, absent = 0, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fmul> <present = 253952, absent = 0, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fdiv> <present = 0, absent = 2048, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <frem> <present = 0, absent = 0, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fneg> <present = 0, absent = 0, operand_types = {{\[\[}}0, 2]], value_operand = [true]>
// CHECK:           }
// CHECK:         }

// -----

// Calls: of a named function, of an intrinsic by name or by a variable
// part of its name, of a function variable with its type, with the rest
// of the arguments captured, with a label argument, and void calls.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":234:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.global "callee" : <Value> loc("to-index.mlir":236:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "callee" : <Value>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":238:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":240:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %3 = mpir.type.int 8 : <Type> loc("to-index.mlir":242:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 8 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":244:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <call> (%0, %1, %2, %x, %3, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":246:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":248:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.global "llvm.umax.i32" : <Value> loc("to-index.mlir":250:1)
// CHECK:           %[[GLOBAL_1:.*]] = mpir.global "llvm.umax.i32" : <Value>
  %6 = mpir.type.int 32 : <Type> loc("to-index.mlir":252:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %7 = mpir.type.int 32 : <Type> loc("to-index.mlir":254:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":256:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_b = mpir.inst <call> (%4, %5, %6, %i_a, %7, %8) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":258:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_3]], %[[GLOBAL_1]], %[[TYPE_4]], %[[INST_0]], %[[TYPE_5]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat> loc("to-index.mlir":260:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %9 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":262:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %id = mpir.var "id" : <IntrinsicID> loc("to-index.mlir":264:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "id" : <IntrinsicID>
  %10 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":266:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-index.mlir":268:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
  %11 = mpir.type.int 1 : <Type> loc("to-index.mlir":270:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
  %12 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":272:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%9, %id, %10, %v, %11, %12) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":274:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_6]], %[[VAR_3]], %[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[INT_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-index.mlir":276:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.type.int 32 : <Type> loc("to-index.mlir":278:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.type.func %13(%14) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":280:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.func %[[TYPE_9]](%[[TYPE_10]]) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %f = mpir.var "f" : <Function> loc("to-index.mlir":282:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "f" : <Function>
  %16 = mpir.type.int 32 : <Type> loc("to-index.mlir":284:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %i_d = mpir.inst <call> (%15, %f, %16, %i_a) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":286:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <call> (%[[TYPE_11]], %[[VAR_5]], %[[TYPE_12]], %[[INST_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %ret = mpir.var "ret" : <Type> loc("to-index.mlir":288:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "ret" : <Type>
  %id2 = mpir.var "id2" : <IntrinsicID> loc("to-index.mlir":290:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "id2" : <IntrinsicID>
  %types = mpir.var "types" : <TypeArray> loc("to-index.mlir":292:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "types" : <TypeArray>
  %values = mpir.var "values" : <ValueArray> loc("to-index.mlir":294:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "values" : <ValueArray>
  %i_e = mpir.inst <call> (%ret, %id2, %types, %values) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-index.mlir":296:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <call> (%[[VAR_6]], %[[VAR_7]], %[[VAR_8]], %[[VAR_9]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-index.mlir":298:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.global "first" : <Value> loc("to-index.mlir":300:1)
// CHECK:           %[[GLOBAL_2:.*]] = mpir.global "first" : <Value>
  %19 = mpir.type.int 32 : <Type> loc("to-index.mlir":302:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %rest_types = mpir.var "rest_types" : <TypeArray> loc("to-index.mlir":304:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "rest_types" : <TypeArray>
  %rest_values = mpir.var "rest_values" : <ValueArray> loc("to-index.mlir":306:1)
// CHECK:           %[[VAR_11:.*]] = mpir.var "rest_values" : <ValueArray>
  %i_f = mpir.inst <call> (%17, %18, %19, %i_a, %rest_types, %rest_values) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-index.mlir":308:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <call> (%[[TYPE_13]], %[[GLOBAL_2]], %[[TYPE_14]], %[[INST_0]], %[[VAR_10]], %[[VAR_11]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %20 = mpir.type.prim void : <Type> loc("to-index.mlir":310:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim void : <Type>
  %21 = mpir.global "take" : <Value> loc("to-index.mlir":312:1)
// CHECK:           %[[GLOBAL_3:.*]] = mpir.global "take" : <Value>
  %22 = mpir.type.prim label : <Type> loc("to-index.mlir":314:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.prim label : <Type>
  %target = mpir.var "target" : <BasicBlock> loc("to-index.mlir":316:1)
// CHECK:           %[[VAR_12:.*]] = mpir.var "target" : <BasicBlock>
  %i_lb = mpir.inst <call> (%20, %21, %22, %target) <result_name = "lb", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-index.mlir":318:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <call> (%[[TYPE_15]], %[[GLOBAL_3]], %[[TYPE_16]], %[[VAR_12]]) <result_name = "lb", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %23 = mpir.type.int 32 : <Type> loc("to-index.mlir":320:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %24 = mpir.global "0" : <Value> loc("to-index.mlir":322:1)
// CHECK:           %[[GLOBAL_4:.*]] = mpir.global "0" : <Value>
  %25 = mpir.type.int 32 : <Type> loc("to-index.mlir":324:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
  %i_num = mpir.inst <call> (%23, %24, %25, %i_a) <result_name = "num", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":326:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <call> (%[[TYPE_17]], %[[GLOBAL_4]], %[[TYPE_18]], %[[INST_0]]) <result_name = "num", flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %26 = mpir.type.prim void : <Type> loc("to-index.mlir":328:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.prim void : <Type>
  %27 = mpir.global "sink" : <Value> loc("to-index.mlir":330:1)
// CHECK:           %[[GLOBAL_5:.*]] = mpir.global "sink" : <Value>
  %28 = mpir.type.int 32 : <Type> loc("to-index.mlir":332:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 32 : <Type>
  %29 = mpir.inst <call> (%26, %27, %28, %i_f) <flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":334:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <call> (%[[TYPE_19]], %[[GLOBAL_5]], %[[TYPE_20]], %[[INST_5]]) <flags = [], flag_modes = [], operand_kinds = [2, 1, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":336:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_edge <call> -> <call>
// CHECK:             mpir_index.has_global "0"
// CHECK:             mpir_index.has_global "callee"
// CHECK:             mpir_index.has_global "first"
// CHECK:             mpir_index.has_global "llvm.umax.i32"
// CHECK:             mpir_index.has_global "sink"
// CHECK:             mpir_index.has_global "take"
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 1, <call>, 4, 129
// CHECK:             mpir_index.has_fact 2, <call>, 4, 128
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 8, 0]], value_operand = [false, true, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0], [], [2, 0, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}7, 1, [1, 32, 0], [1, 32, 0]], [], [1, 32, 0]], value_operand = [false, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}3, 1], [], []], value_operand = [false, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], []], value_operand = [false, true, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}0, 5], [], [0, 6]], value_operand = [false, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0]], value_operand = [false, true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}0, 5], [], [1, 32, 0]], value_operand = [false, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Casts: the source operand and the destination type, with 'nneg'.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 64 : <Type> loc("to-index.mlir":368:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 64 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":370:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":372:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_t = mpir.inst <trunc> (%0, %x, %1) <result_name = "t", flags = [1], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":374:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "t", flags = [1], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":376:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.type.int 64 : <Type> loc("to-index.mlir":378:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
  %i_z = mpir.inst <zext> (%2, %i_t, %3) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":380:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_3]]) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":382:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %wide = mpir.var "wide" : <Nat> loc("to-index.mlir":384:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "wide" : <Nat>
  %5 = mpir.type.meta_int %wide : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":386:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %i_s = mpir.inst <sext> (%4, %i_t, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":388:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <sext> (%[[TYPE_4]], %[[INST_0]], %[[TYPE_5]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim double : <Type> loc("to-index.mlir":390:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand> loc("to-index.mlir":392:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "d" : <Operand>
  %7 = mpir.type.prim float : <Type> loc("to-index.mlir":394:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim float : <Type>
  %i_ft = mpir.inst <fptrunc> (%6, %d, %7) <result_name = "ft", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":396:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <fptrunc> (%[[TYPE_6]], %[[VAR_2]], %[[TYPE_7]]) <result_name = "ft", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim float : <Type> loc("to-index.mlir":398:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim float : <Type>
  %9 = mpir.type.prim double : <Type> loc("to-index.mlir":400:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim double : <Type>
  %i_fe = mpir.inst <fpext> (%8, %i_ft, %9) <result_name = "fe", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":402:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <fpext> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]]) <result_name = "fe", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type> loc("to-index.mlir":404:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim double : <Type>
  %11 = mpir.type.int 32 : <Type> loc("to-index.mlir":406:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %i_fu = mpir.inst <fptoui> (%10, %i_fe, %11) <result_name = "fu", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":408:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <fptoui> (%[[TYPE_10]], %[[INST_4]], %[[TYPE_11]]) <result_name = "fu", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type> loc("to-index.mlir":410:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.prim double : <Type>
  %13 = mpir.type.int 32 : <Type> loc("to-index.mlir":412:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %i_fs = mpir.inst <fptosi> (%12, %i_fe, %13) <result_name = "fs", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":414:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <fptosi> (%[[TYPE_12]], %[[INST_4]], %[[TYPE_13]]) <result_name = "fs", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 32 : <Type> loc("to-index.mlir":416:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %15 = mpir.type.prim half : <Type> loc("to-index.mlir":418:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim half : <Type>
  %i_uf = mpir.inst <uitofp> (%14, %i_fu, %15) <result_name = "uf", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":420:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <uitofp> (%[[TYPE_14]], %[[INST_5]], %[[TYPE_15]]) <result_name = "uf", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %16 = mpir.type.int 32 : <Type> loc("to-index.mlir":422:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %17 = mpir.type.prim bfloat : <Type> loc("to-index.mlir":424:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.prim bfloat : <Type>
  %i_sf = mpir.inst <sitofp> (%16, %i_fs, %17) <result_name = "sf", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":426:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <sitofp> (%[[TYPE_16]], %[[INST_6]], %[[TYPE_17]]) <result_name = "sf", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %18 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":428:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-index.mlir":430:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %19 = mpir.type.int 64 : <Type> loc("to-index.mlir":432:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 64 : <Type>
  %i_pi = mpir.inst <ptrtoint> (%18, %p, %19) <result_name = "pi", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":434:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <ptrtoint> (%[[TYPE_18]], %[[VAR_3]], %[[TYPE_19]]) <result_name = "pi", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %20 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":436:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %21 = mpir.type.int 64 : <Type> loc("to-index.mlir":438:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 64 : <Type>
  %i_pa = mpir.inst <ptrtoaddr> (%20, %p, %21) <result_name = "pa", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":440:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <ptrtoaddr> (%[[TYPE_20]], %[[VAR_3]], %[[TYPE_21]]) <result_name = "pa", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %22 = mpir.type.int 64 : <Type> loc("to-index.mlir":442:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 64 : <Type>
  %23 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":444:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %i_ip = mpir.inst <inttoptr> (%22, %i_pi, %23) <result_name = "ip", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":446:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <inttoptr> (%[[TYPE_22]], %[[INST_9]], %[[TYPE_23]]) <result_name = "ip", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type> loc("to-index.mlir":448:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 32 : <Type>
  %25 = mpir.type.seq vector 2 x %24 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":450:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.seq vector 2 x %[[TYPE_24]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-index.mlir":452:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "v" : <Operand>
  %26 = mpir.type.int 64 : <Type> loc("to-index.mlir":454:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.int 64 : <Type>
  %i_bc = mpir.inst <bitcast> (%25, %v, %26) <result_name = "bc", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":456:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <bitcast> (%[[TYPE_25]], %[[VAR_4]], %[[TYPE_26]]) <result_name = "bc", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %27 = mpir.type.int 32 : <Type> loc("to-index.mlir":458:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 32 : <Type>
  %i_fr = mpir.inst <freeze> (%27, %i_t) <result_name = "fr", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":460:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[INST_0]]) <result_name = "fr", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":462:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <trunc>
// CHECK:             mpir_index.has_instruction <zext>
// CHECK:             mpir_index.has_instruction <sext>
// CHECK:             mpir_index.has_instruction <fptrunc>
// CHECK:             mpir_index.has_instruction <fpext>
// CHECK:             mpir_index.has_instruction <fptoui>
// CHECK:             mpir_index.has_instruction <fptosi>
// CHECK:             mpir_index.has_instruction <uitofp>
// CHECK:             mpir_index.has_instruction <sitofp>
// CHECK:             mpir_index.has_instruction <ptrtoint>
// CHECK:             mpir_index.has_instruction <ptrtoaddr>
// CHECK:             mpir_index.has_instruction <inttoptr>
// CHECK:             mpir_index.has_instruction <bitcast>
// CHECK:             mpir_index.has_instruction <freeze>
// CHECK:             mpir_index.has_edge <zext> -> <trunc>
// CHECK:             mpir_index.has_edge <sext> -> <trunc>
// CHECK:             mpir_index.has_edge <fpext> -> <fptrunc>
// CHECK:             mpir_index.has_edge <fptoui> -> <fpext>
// CHECK:             mpir_index.has_edge <fptosi> -> <fpext>
// CHECK:             mpir_index.has_edge <uitofp> -> <fptoui>
// CHECK:             mpir_index.has_edge <sitofp> -> <fptosi>
// CHECK:             mpir_index.has_edge <inttoptr> -> <ptrtoint>
// CHECK:             mpir_index.has_edge <freeze> -> <trunc>
// CHECK:             mpir_index.has_sibling <zext>, <sext>
// CHECK:             mpir_index.has_sibling <zext>, <freeze>
// CHECK:             mpir_index.has_sibling <sext>, <freeze>
// CHECK:             mpir_index.has_sibling <fptoui>, <fptosi>
// CHECK:             mpir_index.has_sibling <ptrtoint>, <ptrtoaddr>
// CHECK:             mpir_index.has_shape <trunc>, 2, 0, 32
// CHECK:             mpir_index.has_shape <zext>, 256, 0, 64
// CHECK:             mpir_index.has_shape <fptoui>, 0, 0, 32
// CHECK:             mpir_index.has_shape <fptosi>, 0, 0, 32
// CHECK:             mpir_index.has_shape <uitofp>, 256, 0, 0
// CHECK:             mpir_index.has_shape <ptrtoint>, 0, 0, 64
// CHECK:             mpir_index.has_shape <ptrtoaddr>, 0, 0, 64
// CHECK:             mpir_index.has_shape <bitcast>, 0, 0, 64
// CHECK:             mpir_index.typing <trunc> <present = 2, absent = 0, operand_types = {{\[\[}}1, 64, 0], [1, 32, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <zext> <present = 256, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <sext> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [2, 0, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <fptrunc> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [0, 2]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <fpext> <present = 0, absent = 0, operand_types = {{\[\[}}0, 2], [0, 3]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <fptoui> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [1, 32, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <fptosi> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [1, 32, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <uitofp> <present = 256, absent = 0, operand_types = {{\[\[}}1, 32, 0], [0, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <sitofp> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [0, 1]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <ptrtoint> <present = 0, absent = 0, operand_types = {{\[\[}}4, -1, 1], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <ptrtoaddr> <present = 0, absent = 0, operand_types = {{\[\[}}4, -1, 1], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <inttoptr> <present = 0, absent = 0, operand_types = {{\[\[}}1, 64, 0], [4, -1, 1]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <bitcast> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 2, -1, [1, 32, 0]], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0]], value_operand = [true]>
// CHECK:           }
// CHECK:         }

// -----

// Comparisons with a written or a variable predicate, 'samesign', and
// selects with fast-math flags.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.keyword eq : <Value> loc("to-index.mlir":525:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword eq : <Value>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":527:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":529:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":531:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c1 = mpir.inst <icmp> (%0, %1, %x, %1, %2) <result_name = "c1", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":533:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "c1", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.keyword ult : <Value> loc("to-index.mlir":535:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword ult : <Value>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":537:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":539:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_c2 = mpir.inst <icmp> (%3, %4, %x, %4, %y) <result_name = "c2", flags = [9], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":541:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "c2", flags = [9], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %pred = mpir.var "pred" : <CmpPredicate> loc("to-index.mlir":543:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "pred" : <CmpPredicate>
  %5 = mpir.type.int 32 : <Type> loc("to-index.mlir":545:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c3 = mpir.inst <icmp> (%pred, %5, %x, %5, %y) <result_name = "c3", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":547:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_2]], %[[TYPE_2]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c3", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.keyword olt : <Value> loc("to-index.mlir":549:1)
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword olt : <Value>
  %7 = mpir.type.prim float : <Type> loc("to-index.mlir":551:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim float : <Type>
  %f = mpir.var "f" : <Operand> loc("to-index.mlir":553:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "f" : <Operand>
  %8 = mpir.float 0.000000e+00 : f64 -> <Value> loc("to-index.mlir":555:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 0.000000e+00 : f64 -> <Value>
  %i_c4 = mpir.inst <fcmp> (%6, %7, %f, %7, %8) <result_name = "c4", flags = [11], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":557:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <fcmp> (%[[KEYWORD_2]], %[[TYPE_3]], %[[VAR_3]], %[[TYPE_3]], %[[FLOAT_0]]) <result_name = "c4", flags = [11], flag_modes = [0], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %fpred = mpir.var "fpred" : <CmpPredicate> loc("to-index.mlir":559:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "fpred" : <CmpPredicate>
  %9 = mpir.type.prim double : <Type> loc("to-index.mlir":561:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim double : <Type>
  %d = mpir.var "d" : <Operand> loc("to-index.mlir":563:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "d" : <Operand>
  %e = mpir.var "e" : <Operand> loc("to-index.mlir":565:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "e" : <Operand>
  %i_c5 = mpir.inst <fcmp> (%fpred, %9, %d, %9, %e) <result_name = "c5", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":567:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <fcmp> (%[[VAR_4]], %[[TYPE_4]], %[[VAR_5]], %[[TYPE_4]], %[[VAR_6]]) <result_name = "c5", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 1 : <Type> loc("to-index.mlir":569:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 1 : <Type>
  %11 = mpir.type.int 32 : <Type> loc("to-index.mlir":571:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 32 : <Type>
  %12 = mpir.type.int 32 : <Type> loc("to-index.mlir":573:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %i_s1 = mpir.inst <select> (%10, %i_c1, %11, %x, %12, %y) <result_name = "s1", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":575:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[VAR_0]], %[[TYPE_7]], %[[VAR_1]]) <result_name = "s1", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 1 : <Type> loc("to-index.mlir":577:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
  %14 = mpir.type.prim float : <Type> loc("to-index.mlir":579:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim float : <Type>
  %15 = mpir.type.prim float : <Type> loc("to-index.mlir":581:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim float : <Type>
  %16 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-index.mlir":583:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %i_s2 = mpir.inst <select> (%13, %i_c4, %14, %f, %15, %16) <result_name = "s2", flags = [11], flag_modes = [0], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":585:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <select> (%[[TYPE_8]], %[[INST_3]], %[[TYPE_9]], %[[VAR_3]], %[[TYPE_10]], %[[FLOAT_1]]) <result_name = "s2", flags = [11], flag_modes = [0], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 1 : <Type> loc("to-index.mlir":587:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 1 : <Type>
  %18 = mpir.type.seq vector 2 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":589:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 2 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %mask = mpir.var "mask" : <Operand> loc("to-index.mlir":591:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "mask" : <Operand>
  %19 = mpir.type.int 32 : <Type> loc("to-index.mlir":593:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %20 = mpir.type.seq vector 2 x %19 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":595:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq vector 2 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-index.mlir":597:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "v" : <Operand>
  %21 = mpir.type.int 32 : <Type> loc("to-index.mlir":599:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.type.seq vector 2 x %21 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":601:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %23 = mpir.keyword zeroinitializer : <Value> loc("to-index.mlir":603:1)
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
  %i_s3 = mpir.inst <select> (%18, %mask, %20, %v, %22, %23) <result_name = "s3", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":605:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_12]], %[[VAR_7]], %[[TYPE_14]], %[[VAR_8]], %[[TYPE_16]], %[[KEYWORD_3]]) <result_name = "s3", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":607:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <icmp>
// CHECK:             mpir_index.has_instruction <fcmp>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <select> -> <icmp>
// CHECK:             mpir_index.has_edge <select> -> <fcmp>
// CHECK:             mpir_index.has_sibling <icmp>, <select>
// CHECK:             mpir_index.has_sibling <fcmp>, <select>
// CHECK:             mpir_index.has_shape <icmp>, 512, 0, 0
// CHECK:             mpir_index.has_shape <fcmp>, 2048, 0, 0
// CHECK:             mpir_index.has_shape <select>, 2048, 0, 0
// CHECK:             mpir_index.has_fact 0, <icmp>, 2, 128
// CHECK:             mpir_index.typing <icmp> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <icmp> <present = 512, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <icmp> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fcmp> <present = 2048, absent = 0, operand_types = {{\[\[}}0, 2], [0, 2]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fcmp> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [0, 3]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 2048, absent = 0, operand_types = {{\[\[}}1, 1, 0], [0, 2], [0, 2]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 2, -1, [1, 1, 0]], [5, 1, 2, -1, [1, 32, 0]], [5, 1, 2, -1, [1, 32, 0]]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Constant operands: integers (wide ones too), floats, keywords, globals,
// and aggregates of each delimiter.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":639:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":641:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":643:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":645:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":647:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int -1 : si1 : <Value> loc("to-index.mlir":649:1)
// CHECK:           %[[INT_1:.*]] = mpir.int -1 : si1 : <Value>
  %i_b = mpir.inst <add> (%2, %i_a, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":651:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 128 : <Type> loc("to-index.mlir":653:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 128 : <Type>
  %w = mpir.var "w" : <Operand> loc("to-index.mlir":655:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Operand>
  %5 = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value> loc("to-index.mlir":657:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 170141183460469231731687303715884105727 : ui127 : <Value>
  %i_c = mpir.inst <add> (%4, %w, %4, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":659:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_2]], %[[VAR_1]], %[[TYPE_2]], %[[INT_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type> loc("to-index.mlir":661:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
  %bit = mpir.var "bit" : <Boolean> loc("to-index.mlir":663:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "bit" : <Boolean>
  %7 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":665:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %i_d = mpir.inst <add> (%6, %bit, %6, %7) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":667:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[VAR_2]], %[[TYPE_3]], %[[INT_3]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 1 : <Type> loc("to-index.mlir":669:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %9 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":671:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 0 : ui1 : <Value>
  %i_e = mpir.inst <add> (%8, %i_d, %8, %9) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":673:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <add> (%[[TYPE_4]], %[[INST_3]], %[[TYPE_4]], %[[INT_4]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %10 = mpir.type.prim double : <Type> loc("to-index.mlir":675:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim double : <Type>
  %fx = mpir.var "fx" : <Operand> loc("to-index.mlir":677:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "fx" : <Operand>
  %11 = mpir.float 1.500000e-03 : f64 -> <Value> loc("to-index.mlir":679:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.500000e-03 : f64 -> <Value>
  %i_f = mpir.inst <fadd> (%10, %fx, %10, %11) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":681:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <fadd> (%[[TYPE_5]], %[[VAR_3]], %[[TYPE_5]], %[[FLOAT_0]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %12 = mpir.type.prim double : <Type> loc("to-index.mlir":683:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim double : <Type>
  %13 = mpir.float 0x7FF0000000000000 : f64 -> <Value> loc("to-index.mlir":685:1)
// CHECK:           %[[FLOAT_1:.*]] = mpir.float 0x7FF0000000000000 : f64 -> <Value>
  %i_g = mpir.inst <fadd> (%12, %i_f, %12, %13) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":687:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <fadd> (%[[TYPE_6]], %[[INST_5]], %[[TYPE_6]], %[[FLOAT_1]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %14 = mpir.type.int 1 : <Type> loc("to-index.mlir":689:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean> loc("to-index.mlir":691:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "c" : <Boolean>
  %15 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":693:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %16 = mpir.keyword null : <Value> loc("to-index.mlir":695:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
  %17 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":697:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %18 = mpir.global "global" : <Value> loc("to-index.mlir":699:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "global" : <Value>
  %i_h = mpir.inst <select> (%14, %c, %15, %16, %17, %18) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":701:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_4]], %[[TYPE_8]], %[[KEYWORD_0]], %[[TYPE_9]], %[[GLOBAL_0]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %19 = mpir.type.int 1 : <Type> loc("to-index.mlir":703:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 1 : <Type>
  %20 = mpir.type.int 32 : <Type> loc("to-index.mlir":705:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %21 = mpir.keyword poison : <Value> loc("to-index.mlir":707:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword poison : <Value>
  %22 = mpir.type.int 32 : <Type> loc("to-index.mlir":709:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 32 : <Type>
  %23 = mpir.keyword undef : <Value> loc("to-index.mlir":711:1)
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword undef : <Value>
  %i_i = mpir.inst <select> (%19, %c, %20, %21, %22, %23) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":713:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <select> (%[[TYPE_10]], %[[VAR_4]], %[[TYPE_11]], %[[KEYWORD_1]], %[[TYPE_12]], %[[KEYWORD_2]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 1 : <Type> loc("to-index.mlir":715:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 1 : <Type>
  %25 = mpir.type.int 32 : <Type> loc("to-index.mlir":717:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %26 = mpir.type.seq vector 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":719:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.seq vector 2 x %[[TYPE_14]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.keyword zeroinitializer : <Value> loc("to-index.mlir":721:1)
// CHECK:           %[[KEYWORD_3:.*]] = mpir.keyword zeroinitializer : <Value>
  %28 = mpir.type.int 32 : <Type> loc("to-index.mlir":723:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %29 = mpir.type.seq vector 2 x %28 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":725:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.seq vector 2 x %[[TYPE_16]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %30 = mpir.type.int 32 : <Type> loc("to-index.mlir":727:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 32 : <Type>
  %31 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":729:1)
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
  %32 = mpir.type.int 32 : <Type> loc("to-index.mlir":731:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 32 : <Type>
  %33 = mpir.int 2 : ui2 : <Value> loc("to-index.mlir":733:1)
// CHECK:           %[[INT_6:.*]] = mpir.int 2 : ui2 : <Value>
  %34 = mpir.aggregate vector(%30, %31, %32, %33) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-index.mlir":735:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_18]], %[[INT_5]], %[[TYPE_19]], %[[INT_6]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_j = mpir.inst <select> (%24, %c, %26, %27, %29, %34) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":737:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <select> (%[[TYPE_13]], %[[VAR_4]], %[[TYPE_15]], %[[KEYWORD_3]], %[[TYPE_17]], %[[AGGREGATE_0]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %35 = mpir.type.int 1 : <Type> loc("to-index.mlir":739:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 1 : <Type>
  %36 = mpir.type.int 8 : <Type> loc("to-index.mlir":741:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 8 : <Type>
  %37 = mpir.type.seq array 2 x %36 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":743:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.seq array 2 x %[[TYPE_21]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %38 = mpir.type.int 8 : <Type> loc("to-index.mlir":745:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.int 8 : <Type>
  %39 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":747:1)
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
  %40 = mpir.type.int 8 : <Type> loc("to-index.mlir":749:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
  %41 = mpir.int 2 : ui2 : <Value> loc("to-index.mlir":751:1)
// CHECK:           %[[INT_8:.*]] = mpir.int 2 : ui2 : <Value>
  %42 = mpir.aggregate array(%38, %39, %40, %41) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-index.mlir":753:1)
// CHECK:           %[[AGGREGATE_1:.*]] = mpir.aggregate array(%[[TYPE_23]], %[[INT_7]], %[[TYPE_24]], %[[INT_8]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %43 = mpir.type.int 8 : <Type> loc("to-index.mlir":755:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 8 : <Type>
  %44 = mpir.type.seq array 2 x %43 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":757:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %arr = mpir.var "arr" : <Operand> loc("to-index.mlir":759:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "arr" : <Operand>
  %i_k = mpir.inst <select> (%35, %c, %37, %42, %44, %arr) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":761:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <select> (%[[TYPE_20]], %[[VAR_4]], %[[TYPE_22]], %[[AGGREGATE_1]], %[[TYPE_26]], %[[VAR_5]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %45 = mpir.type.int 1 : <Type> loc("to-index.mlir":763:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 1 : <Type>
  %46 = mpir.type.int 32 : <Type> loc("to-index.mlir":765:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.int 32 : <Type>
  %47 = mpir.type.int 8 : <Type> loc("to-index.mlir":767:1)
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 8 : <Type>
  %48 = mpir.type.struct{%46, %47} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":769:1)
// CHECK:           %[[TYPE_30:.*]] = mpir.type.struct{%[[TYPE_28]], %[[TYPE_29]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %49 = mpir.type.int 32 : <Type> loc("to-index.mlir":771:1)
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
  %50 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":773:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 1 : ui1 : <Value>
  %51 = mpir.type.int 8 : <Type> loc("to-index.mlir":775:1)
// CHECK:           %[[TYPE_32:.*]] = mpir.type.int 8 : <Type>
  %52 = mpir.int 2 : ui2 : <Value> loc("to-index.mlir":777:1)
// CHECK:           %[[INT_10:.*]] = mpir.int 2 : ui2 : <Value>
  %53 = mpir.aggregate struct(%49, %50, %51, %52) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-index.mlir":779:1)
// CHECK:           %[[AGGREGATE_2:.*]] = mpir.aggregate struct(%[[TYPE_31]], %[[INT_9]], %[[TYPE_32]], %[[INT_10]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %54 = mpir.type.int 32 : <Type> loc("to-index.mlir":781:1)
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
  %55 = mpir.type.int 8 : <Type> loc("to-index.mlir":783:1)
// CHECK:           %[[TYPE_34:.*]] = mpir.type.int 8 : <Type>
  %56 = mpir.type.struct{%54, %55} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":785:1)
// CHECK:           %[[TYPE_35:.*]] = mpir.type.struct{%[[TYPE_33]], %[[TYPE_34]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %st = mpir.var "st" : <Operand> loc("to-index.mlir":787:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "st" : <Operand>
  %i_l = mpir.inst <select> (%45, %c, %48, %53, %56, %st) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":789:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <select> (%[[TYPE_27]], %[[VAR_4]], %[[TYPE_30]], %[[AGGREGATE_2]], %[[TYPE_35]], %[[VAR_6]]) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":791:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <fadd>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <add> -> <add>
// CHECK:             mpir_index.has_edge <fadd> -> <fadd>
// CHECK:             mpir_index.has_global "global"
// CHECK:             mpir_index.has_shape <add>, 0, 0, 1
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <add>, 0, 0, 128
// CHECK:             mpir_index.has_fact 0, <add>, 2, 128
// CHECK:             mpir_index.has_fact 1, <add>, 2, 127
// CHECK:             mpir_index.has_fact 3, <add>, 2, 129
// CHECK:             mpir_index.has_fact 4, <add>, 2, 128
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 128, 0], [1, 128, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 1, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 1, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fadd> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [0, 3]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <fadd> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3], [0, 3]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [4, -1, 1], [4, -1, 1]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [5, 1, 2, -1, [1, 32, 0]], [5, 1, 2, -1, [1, 32, 0]]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [5, 0, 2, -1, [1, 8, 0]], [5, 0, 2, -1, [1, 8, 0]]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [6, 0, [1, 32, 0], [1, 8, 0]], [6, 0, [1, 32, 0], [1, 8, 0]]], value_operand = [true, true, true]>
// CHECK:           }
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
  %0 = mpir_expr.read %arg1 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-index.mlir":833:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-index.mlir":835:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %2 = mpir_expr.call call "ule"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("to-index.mlir":837:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ule"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-index.mlir":839:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %4 = mpir_expr.read %arg2 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-index.mlir":841:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_2]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %5 = mpir_expr.call call "ule"(%3, %4) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("to-index.mlir":843:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "ule"(%[[READ_2]], %[[READ_3]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("to-index.mlir":845:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %6 : <Boolean> loc("to-index.mlir":847:1)
// CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
} loc("to-index.mlir":849:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %n = mpir.var "n" : <Nat> loc("to-index.mlir":853:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":855:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":857:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %c = mpir.var "c" : <Operand> loc("to-index.mlir":859:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "c" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %c) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":861:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("to-index.mlir":863:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %2 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index.mlir":865:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":867:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("to-index.mlir":869:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %5 = mpir_expr.int 64 : ui64 : <Integer> loc("to-index.mlir":871:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 64 : ui64 : <Integer>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":873:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "||"(%3, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":875:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("to-index.mlir":877:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
  %8 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":879:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "isZero"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":881:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.call unary "!"(%9) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":883:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call unary "!"(%[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %11 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":885:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %12 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":887:1)
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %13 = mpir_expr.int 8 : ui64 : <Integer> loc("to-index.mlir":889:1)
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 8 : ui64 : <Integer>
  %14 = mpir_expr.apply @inRange(%11, %12, %13) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("to-index.mlir":891:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @inRange(%[[READ_3]], %[[INT_2]], %[[INT_3]]) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  %15 = mpir_expr.call binary "&&"(%10, %14) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":893:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %15 : <Boolean> loc("to-index.mlir":895:1)
// CHECK:           mpir.require %[[CALL_5]] : <Boolean>
  %16 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":897:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.int 2 : ui64 : <Integer> loc("to-index.mlir":899:1)
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %18 = mpir_expr.call binary "*"(%16, %17) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":901:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "*"(%[[READ_4]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %19 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":903:1)
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %20 = mpir_expr.call binary "+"(%18, %19) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":905:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "+"(%[[CALL_6]], %[[INT_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %21 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":907:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %22 = mpir_expr.call binary "-"(%20, %21) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":909:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "-"(%[[CALL_7]], %[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %23 = mpir_expr.int 3 : ui64 : <Integer> loc("to-index.mlir":911:1)
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
  %24 = mpir_expr.call unary "-"(%23) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":913:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call unary "-"(%[[INT_6]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %25 = mpir_expr.call binary "!="(%22, %24) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":915:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_8]], %[[CALL_9]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 : <Boolean> loc("to-index.mlir":917:1)
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
  %26 = mpir_expr.str "i8" : <String> loc("to-index.mlir":919:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "i8" : <String>
  %27 = mpir_expr.str "i16" : <String> loc("to-index.mlir":921:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "i16" : <String>
  %28 = mpir_expr.array %26, %27 : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray> loc("to-index.mlir":923:1)
// CHECK:           %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
  %29 = mpir_expr.int 0 : ui64 : <Integer> loc("to-index.mlir":925:1)
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
  %30 = mpir_expr.index %28[%29] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String> loc("to-index.mlir":927:1)
// CHECK:           %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_7]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
  %31 = mpir_expr.str "i8" : <String> loc("to-index.mlir":929:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "i8" : <String>
  %32 = mpir_expr.call binary "=="(%30, %31) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":931:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %32 : <Boolean> loc("to-index.mlir":933:1)
// CHECK:           mpir.require %[[CALL_11]] : <Boolean>
  %33 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":935:1)
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %34 = mpir_expr.call call "bitWidth"(%33) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":937:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %35 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index.mlir":939:1)
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %36 = mpir_expr.call binary "=="(%34, %35) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":941:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[INT_8]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":943:1)
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %38 = mpir_expr.str "Argument" : <String> loc("to-index.mlir":945:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "Argument" : <String>
  %39 = mpir_expr.call call "isa"(%37, %38) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":947:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "isa"(%[[READ_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.call binary "&&"(%36, %39) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":949:1)
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call binary "&&"(%[[CALL_13]], %[[CALL_14]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %40 : <Boolean> loc("to-index.mlir":951:1)
// CHECK:           mpir.require %[[CALL_15]] : <Boolean>
  %cmp = mpir.var "cmp" : <Instruction> loc("to-index.mlir":953:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "cmp" : <Instruction>
  %p = mpir.var "p" : <CmpPredicate> loc("to-index.mlir":955:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "p" : <CmpPredicate>
  %41 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":957:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %42 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":959:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 0 : ui1 : <Value>
  %i_b = mpir.inst <icmp> capture %cmp (%p, %41, %i_a, %41, %42) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":961:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <icmp> capture %[[VAR_3]] (%[[VAR_4]], %[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_9]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %43 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":963:1)
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %44 = mpir_expr.read %cmp : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-index.mlir":965:1)
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %45 = mpir_expr.call call "isKnownNonZero"(%43, %44) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":967:1)
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_8]], %[[READ_9]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %46 = mpir_expr.read %p : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String> loc("to-index.mlir":969:1)
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
  %47 = mpir_expr.str "eq" : <String> loc("to-index.mlir":971:1)
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "eq" : <String>
  %48 = mpir_expr.call binary "=="(%46, %47) anchor %i_b : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":973:1)
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[READ_10]], %[[STR_4]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %49 = mpir_expr.call binary "&&"(%45, %48) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":975:1)
// CHECK:           %[[CALL_18:.*]] = mpir_expr.call binary "&&"(%[[CALL_16]], %[[CALL_17]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %49 : <Boolean> loc("to-index.mlir":977:1)
// CHECK:           mpir.require %[[CALL_18]] : <Boolean>
  %50 = mpir_expr.bool true : <Boolean> loc("to-index.mlir":979:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
  mpir.require %50 : <Boolean> loc("to-index.mlir":981:1)
// CHECK:           mpir.require %[[BOOL_0]] : <Boolean>
  %51 = mpir_expr.bool false : <Boolean> loc("to-index.mlir":983:1)
// CHECK:           %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
  %52 = mpir_expr.call unary "!"(%51) anchor %i_b : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":985:1)
// CHECK:           %[[CALL_19:.*]] = mpir_expr.call unary "!"(%[[BOOL_1]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %52 : <Boolean> loc("to-index.mlir":987:1)
// CHECK:           mpir.require %[[CALL_19]] : <Boolean>
} loc("to-index.mlir":989:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <icmp>
// CHECK:             mpir_index.has_edge <icmp> -> <add>
// CHECK:             mpir_index.has_fact 1, <icmp>, 2, 128
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0], [2, 0, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <icmp> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0], [2, 0, 0]], value_operand = [true, true]>
// CHECK:             %[[TYPE_VAR_0:.*]] = mpir_index.type_var 0 {var_name = "n"} : <Nat>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 64 : ui64 : <Integer>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[NODE_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "c"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[NODE_3]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call unary "!"(%[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 8 : ui64 : <Integer>
// CHECK:             %[[APPLY_0:.*]] = mpir_expr.apply @inRange(%[[READ_3]], %[[INT_2]], %[[INT_3]]) : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_5]] : <Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "*"(%[[READ_4]], %[[INT_4]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "+"(%[[CALL_6]], %[[INT_5]]) anchor %[[NODE_7]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "-"(%[[CALL_7]], %[[READ_5]]) anchor %[[NODE_8]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call unary "-"(%[[INT_6]]) anchor %[[NODE_9]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_8]], %[[CALL_9]]) anchor %[[NODE_10]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_10]] : <Boolean>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "i8" : <String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "i16" : <String>
// CHECK:             %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_7]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "i8" : <String>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_2]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_11]] {closed} : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[NODE_12]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_8:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[INT_8]]) anchor %[[NODE_13]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "Argument" : <String>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call call "isa"(%[[READ_7]], %[[STR_3]]) anchor %[[NODE_14]] : (!mpir.sort<Value>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call binary "&&"(%[[CALL_13]], %[[CALL_14]]) anchor %[[NODE_15]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_15]] : <Boolean>
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}1, 43, 8]] {var_name = "cmp"} : <Instruction>
// CHECK:             %[[READ_9:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_16:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_8]], %[[READ_9]]) anchor %[[NODE_16]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[UNKNOWN_0:.*]] = mpir_index.unknown {var_name = "p"} : <CmpPredicate>
// CHECK:             %[[READ_10:.*]] = mpir_expr.read %[[UNKNOWN_0]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "eq" : <String>
// CHECK:             %[[NODE_17:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[READ_10]], %[[STR_4]]) anchor %[[NODE_17]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_18:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_18:.*]] = mpir_expr.call binary "&&"(%[[CALL_16]], %[[CALL_17]]) anchor %[[NODE_18]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_18]] : <Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             mpir_index.assume %[[BOOL_0]] {closed} : <Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             %[[NODE_19:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_19:.*]] = mpir_expr.call unary "!"(%[[BOOL_1]]) anchor %[[NODE_19]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_19]] {closed} : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// Control flow: blocks written as labels, phis with their incoming blocks,
// branches and returns.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock> loc("to-index.mlir":1091:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
  %0 = mpir.keyword ult : <Value> loc("to-index.mlir":1093:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword ult : <Value>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":1095:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":1097:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.int 10 : ui4 : <Value> loc("to-index.mlir":1099:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 10 : ui4 : <Value>
  %i_c = mpir.inst <icmp> block %entry (%0, %1, %x, %1, %2) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1101:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> block %[[VAR_0]] (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 1 : <Type> loc("to-index.mlir":1103:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
  %4 = mpir.type.prim label : <Type> loc("to-index.mlir":1105:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.prim label : <Type>
  %loop = mpir.var "loop" : <BasicBlock> loc("to-index.mlir":1107:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "loop" : <BasicBlock>
  %5 = mpir.type.prim label : <Type> loc("to-index.mlir":1109:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.prim label : <Type>
  %exit = mpir.var "exit" : <BasicBlock> loc("to-index.mlir":1111:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "exit" : <BasicBlock>
  %6 = mpir.inst <br> block %entry (%3, %i_c, %4, %loop, %5, %exit) <flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-index.mlir":1113:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <br> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type> loc("to-index.mlir":1115:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1117:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %n = mpir.var "n" : <Operand> loc("to-index.mlir":1119:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "n" : <Operand>
  %i_i = mpir.inst <phi> block %loop (%7, %8, %entry, %7, %n, %loop) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 1, 0, 1]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-index.mlir":1121:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <phi> block %[[VAR_2]] (%[[TYPE_4]], %[[INT_1]], %[[VAR_0]], %[[TYPE_4]], %[[VAR_4]], %[[VAR_2]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 1, 0, 1]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-index.mlir":1123:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %10 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":1125:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
  %i_next = mpir.inst <add> block %loop (%9, %i_i, %9, %10) <result_name = "next", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1127:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <add> block %[[VAR_2]] (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INT_2]]) <result_name = "next", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %11 = mpir.type.prim label : <Type> loc("to-index.mlir":1129:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim label : <Type>
  %12 = mpir.inst <br> block %loop (%11, %exit) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction> loc("to-index.mlir":1131:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <br> block %[[VAR_2]] (%[[TYPE_6]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<BasicBlock>) -> !mpir.sort<Instruction>
  %13 = mpir.type.int 32 : <Type> loc("to-index.mlir":1133:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.inst <ret> block %exit (%13, %i_next) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1135:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <ret> block %[[VAR_3]] (%[[TYPE_7]], %[[INST_3]]) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":1137:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <ret>
// CHECK:             mpir_index.has_instruction <br>
// CHECK:             mpir_index.has_instruction <icmp>
// CHECK:             mpir_index.has_instruction <phi>
// CHECK:             mpir_index.has_edge <add> -> <phi>
// CHECK:             mpir_index.has_edge <ret> -> <add>
// CHECK:             mpir_index.has_edge <br> -> <icmp>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <icmp>, 2, 138
// CHECK:             mpir_index.has_fact 2, <phi>, 1, 128
// CHECK:             mpir_index.has_fact 3, <add>, 2, 129
// CHECK:             mpir_index.typing <icmp> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <br> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [0, 6], [0, 6]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <phi> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], []], value_operand = [true, true, true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <br> <present = 0, absent = 0, operand_types = {{\[\[}}0, 6]], value_operand = [true]>
// CHECK:             mpir_index.typing <ret> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0]], value_operand = [true]>
// CHECK:           }
// CHECK:         }

// -----

// 'match' definitions: of each syntax, commutative, with branches that fix
// flags, with concrete parameter types, and their uses with flags, metaflags
// and captures.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %nsw = mpir.var "nsw" : <Boolean> loc("to-index.mlir":1169:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "nsw" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1171:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":1173:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":1175:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %_flag_a_disjoint = mpir.var "_flag$a$disjoint" : <Boolean> loc("to-index.mlir":1177:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "_flag$a$disjoint" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1181:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":1183:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <or> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1187:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %12 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1189:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
    mpir.bind %nsw, %12 : <Boolean>, <Value> loc("to-index.mlir":1191:1)
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":1193:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {result_name = "a"} : <Instruction> loc("to-index.mlir":1195:1)
// CHECK:           } attributes {result_name = "a"} : <Instruction>
  %neg = mpir.var "neg" : <Instruction> loc("to-index.mlir":1197:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "neg" : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":1199:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %_flag_b_nsw = mpir.var "_flag$b$nsw" : <Boolean> loc("to-index.mlir":1201:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "_flag$b$nsw" : <Boolean>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %3 = mpir.alt {
    %12 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1205:1)
// CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
    %i_b = mpir.inst <sub> capture %neg (%2, %12, %2, %1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1207:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> capture %[[VAR_4]] (%[[TYPE_1]], %[[INT_1]], %[[TYPE_1]], %[[ALT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-index.mlir":1209:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  }, {
// CHECK:           }, {
    mpir.bind %neg, %1 : <Instruction>, <Instruction> loc("to-index.mlir":1213:1)
// CHECK:             mpir.bind %[[VAR_4]], %[[ALT_0]] : <Instruction>, <Instruction>
    mpir.yield %1 : <Instruction> loc("to-index.mlir":1215:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  } attributes {or_self_of = "negate", or_self_region = 1 : i32, result_name = "b"} : <Instruction> loc("to-index.mlir":1217:1)
// CHECK:           } attributes {or_self_of = "negate", or_self_region = 1 : i32, result_name = "b"} : <Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":1219:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.type.int 64 : <Type> loc("to-index.mlir":1221:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 64 : <Type>
  %_flag_c_nneg = mpir.var "_flag$c$nneg" : <Boolean> loc("to-index.mlir":1223:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "_flag$c$nneg" : <Boolean>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
  %6 = mpir.alt {
    %i_c = mpir.inst <zext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":1227:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-index.mlir":1229:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_c = mpir.inst <sext> (%4, %3, %5) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":1233:1)
// CHECK:             %[[INST_4:.*]] = mpir.inst <sext> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-index.mlir":1235:1)
// CHECK:             mpir.yield %[[INST_4]] : <Instruction>
  } attributes {result_name = "c"} : <Instruction> loc("to-index.mlir":1237:1)
// CHECK:           } attributes {result_name = "c"} : <Instruction>
  %7 = mpir.type.int 1 : <Type> loc("to-index.mlir":1239:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("to-index.mlir":1241:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "cond" : <Boolean>
  %8 = mpir.type.int 64 : <Type> loc("to-index.mlir":1243:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 64 : <Type>
  %9 = mpir.type.int 64 : <Type> loc("to-index.mlir":1245:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
  %10 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1247:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
  %11 = mpir.alt {
// CHECK:           %[[ALT_3:.*]] = mpir.alt {
    %12 = mpir.type.int 1 : <Type> loc("to-index.mlir":1251:1)
// CHECK:             %[[TYPE_7:.*]] = mpir.type.int 1 : <Type>
    %i_d = mpir.inst <select> (%12, %cond, %8, %6, %8, %10) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1253:1)
// CHECK:             %[[INST_5:.*]] = mpir.inst <select> (%[[TYPE_7]], %[[VAR_7]], %[[TYPE_5]], %[[ALT_2]], %[[TYPE_5]], %[[INT_2]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_d : <Instruction> loc("to-index.mlir":1255:1)
// CHECK:             mpir.yield %[[INST_5]] : <Instruction>
  } attributes {result_name = "d"} : <Instruction> loc("to-index.mlir":1257:1)
// CHECK:           } attributes {result_name = "d"} : <Instruction>
} loc("to-index.mlir":1259:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <zext>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <select> -> <zext>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <zext>, 0, 0, 64
// CHECK:             mpir_index.has_fact 2, <select>, 4, 128
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <zext> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 64, 0], [1, 64, 0]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <or>
// CHECK:             mpir_index.has_instruction <zext>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <select> -> <zext>
// CHECK:             mpir_index.has_shape <or>, 0, 0, 32
// CHECK:             mpir_index.has_shape <zext>, 0, 0, 64
// CHECK:             mpir_index.has_fact 2, <select>, 4, 128
// CHECK:             mpir_index.typing <or> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <zext> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 64, 0], [1, 64, 0]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sext>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <select> -> <sext>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sext>, 0, 0, 64
// CHECK:             mpir_index.has_fact 2, <select>, 4, 128
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sext> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 64, 0], [1, 64, 0]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <or>
// CHECK:             mpir_index.has_instruction <sext>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_edge <select> -> <sext>
// CHECK:             mpir_index.has_shape <or>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sext>, 0, 0, 64
// CHECK:             mpir_index.has_fact 2, <select>, 4, 128
// CHECK:             mpir_index.typing <or> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sext> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 64, 0]], value_operand = [true, false]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 64, 0], [1, 64, 0]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Memory: allocas with a count and alignment, volatile loads and stores
// with their alignment written or captured, and getelementptr with its
// flags, indices and address space.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %ia = mpir.var "ia" : <Boolean> loc("to-index.mlir":1319:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ia" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1321:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":1323:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %n = mpir.var "n" : <Nat> loc("to-index.mlir":1325:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "n" : <Nat>
  %2 = mpir.int 4 : ui3 : <Value> loc("to-index.mlir":1327:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 4 : ui3 : <Value>
  %i_slot = mpir.inst <alloca> flags(%ia) (%0, %1, %n, %2) <result_name = "slot", flags = [4], flag_modes = [2], operand_kinds = [2, 0, 6]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1329:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <alloca> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[TYPE_1]], %[[VAR_1]], %[[INT_0]]) <result_name = "slot", flags = [4], flag_modes = [2], operand_kinds = [2, 0, 6]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Nat>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 64 : <Type> loc("to-index.mlir":1331:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %4 = mpir.int 5 : ui3 : <Value> loc("to-index.mlir":1333:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 5 : ui3 : <Value>
  %i_slot2 = mpir.inst <alloca> (%3, %4) <result_name = "slot2", flags = [], flag_modes = [], operand_kinds = [2, 7]> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1335:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <alloca> (%[[TYPE_2]], %[[INT_1]]) <result_name = "slot2", flags = [], flag_modes = [], operand_kinds = [2, 7]> : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-index.mlir":1337:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1339:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %align = mpir.var "align" : <Nat> loc("to-index.mlir":1341:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "align" : <Nat>
  %i_v = mpir.inst <load> (%5, %6, %i_slot, %align) <result_name = "v", flags = [5], flag_modes = [0], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction> loc("to-index.mlir":1343:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> (%[[TYPE_3]], %[[TYPE_4]], %[[INST_0]], %[[VAR_2]]) <result_name = "v", flags = [5], flag_modes = [0], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %7 = mpir.type.int 32 : <Type> loc("to-index.mlir":1345:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %8 = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type> loc("to-index.mlir":1347:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.ptr addrspace(1) : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-index.mlir":1349:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %i_w = mpir.inst <load> (%7, %8, %p) <result_name = "w", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1351:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <load> (%[[TYPE_5]], %[[TYPE_6]], %[[VAR_3]]) <result_name = "w", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-index.mlir":1353:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %10 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1355:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %11 = mpir.int 8 : ui4 : <Value> loc("to-index.mlir":1357:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 8 : ui4 : <Value>
  %i_st = mpir.inst <store> (%9, %i_v, %10, %i_slot, %11) <result_name = "st", flags = [], flag_modes = [], operand_kinds = [0, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1359:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <store> (%[[TYPE_7]], %[[INST_2]], %[[TYPE_8]], %[[INST_0]], %[[INT_2]]) <result_name = "st", flags = [], flag_modes = [], operand_kinds = [0, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %vol = mpir.var "vol" : <Boolean> loc("to-index.mlir":1361:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "vol" : <Boolean>
  %12 = mpir.type.int 32 : <Type> loc("to-index.mlir":1363:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":1365:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "x" : <Operand>
  %13 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1367:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %q = mpir.var "q" : <Operand> loc("to-index.mlir":1369:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "q" : <Operand>
  %i_st2 = mpir.inst <store> flags(%vol) (%12, %x, %13, %q) <result_name = "st2", flags = [5], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1371:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <store> flags(%[[VAR_4]]) (%[[TYPE_9]], %[[VAR_5]], %[[TYPE_10]], %[[VAR_6]]) <result_name = "st2", flags = [5], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ib = mpir.var "ib" : <Boolean> loc("to-index.mlir":1373:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "ib" : <Boolean>
  %gn = mpir.var "gn" : <Boolean> loc("to-index.mlir":1375:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "gn" : <Boolean>
  %14 = mpir.type.int 8 : <Type> loc("to-index.mlir":1377:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
  %15 = mpir.type.seq array 4 x %14 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1379:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %16 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1381:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %17 = mpir.type.int 64 : <Type> loc("to-index.mlir":1383:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 64 : <Type>
  %18 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1385:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 64 : <Type> loc("to-index.mlir":1387:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 64 : <Type>
  %i = mpir.var "i" : <Operand> loc("to-index.mlir":1389:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "i" : <Operand>
  %i_g = mpir.inst <getelementptr> flags(%ib, %gn) (%15, %16, %i_slot, %17, %18, %19, %i) <result_name = "g", flags = [6, 7, 1], flag_modes = [2, 0, 2], operand_kinds = [2, 0, 0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1391:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <getelementptr> flags(%[[VAR_7]], %[[VAR_8]]) (%[[TYPE_12]], %[[TYPE_13]], %[[INST_0]], %[[TYPE_14]], %[[INT_3]], %[[TYPE_15]], %[[VAR_9]]) <result_name = "g", flags = [6, 7, 1], flag_modes = [2, 0, 2], operand_kinds = [2, 0, 0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %20 = mpir.type.int 8 : <Type> loc("to-index.mlir":1393:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 8 : <Type>
  %21 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1395:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %22 = mpir.type.int 64 : <Type> loc("to-index.mlir":1397:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 64 : <Type>
  %23 = mpir.int 4 : ui3 : <Value> loc("to-index.mlir":1399:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 4 : ui3 : <Value>
  %i_h = mpir.inst <getelementptr> (%20, %21, %q, %22, %23) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [2, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1401:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <getelementptr> (%[[TYPE_16]], %[[TYPE_17]], %[[VAR_6]], %[[TYPE_18]], %[[INT_4]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [2, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":1403:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <alloca>
// CHECK:             mpir_index.has_instruction <load>
// CHECK:             mpir_index.has_instruction <store>
// CHECK:             mpir_index.has_instruction <getelementptr>
// CHECK:             mpir_index.has_edge <load> -> <alloca>
// CHECK:             mpir_index.has_edge <store> -> <alloca>
// CHECK:             mpir_index.has_edge <store> -> <load>
// CHECK:             mpir_index.has_edge <getelementptr> -> <alloca>
// CHECK:             mpir_index.has_sibling <load>, <store>
// CHECK:             mpir_index.has_sibling <load>, <getelementptr>
// CHECK:             mpir_index.has_sibling <store>, <getelementptr>
// CHECK:             mpir_index.has_shape <load>, 0, 0, 32
// CHECK:             mpir_index.has_shape <load>, 32, 0, 32
// CHECK:             mpir_index.has_shape <getelementptr>, 128, 0, 0
// CHECK:             mpir_index.has_fact 6, <getelementptr>, 2, 128
// CHECK:             mpir_index.has_fact 7, <getelementptr>, 2, 132
// CHECK:             mpir_index.typing <alloca> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [false, true]>
// CHECK:             mpir_index.typing <alloca> <present = 0, absent = 0, operand_types = {{\[\[}}1, 64, 0]], value_operand = [false]>
// CHECK:             mpir_index.typing <load> <present = 32, absent = 0, operand_types = {{\[\[}}1, 32, 0], [4, -1, 1]], value_operand = [false, true]>
// CHECK:             mpir_index.typing <load> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [4, 1, 1]], value_operand = [false, true]>
// CHECK:             mpir_index.typing <store> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [4, -1, 1]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <store> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [4, -1, 1]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <getelementptr> <present = 128, absent = 0, operand_types = {{\[\[}}5, 0, 4, -1, [1, 8, 0]], [4, -1, 1], [1, 64, 0], [1, 64, 0]], value_operand = [false, true, true, true]>
// CHECK:             mpir_index.typing <getelementptr> <present = 0, absent = 0, operand_types = {{\[\[}}1, 8, 0], [4, -1, 1], [1, 64, 0]], value_operand = [false, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Metaflags as written, kept for lowering: the built-in ones (':c', ':o'
// with and without an index, ':or' and ':not' of others), those defined in
// the file and in the standard library, with arguments, on instructions and
// on operands.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1442:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":1444:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":1446:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1450:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":1452:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %y, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1456:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":1458:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction> loc("to-index.mlir":1460:1)
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":1462:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value> loc("to-index.mlir":1464:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %4 = mpir.alt {
    mpir.yield %1 : <Instruction> loc("to-index.mlir":1468:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1472:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-index.mlir":1474:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction> loc("to-index.mlir":1476:1)
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-index.mlir":1478:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":1480:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
  %7 = mpir.alt {
    mpir.yield %4 : <Instruction> loc("to-index.mlir":1484:1)
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_c = mpir.inst <sub> (%5, %6, %5, %4) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1488:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INT_1]], %[[TYPE_2]], %[[ALT_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_c : <Instruction> loc("to-index.mlir":1490:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } attributes {or_self_of = "sub", or_self_region = 0 : i32, result_name = "c"} : <Instruction> loc("to-index.mlir":1492:1)
// CHECK:           } attributes {or_self_of = "sub", or_self_region = 0 : i32, result_name = "c"} : <Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-index.mlir":1494:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand> loc("to-index.mlir":1496:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "z" : <Operand>
  %i_d = mpir.inst <xor> (%8, %7, %8, %z) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1498:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <xor> (%[[TYPE_3]], %[[ALT_2]], %[[TYPE_3]], %[[VAR_2]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.int 32 : <Type> loc("to-index.mlir":1500:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %w = mpir.var "w" : <Operand> loc("to-index.mlir":1502:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "w" : <Operand>
  %i_e = mpir.inst <and> (%9, %i_d, %9, %w) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1504:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <and> (%[[TYPE_4]], %[[INST_4]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.int 32 : <Type> loc("to-index.mlir":1506:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %u = mpir.var "u" : <Operand> loc("to-index.mlir":1508:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "u" : <Operand>
  %i_f = mpir.inst <or> (%10, %i_e, %10, %u) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1510:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <or> (%[[TYPE_5]], %[[INST_5]], %[[TYPE_5]], %[[VAR_4]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir_expr.read %1 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-index.mlir":1512:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[ALT_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %12 = mpir_expr.call call "hasOneUse"(%11) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1514:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %12 {from_metaflag} : <Boolean> loc("to-index.mlir":1516:1)
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
  %13 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1518:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %14 = mpir_expr.call call "isZero"(%13) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1520:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %14 {from_metaflag} : <Boolean> loc("to-index.mlir":1522:1)
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
  %15 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":1524:1)
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %16 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1526:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %17 = mpir_expr.call call "sle"(%15, %16) anchor %1 : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1528:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "sle"(%[[INT_2]], %[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1530:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %19 = mpir_expr.int 10 : ui64 : <Integer> loc("to-index.mlir":1532:1)
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 10 : ui64 : <Integer>
  %20 = mpir_expr.call call "sle"(%18, %19) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1534:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "sle"(%[[READ_3]], %[[INT_3]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %21 = mpir_expr.call binary "&&"(%17, %20) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1536:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_2]], %[[CALL_3]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %21 {from_metaflag} : <Boolean> loc("to-index.mlir":1538:1)
// CHECK:           mpir.require %[[CALL_4]] {from_metaflag} : <Boolean>
  %22 = mpir_expr.read %7 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-index.mlir":1540:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[ALT_2]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %23 = mpir_expr.call call "opcode"(%22) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-index.mlir":1542:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[ALT_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %24 = mpir_expr.str "add" : <String> loc("to-index.mlir":1544:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
  %25 = mpir_expr.call binary "=="(%23, %24) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1546:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_0]]) anchor %[[ALT_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %25 {from_metaflag} : <Boolean> loc("to-index.mlir":1548:1)
// CHECK:           mpir.require %[[CALL_6]] {from_metaflag} : <Boolean>
  %26 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1550:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %27 = mpir_expr.call call "isZero"(%26) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1552:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_5]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %28 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1554:1)
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %29 = mpir_expr.call call "isAllOnes"(%28) anchor %i_d : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1556:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_6]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %30 = mpir_expr.call binary "||"(%27, %29) anchor %i_d : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1558:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[INST_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %30 {from_metaflag} : <Boolean> loc("to-index.mlir":1560:1)
// CHECK:           mpir.require %[[CALL_9]] {from_metaflag} : <Boolean>
  %31 = mpir_expr.read %w : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1562:1)
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %32 = mpir_expr.call call "isPower2"(%31) anchor %i_e : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1564:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "isPower2"(%[[READ_7]]) anchor %[[INST_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %33 = mpir_expr.call unary "!"(%32) anchor %i_e : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1566:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call unary "!"(%[[CALL_10]]) anchor %[[INST_5]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %33 {from_metaflag} : <Boolean> loc("to-index.mlir":1568:1)
// CHECK:           mpir.require %[[CALL_11]] {from_metaflag} : <Boolean>
  %34 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1570:1)
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %35 = mpir_expr.call call "isZero"(%34) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1572:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "isZero"(%[[READ_8]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %36 = mpir_expr.call unary "!"(%35) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1574:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call unary "!"(%[[CALL_12]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %37 = mpir_expr.int 2 : ui64 : <Integer> loc("to-index.mlir":1576:1)
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %38 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1578:1)
// CHECK:           %[[READ_9:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %39 = mpir_expr.call call "sle"(%37, %38) anchor %i_f : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1580:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call call "sle"(%[[INT_4]], %[[READ_9]]) anchor %[[INST_6]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %40 = mpir_expr.read %u : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":1582:1)
// CHECK:           %[[READ_10:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %41 = mpir_expr.int 4 : ui64 : <Integer> loc("to-index.mlir":1584:1)
// CHECK:           %[[INT_5:.*]] = mpir_expr.int 4 : ui64 : <Integer>
  %42 = mpir_expr.call call "sle"(%40, %41) anchor %i_f : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1586:1)
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "sle"(%[[READ_10]], %[[INT_5]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %43 = mpir_expr.call binary "&&"(%39, %42) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1588:1)
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call binary "&&"(%[[CALL_14]], %[[CALL_15]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %44 = mpir_expr.call binary "||"(%36, %43) anchor %i_f : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":1590:1)
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_13]], %[[CALL_16]]) anchor %[[INST_6]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %44 {from_metaflag} : <Boolean> loc("to-index.mlir":1592:1)
// CHECK:           mpir.require %[[CALL_17]] {from_metaflag} : <Boolean>
} loc("to-index.mlir":1594:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <and>
// CHECK:             mpir_index.has_instruction <or>
// CHECK:             mpir_index.has_instruction <xor>
// CHECK:             mpir_index.has_edge <and> -> <xor>
// CHECK:             mpir_index.has_edge <or> -> <and>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <and>, 0, 0, 32
// CHECK:             mpir_index.has_shape <or>, 0, 0, 32
// CHECK:             mpir_index.has_shape <xor>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, commutative, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <xor> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <and> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <or> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 8]] {result_name = "a"} : <Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 3]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 1, 3]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "sle"(%[[INT_0]], %[[READ_2]]) anchor %[[NODE_2]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call call "sle"(%[[READ_3]], %[[INT_1]]) anchor %[[NODE_3]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_2]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:             %[[SITES_3:.*]] = mpir_index.sites {{\[\[}}1, 18, 1]] {result_name = "c"} : <Instruction>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_6]] : <Boolean>
// CHECK:             %[[SITES_4:.*]] = mpir_index.sites {{\[\[}}1, 18, 2]] {var_name = "z"} : <Operand>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_5]]) anchor %[[NODE_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_6]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_9]] : <Boolean>
// CHECK:             %[[SITES_5:.*]] = mpir_index.sites {{\[\[}}2, 16, 2]] {var_name = "w"} : <Operand>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 2 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call call "isPower2"(%[[READ_7]]) anchor %[[NODE_8]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 2 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call unary "!"(%[[CALL_10]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_11]] : <Boolean>
// CHECK:             %[[SITES_6:.*]] = mpir_index.sites {{\[\[}}3, 17, 2]] {var_name = "u"} : <Operand>
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call call "isZero"(%[[READ_8]]) anchor %[[NODE_10]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call unary "!"(%[[CALL_12]]) anchor %[[NODE_11]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:             %[[READ_9:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call call "sle"(%[[INT_2]], %[[READ_9]]) anchor %[[NODE_12]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_10:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 4 : ui64 : <Integer>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call call "sle"(%[[READ_10]], %[[INT_3]]) anchor %[[NODE_13]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call binary "&&"(%[[CALL_14]], %[[CALL_15]]) anchor %[[NODE_14]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 3 : <Instruction>
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_13]], %[[CALL_16]]) anchor %[[NODE_15]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_17]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// Numbered results and labels; 'anyblock:' ends the block the instructions
// before it were required to share; a void return and a typed pointer.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %entry = mpir.var "entry" : <BasicBlock> loc("to-index.mlir":1685:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "entry" : <BasicBlock>
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1687:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":1689:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":1691:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_0 = mpir.inst <add> block %entry (%0, %x, %0, %1) <result_name = "0", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1693:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <result_name = "0", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":1695:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_1 = mpir.inst <mul> block %entry (%2, %i_0, %2, %i_0) <result_name = "1", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1697:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> block %[[VAR_0]] (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INST_0]]) <result_name = "1", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %_7 = mpir.var "7" : <BasicBlock> loc("to-index.mlir":1699:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "7" : <BasicBlock>
  %3 = mpir.type.int 32 : <Type> loc("to-index.mlir":1701:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":1703:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.type.ptr %4 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1705:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-index.mlir":1707:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %i_2 = mpir.inst <load> block %_7 (%3, %5, %p) <result_name = "2", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1709:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <load> block %[[VAR_2]] (%[[TYPE_2]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "2", flags = [], flag_modes = [], operand_kinds = [2, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 32 : <Type> loc("to-index.mlir":1711:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %i_3 = mpir.inst <sub> (%6, %i_2, %6, %i_1) <result_name = "3", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1713:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_5]], %[[INST_2]], %[[TYPE_5]], %[[INST_1]]) <result_name = "3", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim void : <Type> loc("to-index.mlir":1715:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim void : <Type>
  %8 = mpir.inst <ret> (%7) <flags = [], flag_modes = [], operand_kinds = [2]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction> loc("to-index.mlir":1717:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <ret> (%[[TYPE_6]]) <flags = [], flag_modes = [], operand_kinds = [2]> : (!mpir.sort<Type>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":1719:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <load>
// CHECK:             mpir_index.has_instruction <ret>
// CHECK:             mpir_index.has_edge <sub> -> <mul>
// CHECK:             mpir_index.has_edge <sub> -> <load>
// CHECK:             mpir_index.has_edge <mul> -> <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_shape <load>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <load> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [4, -1, 0]], value_operand = [false, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <ret> <present = 0, absent = 0, operand_types = {{\[\[}}0, 5]], value_operand = [false]>
// CHECK:           }
// CHECK:         }

// -----

// Settings apply to the instructions after them; names with dots and
// hyphens are made printable; unnamed values and variables.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1751:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x_y = mpir.var "x.y" : <Operand> loc("to-index.mlir":1753:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x.y" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":1755:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_a_b = mpir.inst <add> (%0, %x_y, %0, %1) <result_name = "a.b", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":1757:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a.b", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":1759:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %__0 = mpir.var "_$0" : <Operand> loc("to-index.mlir":1761:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "_$0" : <Operand>
  %i_c_d = mpir.inst <sub> (%2, %i_a_b, %2, %__0) <result_name = "c-d", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1763:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "c-d", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-index.mlir":1765:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %__1 = mpir.var "_$1" : <Operand> loc("to-index.mlir":1767:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "_$1" : <Operand>
  %i_e = mpir.inst <mul> (%3, %i_c_d, %3, %__1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1769:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_2]], %[[INST_1]], %[[TYPE_2]], %[[VAR_2]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":1771:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.inst <ret> (%4, %i_e) <flags = [], flag_modes = [], operand_kinds = [0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":1773:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <ret> (%[[TYPE_3]], %[[INST_2]]) <flags = [], flag_modes = [], operand_kinds = [0], treat_int_as_vec = false> : (!mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":1775:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <ret>
// CHECK:             mpir_index.has_edge <sub> -> <add>
// CHECK:             mpir_index.has_edge <mul> -> <sub>
// CHECK:             mpir_index.has_edge <ret> -> <mul>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, treat_int_as_vec, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <ret> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0]], value_operand = [true]>
// CHECK:           }
// CHECK:         }

// -----

// Type patterns: integer and byte types of fixed and variable width,
// primitives, pointers, arrays and vectors of fixed and variable length,
// structs, and type variables.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("to-index.mlir":1804:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %a1 = mpir.var "a1" : <Boolean> loc("to-index.mlir":1806:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "a1" : <Boolean>
  %i_a = mpir.inst <freeze> (%0, %a1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction> loc("to-index.mlir":1808:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <freeze> (%[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 8 byte : <Type> loc("to-index.mlir":1810:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 byte : <Type>
  %b1 = mpir.var "b1" : <Operand> loc("to-index.mlir":1812:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "b1" : <Operand>
  %i_b = mpir.inst <freeze> (%1, %b1) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1814:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <freeze> (%[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %n = mpir.var "n" : <Nat> loc("to-index.mlir":1816:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %2 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1818:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %c1 = mpir.var "c1" : <Operand> loc("to-index.mlir":1820:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "c1" : <Operand>
  %i_c = mpir.inst <freeze> (%2, %c1) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1822:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <freeze> (%[[TYPE_2]], %[[VAR_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %m = mpir.var "m" : <Nat> loc("to-index.mlir":1824:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "m" : <Nat>
  %3 = mpir.type.meta_int %m byte : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1826:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAR_4]] byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %d1 = mpir.var "d1" : <Operand> loc("to-index.mlir":1828:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "d1" : <Operand>
  %i_d = mpir.inst <freeze> (%3, %d1) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1830:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <freeze> (%[[TYPE_3]], %[[VAR_5]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %4 = mpir.type.prim half : <Type> loc("to-index.mlir":1832:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim half : <Type>
  %e1 = mpir.var "e1" : <Operand> loc("to-index.mlir":1834:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "e1" : <Operand>
  %i_e = mpir.inst <freeze> (%4, %e1) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1836:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <freeze> (%[[TYPE_4]], %[[VAR_6]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %5 = mpir.type.prim bfloat : <Type> loc("to-index.mlir":1838:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim bfloat : <Type>
  %f1 = mpir.var "f1" : <Operand> loc("to-index.mlir":1840:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "f1" : <Operand>
  %i_f = mpir.inst <freeze> (%5, %f1) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1842:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <freeze> (%[[TYPE_5]], %[[VAR_7]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.prim float : <Type> loc("to-index.mlir":1844:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim float : <Type>
  %g1 = mpir.var "g1" : <Operand> loc("to-index.mlir":1846:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "g1" : <Operand>
  %i_g = mpir.inst <freeze> (%6, %g1) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1848:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <freeze> (%[[TYPE_6]], %[[VAR_8]]) <result_name = "g", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %7 = mpir.type.prim double : <Type> loc("to-index.mlir":1850:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim double : <Type>
  %h1 = mpir.var "h1" : <Operand> loc("to-index.mlir":1852:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "h1" : <Operand>
  %i_h = mpir.inst <freeze> (%7, %h1) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1854:1)
// CHECK:           %[[INST_7:.*]] = mpir.inst <freeze> (%[[TYPE_7]], %[[VAR_9]]) <result_name = "h", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %8 = mpir.type.prim fp128 : <Type> loc("to-index.mlir":1856:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim fp128 : <Type>
  %i1 = mpir.var "i1" : <Operand> loc("to-index.mlir":1858:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "i1" : <Operand>
  %i_i = mpir.inst <freeze> (%8, %i1) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1860:1)
// CHECK:           %[[INST_8:.*]] = mpir.inst <freeze> (%[[TYPE_8]], %[[VAR_10]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %9 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1862:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %j1 = mpir.var "j1" : <Operand> loc("to-index.mlir":1864:1)
// CHECK:           %[[VAR_11:.*]] = mpir.var "j1" : <Operand>
  %i_j = mpir.inst <freeze> (%9, %j1) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1866:1)
// CHECK:           %[[INST_9:.*]] = mpir.inst <freeze> (%[[TYPE_9]], %[[VAR_11]]) <result_name = "j", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %10 = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type> loc("to-index.mlir":1868:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
  %k1 = mpir.var "k1" : <Operand> loc("to-index.mlir":1870:1)
// CHECK:           %[[VAR_12:.*]] = mpir.var "k1" : <Operand>
  %i_k = mpir.inst <freeze> (%10, %k1) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1872:1)
// CHECK:           %[[INST_10:.*]] = mpir.inst <freeze> (%[[TYPE_10]], %[[VAR_12]]) <result_name = "k", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %11 = mpir.type.int 8 : <Type> loc("to-index.mlir":1874:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 8 : <Type>
  %12 = mpir.type.seq array 4 x %11 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1876:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq array 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %l1 = mpir.var "l1" : <Operand> loc("to-index.mlir":1878:1)
// CHECK:           %[[VAR_13:.*]] = mpir.var "l1" : <Operand>
  %i_l = mpir.inst <freeze> (%12, %l1) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1880:1)
// CHECK:           %[[INST_11:.*]] = mpir.inst <freeze> (%[[TYPE_12]], %[[VAR_13]]) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %len = mpir.var "len" : <Nat> loc("to-index.mlir":1882:1)
// CHECK:           %[[VAR_14:.*]] = mpir.var "len" : <Nat>
  %13 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1884:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %14 = mpir.type.seq array 0 x %13 count %len : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1886:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq array 0 x %[[TYPE_13]] count %[[VAR_14]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %m1 = mpir.var "m1" : <Operand> loc("to-index.mlir":1888:1)
// CHECK:           %[[VAR_15:.*]] = mpir.var "m1" : <Operand>
  %i_m = mpir.inst <freeze> (%14, %m1) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1890:1)
// CHECK:           %[[INST_12:.*]] = mpir.inst <freeze> (%[[TYPE_14]], %[[VAR_15]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %15 = mpir.type.prim float : <Type> loc("to-index.mlir":1892:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.prim float : <Type>
  %16 = mpir.type.seq vector 2 x %15 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1894:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_15]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %n1 = mpir.var "n1" : <Operand> loc("to-index.mlir":1896:1)
// CHECK:           %[[VAR_16:.*]] = mpir.var "n1" : <Operand>
  %i_n = mpir.inst <freeze> (%16, %n1) <result_name = "n", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1898:1)
// CHECK:           %[[INST_13:.*]] = mpir.inst <freeze> (%[[TYPE_16]], %[[VAR_16]]) <result_name = "n", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 32 : <Type> loc("to-index.mlir":1900:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.type.seq scalable 4 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1902:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.seq scalable 4 x %[[TYPE_17]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %o1 = mpir.var "o1" : <Operand> loc("to-index.mlir":1904:1)
// CHECK:           %[[VAR_17:.*]] = mpir.var "o1" : <Operand>
  %i_o = mpir.inst <freeze> (%18, %o1) <result_name = "o", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1906:1)
// CHECK:           %[[INST_14:.*]] = mpir.inst <freeze> (%[[TYPE_18]], %[[VAR_17]]) <result_name = "o", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %lanes = mpir.var "lanes" : <Nat> loc("to-index.mlir":1908:1)
// CHECK:           %[[VAR_18:.*]] = mpir.var "lanes" : <Nat>
  %19 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1910:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %20 = mpir.type.seq vector 0 x %19 count %lanes : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":1912:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.seq vector 0 x %[[TYPE_19]] count %[[VAR_18]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %p1 = mpir.var "p1" : <Operand> loc("to-index.mlir":1914:1)
// CHECK:           %[[VAR_19:.*]] = mpir.var "p1" : <Operand>
  %i_p = mpir.inst <freeze> (%20, %p1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1916:1)
// CHECK:           %[[INST_15:.*]] = mpir.inst <freeze> (%[[TYPE_20]], %[[VAR_19]]) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %21 = mpir.type.int 32 : <Type> loc("to-index.mlir":1918:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":1920:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %23 = mpir.type.struct{%21, %22} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1922:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.struct{%[[TYPE_21]], %[[TYPE_22]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %q1 = mpir.var "q1" : <Operand> loc("to-index.mlir":1924:1)
// CHECK:           %[[VAR_20:.*]] = mpir.var "q1" : <Operand>
  %i_q = mpir.inst <freeze> (%23, %q1) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1926:1)
// CHECK:           %[[INST_16:.*]] = mpir.inst <freeze> (%[[TYPE_23]], %[[VAR_20]]) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 8 : <Type> loc("to-index.mlir":1928:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
  %25 = mpir.type.int 16 : <Type> loc("to-index.mlir":1930:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 16 : <Type>
  %26 = mpir.type.seq array 2 x %25 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1932:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.seq array 2 x %[[TYPE_25]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %27 = mpir.type.struct packed{%24, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1934:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct packed{%[[TYPE_24]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %r1 = mpir.var "r1" : <Operand> loc("to-index.mlir":1936:1)
// CHECK:           %[[VAR_21:.*]] = mpir.var "r1" : <Operand>
  %i_r = mpir.inst <freeze> (%27, %r1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1938:1)
// CHECK:           %[[INST_17:.*]] = mpir.inst <freeze> (%[[TYPE_27]], %[[VAR_21]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %28 = mpir.type.struct{} : () -> !mpir.sort<Type> loc("to-index.mlir":1940:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.struct{} : () -> !mpir.sort<Type>
  %s1 = mpir.var "s1" : <Operand> loc("to-index.mlir":1942:1)
// CHECK:           %[[VAR_22:.*]] = mpir.var "s1" : <Operand>
  %i_s = mpir.inst <freeze> (%28, %s1) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1944:1)
// CHECK:           %[[INST_18:.*]] = mpir.inst <freeze> (%[[TYPE_28]], %[[VAR_22]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ty = mpir.var "ty" : <Type> loc("to-index.mlir":1946:1)
// CHECK:           %[[VAR_23:.*]] = mpir.var "ty" : <Type>
  %t1 = mpir.var "t1" : <Operand> loc("to-index.mlir":1948:1)
// CHECK:           %[[VAR_24:.*]] = mpir.var "t1" : <Operand>
  %i_t = mpir.inst <freeze> (%ty, %t1) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":1950:1)
// CHECK:           %[[INST_19:.*]] = mpir.inst <freeze> (%[[VAR_23]], %[[VAR_24]]) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":1952:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <freeze>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}1, 8, 1]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}2, 1, 1]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}0, 0]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}0, 1]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}0, 2]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}0, 3]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}0, 4]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}4, -1, 1]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}4, 3, 1]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}5, 0, 4, -1, [1, 8, 0]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}5, 0, 0, 2, [2, 0, 0]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 2, -1, [0, 2]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}5, 2, 4, -1, [1, 32, 0]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 0, 3, [2, 0, 0]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}6, 0, [1, 32, 0], [4, -1, 1]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}6, 1, [1, 8, 0], [5, 0, 2, -1, [1, 16, 0]]]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}6, 0]], value_operand = [true]>
// CHECK:             mpir_index.typing <freeze> <present = 0, absent = 0, operand_types = {{\[\[}}3, 4]], value_operand = [true]>
// CHECK:           }
// CHECK:         }

// -----

// Vector and aggregate instructions: elements, shuffles, and fields by
// their indices or captured as an array.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":1986:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.type.seq vector 4 x %0 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":1988:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.seq vector 4 x %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("to-index.mlir":1990:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "v" : <Operand>
  %2 = mpir.type.int 64 : <Type> loc("to-index.mlir":1992:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %idx = mpir.var "idx" : <Nat> loc("to-index.mlir":1994:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "idx" : <Nat>
  %i_e = mpir.inst <extractelement> (%1, %v, %2, %idx) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction> loc("to-index.mlir":1996:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <extractelement> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-index.mlir":1998:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.type.seq vector 4 x %3 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2000:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.seq vector 4 x %[[TYPE_3]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %5 = mpir.type.int 32 : <Type> loc("to-index.mlir":2002:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.type.int 64 : <Type> loc("to-index.mlir":2004:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 64 : <Type>
  %7 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":2006:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_i = mpir.inst <insertelement> (%4, %v, %5, %i_e, %6, %7) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2008:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <insertelement> (%[[TYPE_4]], %[[VAR_0]], %[[TYPE_5]], %[[INST_0]], %[[TYPE_6]], %[[INT_0]]) <result_name = "i", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %8 = mpir.type.int 32 : <Type> loc("to-index.mlir":2010:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 32 : <Type>
  %9 = mpir.type.seq vector 4 x %8 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2012:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.seq vector 4 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %10 = mpir.type.int 32 : <Type> loc("to-index.mlir":2014:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 32 : <Type>
  %11 = mpir.type.seq vector 4 x %10 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2016:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.seq vector 4 x %[[TYPE_9]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %12 = mpir.keyword poison : <Value> loc("to-index.mlir":2018:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword poison : <Value>
  %13 = mpir.type.int 32 : <Type> loc("to-index.mlir":2020:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.int 32 : <Type>
  %14 = mpir.type.seq vector 4 x %13 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2022:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 4 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %15 = mpir.type.int 32 : <Type> loc("to-index.mlir":2024:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 32 : <Type>
  %16 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":2026:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
  %17 = mpir.type.int 32 : <Type> loc("to-index.mlir":2028:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.int 32 : <Type>
  %18 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":2030:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
  %19 = mpir.type.int 32 : <Type> loc("to-index.mlir":2032:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 32 : <Type>
  %20 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2034:1)
// CHECK:           %[[INT_3:.*]] = mpir.int 1 : ui1 : <Value>
  %21 = mpir.type.int 32 : <Type> loc("to-index.mlir":2036:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.int 32 : <Type>
  %22 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2038:1)
// CHECK:           %[[INT_4:.*]] = mpir.int 1 : ui1 : <Value>
  %23 = mpir.aggregate vector(%15, %16, %17, %18, %19, %20, %21, %22) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("to-index.mlir":2040:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_13]], %[[INT_1]], %[[TYPE_14]], %[[INT_2]], %[[TYPE_15]], %[[INT_3]], %[[TYPE_16]], %[[INT_4]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %i_s = mpir.inst <shufflevector> (%9, %i_i, %11, %12, %14, %23) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2042:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <shufflevector> (%[[TYPE_8]], %[[INST_1]], %[[TYPE_10]], %[[KEYWORD_0]], %[[TYPE_12]], %[[AGGREGATE_0]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %24 = mpir.type.int 32 : <Type> loc("to-index.mlir":2044:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 32 : <Type>
  %25 = mpir.type.int 8 : <Type> loc("to-index.mlir":2046:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 8 : <Type>
  %26 = mpir.type.int 16 : <Type> loc("to-index.mlir":2048:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.int 16 : <Type>
  %27 = mpir.type.struct{%25, %26} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2050:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.struct{%[[TYPE_18]], %[[TYPE_19]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %28 = mpir.type.struct{%24, %27} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2052:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.struct{%[[TYPE_17]], %[[TYPE_20]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg = mpir.var "agg" : <Operand> loc("to-index.mlir":2054:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "agg" : <Operand>
  %29 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2056:1)
// CHECK:           %[[INT_5:.*]] = mpir.int 1 : ui1 : <Value>
  %30 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":2058:1)
// CHECK:           %[[INT_6:.*]] = mpir.int 0 : ui1 : <Value>
  %i_x = mpir.inst <extractvalue> (%28, %agg, %29, %30) <result_name = "x", flags = [], flag_modes = [], operand_kinds = [0, 1, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2060:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <extractvalue> (%[[TYPE_21]], %[[VAR_2]], %[[INT_5]], %[[INT_6]]) <result_name = "x", flags = [], flag_modes = [], operand_kinds = [0, 1, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %31 = mpir.type.int 32 : <Type> loc("to-index.mlir":2062:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.int 32 : <Type>
  %32 = mpir.type.prim float : <Type> loc("to-index.mlir":2064:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.prim float : <Type>
  %33 = mpir.type.struct{%31, %32} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2066:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.struct{%[[TYPE_22]], %[[TYPE_23]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %agg2 = mpir.var "agg2" : <Operand> loc("to-index.mlir":2068:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "agg2" : <Operand>
  %path = mpir.var "path" : <ValueArray> loc("to-index.mlir":2070:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "path" : <ValueArray>
  %i_y = mpir.inst <extractvalue> (%33, %agg2, %path) <result_name = "y", flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("to-index.mlir":2072:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <extractvalue> (%[[TYPE_24]], %[[VAR_3]], %[[VAR_4]]) <result_name = "y", flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %34 = mpir.type.int 32 : <Type> loc("to-index.mlir":2074:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.int 32 : <Type>
  %35 = mpir.type.prim float : <Type> loc("to-index.mlir":2076:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.prim float : <Type>
  %36 = mpir.type.struct{%34, %35} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2078:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.struct{%[[TYPE_25]], %[[TYPE_26]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %37 = mpir.type.prim float : <Type> loc("to-index.mlir":2080:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.prim float : <Type>
  %38 = mpir.float 1.000000e+00 : f64 -> <Value> loc("to-index.mlir":2082:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
  %39 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2084:1)
// CHECK:           %[[INT_7:.*]] = mpir.int 1 : ui1 : <Value>
  %i_z = mpir.inst <insertvalue> (%36, %agg2, %37, %38, %39) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 0, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2086:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <insertvalue> (%[[TYPE_27]], %[[VAR_3]], %[[TYPE_28]], %[[FLOAT_0]], %[[INT_7]]) <result_name = "z", flags = [], flag_modes = [], operand_kinds = [0, 0, 1]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %40 = mpir.type.int 32 : <Type> loc("to-index.mlir":2088:1)
// CHECK:           %[[TYPE_29:.*]] = mpir.type.int 32 : <Type>
  %41 = mpir.type.seq scalable 4 x %40 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2090:1)
// CHECK:           %[[TYPE_30:.*]] = mpir.type.seq scalable 4 x %[[TYPE_29]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.var "a" : <Operand> loc("to-index.mlir":2092:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "a" : <Operand>
  %42 = mpir.type.int 32 : <Type> loc("to-index.mlir":2094:1)
// CHECK:           %[[TYPE_31:.*]] = mpir.type.int 32 : <Type>
  %43 = mpir.type.seq scalable 4 x %42 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2096:1)
// CHECK:           %[[TYPE_32:.*]] = mpir.type.seq scalable 4 x %[[TYPE_31]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %b = mpir.var "b" : <Operand> loc("to-index.mlir":2098:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "b" : <Operand>
  %44 = mpir.type.int 32 : <Type> loc("to-index.mlir":2100:1)
// CHECK:           %[[TYPE_33:.*]] = mpir.type.int 32 : <Type>
  %45 = mpir.type.seq scalable 4 x %44 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("to-index.mlir":2102:1)
// CHECK:           %[[TYPE_34:.*]] = mpir.type.seq scalable 4 x %[[TYPE_33]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %46 = mpir.keyword zeroinitializer : <Value> loc("to-index.mlir":2104:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword zeroinitializer : <Value>
  %i_sv = mpir.inst <shufflevector> (%41, %a, %43, %b, %45, %46) <result_name = "sv", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2106:1)
// CHECK:           %[[INST_6:.*]] = mpir.inst <shufflevector> (%[[TYPE_30]], %[[VAR_5]], %[[TYPE_32]], %[[VAR_6]], %[[TYPE_34]], %[[KEYWORD_1]]) <result_name = "sv", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":2108:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <extractelement>
// CHECK:             mpir_index.has_instruction <insertelement>
// CHECK:             mpir_index.has_instruction <shufflevector>
// CHECK:             mpir_index.has_instruction <extractvalue>
// CHECK:             mpir_index.has_instruction <insertvalue>
// CHECK:             mpir_index.has_edge <insertelement> -> <extractelement>
// CHECK:             mpir_index.has_edge <shufflevector> -> <insertelement>
// CHECK:             mpir_index.has_sibling <extractelement>, <insertelement>
// CHECK:             mpir_index.has_fact 1, <insertelement>, 4, 128
// CHECK:             mpir_index.has_fact 3, <extractvalue>, 2, 129
// CHECK:             mpir_index.has_fact 3, <extractvalue>, 4, 128
// CHECK:             mpir_index.has_fact 5, <insertvalue>, 4, 129
// CHECK:             mpir_index.typing <extractelement> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 4, -1, [1, 32, 0]], [1, 64, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <insertelement> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 4, -1, [1, 32, 0]], [1, 32, 0], [1, 64, 0]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <shufflevector> <present = 0, absent = 0, operand_types = {{\[\[}}5, 1, 4, -1, [1, 32, 0]], [5, 1, 4, -1, [1, 32, 0]], [5, 1, 4, -1, [1, 32, 0]]], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <extractvalue> <present = 0, absent = 0, operand_types = {{\[\[}}6, 0, [1, 32, 0], [6, 0, [1, 8, 0], [1, 16, 0]]], [], []], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <extractvalue> <present = 0, absent = 0, operand_types = {{\[\[}}6, 0, [1, 32, 0], [0, 2]], []], value_operand = [true, true]>
// CHECK:             mpir_index.typing <insertvalue> <present = 0, absent = 0, operand_types = {{\[\[}}6, 0, [1, 32, 0], [0, 2]], [0, 2], []], value_operand = [true, true, true]>
// CHECK:             mpir_index.typing <shufflevector> <present = 0, absent = 0, operand_types = {{\[\[}}5, 2, 4, -1, [1, 32, 0]], [5, 2, 4, -1, [1, 32, 0]], [5, 2, 4, -1, [1, 32, 0]]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// A variant per branch of a matcher, and per pair of branches of two.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2139:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2141:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":2143:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <add> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2147:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-index.mlir":2149:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2153:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-index.mlir":2155:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {result_name = "r"} : <Instruction> loc("to-index.mlir":2157:1)
// CHECK:           } attributes {result_name = "r"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":2159:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %3 = mpir.alt {
    %i_s = mpir.inst <add> (%2, %1, %2, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2163:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_s : <Instruction> loc("to-index.mlir":2165:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_s = mpir.inst <sub> (%2, %1, %2, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2169:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_s : <Instruction> loc("to-index.mlir":2171:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } attributes {result_name = "s"} : <Instruction> loc("to-index.mlir":2173:1)
// CHECK:           } attributes {result_name = "s"} : <Instruction>
} loc("to-index.mlir":2175:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_edge <add> -> <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_edge <add> -> <sub>
// CHECK:             mpir_index.has_sibling <add>, <sub>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_edge <sub> -> <add>
// CHECK:             mpir_index.has_sibling <add>, <sub>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_edge <sub> -> <sub>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:         }

// -----

// ':c' is one variant: its operands' sites are either slot. ':o' requires
// only what both its alternatives do.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2220:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2222:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2224:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2228:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":2230:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2234:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":2236:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction> loc("to-index.mlir":2238:1)
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
  %3 = mpir.type.int 32 : <Type> loc("to-index.mlir":2240:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":2242:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %4 = mpir.alt {
    mpir.yield %2 : <Instruction> loc("to-index.mlir":2246:1)
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_b = mpir.inst <mul> (%3, %2, %3, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2250:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("to-index.mlir":2252:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction> loc("to-index.mlir":2254:1)
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-index.mlir":2256:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%5, %4, %5, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2258:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[ALT_1]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":2260:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <add>, 3, 129
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, commutative, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Values used by two instructions make them siblings.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2279:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2281:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":2283:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2285:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":2287:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %x, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2289:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("to-index.mlir":2291:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_c = mpir.inst <sub> (%2, %i_a, %2, %i_b) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("to-index.mlir":2293:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_2]], %[[INST_0]], %[[TYPE_2]], %[[INST_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":2295:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_edge <sub> -> <add>
// CHECK:             mpir_index.has_edge <sub> -> <mul>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Constants at operands are facts of the sites; flags and widths, shapes.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2319:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2321:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 5 : ui3 : <Value> loc("to-index.mlir":2323:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 5 : ui3 : <Value>
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2325:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 64 : <Type> loc("to-index.mlir":2327:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 64 : <Type>
  %w = mpir.var "w" : <Operand> loc("to-index.mlir":2329:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Operand>
  %3 = mpir.int 3 : ui2 : <Value> loc("to-index.mlir":2331:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <lshr> (%2, %w, %2, %3) <result_name = "b", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2333:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[INT_1]]) <result_name = "b", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 1 : <Type> loc("to-index.mlir":2335:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean> loc("to-index.mlir":2337:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "c" : <Boolean>
  %5 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":2339:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %6 = mpir.keyword null : <Value> loc("to-index.mlir":2341:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
  %7 = mpir.type.ptr : () -> !mpir.sort<Type> loc("to-index.mlir":2343:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %p = mpir.var "p" : <Operand> loc("to-index.mlir":2345:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "p" : <Operand>
  %i_c = mpir.inst <select> (%4, %c, %5, %6, %7, %p) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2347:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <select> (%[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]], %[[KEYWORD_0]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":2349:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_shape <add>, 1, 0, 32
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 64
// CHECK:             mpir_index.has_fact 0, <add>, 2, 133
// CHECK:             mpir_index.has_fact 1, <lshr>, 2, 131
// CHECK:             mpir_index.typing <add> <present = 1, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = {{\[\[}}1, 64, 0], [1, 64, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [4, -1, 1], [4, -1, 1]], value_operand = [true, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// Constraints read the sites of their values; a closed one is marked.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2371:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2373:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %c = mpir.var "c" : <Operand> loc("to-index.mlir":2375:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "c" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %c) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2377:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2379:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isPower2"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2381:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2383:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.int 8 : ui64 : <Integer> loc("to-index.mlir":2385:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 8 : ui64 : <Integer>
  %5 = mpir_expr.call binary "!="(%3, %4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2387:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "!="(%[[READ_1]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2389:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("to-index.mlir":2391:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
  %7 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":2393:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %8 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":2395:1)
// CHECK:           %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %9 = mpir_expr.call binary "+"(%7, %8) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("to-index.mlir":2397:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "+"(%[[INT_1]], %[[INT_2]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %10 = mpir_expr.int 2 : ui64 : <Integer> loc("to-index.mlir":2399:1)
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2401:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[CALL_3]], %[[INT_3]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %11 : <Boolean> loc("to-index.mlir":2403:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
  %12 = mpir_expr.bool false : <Boolean> loc("to-index.mlir":2405:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool false : <Boolean>
  mpir.require %12 : <Boolean> loc("to-index.mlir":2407:1)
// CHECK:           mpir.require %[[BOOL_0]] : <Boolean>
} loc("to-index.mlir":2409:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "c"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 8 : ui64 : <Integer>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "!="(%[[READ_1]], %[[INT_0]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "+"(%[[INT_1]], %[[INT_2]]) anchor %[[NODE_3]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[CALL_3]], %[[INT_3]]) anchor %[[NODE_4]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] {closed} : <Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             mpir_index.assume %[[BOOL_0]] {closed} : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A constraint on a value with no certain site, and on a type variable.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %n = mpir.var "n" : <Nat> loc("to-index.mlir":2445:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":2447:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2449:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %_k = mpir.var "_k" : <Operand> loc("to-index.mlir":2451:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "_k" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    mpir.yield %x : <Operand> loc("to-index.mlir":2455:1)
// CHECK:             mpir.yield %[[VAR_1]] : <Operand>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %_k) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2459:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("to-index.mlir":2461:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction> loc("to-index.mlir":2463:1)
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("to-index.mlir":2465:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %3 = mpir.int 3 : ui2 : <Value> loc("to-index.mlir":2467:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2469:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("to-index.mlir":2471:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %5 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index.mlir":2473:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_b : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2475:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_1]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("to-index.mlir":2477:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
  %7 = mpir_expr.read %_k : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2479:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %8 = mpir_expr.call call "isZero"(%7) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2481:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %8 : <Boolean> loc("to-index.mlir":2483:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
} loc("to-index.mlir":2485:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_fact 0, <mul>, 2, 131
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0], [2, 0, 0]], value_operand = [true, true]>
// CHECK:             %[[TYPE_VAR_0:.*]] = mpir_index.type_var 0 {var_name = "n"} : <Nat>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[UNKNOWN_0:.*]] = mpir_index.unknown {var_name = "_k"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[UNKNOWN_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A constraint definition is called, and a metaflag's requirement kept.
mpir.constraint_def @small <param_names = ["v"]> {
// CHECK-LABEL:   mpir.constraint_def @small <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("to-index.mlir":2513:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.int 16 : ui64 : <Integer> loc("to-index.mlir":2515:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 16 : ui64 : <Integer>
  %2 = mpir_expr.call call "ult"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("to-index.mlir":2517:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[READ_0]], %[[INT_0]]) : (!mpir.sort<Unknown>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %2 : <Boolean> loc("to-index.mlir":2519:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("to-index.mlir":2521:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2525:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2527:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %c = mpir.var "c" : <Operand> loc("to-index.mlir":2529:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "c" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %c) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2531:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %c : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2533:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.apply @small(%1) : (!mpir.sort<Value>) -> !mpir.sort<Boolean> loc("to-index.mlir":2535:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @small(%[[READ_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %i_a : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("to-index.mlir":2537:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "hasOneUse"(%3) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2539:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 {from_metaflag} : <Boolean> loc("to-index.mlir":2541:1)
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
  %5 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2543:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "isZero"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2545:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 {from_metaflag} : <Boolean> loc("to-index.mlir":2547:1)
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
  mpir.require %2 : <Boolean> loc("to-index.mlir":2549:1)
// CHECK:           mpir.require %[[APPLY_0]] : <Boolean>
} loc("to-index.mlir":2551:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 8]] {result_name = "a"} : <Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "c"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[APPLY_0:.*]] = mpir_expr.apply @small(%[[READ_2]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[APPLY_0]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A matcher branch's constraints belong to its variants only.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %ex = mpir.var "ex" : <Boolean> loc("to-index.mlir":2580:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ex" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("to-index.mlir":2582:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index.mlir":2584:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index.mlir":2586:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <lshr> flags(%ex) (%0, %x, %0, %y) <result_name = "r", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2590:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_0]]) (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("to-index.mlir":2592:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <ashr> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index.mlir":2596:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <ashr> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %7 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2598:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_expr.call call "isKnownNonNegative"(%7) anchor %i_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2600:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isKnownNonNegative"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %8 : <Boolean> loc("to-index.mlir":2602:1)
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
    %9 = mpir.int 0 : ui1 : <Value> loc("to-index.mlir":2604:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
    mpir.bind %ex, %9 : <Boolean>, <Value> loc("to-index.mlir":2606:1)
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
    mpir.yield %i_r : <Instruction> loc("to-index.mlir":2608:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {result_name = "r"} : <Instruction> loc("to-index.mlir":2610:1)
// CHECK:           } attributes {result_name = "r"} : <Instruction>
  %2 = mpir_expr.read %ex : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("to-index.mlir":2612:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index.mlir":2614:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.int 1 : ui64 : <Integer> loc("to-index.mlir":2616:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2618:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[INT_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "||"(%2, %5) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index.mlir":2620:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[READ_1]], %[[CALL_1]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("to-index.mlir":2622:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
} loc("to-index.mlir":2624:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_shape <lshr>, 0, 0, 32
// CHECK:             mpir_index.typing <lshr> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[UNKNOWN_0:.*]] = mpir_index.unknown {var_name = "ex"} : <Boolean>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[UNKNOWN_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 14, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[READ_0]], %[[CALL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <ashr>
// CHECK:             mpir_index.has_shape <ashr>, 0, 0, 32
// CHECK:             mpir_index.typing <ashr> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 15, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "isKnownNonNegative"(%[[READ_2]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:             %[[UNKNOWN_1:.*]] = mpir_index.unknown {var_name = "ex"} : <Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[UNKNOWN_1]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 15, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_4]], %[[INT_1]]) anchor %[[NODE_3]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[READ_3]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A use no branch fits: no variant.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("to-index.mlir":2669:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("to-index.mlir":2671:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("to-index.mlir":2673:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand> loc("to-index.mlir":2675:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %2 = mpir.type.int 64 : <Type> loc("to-index.mlir":2677:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %b = mpir.var "b" : <Operand> loc("to-index.mlir":2679:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
  %3 = mpir.alt  attributes {result_name = "r"} : <Instruction> loc("to-index.mlir":2681:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt  attributes {result_name = "r"} : <Instruction>
  %4 = mpir.type.int 32 : <Type> loc("to-index.mlir":2683:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.int 1 : ui1 : <Value> loc("to-index.mlir":2685:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %i_s = mpir.inst <add> (%4, %3, %4, %5) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index.mlir":2687:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_3]], %[[ALT_0]], %[[TYPE_3]], %[[INT_0]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("to-index.mlir":2689:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <add>, 2, 129
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:         }
