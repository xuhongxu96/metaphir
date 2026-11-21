// RUN: %metaphir-opt --split-input-file --mpir-index-retrieval %s | FileCheck %s
// mpir-index-retrieval adds the lookup to each query: the union over the
// possible variants of the intersection of the posting lists of their
// posted features (instructions, edges, siblings, globals).

// One variant: the intersection of its lists.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":9:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-retrieval.mlir":11:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-retrieval.mlir":13:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":15:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":17:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":19:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":21:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.global "llvm.ctlz.i32" : <Value> loc("index-retrieval.mlir":23:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.ctlz.i32" : <Value>
  %4 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":25:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %5 = mpir.type.int 1 : <Type> loc("index-retrieval.mlir":27:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
  %6 = mpir.int 0 : ui1 : <Value> loc("index-retrieval.mlir":29:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%2, %3, %4, %i_b, %5, %6) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":31:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_2]], %[[GLOBAL_0]], %[[TYPE_3]], %[[INST_1]], %[[TYPE_4]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("index-retrieval.mlir":33:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-retrieval.mlir":39:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul> loc("index-retrieval.mlir":41:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_instruction <call> loc("index-retrieval.mlir":43:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_edge <mul> -> <add> loc("index-retrieval.mlir":45:1)
// CHECK:             mpir_index.has_edge <mul> -> <add>
    mpir_index.has_edge <call> -> <mul> loc("index-retrieval.mlir":47:1)
// CHECK:             mpir_index.has_edge <call> -> <mul>
    mpir_index.has_sibling <add>, <mul> loc("index-retrieval.mlir":49:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_global "llvm.ctlz.i32" loc("index-retrieval.mlir":51:1)
// CHECK:             mpir_index.has_global "llvm.ctlz.i32"
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-retrieval.mlir":53:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-retrieval.mlir":55:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-retrieval.mlir":57:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.has_fact 2, <call>, 4, 128 loc("index-retrieval.mlir":59:1)
// CHECK:             mpir_index.has_fact 2, <call>, 4, 128
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":61:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":63:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]> loc("index-retrieval.mlir":65:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
  } loc("index-retrieval.mlir":67:1)
// CHECK:           }
// CHECK:           mpir_index.retrieve {
} loc("index-retrieval.mlir":70:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 0, 48 : i64
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 1, 321 : i64
// CHECK:             %[[POSTINGS_4:.*]] = mpir_index.postings 1, 3077 : i64
// CHECK:             %[[POSTINGS_5:.*]] = mpir_index.postings 2, 69 : i64
// CHECK:             %[[POSTINGS_6:.*]] = mpir_index.postings 3, "llvm.ctlz.i32"
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]], %[[POSTINGS_2]], %[[POSTINGS_3]], %[[POSTINGS_4]], %[[POSTINGS_5]], %[[POSTINGS_6]]
// CHECK:             mpir_index.result %[[INTERSECT_0]]
// CHECK:           }
// CHECK:         }

// -----

// A variant per branch: their union.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":88:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-retrieval.mlir":90:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-retrieval.mlir":92:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <add> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":96:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-retrieval.mlir":98:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":102:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-retrieval.mlir":104:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("index-retrieval.mlir":106:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":108:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <mul> (%2, %1, %2, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":110:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("index-retrieval.mlir":112:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-retrieval.mlir":118:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul> loc("index-retrieval.mlir":120:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <add> loc("index-retrieval.mlir":122:1)
// CHECK:             mpir_index.has_edge <mul> -> <add>
    mpir_index.has_sibling <add>, <mul> loc("index-retrieval.mlir":124:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-retrieval.mlir":126:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-retrieval.mlir":128:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":130:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":132:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-retrieval.mlir":134:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <sub> loc("index-retrieval.mlir":138:1)
// CHECK:             mpir_index.has_instruction <sub>
    mpir_index.has_instruction <mul> loc("index-retrieval.mlir":140:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <sub> loc("index-retrieval.mlir":142:1)
// CHECK:             mpir_index.has_edge <mul> -> <sub>
    mpir_index.has_sibling <sub>, <mul> loc("index-retrieval.mlir":144:1)
// CHECK:             mpir_index.has_sibling <sub>, <mul>
    mpir_index.has_shape <sub>, 0, 0, 32 loc("index-retrieval.mlir":146:1)
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-retrieval.mlir":148:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":150:1)
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":152:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-retrieval.mlir":154:1)
// CHECK:           }
// CHECK:           mpir_index.retrieve {
} loc("index-retrieval.mlir":157:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 1, 321 : i64
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 2, 69 : i64
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]], %[[POSTINGS_2]], %[[POSTINGS_3]]
// CHECK:             %[[POSTINGS_4:.*]] = mpir_index.postings 0, 3 : i64
// CHECK:             %[[POSTINGS_5:.*]] = mpir_index.postings 0, 5 : i64
// CHECK:             %[[POSTINGS_6:.*]] = mpir_index.postings 1, 323 : i64
// CHECK:             %[[POSTINGS_7:.*]] = mpir_index.postings 2, 197 : i64
// CHECK:             %[[INTERSECT_1:.*]] = mpir_index.intersect %[[POSTINGS_4]], %[[POSTINGS_5]], %[[POSTINGS_6]], %[[POSTINGS_7]]
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[INTERSECT_1]]
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }

