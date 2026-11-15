// RUN: %metaphir-opt --split-input-file --mpir-index-factor %s | FileCheck %s
// mpir-index-factor reads a list every variant needs once: (A & B) | (A & C)
// becomes A & (B | C), and repeated lists and sets are merged.

// One variant: nothing to factor.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
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
  mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.postings 0, 5 : i64
    %2 = mpir_index.postings 1, 321 : i64
    %3 = mpir_index.postings 2, 69 : i64
    %4 = mpir_index.intersect %0, %1, %2, %3
    mpir_index.result %4
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
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
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 1, 321 : i64
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 2, 69 : i64
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_1]], %[[POSTINGS_2]], %[[POSTINGS_3]]
// CHECK:             mpir_index.result %[[INTERSECT_0]]
// CHECK:           }
// CHECK:         }

// -----

// Two variants with lists in common.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_m = mpir.inst <mul> (%0, %x, %0, %y) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.alt {
    %i_r = mpir.inst <add> (%1, %i_m, %1, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <sub> (%1, %i_m, %1, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  } attributes {result_name = "r"} : <Instruction>
  %3 = mpir.type.int 32 : <Type>
  %i_s = mpir.inst <shl> (%3, %2, %3, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_instruction <mul>
    mpir_index.has_instruction <shl>
    mpir_index.has_edge <add> -> <mul>
    mpir_index.has_edge <shl> -> <add>
    mpir_index.has_sibling <add>, <mul>
    mpir_index.has_sibling <add>, <shl>
    mpir_index.has_sibling <mul>, <shl>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <shl>, 0, 0, 32
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <shl> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
  mpir_index.variant {
    mpir_index.has_instruction <sub>
    mpir_index.has_instruction <mul>
    mpir_index.has_instruction <shl>
    mpir_index.has_edge <sub> -> <mul>
    mpir_index.has_edge <shl> -> <sub>
    mpir_index.has_sibling <sub>, <mul>
    mpir_index.has_sibling <sub>, <shl>
    mpir_index.has_sibling <mul>, <shl>
    mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.has_shape <mul>, 0, 0, 32
    mpir_index.has_shape <shl>, 0, 0, 32
    mpir_index.typing <mul> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    mpir_index.typing <shl> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
  mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.postings 0, 5 : i64
    %2 = mpir_index.postings 0, 13 : i64
    %3 = mpir_index.postings 1, 69 : i64
    %4 = mpir_index.postings 1, 833 : i64
    %5 = mpir_index.postings 2, 69 : i64
    %6 = mpir_index.postings 2, 77 : i64
    %7 = mpir_index.postings 2, 333 : i64
    %8 = mpir_index.intersect %0, %1, %2, %3, %4, %5, %6, %7
    %9 = mpir_index.postings 0, 3 : i64
    %10 = mpir_index.postings 0, 5 : i64
    %11 = mpir_index.postings 0, 13 : i64
    %12 = mpir_index.postings 1, 197 : i64
    %13 = mpir_index.postings 1, 835 : i64
    %14 = mpir_index.postings 2, 197 : i64
    %15 = mpir_index.postings 2, 205 : i64
    %16 = mpir_index.postings 2, 333 : i64
    %17 = mpir_index.intersect %9, %10, %11, %12, %13, %14, %15, %16
    %18 = mpir_index.union %8, %17
    mpir_index.result %18
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <shl> (%[[TYPE_2]], %[[ALT_0]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <shl>
// CHECK:             mpir_index.has_edge <add> -> <mul>
// CHECK:             mpir_index.has_edge <shl> -> <add>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_sibling <add>, <shl>
// CHECK:             mpir_index.has_sibling <mul>, <shl>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_shape <shl>, 0, 0, 32
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <shl> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_instruction <shl>
// CHECK:             mpir_index.has_edge <sub> -> <mul>
// CHECK:             mpir_index.has_edge <shl> -> <sub>
// CHECK:             mpir_index.has_sibling <sub>, <mul>
// CHECK:             mpir_index.has_sibling <sub>, <shl>
// CHECK:             mpir_index.has_sibling <mul>, <shl>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.has_shape <shl>, 0, 0, 32
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <shl> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 5 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 0, 13 : i64
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 1, 69 : i64
// CHECK:             %[[POSTINGS_4:.*]] = mpir_index.postings 1, 833 : i64
// CHECK:             %[[POSTINGS_5:.*]] = mpir_index.postings 2, 69 : i64
// CHECK:             %[[POSTINGS_6:.*]] = mpir_index.postings 2, 77 : i64
// CHECK:             %[[POSTINGS_7:.*]] = mpir_index.postings 2, 333 : i64
// CHECK:             %[[POSTINGS_8:.*]] = mpir_index.postings 0, 3 : i64
// CHECK:             %[[POSTINGS_9:.*]] = mpir_index.postings 1, 197 : i64
// CHECK:             %[[POSTINGS_10:.*]] = mpir_index.postings 1, 835 : i64
// CHECK:             %[[POSTINGS_11:.*]] = mpir_index.postings 2, 197 : i64
// CHECK:             %[[POSTINGS_12:.*]] = mpir_index.postings 2, 205 : i64
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_0]], %[[POSTINGS_3]], %[[POSTINGS_4]], %[[POSTINGS_5]], %[[POSTINGS_6]]
// CHECK:             %[[INTERSECT_1:.*]] = mpir_index.intersect %[[POSTINGS_8]], %[[POSTINGS_9]], %[[POSTINGS_10]], %[[POSTINGS_11]], %[[POSTINGS_12]]
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[INTERSECT_0]], %[[INTERSECT_1]]
// CHECK:             %[[INTERSECT_2:.*]] = mpir_index.intersect %[[POSTINGS_7]], %[[UNION_0]]
// CHECK:             %[[INTERSECT_3:.*]] = mpir_index.intersect %[[POSTINGS_2]], %[[INTERSECT_2]]
// CHECK:             %[[INTERSECT_4:.*]] = mpir_index.intersect %[[POSTINGS_1]], %[[INTERSECT_3]]
// CHECK:             mpir_index.result %[[INTERSECT_4]]
// CHECK:           }
// CHECK:         }

// -----

// Variants that differ in one list only.
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
  %10 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %11 = mpir_expr.str "llvm.umax" : <String>
  %12 = mpir_expr.call binary "=="(%10, %11) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %13 = mpir_expr.call binary "||"(%9, %12) anchor %i_c : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %13 : <Boolean>
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
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean>
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
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean>
  }
  mpir_index.variant {
    mpir_index.has_global "llvm.umax" {derived}
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
    %11 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %12 = mpir_expr.str "llvm.umax" : <String>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "=="(%11, %12) anchor %13 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %15 = mpir_index.node 0 : <Instruction>
    %16 = mpir_expr.call binary "||"(%10, %14) anchor %15 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean>
  }
  mpir_index.retrieve {
    %0 = mpir_index.postings 3, "llvm.smax"
    %1 = mpir_index.postings 0, 48 : i64
    %2 = mpir_index.intersect %0, %1
    %3 = mpir_index.postings 3, "llvm.umin"
    %4 = mpir_index.postings 0, 48 : i64
    %5 = mpir_index.intersect %3, %4
    %6 = mpir_index.postings 3, "llvm.umax"
    %7 = mpir_index.postings 0, 48 : i64
    %8 = mpir_index.intersect %6, %7
    %9 = mpir_index.union %2, %5, %8
    mpir_index.result %9
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
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
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
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[STR_2]]) anchor %[[NODE_3]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[NODE_4]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_4]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.umin" {derived}
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
// CHECK:             mpir_index.has_global "llvm.umax" {derived}
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
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 3, "llvm.smax"
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 48 : i64
// CHECK:             %[[POSTINGS_2:.*]] = mpir_index.postings 3, "llvm.umin"
// CHECK:             %[[POSTINGS_3:.*]] = mpir_index.postings 3, "llvm.umax"
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[POSTINGS_0]], %[[POSTINGS_2]], %[[POSTINGS_3]]
// CHECK:             %[[INTERSECT_0:.*]] = mpir_index.intersect %[[POSTINGS_1]], %[[UNION_0]]
// CHECK:             mpir_index.result %[[INTERSECT_0]]
// CHECK:           }
// CHECK:         }

