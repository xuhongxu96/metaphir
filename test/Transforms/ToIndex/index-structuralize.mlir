// RUN: %metaphir-opt --split-input-file --mpir-index-structuralize %s | FileCheck %s
// mpir-index-structuralize requires, as features the posting lists have,
// what a variant's constraints say of its instructions: the opcode of a
// value, the intrinsic a call calls. A disjunction splits the variant; a
// contradiction makes it impossible.

// An intrinsic named by a constraint on '@llvm.?id'.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":10:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID> loc("index-structuralize.mlir":12:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":14:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":16:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.type.int 1 : <Type> loc("index-structuralize.mlir":18:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 1 : <Type>
  %3 = mpir.int 0 : ui1 : <Value> loc("index-structuralize.mlir":20:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %3) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":22:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":24:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %5 = mpir_expr.str "llvm.ctlz" : <String> loc("index-structuralize.mlir":26:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.ctlz" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":28:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean> loc("index-structuralize.mlir":30:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
} loc("index-structuralize.mlir":32:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <call> loc("index-structuralize.mlir":38:1)
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-structuralize.mlir":39:1)
    mpir_index.has_fact 0, <call>, 4, 128 loc("index-structuralize.mlir":40:1)
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]> loc("index-structuralize.mlir":41:1)
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-structuralize.mlir":42:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":43:1)
    %2 = mpir_expr.str "llvm.ctlz" : <String> loc("index-structuralize.mlir":44:1)
    %3 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":45:1)
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":46:1)
    mpir_index.assume %4 : <Boolean> loc("index-structuralize.mlir":47:1)
  } loc("index-structuralize.mlir":48:1)
// CHECK:             mpir_index.has_global "llvm.ctlz" <derived>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 0, <call>, 4, 128
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "llvm.ctlz" : <String>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":61:1)
// CHECK:         }

// -----

// ...on either side of '==', and through intrinsic() of the call.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %call = mpir.var "call" : <Instruction> loc("index-structuralize.mlir":69:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "call" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":71:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID> loc("index-structuralize.mlir":73:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":75:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":77:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":79:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":81:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> capture %call (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":83:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_2]], %[[TYPE_2]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":85:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
  %4 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":87:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":89:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 : <Boolean> loc("index-structuralize.mlir":91:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
  %6 = mpir_expr.read %call : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":93:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "intrinsic"(%6) anchor %i_c : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":95:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "intrinsic"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %8 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":97:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.smax" : <String>
  %9 = mpir_expr.call binary "=="(%7, %8) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":99:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-structuralize.mlir":101:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
} loc("index-structuralize.mlir":103:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <call> loc("index-structuralize.mlir":109:1)
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-structuralize.mlir":110:1)
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-structuralize.mlir":111:1)
    %0 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":112:1)
    %1 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-structuralize.mlir":113:1)
    %2 = mpir_expr.read %1 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":114:1)
    %3 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":115:1)
    %4 = mpir_expr.call binary "=="(%0, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":116:1)
    mpir_index.assume %4 : <Boolean> loc("index-structuralize.mlir":117:1)
    %5 = mpir_index.sites [[0, 48, 8]] {var_name = "call"} : <Instruction> loc("index-structuralize.mlir":118:1)
    %6 = mpir_expr.read %5 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":119:1)
    %7 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":120:1)
    %8 = mpir_expr.call call "intrinsic"(%6) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":121:1)
    %9 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":122:1)
    %10 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":123:1)
    %11 = mpir_expr.call binary "=="(%8, %9) anchor %10 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":124:1)
    mpir_index.assume %11 : <Boolean> loc("index-structuralize.mlir":125:1)
  } loc("index-structuralize.mlir":126:1)
// CHECK:             mpir_index.has_global "llvm.smax" <derived>
// CHECK:             mpir_index.has_global "llvm.smax" <derived>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 48, 8]] {var_name = "call"} : <Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "intrinsic"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_1]]) anchor %[[NODE_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":147:1)
// CHECK:         }

// -----

// A disjunction of intrinsics: a variant each.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":155:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID> loc("index-structuralize.mlir":157:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":159:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":161:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":163:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":165:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":167:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":169:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %4 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":171:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":173:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":175:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %7 = mpir_expr.str "llvm.umin" : <String> loc("index-structuralize.mlir":177:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":179:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%5, %8) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":181:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":183:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %11 = mpir_expr.str "llvm.umax" : <String> loc("index-structuralize.mlir":185:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
  %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":187:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %13 = mpir_expr.call binary "||"(%9, %12) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":189:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %13 : <Boolean> loc("index-structuralize.mlir":191:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
} loc("index-structuralize.mlir":193:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <call> loc("index-structuralize.mlir":199:1)
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-structuralize.mlir":200:1)
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-structuralize.mlir":201:1)
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-structuralize.mlir":202:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":203:1)
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-structuralize.mlir":204:1)
    %3 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":205:1)
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":206:1)
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":207:1)
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-structuralize.mlir":208:1)
    %7 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":209:1)
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":210:1)
    %9 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":211:1)
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":212:1)
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-structuralize.mlir":213:1)
    %12 = mpir_expr.str "llvm.umax" : <String> loc("index-structuralize.mlir":214:1)
    %13 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":215:1)
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":216:1)
    %15 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":217:1)
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":218:1)
    mpir_index.assume %16 : <Boolean> loc("index-structuralize.mlir":219:1)
  } loc("index-structuralize.mlir":220:1)
