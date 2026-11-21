// RUN: %metaphir-opt --split-input-file --mpir-index-factor %s | FileCheck %s
// mpir-index-factor reads a list every variant needs once: (A & B) | (A & C)
// becomes A & (B | C), and repeated lists and sets are merged.

// One variant: nothing to factor.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-factor.mlir":8:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-factor.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-factor.mlir":12:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":14:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("index-factor.mlir":16:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":18:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("index-factor.mlir":20:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-factor.mlir":26:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul> loc("index-factor.mlir":28:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <add> loc("index-factor.mlir":30:1)
// CHECK:             mpir_index.has_edge <mul> -> <add>
    mpir_index.has_sibling <add>, <mul> loc("index-factor.mlir":32:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-factor.mlir":34:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-factor.mlir":36:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":38:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":40:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-factor.mlir":42:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":46:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.postings 0, 5 : i64 loc("index-factor.mlir":48:1)
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
    %2 = mpir_index.postings 1, 321 : i64 loc("index-factor.mlir":50:1)
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 1, 321 : i64
    %3 = mpir_index.postings 2, 69 : i64 loc("index-factor.mlir":52:1)
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 2, 69 : i64
    %4 = mpir_index.intersect %0, %1, %2, %3 loc("index-factor.mlir":54:1)
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]], %[[POSTINGS_2]], %[[POSTINGS_3]]
    mpir_index.result %4 loc("index-factor.mlir":56:1)
// CHECK:             mpir_index.result %[[INTERSECT_0]]
  } loc("index-factor.mlir":58:1)
// CHECK:           }
} loc("index-factor.mlir":60:1)
// CHECK:         }

// -----

// Two variants with lists in common.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-factor.mlir":68:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-factor.mlir":70:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-factor.mlir":72:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_m = mpir.inst <mul> (%0, %x, %0, %y) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":74:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("index-factor.mlir":76:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.alt {
    %i_r = mpir.inst <add> (%1, %i_m, %1, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":80:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-factor.mlir":82:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%1, %i_m, %1, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":86:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-factor.mlir":88:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("index-factor.mlir":90:1)
// CHECK:           } <result_name = "r"> : <Instruction>
  %3 = mpir.type.int 32 : <Type> loc("index-factor.mlir":92:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <shl> (%3, %2, %3, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":94:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <shl> (%[[TYPE_2]], %[[ALT_0]], %[[TYPE_2]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("index-factor.mlir":96:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-factor.mlir":102:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul> loc("index-factor.mlir":104:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_instruction <shl> loc("index-factor.mlir":106:1)
// CHECK:             mpir_index.has_instruction <shl>
    mpir_index.has_edge <add> -> <mul> loc("index-factor.mlir":108:1)
// CHECK:             mpir_index.has_edge <add> -> <mul>
    mpir_index.has_edge <shl> -> <add> loc("index-factor.mlir":110:1)
// CHECK:             mpir_index.has_edge <shl> -> <add>
    mpir_index.has_sibling <add>, <mul> loc("index-factor.mlir":112:1)
// CHECK:             mpir_index.has_sibling <add>, <mul>
    mpir_index.has_sibling <add>, <shl> loc("index-factor.mlir":114:1)
// CHECK:             mpir_index.has_sibling <add>, <shl>
    mpir_index.has_sibling <mul>, <shl> loc("index-factor.mlir":116:1)
// CHECK:             mpir_index.has_sibling <mul>, <shl>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-factor.mlir":118:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-factor.mlir":120:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <shl>, 0, 0, 32 loc("index-factor.mlir":122:1)
// CHECK:             mpir_index.has_shape <shl>, 0, 0, 32
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":124:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":126:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <shl> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":128:1)
// CHECK:             mpir_index.typing <shl> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-factor.mlir":130:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <sub> loc("index-factor.mlir":134:1)
// CHECK:             mpir_index.has_instruction <sub>
    mpir_index.has_instruction <mul> loc("index-factor.mlir":136:1)
// CHECK:             mpir_index.has_instruction <mul>
    mpir_index.has_instruction <shl> loc("index-factor.mlir":138:1)
// CHECK:             mpir_index.has_instruction <shl>
    mpir_index.has_edge <sub> -> <mul> loc("index-factor.mlir":140:1)
// CHECK:             mpir_index.has_edge <sub> -> <mul>
    mpir_index.has_edge <shl> -> <sub> loc("index-factor.mlir":142:1)
// CHECK:             mpir_index.has_edge <shl> -> <sub>
    mpir_index.has_sibling <sub>, <mul> loc("index-factor.mlir":144:1)
// CHECK:             mpir_index.has_sibling <sub>, <mul>
    mpir_index.has_sibling <sub>, <shl> loc("index-factor.mlir":146:1)
// CHECK:             mpir_index.has_sibling <sub>, <shl>
    mpir_index.has_sibling <mul>, <shl> loc("index-factor.mlir":148:1)
// CHECK:             mpir_index.has_sibling <mul>, <shl>
    mpir_index.has_shape <sub>, 0, 0, 32 loc("index-factor.mlir":150:1)
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32 loc("index-factor.mlir":152:1)
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <shl>, 0, 0, 32 loc("index-factor.mlir":154:1)
// CHECK:             mpir_index.has_shape <shl>, 0, 0, 32
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":156:1)
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":158:1)
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <shl> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":160:1)
// CHECK:             mpir_index.typing <shl> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-factor.mlir":162:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":166:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.postings 0, 5 : i64 loc("index-factor.mlir":168:1)
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
    %2 = mpir_index.postings 0, 13 : i64 loc("index-factor.mlir":170:1)
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 0, 13 : i64
    %3 = mpir_index.postings 1, 69 : i64 loc("index-factor.mlir":172:1)
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 1, 69 : i64
    %4 = mpir_index.postings 1, 833 : i64 loc("index-factor.mlir":174:1)
// CHECK:             %[[POSTINGS_4:.*]] = mpir_index.postings 1, 833 : i64
    %5 = mpir_index.postings 2, 69 : i64 loc("index-factor.mlir":176:1)
// CHECK:             %[[POSTINGS_5:.*]] = mpir_index.postings 2, 69 : i64
    %6 = mpir_index.postings 2, 77 : i64 loc("index-factor.mlir":178:1)
// CHECK:             %[[POSTINGS_6:.*]] = mpir_index.postings 2, 77 : i64
    %7 = mpir_index.postings 2, 333 : i64 loc("index-factor.mlir":180:1)
// CHECK:             %[[POSTINGS_7:.*]] = mpir_index.postings 2, 333 : i64
    %8 = mpir_index.intersect %0, %1, %2, %3, %4, %5, %6, %7 loc("index-factor.mlir":182:1)
    %9 = mpir_index.postings 0, 3 : i64 loc("index-factor.mlir":183:1)
// CHECK:             %[[POSTINGS_8:.*]] = mpir_index.postings 0, 3 : i64
    %10 = mpir_index.postings 0, 5 : i64 loc("index-factor.mlir":185:1)
    %11 = mpir_index.postings 0, 13 : i64 loc("index-factor.mlir":186:1)
    %12 = mpir_index.postings 1, 197 : i64 loc("index-factor.mlir":187:1)
// CHECK:             %[[POSTINGS_9:.*]] = mpir_index.postings 1, 197 : i64
    %13 = mpir_index.postings 1, 835 : i64 loc("index-factor.mlir":189:1)
// CHECK:             %[[POSTINGS_10:.*]] = mpir_index.postings 1, 835 : i64
    %14 = mpir_index.postings 2, 197 : i64 loc("index-factor.mlir":191:1)
// CHECK:             %[[POSTINGS_11:.*]] = mpir_index.postings 2, 197 : i64
    %15 = mpir_index.postings 2, 205 : i64 loc("index-factor.mlir":193:1)
// CHECK:             %[[POSTINGS_12:.*]] = mpir_index.postings 2, 205 : i64
    %16 = mpir_index.postings 2, 333 : i64 loc("index-factor.mlir":195:1)
    %17 = mpir_index.intersect %9, %10, %11, %12, %13, %14, %15, %16 loc("index-factor.mlir":196:1)
    %18 = mpir_index.union %8, %17 loc("index-factor.mlir":197:1)
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_3]], %[[POSTINGS_4]], %[[POSTINGS_5]], %[[POSTINGS_6]]
// CHECK:             %[[INTERSECT_1:.*]] = mpir_index.intersect %[[POSTINGS_8]], %[[POSTINGS_9]], %[[POSTINGS_10]], %[[POSTINGS_11]], %[[POSTINGS_12]]
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[INTERSECT_1]]
// CHECK:             %[[INTERSECT_2:.*]] = mpir_index.intersect %[[POSTINGS_7]], %[[UNION_0]]
// CHECK:             %[[INTERSECT_3:.*]] = mpir_index.intersect %[[POSTINGS_2]], %[[INTERSECT_2]]
// CHECK:             %[[INTERSECT_4:.*]] = mpir_index.intersect %[[POSTINGS_1]], %[[INTERSECT_3]]
    mpir_index.result %18 loc("index-factor.mlir":204:1)
// CHECK:             mpir_index.result %[[INTERSECT_4]]
  } loc("index-factor.mlir":206:1)
// CHECK:           }
} loc("index-factor.mlir":208:1)
// CHECK:         }

// -----

// Variants that differ in one list only.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-factor.mlir":216:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID> loc("index-factor.mlir":218:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type> loc("index-factor.mlir":220:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-factor.mlir":222:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("index-factor.mlir":224:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand> loc("index-factor.mlir":226:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":228:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":230:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %4 = mpir_expr.str "llvm.smax" : <String> loc("index-factor.mlir":232:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":234:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":236:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %7 = mpir_expr.str "llvm.umin" : <String> loc("index-factor.mlir":238:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":240:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%5, %8) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":242:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":244:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %11 = mpir_expr.str "llvm.umax" : <String> loc("index-factor.mlir":246:1)
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
  %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":248:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %13 = mpir_expr.call binary "||"(%9, %12) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":250:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %13 : <Boolean> loc("index-factor.mlir":252:1)
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
} loc("index-factor.mlir":254:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_global "llvm.smax" <derived> loc("index-factor.mlir":260:1)
// CHECK:             mpir_index.has_global "llvm.smax" <derived>
    mpir_index.has_instruction <call> loc("index-factor.mlir":262:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-factor.mlir":264:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-factor.mlir":266:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-factor.mlir":268:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":270:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-factor.mlir":272:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":274:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":276:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":278:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-factor.mlir":280:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":282:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":284:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":286:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":288:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":290:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String> loc("index-factor.mlir":292:1)
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":294:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":296:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":298:1)
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":300:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean> loc("index-factor.mlir":302:1)
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
  } loc("index-factor.mlir":304:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_global "llvm.umin" <derived> loc("index-factor.mlir":308:1)
// CHECK:             mpir_index.has_global "llvm.umin" <derived>
    mpir_index.has_instruction <call> loc("index-factor.mlir":310:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-factor.mlir":312:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-factor.mlir":314:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-factor.mlir":316:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":318:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-factor.mlir":320:1)
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":322:1)
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":324:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[STR_3]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":326:1)
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-factor.mlir":328:1)
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":330:1)
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":332:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[READ_4]], %[[STR_4]]) anchor %[[NODE_6]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":334:1)
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":336:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_6]]) anchor %[[NODE_7]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":338:1)
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String> loc("index-factor.mlir":340:1)
// CHECK:             %[[STR_5:.*]] = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":342:1)
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":344:1)
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[READ_5]], %[[STR_5]]) anchor %[[NODE_8]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":346:1)
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":348:1)
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_8]]) anchor %[[NODE_9]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean> loc("index-factor.mlir":350:1)
// CHECK:             mpir_index.assume %[[CALL_9]] : <Boolean>
  } loc("index-factor.mlir":352:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_global "llvm.umax" <derived> loc("index-factor.mlir":356:1)
// CHECK:             mpir_index.has_global "llvm.umax" <derived>
    mpir_index.has_instruction <call> loc("index-factor.mlir":358:1)
// CHECK:             mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32 loc("index-factor.mlir":360:1)
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]> loc("index-factor.mlir":362:1)
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID> loc("index-factor.mlir":364:1)
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":366:1)
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String> loc("index-factor.mlir":368:1)
// CHECK:             %[[STR_6:.*]] = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":370:1)
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":372:1)
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "=="(%[[READ_6]], %[[STR_6]]) anchor %[[NODE_10]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":374:1)
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String> loc("index-factor.mlir":376:1)
// CHECK:             %[[STR_7:.*]] = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":378:1)
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":380:1)
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[READ_7]], %[[STR_7]]) anchor %[[NODE_11]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":382:1)
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":384:1)
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "||"(%[[CALL_10]], %[[CALL_11]]) anchor %[[NODE_12]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String> loc("index-factor.mlir":386:1)
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String> loc("index-factor.mlir":388:1)
// CHECK:             %[[STR_8:.*]] = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":390:1)
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":392:1)
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[READ_8]], %[[STR_8]]) anchor %[[NODE_13]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":394:1)
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":396:1)
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "||"(%[[CALL_12]], %[[CALL_13]]) anchor %[[NODE_14]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean> loc("index-factor.mlir":398:1)
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
  } loc("index-factor.mlir":400:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %0 = mpir_index.postings 3, "llvm.smax" loc("index-factor.mlir":404:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 3, "llvm.smax"
    %1 = mpir_index.postings 0, 48 : i64 loc("index-factor.mlir":406:1)
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 48 : i64
    %2 = mpir_index.intersect %0, %1 loc("index-factor.mlir":408:1)
    %3 = mpir_index.postings 3, "llvm.umin" loc("index-factor.mlir":409:1)
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 3, "llvm.umin"
    %4 = mpir_index.postings 0, 48 : i64 loc("index-factor.mlir":411:1)
    %5 = mpir_index.intersect %3, %4 loc("index-factor.mlir":412:1)
    %6 = mpir_index.postings 3, "llvm.umax" loc("index-factor.mlir":413:1)
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 3, "llvm.umax"
    %7 = mpir_index.postings 0, 48 : i64 loc("index-factor.mlir":415:1)
    %8 = mpir_index.intersect %6, %7 loc("index-factor.mlir":416:1)
    %9 = mpir_index.union %2, %5, %8 loc("index-factor.mlir":417:1)
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[POSTINGS_0]], %[[POSTINGS_2]], %[[POSTINGS_3]]
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_1]], %[[UNION_0]]
    mpir_index.result %9 loc("index-factor.mlir":420:1)
