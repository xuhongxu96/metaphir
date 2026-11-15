// RUN: %metaphir-opt --split-input-file --mpir-index-retrieval %s | FileCheck %s
// mpir-index-retrieval adds the lookup to each query: the union over the
// possible variants of the intersection of the posting lists of their
// coarse features (instructions, edges, siblings, globals).

// One variant: the intersection of its lists.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.global "llvm.ctlz.i32" : <Value>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.type.int 1 : <Type>
  %6 = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%2, %3, %4, %i_b, %5, %6) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul>
    mpir_index.has_instruction <call>
    mpir_index.has_edge <mul> -> <add>
    mpir_index.has_edge <call> -> <mul>
    mpir_index.has_sibling <add>, <mul>
    mpir_index.has_global "llvm.ctlz.i32"
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.has_fact 2, <call>, 4, 128
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.ctlz.i32" : <Value>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_2]], %[[GLOBAL_0]], %[[TYPE_3]], %[[INST_1]], %[[TYPE_4]], %[[INT_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_edge <mul> -> <add>
// CHECK:             mpir_index.has_edge <call> -> <mul>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_global "llvm.ctlz.i32"
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.has_fact 2, <call>, 4, 128
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
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
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    %i_r = mpir.inst <add> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <sub> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <mul> (%2, %1, %2, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <add>
    mpir_index.has_sibling <add>, <mul>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
  mpir_index.variant {
    mpir_index.has_instruction <sub>
    mpir_index.has_instruction <mul>
    mpir_index.has_edge <mul> -> <sub>
    mpir_index.has_sibling <sub>, <mul>
    mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_edge <mul> -> <add>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_edge <mul> -> <sub>
// CHECK:             mpir_index.has_sibling <sub>, <mul>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
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
  %self = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "sub" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "&&"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
}
mpir_index.query {
  mpir_index.variant <impossible> {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 8]] {var_name = "self"} : <Instruction>
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "sub" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call call "opcode"(%8) anchor %9 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %11 = mpir_expr.str "mul" : <String>
    %12 = mpir_index.node 0 : <Instruction>
    %13 = mpir_expr.call binary "=="(%10, %11) anchor %12 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %14 = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call binary "&&"(%6, %13) anchor %14 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant <impossible> {
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
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[UNION_0:.*]] = mpir_index.union
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }

// -----

// Features from constraints are read too.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %4 = mpir_expr.str "llvm.smax" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %7 = mpir_expr.str "llvm.umin" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%5, %8) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_global "llvm.smax" {derived}
    mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean>
  }
  mpir_index.variant {
    mpir_index.has_global "llvm.umin" {derived}
    mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.smax" : <String>
    %3 = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %6 = mpir_expr.str "llvm.umin" : <String>
    %7 = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call binary "=="(%5, %6) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "||"(%4, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[VAR_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.umin" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.smax" {derived}
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
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.umin" {derived}
// CHECK:             mpir_index.has_instruction <call>
// CHECK:             mpir_index.has_shape <call>, 0, 0, 32
// CHECK:             mpir_index.typing <call> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 48, 1]] {var_name = "id"} : <IntrinsicID>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "llvm.umin" : <String>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[STR_3]]) anchor %[[NODE_4]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_4]]) anchor %[[NODE_5]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_5]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
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
