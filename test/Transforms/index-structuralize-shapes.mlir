// RUN: %metaphir-opt --split-input-file --mpir-index-structuralize %s | FileCheck %s
// Equalities and calls the index cannot read as features: an operator other
// than opcode() or intrinsic() on a value, a comparison with a number or a
// boolean, and comparisons of constants. Each holds nothing the index looks up.

// An operator other than opcode() or intrinsic() on a value.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize-shapes.mlir":9:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize-shapes.mlir":11:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize-shapes.mlir":13:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize-shapes.mlir":15:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":17:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "bitWidth"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("index-structuralize-shapes.mlir":19:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %3 = mpir_expr.str "32" : <String> loc("index-structuralize-shapes.mlir":21:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "32" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":23:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean> loc("index-structuralize-shapes.mlir":25:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
} loc("index-structuralize-shapes.mlir":27:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize-shapes.mlir":33:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize-shapes.mlir":35:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize-shapes.mlir":37:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize-shapes.mlir":39:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":41:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":43:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "bitWidth"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("index-structuralize-shapes.mlir":45:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
    %4 = mpir_expr.str "32" : <String> loc("index-structuralize-shapes.mlir":47:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "32" : <String>
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":49:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":51:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean> loc("index-structuralize-shapes.mlir":53:1)
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
  } loc("index-structuralize-shapes.mlir":55:1)
// CHECK:           }
} loc("index-structuralize-shapes.mlir":57:1)
// CHECK:         }

// -----

// A comparison with a number, a boolean, or another value.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize-shapes.mlir":65:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize-shapes.mlir":67:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize-shapes.mlir":69:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize-shapes.mlir":71:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":73:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 5 : ui64 : <Integer> loc("index-structuralize-shapes.mlir":75:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 5 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":77:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean> loc("index-structuralize-shapes.mlir":79:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
  %4 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":81:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %5 = mpir_expr.call call "isZero"(%4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":83:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.bool true : <Boolean> loc("index-structuralize-shapes.mlir":85:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
  %7 = mpir_expr.call binary "=="(%5, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":87:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("index-structuralize-shapes.mlir":89:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
  %8 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":91:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":93:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %10 = mpir_expr.call binary "=="(%8, %9) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":95:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %10 : <Boolean> loc("index-structuralize-shapes.mlir":97:1)
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
} loc("index-structuralize-shapes.mlir":99:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize-shapes.mlir":105:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize-shapes.mlir":107:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize-shapes.mlir":109:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize-shapes.mlir":111:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":113:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_expr.int 5 : ui64 : <Integer> loc("index-structuralize-shapes.mlir":115:1)
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 5 : ui64 : <Integer>
    %3 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":117:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":119:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %4 : <Boolean> loc("index-structuralize-shapes.mlir":121:1)
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":123:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %6 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":125:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call call "isZero"(%5) anchor %6 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":127:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %8 = mpir_expr.bool true : <Boolean> loc("index-structuralize-shapes.mlir":129:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":131:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "=="(%7, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":133:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[BOOL_0]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean> loc("index-structuralize-shapes.mlir":135:1)
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
    %11 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-structuralize-shapes.mlir":137:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
    %12 = mpir_expr.read %11 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":139:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":141:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":143:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call binary "=="(%12, %13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":145:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[READ_3]]) anchor %[[NODE_3]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean> loc("index-structuralize-shapes.mlir":147:1)
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
  } loc("index-structuralize-shapes.mlir":149:1)
// CHECK:           }
} loc("index-structuralize-shapes.mlir":151:1)
// CHECK:         }

// -----

// Comparisons of constants.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize-shapes.mlir":159:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize-shapes.mlir":161:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize-shapes.mlir":163:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize-shapes.mlir":165:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.str "add" : <String> loc("index-structuralize-shapes.mlir":167:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
  %2 = mpir_expr.str "add" : <String> loc("index-structuralize-shapes.mlir":169:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "add" : <String>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":171:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean> loc("index-structuralize-shapes.mlir":173:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
  %4 = mpir_expr.str "sub" : <String> loc("index-structuralize-shapes.mlir":175:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
  %5 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":177:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":179:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[STR_2]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("index-structuralize-shapes.mlir":181:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
} loc("index-structuralize-shapes.mlir":183:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize-shapes.mlir":189:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize-shapes.mlir":191:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize-shapes.mlir":193:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_expr.str "add" : <String> loc("index-structuralize-shapes.mlir":195:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "add" : <String>
    %1 = mpir_expr.str "add" : <String> loc("index-structuralize-shapes.mlir":197:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "add" : <String>
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":199:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call binary "=="(%0, %1) anchor %2 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":201:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[STR_1]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %3 {closed} : <Boolean> loc("index-structuralize-shapes.mlir":203:1)
// CHECK:             mpir_index.assume %[[CALL_0]] {closed} : <Boolean>
    %4 = mpir_expr.str "sub" : <String> loc("index-structuralize-shapes.mlir":205:1)
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
    %5 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":207:1)
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
    %6 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":209:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call binary "=="(%4, %5) anchor %6 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":211:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[STR_2]], %[[STR_3]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %7 {closed} : <Boolean> loc("index-structuralize-shapes.mlir":213:1)
// CHECK:             mpir_index.assume %[[CALL_1]] {closed} : <Boolean>
  } loc("index-structuralize-shapes.mlir":215:1)
// CHECK:           }
} loc("index-structuralize-shapes.mlir":217:1)
// CHECK:         }

// -----

// Operators on a value that is not a site.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize-shapes.mlir":225:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize-shapes.mlir":227:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize-shapes.mlir":229:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize-shapes.mlir":231:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":233:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":235:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":237:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":239:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":241:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":243:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":245:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":247:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "&&"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":249:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-structuralize-shapes.mlir":251:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
  %10 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":253:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "intrinsic"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":255:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "intrinsic"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "llvm.umax" : <String> loc("index-structuralize-shapes.mlir":257:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":259:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %13 : <Boolean> loc("index-structuralize-shapes.mlir":261:1)
// CHECK:           mpir.require %[[CALL_6]] : <Boolean>
} loc("index-structuralize-shapes.mlir":263:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize-shapes.mlir":269:1)
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize-shapes.mlir":270:1)
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize-shapes.mlir":271:1)
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-structuralize-shapes.mlir":272:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":273:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":274:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":275:1)
    %4 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":276:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":277:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":278:1)
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":279:1)
    %8 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":280:1)
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":281:1)
    %10 = mpir_expr.str "mul" : <String> loc("index-structuralize-shapes.mlir":282:1)
    %11 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":283:1)
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":284:1)
    %13 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":285:1)
    %14 = mpir_expr.call binary "&&"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":286:1)
    mpir_index.assume %14 : <Boolean> loc("index-structuralize-shapes.mlir":287:1)
    %15 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize-shapes.mlir":288:1)
    %16 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":289:1)
    %17 = mpir_expr.call call "intrinsic"(%15) anchor %16 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize-shapes.mlir":290:1)
    %18 = mpir_expr.str "llvm.umax" : <String> loc("index-structuralize-shapes.mlir":291:1)
    %19 = mpir_index.node 0 : <Instruction> loc("index-structuralize-shapes.mlir":292:1)
    %20 = mpir_expr.call binary "=="(%17, %18) anchor %19 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize-shapes.mlir":293:1)
    mpir_index.assume %20 : <Boolean> loc("index-structuralize-shapes.mlir":294:1)
  } loc("index-structuralize-shapes.mlir":295:1)
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "intrinsic"(%[[READ_2]]) anchor %[[NODE_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_6]] : <Boolean>
// CHECK:           }
} loc("index-structuralize-shapes.mlir":325:1)
// CHECK:         }