// CHECK:             mpir_index.has_global "llvm.smax" <derived>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.umin" <derived>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[STR_3]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "llvm.umin" : <String>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[READ_4]], %[[STR_4]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_5:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[READ_5]], %[[STR_5]]) anchor %[[NODE_8]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_9]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.umax" <derived>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_6:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "=="(%[[READ_6]], %[[STR_6]]) anchor %[[NODE_10]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_7:.*]] = mpir_expr.str "llvm.umin" : <String>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[READ_7]], %[[STR_7]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "||"(%[[CALL_10]], %[[CALL_11]]) anchor %[[NODE_12]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_8:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[READ_8]], %[[STR_8]]) anchor %[[NODE_13]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "||"(%[[CALL_12]], %[[CALL_13]]) anchor %[[NODE_14]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":292:1)
// CHECK:         }

// -----

// The opcode of an operand: the instruction it must be.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":300:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":302:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":304:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":306:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":308:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":310:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":312:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":314:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean> loc("index-structuralize.mlir":316:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
} loc("index-structuralize.mlir":318:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":324:1)
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":325:1)
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":326:1)
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":327:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":328:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":329:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":330:1)
    %4 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":331:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":332:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":333:1)
    mpir_index.assume %6 : <Boolean> loc("index-structuralize.mlir":334:1)
  } loc("index-structuralize.mlir":335:1)
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":349:1)
// CHECK:         }

// -----

// Two disjunctions multiply; a conjunction inside one adds.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":357:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":359:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":361:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":363:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":365:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":367:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":369:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":371:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":373:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":375:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "shl" : <String> loc("index-structuralize.mlir":377:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":379:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":381:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-structuralize.mlir":383:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
  %10 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":385:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "opcode"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":387:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":389:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":391:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":393:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %15 = mpir_expr.call call "opcode"(%14) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":395:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %16 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":397:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
  %17 = mpir_expr.call binary "=="(%15, %16) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":399:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.call binary "&&"(%13, %17) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":401:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "&&"(%[[CALL_6]], %[[CALL_8]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %19 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":403:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %20 = mpir_expr.call call "opcode"(%19) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":405:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %21 = mpir_expr.str "xor" : <String> loc("index-structuralize.mlir":407:1)
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "xor" : <String>
  %22 = mpir_expr.call binary "=="(%20, %21) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":409:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %23 = mpir_expr.call binary "||"(%18, %22) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":411:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call binary "||"(%[[CALL_9]], %[[CALL_11]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %23 : <Boolean> loc("index-structuralize.mlir":413:1)
// CHECK:           mpir.require %[[CALL_12]] : <Boolean>
} loc("index-structuralize.mlir":415:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":421:1)
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":422:1)
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":423:1)
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-structuralize.mlir":424:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":425:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":426:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":427:1)
    %4 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":428:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":429:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":430:1)
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":431:1)
    %8 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":432:1)
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":433:1)
    %10 = mpir_expr.str "shl" : <String> loc("index-structuralize.mlir":434:1)
    %11 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":435:1)
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":436:1)
    %13 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":437:1)
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":438:1)
    mpir_index.assume %14 : <Boolean> loc("index-structuralize.mlir":439:1)
    %15 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":440:1)
    %16 = mpir_expr.read %15 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":441:1)
    %17 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":442:1)
    %18 = mpir_expr.call call "opcode"(%16) anchor %17 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":443:1)
    %19 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":444:1)
    %20 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":445:1)
    %21 = mpir_expr.call binary "=="(%18, %19) anchor %20 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":446:1)
    %22 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":447:1)
    %23 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":448:1)
    %24 = mpir_expr.call call "opcode"(%22) anchor %23 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":449:1)
    %25 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":450:1)
    %26 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":451:1)
    %27 = mpir_expr.call binary "=="(%24, %25) anchor %26 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":452:1)
    %28 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":453:1)
    %29 = mpir_expr.call binary "&&"(%21, %27) anchor %28 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":454:1)
    %30 = mpir_expr.read %15 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":455:1)
    %31 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":456:1)
    %32 = mpir_expr.call call "opcode"(%30) anchor %31 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":457:1)
    %33 = mpir_expr.str "xor" : <String> loc("index-structuralize.mlir":458:1)
    %34 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":459:1)
    %35 = mpir_expr.call binary "=="(%32, %33) anchor %34 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":460:1)
    %36 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":461:1)
    %37 = mpir_expr.call binary "||"(%29, %35) anchor %36 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":462:1)
    mpir_index.assume %37 : <Boolean> loc("index-structuralize.mlir":463:1)
  } loc("index-structuralize.mlir":464:1)
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <sub> <derived>
// CHECK:             mpir_index.has_instruction <mul> <derived>
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
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[NODE_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[NODE_8]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "&&"(%[[CALL_6]], %[[CALL_8]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[NODE_10]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "xor" : <String>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "||"(%[[CALL_9]], %[[CALL_11]]) anchor %[[NODE_12]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_12]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <xor> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) anchor %[[NODE_13]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_5:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "=="(%[[CALL_13]], %[[STR_5]]) anchor %[[NODE_14]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_6]]) anchor %[[NODE_15]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_6:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_16:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[STR_6]]) anchor %[[NODE_16]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_17:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call binary "||"(%[[CALL_14]], %[[CALL_16]]) anchor %[[NODE_17]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_17]] : <Boolean>
// CHECK:             %[[SITES_3:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_18:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_18:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[NODE_18]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_7:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_19:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_19:.*]] = mpir_expr.call binary "=="(%[[CALL_18]], %[[STR_7]]) anchor %[[NODE_19]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_20:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_20:.*]] = mpir_expr.call call "opcode"(%[[READ_8]]) anchor %[[NODE_20]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_8:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_21:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_21:.*]] = mpir_expr.call binary "=="(%[[CALL_20]], %[[STR_8]]) anchor %[[NODE_21]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_22:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_22:.*]] = mpir_expr.call binary "&&"(%[[CALL_19]], %[[CALL_21]]) anchor %[[NODE_22]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_9:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_23:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_23:.*]] = mpir_expr.call call "opcode"(%[[READ_9]]) anchor %[[NODE_23]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_9:.*]] = mpir_expr.str "xor" : <String>
// CHECK:             %[[NODE_24:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_24:.*]] = mpir_expr.call binary "=="(%[[CALL_23]], %[[STR_9]]) anchor %[[NODE_24]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_25:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_25:.*]] = mpir_expr.call binary "||"(%[[CALL_22]], %[[CALL_24]]) anchor %[[NODE_25]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_25]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <shl> <derived>
// CHECK:             mpir_index.has_instruction <sub> <derived>
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_4:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_10:.*]] = mpir_expr.read %[[SITES_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_26:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_26:.*]] = mpir_expr.call call "opcode"(%[[READ_10]]) anchor %[[NODE_26]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_10:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_27:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_27:.*]] = mpir_expr.call binary "=="(%[[CALL_26]], %[[STR_10]]) anchor %[[NODE_27]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_11:.*]] = mpir_expr.read %[[SITES_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_28:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_28:.*]] = mpir_expr.call call "opcode"(%[[READ_11]]) anchor %[[NODE_28]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_11:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_29:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_29:.*]] = mpir_expr.call binary "=="(%[[CALL_28]], %[[STR_11]]) anchor %[[NODE_29]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_30:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_30:.*]] = mpir_expr.call binary "||"(%[[CALL_27]], %[[CALL_29]]) anchor %[[NODE_30]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_30]] : <Boolean>
// CHECK:             %[[SITES_5:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_12:.*]] = mpir_expr.read %[[SITES_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_31:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_31:.*]] = mpir_expr.call call "opcode"(%[[READ_12]]) anchor %[[NODE_31]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_12:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_32:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_32:.*]] = mpir_expr.call binary "=="(%[[CALL_31]], %[[STR_12]]) anchor %[[NODE_32]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_13:.*]] = mpir_expr.read %[[SITES_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_33:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_33:.*]] = mpir_expr.call call "opcode"(%[[READ_13]]) anchor %[[NODE_33]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_13:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_34:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_34:.*]] = mpir_expr.call binary "=="(%[[CALL_33]], %[[STR_13]]) anchor %[[NODE_34]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_35:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_35:.*]] = mpir_expr.call binary "&&"(%[[CALL_32]], %[[CALL_34]]) anchor %[[NODE_35]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_14:.*]] = mpir_expr.read %[[SITES_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_36:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_36:.*]] = mpir_expr.call call "opcode"(%[[READ_14]]) anchor %[[NODE_36]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_14:.*]] = mpir_expr.str "xor" : <String>
// CHECK:             %[[NODE_37:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_37:.*]] = mpir_expr.call binary "=="(%[[CALL_36]], %[[STR_14]]) anchor %[[NODE_37]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_38:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_38:.*]] = mpir_expr.call binary "||"(%[[CALL_35]], %[[CALL_37]]) anchor %[[NODE_38]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_38]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <shl> <derived>
// CHECK:             mpir_index.has_instruction <xor> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_6:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_15:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_39:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_39:.*]] = mpir_expr.call call "opcode"(%[[READ_15]]) anchor %[[NODE_39]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_15:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_40:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_40:.*]] = mpir_expr.call binary "=="(%[[CALL_39]], %[[STR_15]]) anchor %[[NODE_40]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_16:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_41:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_41:.*]] = mpir_expr.call call "opcode"(%[[READ_16]]) anchor %[[NODE_41]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_16:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_42:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_42:.*]] = mpir_expr.call binary "=="(%[[CALL_41]], %[[STR_16]]) anchor %[[NODE_42]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_43:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_43:.*]] = mpir_expr.call binary "||"(%[[CALL_40]], %[[CALL_42]]) anchor %[[NODE_43]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_43]] : <Boolean>
// CHECK:             %[[SITES_7:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_17:.*]] = mpir_expr.read %[[SITES_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_44:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_44:.*]] = mpir_expr.call call "opcode"(%[[READ_17]]) anchor %[[NODE_44]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_17:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_45:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_45:.*]] = mpir_expr.call binary "=="(%[[CALL_44]], %[[STR_17]]) anchor %[[NODE_45]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_18:.*]] = mpir_expr.read %[[SITES_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_46:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_46:.*]] = mpir_expr.call call "opcode"(%[[READ_18]]) anchor %[[NODE_46]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_18:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_47:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_47:.*]] = mpir_expr.call binary "=="(%[[CALL_46]], %[[STR_18]]) anchor %[[NODE_47]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_48:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_48:.*]] = mpir_expr.call binary "&&"(%[[CALL_45]], %[[CALL_47]]) anchor %[[NODE_48]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_19:.*]] = mpir_expr.read %[[SITES_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_49:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_49:.*]] = mpir_expr.call call "opcode"(%[[READ_19]]) anchor %[[NODE_49]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_19:.*]] = mpir_expr.str "xor" : <String>
// CHECK:             %[[NODE_50:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_50:.*]] = mpir_expr.call binary "=="(%[[CALL_49]], %[[STR_19]]) anchor %[[NODE_50]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_51:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_51:.*]] = mpir_expr.call binary "||"(%[[CALL_48]], %[[CALL_50]]) anchor %[[NODE_51]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_51]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":654:1)
// CHECK:         }

// -----

// The opcode of a value an instruction matcher matches: another opcode
// cannot hold, and the same one adds nothing new.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %self = mpir.var "self" : <Instruction> loc("index-structuralize.mlir":663:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":665:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":667:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":669:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":671:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":673:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":675:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":677:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %3 = mpir_expr.call call "opcode"(%2) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":679:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %4 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":681:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_b : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":683:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 : <Boolean> loc("index-structuralize.mlir":685:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
} loc("index-structuralize.mlir":687:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant <impossible> {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":693:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul> loc("index-structuralize.mlir":695:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <add> loc("index-structuralize.mlir":697:1)
// CHECK:             mpir_index.has_edge <mul> -> <add>
    mpir_index.has_sibling <add>, <mul> loc("index-structuralize.mlir":699:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":701:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-structuralize.mlir":703:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":705:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":707:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[1, 5, 1], [0, 1, 8]] {var_name = "self"} : <Instruction> loc("index-structuralize.mlir":709:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}1, 5, 1], [0, 1, 8]] {var_name = "self"} : <Instruction>
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":711:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %2 = mpir_index.node 1 : <Instruction> loc("index-structuralize.mlir":713:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 1 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":715:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":717:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
    %5 = mpir_index.node 1 : <Instruction> loc("index-structuralize.mlir":719:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 1 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":721:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean> loc("index-structuralize.mlir":723:1)
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
  } loc("index-structuralize.mlir":725:1)
