// RUN: %metaphir-opt --split-input-file --mpir-index-structuralize %s | FileCheck %s
// Equalities and calls the index cannot read as features: an operator other
// than opcode() or intrinsic() on a value, a comparison with a number or a
// boolean, and comparisons of constants. Each holds nothing the index looks up.

// An operator other than opcode() or intrinsic() on a value.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "bitWidth"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %3 = mpir_expr.str "32" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "bitWidth"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
    %4 = mpir_expr.str "32" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "32" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "bitWidth"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "32" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<Integer>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// A comparison with a number, a boolean, or another value.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 5 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean>
  %4 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %5 = mpir_expr.call call "isZero"(%4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.bool true : <Boolean>
  %7 = mpir_expr.call binary "=="(%5, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean>
  %8 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %10 = mpir_expr.call binary "=="(%8, %9) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %10 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_expr.int 5 : ui64 : <Integer>
    %3 = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %4 : <Boolean>
    %5 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %6 = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call call "isZero"(%5) anchor %6 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %8 = mpir_expr.bool true : <Boolean>
    %9 = mpir_index.node 0 : <Instruction>
    %10 = mpir_expr.call binary "=="(%7, %8) anchor %9 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %10 : <Boolean>
    %11 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand>
    %12 = mpir_expr.read %11 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %13 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call binary "=="(%12, %13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 5 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[BOOL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}0, 1, 2]] {var_name = "y"} : <Operand>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 5 : ui64 : <Integer>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] : <Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[NODE_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:             %[[NODE_2:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[BOOL_0]]) anchor %[[NODE_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_2]] : <Boolean>
// CHECK:             %[[SITES_1:.*]] = mpir_index.sites {{\[\[}}0, 1, 1]] {var_name = "x"} : <Operand>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_3:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[READ_3]]) anchor %[[NODE_3]] : (!mpir.sort<Value>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// Comparisons of constants.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.str "add" : <String>
  %2 = mpir_expr.str "add" : <String>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean>
  %4 = mpir_expr.str "sub" : <String>
  %5 = mpir_expr.str "mul" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_expr.str "add" : <String>
    %1 = mpir_expr.str "add" : <String>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call binary "=="(%0, %1) anchor %2 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %3 {closed} : <Boolean>
    %4 = mpir_expr.str "sub" : <String>
    %5 = mpir_expr.str "mul" : <String>
    %6 = mpir_index.node 0 : <Instruction>
    %7 = mpir_expr.call binary "=="(%4, %5) anchor %6 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %7 {closed} : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[STR_2]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "add" : <String>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[STR_1]]) anchor %[[NODE_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_0]] {closed} : <Boolean>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[STR_2]], %[[STR_3]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] {closed} : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// Operators on a value that is not a site.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "mul" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.call call "opcode"(%5) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %7 = mpir_expr.str "mul" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "&&"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
  %10 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "intrinsic"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "llvm.umax" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %13 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 1]] {var_name = "x"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "mul" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_index.node 0 : <Instruction>
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %10 = mpir_expr.str "mul" : <String>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "&&"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %14 : <Boolean>
    %15 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %16 = mpir_index.node 0 : <Instruction>
    %17 = mpir_expr.call call "intrinsic"(%15) anchor %16 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %18 = mpir_expr.str "llvm.umax" : <String>
    %19 = mpir_index.node 0 : <Instruction>
    %20 = mpir_expr.call binary "=="(%17, %18) anchor %19 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %20 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "intrinsic"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "llvm.umax" : <String>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
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
// CHECK:         }