// CHECK:             mpir_index.result %[[INTERSECT_0]]
  } loc("index-factor.mlir":422:1)
// CHECK:           }
} loc("index-factor.mlir":424:1)
// CHECK:         }

// -----

// Variants with nothing in common.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-factor.mlir":432:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-factor.mlir":434:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-factor.mlir":436:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_r = mpir.inst <add> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":440:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-factor.mlir":442:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <sub> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":446:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("index-factor.mlir":448:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "r"> : <Instruction> loc("index-factor.mlir":450:1)
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("index-factor.mlir":452:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> loc("index-factor.mlir":458:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-factor.mlir":460:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":462:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-factor.mlir":464:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <sub> loc("index-factor.mlir":468:1)
// CHECK:             mpir_index.has_instruction <sub>
    mpir_index.has_shape <sub>, 0, 0, 32 loc("index-factor.mlir":470:1)
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":472:1)
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  } loc("index-factor.mlir":474:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":478:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.intersect %0 loc("index-factor.mlir":480:1)
    %2 = mpir_index.postings 0, 3 : i64 loc("index-factor.mlir":481:1)
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 3 : i64
    %3 = mpir_index.intersect %2 loc("index-factor.mlir":483:1)
    %4 = mpir_index.union %1, %3 loc("index-factor.mlir":484:1)
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[POSTINGS_0]], %[[POSTINGS_1]]
    mpir_index.result %4 loc("index-factor.mlir":486:1)
// CHECK:             mpir_index.result %[[UNION_0]]
  } loc("index-factor.mlir":488:1)
// CHECK:           }
} loc("index-factor.mlir":490:1)
// CHECK:         }

// -----