// -----

// An impossible variant reads nothing.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %self = mpir.var "self" : <Instruction> loc("index-retrieval.mlir":178:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":180:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-retrieval.mlir":182:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-retrieval.mlir":184:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":186:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-retrieval.mlir":188:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-retrieval.mlir":190:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "sub" : <String> loc("index-retrieval.mlir":192:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":194:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-retrieval.mlir":196:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-retrieval.mlir":198:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String> loc("index-retrieval.mlir":200:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":202:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "&&"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":204:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-retrieval.mlir":206:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
} loc("index-retrieval.mlir":208:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant <impossible> {
// CHECK:           mpir_index.variant <impossible> {
    mpir_index.has_instruction <add> loc("index-retrieval.mlir":214:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-retrieval.mlir":216:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-retrieval.mlir":218:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 8]] {var_name = "self"} : <Instruction> loc("index-retrieval.mlir":220:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 8]] {var_name = "self"} : <Instruction>
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("index-retrieval.mlir":222:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":224:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-retrieval.mlir":226:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "sub" : <String> loc("index-retrieval.mlir":228:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
    %5 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":230:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":232:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-retrieval.mlir":234:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-retrieval.mlir":236:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":238:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call call "opcode"(%8) anchor %9 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-retrieval.mlir":240:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %11 = mpir_expr.str "mul" : <String> loc("index-retrieval.mlir":242:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
    %12 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":244:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %13 = mpir_expr.call binary "=="(%10, %11) anchor %12 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":246:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %14 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":248:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call binary "&&"(%6, %13) anchor %14 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":250:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean> loc("index-retrieval.mlir":252:1)
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
  } loc("index-retrieval.mlir":254:1)
// CHECK:           }
// CHECK:           mpir_index.retrieve {
} loc("index-retrieval.mlir":257:1)
// CHECK:             %[[UNION_0:.*]] = mpir_index.union
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }

// -----

// Features from constraints are read too.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":268:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID> loc("index-retrieval.mlir":270:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":272:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-retrieval.mlir":274:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("index-retrieval.mlir":276:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("index-retrieval.mlir":278:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-retrieval.mlir":280:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":282:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %4 = mpir_expr.str "llvm.smax" : <String> loc("index-retrieval.mlir":284:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":286:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":288:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %7 = mpir_expr.str "llvm.umin" : <String> loc("index-retrieval.mlir":290:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":292:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%5, %8) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":294:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean> loc("index-retrieval.mlir":296:1)
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
} loc("index-retrieval.mlir":298:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_global "llvm.smax" <derived> loc("index-retrieval.mlir":304:1)
// CHECK:             mpir_index.has_global "llvm.smax" <derived>
    mpir_index.has_instruction <call> loc("index-retrieval.mlir":306:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-retrieval.mlir":308:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-retrieval.mlir":310:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-retrieval.mlir":312:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":314:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-retrieval.mlir":316:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":318:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":320:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":322:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-retrieval.mlir":324:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":326:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":328:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":330:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":332:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean> loc("index-retrieval.mlir":334:1)
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
  } loc("index-retrieval.mlir":336:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_global "llvm.umin" <derived> loc("index-retrieval.mlir":340:1)
// CHECK:             mpir_index.has_global "llvm.umin" <derived>
    mpir_index.has_instruction <call> loc("index-retrieval.mlir":342:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-retrieval.mlir":344:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-retrieval.mlir":346:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-retrieval.mlir":348:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":350:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-retrieval.mlir":352:1)
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":354:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":356:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-retrieval.mlir":358:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-retrieval.mlir":360:1)
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":362:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":364:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[STR_3]]) anchor %[[NODE_4]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-retrieval.mlir":366:1)
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-retrieval.mlir":368:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_4]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean> loc("index-retrieval.mlir":370:1)
// CHECK:             mpir_index.assume %[[CALL_5]] : <Boolean>
  } loc("index-retrieval.mlir":372:1)
// CHECK:           }
// CHECK:           mpir_index.retrieve {
} loc("index-retrieval.mlir":375:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 3, "llvm.smax"
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 48 : i64
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]]
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 3, "llvm.umin"
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 0, 48 : i64
// CHECK:             %[[INTERSECT_1:.*]] = mpir_index.intersect %[[POSTINGS_2]], %[[POSTINGS_3]]
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[INTERSECT_1]]
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }
