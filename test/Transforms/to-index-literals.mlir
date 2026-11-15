// RUN: %metaphir-opt --split-input-file --mpir-to-index %s | FileCheck %s
// Parameters a use binds to literals are read as those numbers, in the index
// queries as in the plans: a width, a flag, a negative and a positive number.

// A use with literal operands: the constraints read the numbers.
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
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <lshr>
    mpir_index.has_edge <lshr> -> <lshr>
    mpir_index.has_shape <lshr>, 0, 4, 32
    mpir_index.has_shape <lshr>, 4, 0, 32
    mpir_index.has_fact 0, <lshr>, 2, 131
    mpir_index.has_fact 1, <lshr>, 2, 124
    mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_expr.int 32 : ui64 : <Integer>
    %1 = mpir_expr.int 32 : ui64 : <Integer>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call binary "=="(%0, %1) anchor %2 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "&&"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_expr.int 3 : ui64 : <Integer>
    %8 = mpir_expr.int 0 : ui64 : <Integer>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "!="(%7, %8) anchor %9 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "&&"(%6, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean>
    %13 = mpir_expr.int 32 : ui64 : <Integer>
    %14 = mpir_expr.int 32 : ui64 : <Integer>
    %15 = mpir_index.node 1 : <Instruction>
    %16 = mpir_expr.call binary "=="(%13, %14) anchor %15 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %17 = mpir_expr.bool false : <Boolean>
    %18 = mpir_index.node 1 : <Instruction>
    %19 = mpir_expr.call binary "&&"(%16, %17) anchor %18 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %20 = mpir_expr.int -4 : si64 : <Integer>
    %21 = mpir_expr.int 0 : ui64 : <Integer>
    %22 = mpir_index.node 1 : <Instruction>
    %23 = mpir_expr.call binary "!="(%20, %21) anchor %22 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %24 = mpir_index.node 1 : <Instruction>
    %25 = mpir_expr.call binary "&&"(%19, %23) anchor %24 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %25 : <Boolean>
  }
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
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_edge <lshr> -> <lshr>
// CHECK:             mpir_index.has_shape <lshr>, 0, 4, 32
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 32
// CHECK:             mpir_index.has_fact 0, <lshr>, 2, 131
// CHECK:             mpir_index.has_fact 1, <lshr>, 2, 124
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_2]], %[[INT_3]]) anchor %[[NODE_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_4]], %[[INT_5]]) anchor %[[NODE_4]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_6:.*]] = mpir_expr.int -4 : si64 : <Integer>
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_6]], %[[INT_7]]) anchor %[[NODE_6]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_7]] : <Boolean>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <lshr>
// CHECK:             mpir_index.has_edge <lshr> -> <lshr>
// CHECK:             mpir_index.has_shape <lshr>, 0, 4, 32
// CHECK:             mpir_index.has_shape <lshr>, 4, 0, 32
// CHECK:             mpir_index.has_fact 0, <lshr>, 2, 131
// CHECK:             mpir_index.has_fact 1, <lshr>, 2, 124
// CHECK:             mpir_index.typing <lshr> <present = 4, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <lshr> <present = 0, absent = 4, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[INT_3:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "!="(%[[INT_2]], %[[INT_3]]) anchor %[[NODE_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
// CHECK:             %[[INT_4:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_5:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[INT_4]], %[[INT_5]]) anchor %[[NODE_4]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[BOOL_1]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[INT_6:.*]] = mpir_expr.int -4 : si64 : <Integer>
// CHECK:             %[[INT_7:.*]] = mpir_expr.int 0 : ui64 : <Integer>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "!="(%[[INT_6]], %[[INT_7]]) anchor %[[NODE_6]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_7]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A boolean literal read as a boolean.
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %1 = mpir.int 1 : ui1 : <Value>
  %2 = mpir.alt {
    %3 = mpir.type.int 1 : <Type>
    %4 = mpir.type.int 32 : <Type>
    %5 = mpir.int 1 : ui1 : <Value>
    %6 = mpir.type.int 32 : <Type>
    %7 = mpir.int 2 : ui2 : <Value>
    %i_r = mpir.inst <select> (%3, %1, %4, %5, %6, %7) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %8 = mpir_expr.read %1 : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
    mpir.require %8 : <Boolean>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <select>
    mpir_index.has_fact 0, <select>, 1, 129
    mpir_index.has_fact 0, <select>, 2, 129
    mpir_index.has_fact 0, <select>, 4, 130
    mpir_index.typing <select> <present = 0, absent = 0, operand_types = [[1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
    %0 = mpir_expr.bool true : <Boolean>
    mpir_index.assume %0 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:             %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:             %[[INT_2:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[INT_0]], %[[TYPE_2]], %[[INT_1]], %[[TYPE_3]], %[[INT_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[INT_0]] : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[READ_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_fact 0, <select>, 1, 129
// CHECK:             mpir_index.has_fact 0, <select>, 2, 129
// CHECK:             mpir_index.has_fact 0, <select>, 4, 130
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             mpir_index.assume %[[BOOL_0]] : <Boolean>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_fact 0, <select>, 1, 129
// CHECK:             mpir_index.has_fact 0, <select>, 2, 129
// CHECK:             mpir_index.has_fact 0, <select>, 4, 130
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             mpir_index.assume %[[BOOL_0]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A call of a commutative intrinsic: its two arguments, either order.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %1 = mpir.global "llvm.umax.i32" : <Value>
  %2 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.int 7 : ui3 : <Value>
  %5 = mpir.alt {
    %i_m = mpir.inst <call> (%0, %1, %2, %x, %3, %4) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_m : <Instruction>
  }, {
    %i_m = mpir.inst <call> (%0, %1, %3, %4, %2, %x) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_m : <Instruction>
  } attributes {commuted, result_name = "m"} : <Instruction>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <call>
    mpir_index.has_global "llvm.umax.i32"
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.has_fact 0, <call>, 6, 135
    mpir_index.typing <call> <present = 0, absent = 0, commutative, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.umax.i32" : <Value>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 7 : ui3 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[INT_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_2]], %[[INT_0]], %[[TYPE_1]], %[[VAR_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "m"} : <Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_global "llvm.umax.i32"
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <call>, 6, 135
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, commutative, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_global "llvm.umax.i32"
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <call>, 6, 135
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, commutative, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:           }
// CHECK:         }

// -----

// A conjunction with a side that cannot be read as features.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isZero"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "opcode"(%3) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %5 = mpir_expr.str "mul" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "&&"(%2, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "mul" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "isZero"(%12) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.call binary "&&"(%11, %13) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %14 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %5 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %6 = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call call "opcode"(%5) anchor %6 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %8 = mpir_expr.str "mul" : <String>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "=="(%7, %8) anchor %9 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "&&"(%3, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean>
    %13 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call call "opcode"(%13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %16 = mpir_expr.str "mul" : <String>
    %17 = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call binary "=="(%15, %16) anchor %17 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %19 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %20 = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call call "isZero"(%19) anchor %20 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %22 = mpir_index.node 0 : <Instruction>
    %23 = mpir_expr.call binary "&&"(%18, %21) anchor %22 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %23 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "&&"(%[[CALL_5]], %[[CALL_6]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_7]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
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
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
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
