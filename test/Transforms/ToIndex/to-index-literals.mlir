// RUN: %metaphir-opt --split-input-file --mpir-to-index %s | FileCheck %s
// Parameters a use binds to literals are read as those numbers, in the index
// queries as in the plans: a width, a flag, a negative and a positive number.

// A use with literal operands: the constraints read the numbers.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":8:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index-literals.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 3 : ui2 : <Value> loc("to-index-literals.mlir":12:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
  %2 = mpir.int 32 : ui64 : <Value> loc("to-index-literals.mlir":14:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 32 : ui64 : <Value>
  %3 = mpir.int 1 : ui1 : <Value> loc("to-index-literals.mlir":16:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
  %4 = mpir.alt {
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
    %i_r = mpir.inst <lshr> (%0, %x, %0, %1) <result_name = "r", flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":20:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":22:1)
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":24:1)
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_r : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":26:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_3]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.bool true : <Boolean> loc("to-index-literals.mlir":28:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":30:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.int 3 : ui64 : <Integer> loc("to-index-literals.mlir":32:1)
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 3 : ui64 : <Integer>
    %16 = mpir_expr.int 0 : ui64 : <Integer> loc("to-index-literals.mlir":34:1)
// CHECK:             %[[INT_6:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_r : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":36:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_5]], %[[INT_6]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_r : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":38:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean> loc("to-index-literals.mlir":40:1)
// CHECK:             mpir.require %[[CALL_3]] : <Boolean>
    mpir.yield %i_r : <Instruction> loc("to-index-literals.mlir":42:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-index-literals.mlir":44:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %5 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":46:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.int -4 : si3 : <Value> loc("to-index-literals.mlir":48:1)
// CHECK:           %[[INT_7:.*]] = mpir.int -4 : si3 : <Value>
  %7 = mpir.int 32 : ui64 : <Value> loc("to-index-literals.mlir":50:1)
// CHECK:           %[[INT_8:.*]] = mpir.int 32 : ui64 : <Value>
  %8 = mpir.int 0 : ui1 : <Value> loc("to-index-literals.mlir":52:1)
// CHECK:           %[[INT_9:.*]] = mpir.int 0 : ui1 : <Value>
  %9 = mpir.alt {
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
    %i_s = mpir.inst <lshr> (%5, %4, %5, %6) <result_name = "s", flags = [exact], flag_modes = [negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":56:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_7]]) <flags = [exact], flag_modes = [negated], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %10 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":58:1)
// CHECK:             %[[INT_10:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %11 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":60:1)
// CHECK:             %[[INT_11:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_s : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":62:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_10]], %[[INT_11]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_expr.bool false : <Boolean> loc("to-index-literals.mlir":64:1)
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
    %14 = mpir_expr.call binary "&&"(%12, %13) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":66:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_expr.int -4 : si64 : <Integer> loc("to-index-literals.mlir":68:1)
// CHECK:             %[[INT_12:.*]] = mpir_expr.int -4 : si64 : <Integer>
    %16 = mpir_expr.int 0 : ui64 : <Integer> loc("to-index-literals.mlir":70:1)
// CHECK:             %[[INT_13:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %17 = mpir_expr.call binary "!="(%15, %16) anchor %i_s : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":72:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_12]], %[[INT_13]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %18 = mpir_expr.call binary "&&"(%14, %17) anchor %i_s : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":74:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %18 : <Boolean> loc("to-index-literals.mlir":76:1)
// CHECK:             mpir.require %[[CALL_7]] : <Boolean>
    mpir.yield %i_s : <Instruction> loc("to-index-literals.mlir":78:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "s"> : <Instruction> loc("to-index-literals.mlir":80:1)
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("to-index-literals.mlir":82:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_edge <lshr> -> <lshr>
// CHECK:             mpir_index.has_shape <lshr>, 0, 4, 32
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 32
// CHECK:             mpir_index.has_fact 0, <lshr>, 2, 131
// CHECK:             mpir_index.has_fact 1, <lshr>, 2, 124
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
// CHECK:             mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int -4 : si64 : <Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_2]], %[[INT_3]]) anchor %[[NODE_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] <closed> : <Boolean>
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_4]], %[[INT_5]]) anchor %[[NODE_4]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_6:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_6]], %[[INT_7]]) anchor %[[NODE_6]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_7]] <closed> : <Boolean>
// CHECK:           }
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <lshr> loc("to-index-literals.mlir":128:1)
// CHECK:             mpir_index.has_instruction <lshr>
    mpir_index.has_edge <lshr> -> <lshr> loc("to-index-literals.mlir":130:1)