// -----

// Variants with nothing in common.
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
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
  mpir_index.variant {
    mpir_index.has_instruction <sub>
    mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
  }
  mpir_index.retrieve {
    %0 = mpir_index.postings 0, 1 : i64
    %1 = mpir_index.intersect %0
    %2 = mpir_index.postings 0, 3 : i64
    %3 = mpir_index.intersect %2
    %4 = mpir_index.union %1, %3
    mpir_index.result %4
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
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <sub>
// CHECK:             mpir_index.has_shape <sub>, 0, 0, 32
// CHECK:             mpir_index.typing <sub> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             %[[POSTINGS_1:.*]] = mpir_index.postings 0, 3 : i64
// CHECK:             %[[UNION_0:.*]] = mpir_index.union %[[POSTINGS_0]], %[[POSTINGS_1]]
// CHECK:             mpir_index.result %[[UNION_0]]
// CHECK:           }
// CHECK:         }

// -----

// A variant whose lists are all common: the others add nothing.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "isZero"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.bool true : <Boolean>
  %4 = mpir_expr.call binary "||"(%2, %3) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean>
  %5 = mpir.type.int 32 : <Type>
  %6 = mpir.int 3 : ui2 : <Value>
  %7 = mpir.alt {
    mpir.yield %i_a : <Instruction>
  }, {
    %i_b = mpir.inst <mul> (%5, %i_a, %5, %6) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_b : <Instruction>
  } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "shl" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "opcode"(%12) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %14 = mpir_expr.str "add" : <String>
  %15 = mpir_expr.call binary "=="(%13, %14) anchor %7 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %16 = mpir_expr.call binary "||"(%11, %15) anchor %7 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %16 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <shl> {derived}
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "||"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_expr.call call "opcode"(%8) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String>
    %11 = mpir_expr.call binary "=="(%9, %10) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %12 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.call call "opcode"(%12) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %14 = mpir_expr.str "add" : <String>
    %15 = mpir_expr.call binary "=="(%13, %14) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %16 = mpir_expr.call binary "||"(%11, %15) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean>
  }
  mpir_index.variant {
    mpir_index.has_instruction <add> {derived}
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "isZero"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %4 = mpir_expr.bool true : <Boolean>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "||"(%3, %4) anchor %5 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
    %7 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %8 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %9 = mpir_expr.call call "opcode"(%8) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String>
    %11 = mpir_expr.call binary "=="(%9, %10) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %12 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.call call "opcode"(%12) : (!mpir.sort<Value>) -> !mpir.sort<String>
    %14 = mpir_expr.str "add" : <String>
    %15 = mpir_expr.call binary "=="(%13, %14) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
    %16 = mpir_expr.call binary "||"(%11, %15) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
    mpir_index.assume %16 : <Boolean>
  }
  mpir_index.retrieve {
    %0 = mpir_index.postings 0, 13 : i64
    %1 = mpir_index.postings 0, 1 : i64
    %2 = mpir_index.intersect %0, %1
    %3 = mpir_index.postings 0, 1 : i64
    %4 = mpir_index.postings 0, 1 : i64
    %5 = mpir_index.intersect %3, %4
    %6 = mpir_index.union %2, %5
    mpir_index.result %6
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "b"} : <Instruction>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "shl" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_0]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_5]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <shl> {derived}
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[BOOL_0]]) anchor %[[NODE_1]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_3]], %[[CALL_5]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_6]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add> {derived}
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_2:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[NODE_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_1:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[BOOL_1]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_8]] : <Boolean>
// CHECK:             %[[SITES_3:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "shl" : <String>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "=="(%[[CALL_9]], %[[STR_2]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) : (!mpir.sort<Value>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_3]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call binary "||"(%[[CALL_10]], %[[CALL_12]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_13]] : <Boolean>
// CHECK:           }
// CHECK:           mpir_index.retrieve {
// CHECK:             %[[POSTINGS_0:.*]] = mpir_index.postings 0, 1 : i64
// CHECK:             mpir_index.result %[[POSTINGS_0]]
// CHECK:           }
// CHECK:         }
