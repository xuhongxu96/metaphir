// RUN: %metaphir-opt --split-input-file --mpir-index-structuralize %s | FileCheck %s
// A constraint that is a meta variable, and an operator read on a variable that
// is no value of the pattern: a count or a flag, which the index cannot tell
// the sites of.

// A boolean variable as a constraint.
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.int 1 : ui1 : <Value>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.int 2 : ui2 : <Value>
  %i_s = mpir.inst <select> (%0, %c, %1, %2, %3, %4) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %5 = mpir_expr.read %c : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.require %5 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <select>
    mpir_index.has_fact 0, <select>, 2, 129
    mpir_index.has_fact 0, <select>, 4, 130
    mpir_index.typing <select> <present = 0, absent = 0, operand_types = [[1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
    %0 = mpir_index.sites [[0, 46, 1]] {var_name = "c"} : <Boolean>
    %1 = mpir_expr.read %0 : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
    mpir_index.assume %1 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "c" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 2 : ui2 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[INT_0]], %[[TYPE_2]], %[[INT_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[READ_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <select>
// CHECK:             mpir_index.has_fact 0, <select>, 2, 129
// CHECK:             mpir_index.has_fact 0, <select>, 4, 130
// CHECK:             mpir_index.typing <select> <present = 0, absent = 0, operand_types = {{\[\[}}1, 1, 0], [1, 32, 0], [1, 32, 0]], value_operand = [true, true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 46, 1]] {var_name = "c"} : <Boolean>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[READ_0]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// An operator on a count, compared with a string.
mpir.pattern {
  %n = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %n : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
  %2 = mpir_expr.call call "bitWidth"(%1) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %3 = mpir_expr.str "32" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[2, 0, 0], [2, 0, 0]], value_operand = [true, true]>
    %0 = mpir_index.type_var 0 {var_name = "n"} : <Nat>
    %1 = mpir_expr.read %0 : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "bitWidth"(%1) anchor %2 : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
    %4 = mpir_expr.str "32" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "32" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}2, 0, 0], [2, 0, 0]], value_operand = [true, true]>
// CHECK:             %[[TYPE_VAR_0:.*]] = mpir_index.type_var 0 {var_name = "n"} : <Nat>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[TYPE_VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "32" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
// CHECK:         }