// CHECK:             mpir_index.has_edge <lshr> -> <lshr>
    mpir_index.has_shape <lshr>, 0, 4, 32 loc("to-index-literals.mlir":132:1)
// CHECK:             mpir_index.has_shape <lshr>, 0, 4, 32
    mpir_index.has_shape <lshr>, 4, 0, 32 loc("to-index-literals.mlir":134:1)
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 32
    mpir_index.has_fact 0, <lshr>, 2, 131 loc("to-index-literals.mlir":136:1)
// CHECK:             mpir_index.has_fact 0, <lshr>, 2, 131
    mpir_index.has_fact 1, <lshr>, 2, 124 loc("to-index-literals.mlir":138:1)
// CHECK:             mpir_index.has_fact 1, <lshr>, 2, 124
    mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]> loc("to-index-literals.mlir":140:1)
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
    mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]> loc("to-index-literals.mlir":142:1)
// CHECK:             mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
    %0 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":144:1)
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %1 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":146:1)
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %2 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":148:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call binary "=="(%0, %1) anchor %2 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":150:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean> loc("to-index-literals.mlir":152:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":154:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "&&"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":156:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_expr.int 3 : ui64 : <Integer> loc("to-index-literals.mlir":158:1)
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 3 : ui64 : <Integer>
    %8 = mpir_expr.int 0 : ui64 : <Integer> loc("to-index-literals.mlir":160:1)
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %9 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":162:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "!="(%7, %8) anchor %9 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":164:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_2]], %[[INT_3]]) anchor %[[NODE_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":166:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "&&"(%6, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":168:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean> loc("to-index-literals.mlir":170:1)
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
    %13 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":172:1)
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %14 = mpir_expr.int 32 : ui64 : <Integer> loc("to-index-literals.mlir":174:1)
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %15 = mpir_index.node 1 : <Instruction> loc("to-index-literals.mlir":176:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 1 : <Instruction>
    %16 = mpir_expr.call binary "=="(%13, %14) anchor %15 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":178:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_4]], %[[INT_5]]) anchor %[[NODE_4]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %17 = mpir_expr.bool false : <Boolean> loc("to-index-literals.mlir":180:1)
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
    %18 = mpir_index.node 1 : <Instruction> loc("to-index-literals.mlir":182:1)
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 1 : <Instruction>
    %19 = mpir_expr.call binary "&&"(%16, %17) anchor %18 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":184:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %20 = mpir_expr.int -4 : si64 : <Integer> loc("to-index-literals.mlir":186:1)
// CHECK:             %[[INT_6:.*]] = mpir_expr.int -4 : si64 : <Integer>
    %21 = mpir_expr.int 0 : ui64 : <Integer> loc("to-index-literals.mlir":188:1)
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
    %22 = mpir_index.node 1 : <Instruction> loc("to-index-literals.mlir":190:1)
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 1 : <Instruction>
    %23 = mpir_expr.call binary "!="(%20, %21) anchor %22 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":192:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_6]], %[[INT_7]]) anchor %[[NODE_6]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %24 = mpir_index.node 1 : <Instruction> loc("to-index-literals.mlir":194:1)
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 1 : <Instruction>
    %25 = mpir_expr.call binary "&&"(%19, %23) anchor %24 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":196:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %25 : <Boolean> loc("to-index-literals.mlir":198:1)
// CHECK:             mpir_index.assume %[[CALL_7]] : <Boolean>
  } loc("to-index-literals.mlir":200:1)
// CHECK:           }
} loc("to-index-literals.mlir":202:1)
// CHECK:         }

// -----

// A boolean literal read as a boolean.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("to-index-literals.mlir":210:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %1 = mpir.int 1 : ui1 : <Value> loc("to-index-literals.mlir":212:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %2 = mpir.alt {
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
    %3 = mpir.type.int 1 : <Type> loc("to-index-literals.mlir":216:1)
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
    %4 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":218:1)
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
    %5 = mpir.int 1 : ui1 : <Value> loc("to-index-literals.mlir":220:1)
// CHECK:             %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
    %6 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":222:1)
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
    %7 = mpir.int 2 : ui2 : <Value> loc("to-index-literals.mlir":224:1)
// CHECK:             %[[INT_2:.*]] = mpir.int 2 : ui2 : <Value>
    %i_r = mpir.inst <select> (%3, %1, %4, %5, %6, %7) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":226:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[INT_0]], %[[TYPE_2]], %[[INT_1]], %[[TYPE_3]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %8 = mpir_expr.bool true : <Boolean> loc("to-index-literals.mlir":228:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    mpir.require %8 : <Boolean> loc("to-index-literals.mlir":230:1)
// CHECK:             mpir.require %[[BOOL_0]] : <Boolean>
    mpir.yield %i_r : <Instruction> loc("to-index-literals.mlir":232:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("to-index-literals.mlir":234:1)
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("to-index-literals.mlir":236:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_fact 0, <select>, 1, 129
// CHECK:             mpir_index.has_fact 0, <select>, 2, 129
// CHECK:             mpir_index.has_fact 0, <select>, 4, 130
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = [#mpir.tp_int<1>, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true, true]>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             mpir_index.assume %[[BOOL_0]] <closed> : <Boolean>
// CHECK:           }
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <select> loc("to-index-literals.mlir":253:1)
// CHECK:             mpir_index.has_instruction <select>
    mpir_index.has_fact 0, <select>, 1, 129 loc("to-index-literals.mlir":255:1)
// CHECK:             mpir_index.has_fact 0, <select>, 1, 129
    mpir_index.has_fact 0, <select>, 2, 129 loc("to-index-literals.mlir":257:1)
// CHECK:             mpir_index.has_fact 0, <select>, 2, 129
    mpir_index.has_fact 0, <select>, 4, 130 loc("to-index-literals.mlir":259:1)
// CHECK:             mpir_index.has_fact 0, <select>, 4, 130
    mpir_index.typing <select> <present = 0, absent = 0, operand_types = [#mpir.tp_int<1>, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true, true]> loc("to-index-literals.mlir":261:1)
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = [#mpir.tp_int<1>, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true, true]>
    %0 = mpir_expr.bool true : <Boolean> loc("to-index-literals.mlir":263:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    mpir_index.assume %0 : <Boolean> loc("to-index-literals.mlir":265:1)
// CHECK:             mpir_index.assume %[[BOOL_0]] : <Boolean>
  } loc("to-index-literals.mlir":267:1)
// CHECK:           }
} loc("to-index-literals.mlir":269:1)
// CHECK:         }

// -----

// A call of a commutative intrinsic: its two arguments, either order.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":277:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.global "llvm.umax.i32" : <Value> loc("to-index-literals.mlir":279:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.umax.i32" : <Value>
  %2 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":281:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index-literals.mlir":283:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %3 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":285:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.int 7 : ui3 : <Value> loc("to-index-literals.mlir":287:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 7 : ui3 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %5 = mpir.alt {
    %i_m = mpir.inst <call> (%0, %1, %2, %x, %3, %4) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":291:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_m : <Instruction> loc("to-index-literals.mlir":293:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_m = mpir.inst <call> (%0, %1, %3, %4, %2, %x) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":297:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_2]], %[[INT_0]], %[[TYPE_1]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_m : <Instruction> loc("to-index-literals.mlir":299:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "m"> : <Instruction> loc("to-index-literals.mlir":301:1)
// CHECK:           } <result_name = "m"> : <Instruction>
} loc("to-index-literals.mlir":303:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_global "llvm.umax.i32"
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <call>, 4, 135
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, unit, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [false, true, true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_global "llvm.umax.i32"
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <call>, 2, 135
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, unit, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [false, true, true, true]>
// CHECK:           }
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <call> loc("to-index-literals.mlir":325:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_global "llvm.umax.i32" loc("to-index-literals.mlir":327:1)
// CHECK:             mpir_index.has_global "llvm.umax.i32"
    mpir_index.has_shape <call>, 0, 0, 32 loc("to-index-literals.mlir":329:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.has_fact 0, <call>, 6, 135 loc("to-index-literals.mlir":331:1)
// CHECK:             mpir_index.has_fact 0, <call>, 6, 135
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, unit, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [false, true, true, true]> loc("to-index-literals.mlir":333:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, unit, #mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [false, true, true, true]>
  } loc("to-index-literals.mlir":335:1)
// CHECK:           }
} loc("to-index-literals.mlir":337:1)
// CHECK:         }

// -----

// A conjunction with a side that cannot be read as features.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("to-index-literals.mlir":345:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("to-index-literals.mlir":347:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("to-index-literals.mlir":349:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("to-index-literals.mlir":351:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":353:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isZero"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":355:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":357:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "opcode"(%3) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-index-literals.mlir":359:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %5 = mpir_expr.str "mul" : <String> loc("to-index-literals.mlir":361:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":363:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "&&"(%2, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":365:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("to-index-literals.mlir":367:1)
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":369:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-index-literals.mlir":371:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "mul" : <String> loc("to-index-literals.mlir":373:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":375:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":377:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "isZero"(%12) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":379:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.call binary "&&"(%11, %13) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":381:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %14 : <Boolean> loc("to-index-literals.mlir":383:1)
// CHECK:           mpir.require %[[CALL_7]] : <Boolean>
} loc("to-index-literals.mlir":385:1)
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[NODE_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_7]] : <Boolean>
// CHECK:           }
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("to-index-literals.mlir":424:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("to-index-literals.mlir":426:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]> loc("to-index-literals.mlir":428:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = [#mpir.tp_int<32>, #mpir.tp_int<32>], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("to-index-literals.mlir":430:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":432:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":434:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":436:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("to-index-literals.mlir":438:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %5 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":440:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %6 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":442:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call call "opcode"(%5) anchor %6 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-index-literals.mlir":444:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %8 = mpir_expr.str "mul" : <String> loc("to-index-literals.mlir":446:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
    %9 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":448:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "=="(%7, %8) anchor %9 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":450:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[NODE_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":452:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "&&"(%3, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":454:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean> loc("to-index-literals.mlir":456:1)
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
    %13 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":458:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":460:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call call "opcode"(%13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("to-index-literals.mlir":462:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %16 = mpir_expr.str "mul" : <String> loc("to-index-literals.mlir":464:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
    %17 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":466:1)
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call binary "=="(%15, %16) anchor %17 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":468:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %19 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("to-index-literals.mlir":470:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %20 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":472:1)
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call call "isZero"(%19) anchor %20 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":474:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %22 = mpir_index.node 0 : <Instruction> loc("to-index-literals.mlir":476:1)
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
    %23 = mpir_expr.call binary "&&"(%18, %21) anchor %22 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("to-index-literals.mlir":478:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %23 : <Boolean> loc("to-index-literals.mlir":480:1)
// CHECK:             mpir_index.assume %[[CALL_7]] : <Boolean>
  } loc("to-index-literals.mlir":482:1)
// CHECK:           }
} loc("to-index-literals.mlir":484:1)
// CHECK:         }