// A variant whose lists are all common: the others add nothing.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("index-factor.mlir":498:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("index-factor.mlir":500:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("index-factor.mlir":502:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("index-factor.mlir":504:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":506:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isZero"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":508:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.bool true : <Boolean> loc("index-factor.mlir":510:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
  %4 = mpir_expr.call binary "||"(%2, %3) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":512:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean> loc("index-factor.mlir":514:1)
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
  %5 = mpir.type.int 32 : <Type> loc("index-factor.mlir":516:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %6 = mpir.int 3 : ui2 : <Value> loc("index-factor.mlir":518:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %7 = mpir.alt {
    mpir.yield %i_a : <Instruction> loc("index-factor.mlir":522:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_b = mpir.inst <mul> (%5, %i_a, %5, %6) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("index-factor.mlir":526:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction> loc("index-factor.mlir":528:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } <result_name = "b"> : <Instruction> loc("index-factor.mlir":530:1)
// CHECK:           } <result_name = "b"> : <Instruction>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":532:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-factor.mlir":534:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "shl" : <String> loc("index-factor.mlir":536:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "shl" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":538:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_0]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":540:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "opcode"(%12) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String> loc("index-factor.mlir":542:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %14 = mpir_expr.str "add" : <String> loc("index-factor.mlir":544:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "add" : <String>
  %15 = mpir_expr.call binary "=="(%13, %14) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":546:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %16 = mpir_expr.call binary "||"(%11, %15) anchor %7 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":548:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_5]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %16 : <Boolean> loc("index-factor.mlir":550:1)
// CHECK:           mpir.require %[[CALL_6]] : <Boolean>
} loc("index-factor.mlir":552:1)
// CHECK:         }
mpir_index.query {
// CHECK-LABEL:   mpir_index.query {
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <shl> <derived> loc("index-factor.mlir":558:1)
// CHECK:             mpir_index.has_instruction <shl> <derived>
    mpir_index.has_instruction <add> loc("index-factor.mlir":560:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-factor.mlir":562:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":564:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-factor.mlir":566:1)
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":568:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":570:1)
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":572:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean> loc("index-factor.mlir":574:1)
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":576:1)
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "||"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":578:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean> loc("index-factor.mlir":580:1)
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-factor.mlir":582:1)
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":584:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_expr.call call "opcode"(%8) : (!mpir.sort<Value>) -> !mpir.sort<String> loc("index-factor.mlir":586:1)
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String> loc("index-factor.mlir":588:1)
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "shl" : <String>
    %11 = mpir_expr.call binary "=="(%9, %10) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("index-factor.mlir":590:1)
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %12 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":592:1)
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.call call "opcode"(%12) : (!mpir.sort<Value>) -> !mpir.sort<String> loc("index-factor.mlir":594:1)
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %14 = mpir_expr.str "add" : <String> loc("index-factor.mlir":596:1)
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "add" : <String>
    %15 = mpir_expr.call binary "=="(%13, %14) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("index-factor.mlir":598:1)
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %16 = mpir_expr.call binary "||"(%11, %15) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("index-factor.mlir":600:1)
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_5]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean> loc("index-factor.mlir":602:1)
// CHECK:             mpir_index.assume %[[CALL_6]] : <Boolean>
  } loc("index-factor.mlir":604:1)
// CHECK:           }
  mpir_index.variant {
// CHECK:           mpir_index.variant {
    mpir_index.has_instruction <add> <derived> loc("index-factor.mlir":608:1)
// CHECK:             mpir_index.has_instruction <add> <derived>
    mpir_index.has_instruction <add> loc("index-factor.mlir":610:1)
// CHECK:             mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32 loc("index-factor.mlir":612:1)
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]> loc("index-factor.mlir":614:1)
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand> loc("index-factor.mlir":616:1)
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":618:1)
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":620:1)
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":622:1)
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean> loc("index-factor.mlir":624:1)
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction> loc("index-factor.mlir":626:1)
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "||"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("index-factor.mlir":628:1)
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[BOOL_1]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean> loc("index-factor.mlir":630:1)
// CHECK:             mpir_index.assume %[[CALL_8]] : <Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand> loc("index-factor.mlir":632:1)
// CHECK:             %[[SITES_3:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":634:1)
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_expr.call call "opcode"(%8) : (!mpir.sort<Value>) -> !mpir.sort<String> loc("index-factor.mlir":636:1)
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String> loc("index-factor.mlir":638:1)
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "shl" : <String>
    %11 = mpir_expr.call binary "=="(%9, %10) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("index-factor.mlir":640:1)
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "=="(%[[CALL_9]], %[[STR_2]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %12 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("index-factor.mlir":642:1)
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.call call "opcode"(%12) : (!mpir.sort<Value>) -> !mpir.sort<String> loc("index-factor.mlir":644:1)
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %14 = mpir_expr.str "add" : <String> loc("index-factor.mlir":646:1)
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "add" : <String>
    %15 = mpir_expr.call binary "=="(%13, %14) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("index-factor.mlir":648:1)
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_3]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %16 = mpir_expr.call binary "||"(%11, %15) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("index-factor.mlir":650:1)
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "||"(%[[CALL_10]], %[[CALL_12]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean> loc("index-factor.mlir":652:1)
// CHECK:             mpir_index.assume %[[CALL_13]] : <Boolean>
  } loc("index-factor.mlir":654:1)
// CHECK:           }
  mpir_index.retrieve {
// CHECK:           mpir_index.retrieve {
    %0 = mpir_index.postings 0, 13 : i64 loc("index-factor.mlir":658:1)
    %1 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":659:1)
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
    %2 = mpir_index.intersect %0, %1 loc("index-factor.mlir":661:1)
    %3 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":662:1)
    %4 = mpir_index.postings 0, 1 : i64 loc("index-factor.mlir":663:1)
    %5 = mpir_index.intersect %3, %4 loc("index-factor.mlir":664:1)
    %6 = mpir_index.union %2, %5 loc("index-factor.mlir":665:1)
    mpir_index.result %6 loc("index-factor.mlir":666:1)
// CHECK:             mpir_index.result %[[POSTINGS_0]]
  } loc("index-factor.mlir":668:1)
// CHECK:           }
} loc("index-factor.mlir":670:1)
// CHECK:         }