// CHECK:           }
} loc("index-structuralize.mlir":727:1)
// CHECK:         }

// -----

// ...one side of a disjunction that cannot hold leaves the other; of a
// conjunction, nothing.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %self = mpir.var "self" : <Instruction> loc("index-structuralize.mlir":736:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":738:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":740:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":742:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":744:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":746:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":748:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":750:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":752:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":754:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":756:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":758:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":760:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":762:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-structuralize.mlir":764:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
  %10 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":766:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "opcode"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":768:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":770:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "mul" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":772:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":774:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %15 = mpir_expr.call call "opcode"(%14) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":776:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %16 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":778:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "sub" : <String>
  %17 = mpir_expr.call binary "=="(%15, %16) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":780:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.call binary "||"(%13, %17) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":782:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_6]], %[[CALL_8]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %18 : <Boolean> loc("index-structuralize.mlir":784:1)
// CHECK:           mpir.require %[[CALL_9]] : <Boolean>
  %19 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":786:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %20 = mpir_expr.call call "opcode"(%19) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":788:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %21 = mpir_expr.str "add" : <String> loc("index-structuralize.mlir":790:1)
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "add" : <String>
  %22 = mpir_expr.call binary "=="(%20, %21) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":792:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %23 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":794:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %24 = mpir_expr.call call "opcode"(%23) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":796:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %25 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":798:1)
// CHECK:           %[[STR_5:.*]] = mpir_expr.str "mul" : <String>
  %26 = mpir_expr.call binary "=="(%24, %25) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":800:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[STR_5]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %27 = mpir_expr.call binary "&&"(%22, %26) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":802:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call binary "&&"(%[[CALL_11]], %[[CALL_13]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %27 : <Boolean> loc("index-structuralize.mlir":804:1)
// CHECK:           mpir.require %[[CALL_14]] : <Boolean>
} loc("index-structuralize.mlir":806:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":812:1)
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":813:1)
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":814:1)
    %0 = mpir_index.sites [[0, 1, 8]] {var_name = "self"} : <Instruction> loc("index-structuralize.mlir":815:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":816:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":817:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":818:1)
    %4 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":819:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":820:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":821:1)
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":822:1)
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":823:1)
    %9 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":824:1)
    %10 = mpir_expr.call call "opcode"(%8) anchor %9 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":825:1)
    %11 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":826:1)
    %12 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":827:1)
    %13 = mpir_expr.call binary "=="(%10, %11) anchor %12 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":828:1)
    %14 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":829:1)
    %15 = mpir_expr.call binary "||"(%6, %13) anchor %14 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":830:1)
    mpir_index.assume %15 : <Boolean> loc("index-structuralize.mlir":831:1)
    %16 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":832:1)
    %17 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":833:1)
    %18 = mpir_expr.call call "opcode"(%16) anchor %17 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":834:1)
    %19 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":835:1)
    %20 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":836:1)
    %21 = mpir_expr.call binary "=="(%18, %19) anchor %20 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":837:1)
    %22 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":838:1)
    %23 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":839:1)
    %24 = mpir_expr.call call "opcode"(%22) anchor %23 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":840:1)
    %25 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":841:1)
    %26 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":842:1)
    %27 = mpir_expr.call binary "=="(%24, %25) anchor %26 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":843:1)
    %28 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":844:1)
    %29 = mpir_expr.call binary "||"(%21, %27) anchor %28 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":845:1)
    mpir_index.assume %29 : <Boolean> loc("index-structuralize.mlir":846:1)
    %30 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":847:1)
    %31 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":848:1)
    %32 = mpir_expr.call call "opcode"(%30) anchor %31 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":849:1)
    %33 = mpir_expr.str "add" : <String> loc("index-structuralize.mlir":850:1)
    %34 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":851:1)
    %35 = mpir_expr.call binary "=="(%32, %33) anchor %34 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":852:1)
    %36 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":853:1)
    %37 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":854:1)
    %38 = mpir_expr.call call "opcode"(%36) anchor %37 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":855:1)
    %39 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":856:1)
    %40 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":857:1)
    %41 = mpir_expr.call binary "=="(%38, %39) anchor %40 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":858:1)
    %42 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":859:1)
    %43 = mpir_expr.call binary "&&"(%35, %41) anchor %42 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":860:1)
    mpir_index.assume %43 : <Boolean> loc("index-structuralize.mlir":861:1)
  } loc("index-structuralize.mlir":862:1)
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <add> <derived>
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 8]] {var_name = "self"} : <Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[NODE_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[NODE_8]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_6]], %[[CALL_8]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_9]] : <Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[NODE_10]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) anchor %[[NODE_12]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_5:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[STR_5]]) anchor %[[NODE_13]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "&&"(%[[CALL_11]], %[[CALL_13]]) anchor %[[NODE_14]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":918:1)
// CHECK:         }

// -----

// ...and a conjunction with it makes the variant impossible.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %self = mpir.var "self" : <Instruction> loc("index-structuralize.mlir":926:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":928:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":930:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":932:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":934:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":936:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":938:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":940:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":942:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":944:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":946:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":948:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":950:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "&&"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":952:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-structuralize.mlir":954:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
} loc("index-structuralize.mlir":956:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant <impossible> {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":962:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":964:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":966:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 8]] {var_name = "self"} : <Instruction> loc("index-structuralize.mlir":968:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 8]] {var_name = "self"} : <Instruction>
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-structuralize.mlir":970:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":972:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":974:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "sub" : <String> loc("index-structuralize.mlir":976:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":978:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":980:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":982:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":984:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":986:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call call "opcode"(%8) anchor %9 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":988:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %11 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":990:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
    %12 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":992:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %13 = mpir_expr.call binary "=="(%10, %11) anchor %12 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":994:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %14 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":996:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call binary "&&"(%6, %13) anchor %14 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":998:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean> loc("index-structuralize.mlir":1000:1)
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
  } loc("index-structuralize.mlir":1002:1)
// CHECK:           }
} loc("index-structuralize.mlir":1004:1)
// CHECK:         }

// -----

// What says nothing the index has: other operators, other operands, a
// disjunction with such a side, 'br' (two kinds of instruction), names
// that are no opcode, intrinsic() of what is no call.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":1014:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":1016:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":1018:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":1020:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1022:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isZero"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1024:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1026:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "opcode"(%3) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1028:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %5 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1030:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1032:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "||"(%2, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1034:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("index-structuralize.mlir":1036:1)
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1038:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1040:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "br" : <String> loc("index-structuralize.mlir":1042:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "br" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1044:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1046:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "opcode"(%12) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1048:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %14 = mpir_expr.str "nothing" : <String> loc("index-structuralize.mlir":1050:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "nothing" : <String>
  %15 = mpir_expr.call binary "=="(%13, %14) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1052:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "=="(%[[CALL_6]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %16 = mpir_expr.call binary "||"(%11, %15) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1054:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_7]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %16 : <Boolean> loc("index-structuralize.mlir":1056:1)
// CHECK:           mpir.require %[[CALL_8]] : <Boolean>
  %17 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1058:1)
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %18 = mpir_expr.call call "opcode"(%17) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1060:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %19 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1062:1)
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
  %20 = mpir_expr.call binary "!="(%18, %19) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1064:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_9]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %20 : <Boolean> loc("index-structuralize.mlir":1066:1)
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
  %21 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1068:1)
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %22 = mpir_expr.call call "intrinsic"(%21) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1070:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call call "intrinsic"(%[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %23 = mpir_expr.str "llvm.ctlz" : <String> loc("index-structuralize.mlir":1072:1)
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "llvm.ctlz" : <String>
  %24 = mpir_expr.call binary "=="(%22, %23) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1074:1)
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %24 : <Boolean> loc("index-structuralize.mlir":1076:1)
// CHECK:           mpir.require %[[CALL_12]] : <Boolean>
  %25 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1078:1)
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %26 = mpir_expr.call call "bitWidth"(%25) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("index-structuralize.mlir":1080:1)
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %27 = mpir_expr.int 32 : ui64 : <Integer> loc("index-structuralize.mlir":1082:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
  %28 = mpir_expr.call binary "=="(%26, %27) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1084:1)
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call binary "=="(%[[CALL_13]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %28 : <Boolean> loc("index-structuralize.mlir":1086:1)
// CHECK:           mpir.require %[[CALL_14]] : <Boolean>
  %29 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1088:1)
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %30 = mpir_expr.call call "opcode"(%29) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1090:1)
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %31 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1092:1)
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %32 = mpir_expr.call call "opcode"(%31) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1094:1)
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "opcode"(%[[READ_8]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %33 = mpir_expr.call binary "=="(%30, %32) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1096:1)
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[CALL_16]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %33 : <Boolean> loc("index-structuralize.mlir":1098:1)
// CHECK:           mpir.require %[[CALL_17]] : <Boolean>
} loc("index-structuralize.mlir":1100:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":1106:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":1108:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":1110:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-structuralize.mlir":1112:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1114:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1116:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1118:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":1120:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %5 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1122:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %6 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1124:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call call "opcode"(%5) anchor %6 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1126:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %8 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1128:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
    %9 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1130:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "=="(%7, %8) anchor %9 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1132:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_0]]) anchor %[[NODE_2]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1134:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "||"(%3, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1136:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean> loc("index-structuralize.mlir":1138:1)
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
    %13 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1140:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1142:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call call "opcode"(%13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1144:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %16 = mpir_expr.str "br" : <String> loc("index-structuralize.mlir":1146:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "br" : <String>
    %17 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1148:1)
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call binary "=="(%15, %16) anchor %17 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1150:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %19 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1152:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %20 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1154:1)
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call call "opcode"(%19) anchor %20 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1156:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %22 = mpir_expr.str "nothing" : <String> loc("index-structuralize.mlir":1158:1)
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "nothing" : <String>
    %23 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1160:1)
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
    %24 = mpir_expr.call binary "=="(%21, %22) anchor %23 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1162:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "=="(%[[CALL_6]], %[[STR_2]]) anchor %[[NODE_7]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %25 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1164:1)
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
    %26 = mpir_expr.call binary "||"(%18, %24) anchor %25 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1166:1)
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_7]]) anchor %[[NODE_8]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %26 : <Boolean> loc("index-structuralize.mlir":1168:1)
// CHECK:             mpir_index.assume %[[CALL_8]] : <Boolean>
    %27 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1170:1)
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %28 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1172:1)
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
    %29 = mpir_expr.call call "opcode"(%27) anchor %28 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1174:1)
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[NODE_9]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %30 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1176:1)
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
    %31 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1178:1)
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
    %32 = mpir_expr.call binary "!="(%29, %30) anchor %31 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1180:1)
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_9]], %[[STR_3]]) anchor %[[NODE_10]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %32 : <Boolean> loc("index-structuralize.mlir":1182:1)
// CHECK:             mpir_index.assume %[[CALL_10]] : <Boolean>
    %33 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1184:1)
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %34 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1186:1)
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
    %35 = mpir_expr.call call "intrinsic"(%33) anchor %34 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1188:1)
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call call "intrinsic"(%[[READ_5]]) anchor %[[NODE_11]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %36 = mpir_expr.str "llvm.ctlz" : <String> loc("index-structuralize.mlir":1190:1)
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "llvm.ctlz" : <String>
    %37 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1192:1)
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
    %38 = mpir_expr.call binary "=="(%35, %36) anchor %37 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1194:1)
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_4]]) anchor %[[NODE_12]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %38 : <Boolean> loc("index-structuralize.mlir":1196:1)
// CHECK:             mpir_index.assume %[[CALL_12]] : <Boolean>
    %39 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1198:1)
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %40 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1200:1)
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
    %41 = mpir_expr.call call "bitWidth"(%39) anchor %40 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer> loc("index-structuralize.mlir":1202:1)
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[NODE_13]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
    %42 = mpir_expr.int 32 : ui64 : <Integer> loc("index-structuralize.mlir":1204:1)
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %43 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1206:1)
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
    %44 = mpir_expr.call binary "=="(%41, %42) anchor %43 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1208:1)
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "=="(%[[CALL_13]], %[[INT_0]]) anchor %[[NODE_14]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %44 : <Boolean> loc("index-structuralize.mlir":1210:1)
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
    %45 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1212:1)
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %46 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1214:1)
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 0 : <Instruction>
    %47 = mpir_expr.call call "opcode"(%45) anchor %46 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1216:1)
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[NODE_15]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %48 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1218:1)
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %49 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1220:1)
// CHECK:             %[[NODE_16:.*]] = mpir_index.node 0 : <Instruction>
    %50 = mpir_expr.call call "opcode"(%48) anchor %49 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1222:1)
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call call "opcode"(%[[READ_8]]) anchor %[[NODE_16]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %51 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1224:1)
// CHECK:             %[[NODE_17:.*]] = mpir_index.node 0 : <Instruction>
    %52 = mpir_expr.call binary "=="(%47, %50) anchor %51 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1226:1)
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[CALL_16]]) anchor %[[NODE_17]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %52 : <Boolean> loc("index-structuralize.mlir":1228:1)
// CHECK:             mpir_index.assume %[[CALL_17]] : <Boolean>
  } loc("index-structuralize.mlir":1230:1)
// CHECK:           }
} loc("index-structuralize.mlir":1232:1)
// CHECK:         }

// -----

// Each variant of a matcher's branches is split on its own.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-structuralize.mlir":1240:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-structuralize.mlir":1242:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-structuralize.mlir":1244:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <add> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":1248:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-structuralize.mlir":1250:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-structuralize.mlir":1254:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-structuralize.mlir":1256:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("index-structuralize.mlir":1258:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1260:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %3 = mpir_expr.call call "opcode"(%2) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1262:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %4 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1264:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %1 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1266:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1268:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "opcode"(%6) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1270:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %8 = mpir_expr.str "shl" : <String> loc("index-structuralize.mlir":1272:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
  %9 = mpir_expr.call binary "=="(%7, %8) anchor %1 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1274:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.call binary "||"(%5, %9) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1276:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %10 : <Boolean> loc("index-structuralize.mlir":1278:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
} loc("index-structuralize.mlir":1280:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-structuralize.mlir":1286:1)
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-structuralize.mlir":1287:1)
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":1288:1)
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":1289:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1290:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1291:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1292:1)
    %4 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1293:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1294:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1295:1)
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1296:1)
    %8 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1297:1)
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1298:1)
    %10 = mpir_expr.str "shl" : <String> loc("index-structuralize.mlir":1299:1)
    %11 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1300:1)
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1301:1)
    %13 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1302:1)
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1303:1)
    mpir_index.assume %14 : <Boolean> loc("index-structuralize.mlir":1304:1)
  } loc("index-structuralize.mlir":1305:1)
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <shl> <derived>
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[NODE_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[NODE_8]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_6]], %[[CALL_8]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_9]] : <Boolean>
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <sub> loc("index-structuralize.mlir":1351:1)
    mpir_index.has_shape <sub>, 0, 0, 32 loc("index-structuralize.mlir":1352:1)
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-structuralize.mlir":1353:1)
    %0 = mpir_index.sites [[0, 3, 2]] {var_name = "y"} : <Operand> loc("index-structuralize.mlir":1354:1)
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1355:1)
    %2 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1356:1)
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1357:1)
    %4 = mpir_expr.str "mul" : <String> loc("index-structuralize.mlir":1358:1)
    %5 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1359:1)
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1360:1)
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-structuralize.mlir":1361:1)
    %8 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1362:1)
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-structuralize.mlir":1363:1)
    %10 = mpir_expr.str "shl" : <String> loc("index-structuralize.mlir":1364:1)
    %11 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1365:1)
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1366:1)
    %13 = mpir_index.node 0 : <Instruction> loc("index-structuralize.mlir":1367:1)
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-structuralize.mlir":1368:1)
    mpir_index.assume %14 : <Boolean> loc("index-structuralize.mlir":1369:1)
  } loc("index-structuralize.mlir":1370:1)
// CHECK:             mpir_index.has_instruction <mul> <derived>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 3, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[NODE_10]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) anchor %[[NODE_12]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_5:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[STR_5]]) anchor %[[NODE_13]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "||"(%[[CALL_11]], %[[CALL_13]]) anchor %[[NODE_14]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <shl> <derived>
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_3:.*]] = mpir_index.sites {{\[\[}}0, 3, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_6]]) anchor %[[NODE_15]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_6:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_16:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[STR_6]]) anchor %[[NODE_16]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_17:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[NODE_17]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_7:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[NODE_18:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_18:.*]] = mpir_expr.call binary "=="(%[[CALL_17]], %[[STR_7]]) anchor %[[NODE_18]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_19:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_19:.*]] = mpir_expr.call binary "||"(%[[CALL_16]], %[[CALL_18]]) anchor %[[NODE_19]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_19]] : <Boolean>
// CHECK:           }
} loc("index-structuralize.mlir":1414:1)
// CHECK:         }
