// RUN: %metaphir-opt --split-input-file --mpir-index-structuralize %s | FileCheck %s
// mpir-index-structuralize requires, as features the posting lists have,
// what a variant's constraints say of its instructions: the opcode of a
// value, the intrinsic a call calls. A disjunction splits the variant; a
// contradiction makes it impossible.

// An intrinsic named by a constraint on '@llvm.?id'.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %2 = mpir.type.int 1 : <Type>
  %3 = mpir.int 0 : ui1 : <Value>
  %i_c = mpir.inst <call> (%0, %id, %1, %x, %2, %3) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %5 = mpir_expr.str "llvm.ctlz" : <String>
  %6 = mpir_expr.call binary "=="(%4, %5) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %6 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.has_fact 0, <call>, 4, 128
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 1, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %1 = mpir_expr.read %0 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %2 = mpir_expr.str "llvm.ctlz" : <String>
    %3 = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%1, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %4 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "id" : <IntrinsicID>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_2]], %[[INT_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.ctlz" : <String>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.ctlz" {derived}
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
// CHECK:         }

// -----

// ...on either side of '==', and through intrinsic() of the call.
mpir.pattern {
  %call = mpir.var "call" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %id = mpir.var "id" : <IntrinsicID>
  %1 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %2 = mpir.type.int 32 : <Type>
  %y = mpir.var "y" : <Operand>
  %i_c = mpir.inst <call> capture %call (%0, %id, %1, %x, %2, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %3 = mpir_expr.str "llvm.smax" : <String>
  %4 = mpir_expr.read %id : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 : <Boolean>
  %6 = mpir_expr.read %call : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "intrinsic"(%6) anchor %i_c : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %8 = mpir_expr.str "llvm.smax" : <String>
  %9 = mpir_expr.call binary "=="(%7, %8) anchor %i_c : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <call>
    mpir_index.has_shape <call>, 0, 0, 32
    mpir_index.typing <call> <present = 0, absent = 0, operand_types = [[1, 32, 0], [], [1, 32, 0], [1, 32, 0]], value_operand = [false, true, true, true]>
    %0 = mpir_expr.str "llvm.smax" : <String>
    %1 = mpir_index.sites [[0, 48, 1]] {var_name = "id"} : <IntrinsicID>
    %2 = mpir_expr.read %1 : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
    %3 = mpir_index.node 0 : <Instruction>
    %4 = mpir_expr.call binary "=="(%0, %2) anchor %3 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %4 : <Boolean>
    %5 = mpir_index.sites [[0, 48, 8]] {var_name = "call"} : <Instruction>
    %6 = mpir_expr.read %5 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %7 = mpir_index.node 0 : <Instruction>
    %8 = mpir_expr.call call "intrinsic"(%6) anchor %7 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %9 = mpir_expr.str "llvm.smax" : <String>
    %10 = mpir_index.node 0 : <Instruction>
    %11 = mpir_expr.call binary "=="(%8, %9) anchor %10 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %11 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "call" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "id" : <IntrinsicID>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <call> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_2]], %[[TYPE_2]], %[[VAR_3]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<IntrinsicID>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<IntrinsicID>) -> !mpir.sort<String>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[STR_0]], %[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "intrinsic"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "llvm.smax" : <String>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_global "llvm.smax" {derived}
// CHECK:             mpir_index.has_global "llvm.smax" {derived}
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
// CHECK:         }

// -----

// A disjunction of intrinsics: a variant each.
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
// CHECK:         }

// -----

// The opcode of an operand: the instruction it must be.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "opcode"(%1) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %3 = mpir_expr.str "mul" : <String>
  %4 = mpir_expr.call binary "=="(%2, %3) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
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
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "mul" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> {derived}
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
// CHECK:         }

// -----

// Two disjunctions multiply; a conjunction inside one adds.
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
  %7 = mpir_expr.str "shl" : <String>
  %8 = mpir_expr.call binary "=="(%6, %7) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %9 = mpir_expr.call binary "||"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
  %10 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "opcode"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "sub" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %15 = mpir_expr.call call "opcode"(%14) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %16 = mpir_expr.str "mul" : <String>
  %17 = mpir_expr.call binary "=="(%15, %16) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.call binary "&&"(%13, %17) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %19 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %20 = mpir_expr.call call "opcode"(%19) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %21 = mpir_expr.str "xor" : <String>
  %22 = mpir_expr.call binary "=="(%20, %21) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %23 = mpir_expr.call binary "||"(%18, %22) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %23 : <Boolean>
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
    %10 = mpir_expr.str "shl" : <String>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %14 : <Boolean>
    %15 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %16 = mpir_expr.read %15 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %17 = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call call "opcode"(%16) anchor %17 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %19 = mpir_expr.str "sub" : <String>
    %20 = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call binary "=="(%18, %19) anchor %20 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %22 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %23 = mpir_index.node 0 : <Instruction>
    %24 = mpir_expr.call call "opcode"(%22) anchor %23 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %25 = mpir_expr.str "mul" : <String>
    %26 = mpir_index.node 0 : <Instruction>
    %27 = mpir_expr.call binary "=="(%24, %25) anchor %26 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %28 = mpir_index.node 0 : <Instruction>
    %29 = mpir_expr.call binary "&&"(%21, %27) anchor %28 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %30 = mpir_expr.read %15 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %31 = mpir_index.node 0 : <Instruction>
    %32 = mpir_expr.call call "opcode"(%30) anchor %31 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %33 = mpir_expr.str "xor" : <String>
    %34 = mpir_index.node 0 : <Instruction>
    %35 = mpir_expr.call binary "=="(%32, %33) anchor %34 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %36 = mpir_index.node 0 : <Instruction>
    %37 = mpir_expr.call binary "||"(%29, %35) anchor %36 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %37 : <Boolean>
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
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "sub" : <String>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "&&"(%[[CALL_6]], %[[CALL_8]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "xor" : <String>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call binary "||"(%[[CALL_9]], %[[CALL_11]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_12]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <sub> {derived}
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
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <xor> {derived}
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
// CHECK:             mpir_index.has_instruction <shl> {derived}
// CHECK:             mpir_index.has_instruction <sub> {derived}
// CHECK:             mpir_index.has_instruction <mul> {derived}
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
// CHECK:             mpir_index.has_instruction <shl> {derived}
// CHECK:             mpir_index.has_instruction <xor> {derived}
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
// CHECK:         }

// -----

// The opcode of a value an instruction matcher matches: another opcode
// cannot hold, and the same one adds nothing new.
mpir.pattern {
  %self = mpir.var "self" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> capture %self (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %3 = mpir_expr.call call "opcode"(%2) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %4 = mpir_expr.str "sub" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_b : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 : <Boolean>
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
    %0 = mpir_index.sites [[1, 5, 1], [0, 1, 8]] {var_name = "self"} : <Instruction>
    %1 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %2 = mpir_index.node 1 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "sub" : <String>
    %5 = mpir_index.node 1 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %6 : <Boolean>
  }
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "self" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_2]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant <impossible> {
// CHECK:             mpir_index.has_instruction <add>
// CHECK:             mpir_index.has_instruction <mul>
// CHECK:             mpir_index.has_edge <mul> -> <add>
// CHECK:             mpir_index.has_sibling <add>, <mul>
// CHECK:             mpir_index.has_shape <add>, 0, 0, 32
// CHECK:             mpir_index.has_shape <mul>, 0, 0, 32
// CHECK:             mpir_index.typing <add> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             mpir_index.typing <mul> <present = 0, absent = 0, operand_types = {{\[\[}}1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
// CHECK:             %[[SITES_0:.*]] = mpir_index.sites {{\[\[}}1, 5, 1], [0, 1, 8]] {var_name = "self"} : <Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_0:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[NODE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_0:.*]] = mpir_expr.str "sub" : <String>
// CHECK:             %[[NODE_1:.*]] = mpir_index.node 1 : <Instruction>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[NODE_1]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_1]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// ...one side of a disjunction that cannot hold leaves the other; of a
// conjunction, nothing.
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
  %9 = mpir_expr.call binary "||"(%4, %8) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %9 : <Boolean>
  %10 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %11 = mpir_expr.call call "opcode"(%10) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %12 = mpir_expr.str "mul" : <String>
  %13 = mpir_expr.call binary "=="(%11, %12) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %14 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %15 = mpir_expr.call call "opcode"(%14) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %16 = mpir_expr.str "sub" : <String>
  %17 = mpir_expr.call binary "=="(%15, %16) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %18 = mpir_expr.call binary "||"(%13, %17) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %18 : <Boolean>
  %19 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %20 = mpir_expr.call call "opcode"(%19) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %21 = mpir_expr.str "add" : <String>
  %22 = mpir_expr.call binary "=="(%20, %21) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %23 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %24 = mpir_expr.call call "opcode"(%23) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %25 = mpir_expr.str "mul" : <String>
  %26 = mpir_expr.call binary "=="(%24, %25) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %27 = mpir_expr.call binary "&&"(%22, %26) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %27 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
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
    %15 = mpir_expr.call binary "||"(%6, %13) anchor %14 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %15 : <Boolean>
    %16 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %17 = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call call "opcode"(%16) anchor %17 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %19 = mpir_expr.str "mul" : <String>
    %20 = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call binary "=="(%18, %19) anchor %20 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %22 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %23 = mpir_index.node 0 : <Instruction>
    %24 = mpir_expr.call call "opcode"(%22) anchor %23 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %25 = mpir_expr.str "sub" : <String>
    %26 = mpir_index.node 0 : <Instruction>
    %27 = mpir_expr.call binary "=="(%24, %25) anchor %26 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %28 = mpir_index.node 0 : <Instruction>
    %29 = mpir_expr.call binary "||"(%21, %27) anchor %28 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %29 : <Boolean>
    %30 = mpir_expr.read %0 : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %31 = mpir_index.node 0 : <Instruction>
    %32 = mpir_expr.call call "opcode"(%30) anchor %31 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %33 = mpir_expr.str "add" : <String>
    %34 = mpir_index.node 0 : <Instruction>
    %35 = mpir_expr.call binary "=="(%32, %33) anchor %34 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %36 = mpir_expr.read %7 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %37 = mpir_index.node 0 : <Instruction>
    %38 = mpir_expr.call call "opcode"(%36) anchor %37 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %39 = mpir_expr.str "mul" : <String>
    %40 = mpir_index.node 0 : <Instruction>
    %41 = mpir_expr.call binary "=="(%38, %39) anchor %40 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %42 = mpir_index.node 0 : <Instruction>
    %43 = mpir_expr.call binary "&&"(%35, %41) anchor %42 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %43 : <Boolean>
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
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "sub" : <String>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "=="(%[[CALL_7]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "||"(%[[CALL_6]], %[[CALL_8]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_9]] : <Boolean>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[CALL_10]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call call "opcode"(%[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_5:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call binary "=="(%[[CALL_12]], %[[STR_5]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call binary "&&"(%[[CALL_11]], %[[CALL_13]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_14]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <mul> {derived}
// CHECK:             mpir_index.has_instruction <add> {derived}
// CHECK:             mpir_index.has_instruction <mul> {derived}
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
// CHECK:         }

// -----

// ...and a conjunction with it makes the variant impossible.
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
  mpir_index.variant {
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
// CHECK:         }

// -----

// What says nothing the index has: other operators, other operands, a
// disjunction with such a side, 'br' (two kinds of instruction), names
// that are no opcode, intrinsic() of what is no call.
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
  %7 = mpir_expr.call binary "||"(%2, %6) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean>
  %8 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %9 = mpir_expr.call call "opcode"(%8) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %10 = mpir_expr.str "br" : <String>
  %11 = mpir_expr.call binary "=="(%9, %10) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %12 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %13 = mpir_expr.call call "opcode"(%12) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %14 = mpir_expr.str "nothing" : <String>
  %15 = mpir_expr.call binary "=="(%13, %14) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %16 = mpir_expr.call binary "||"(%11, %15) anchor %i_a : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %16 : <Boolean>
  %17 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %18 = mpir_expr.call call "opcode"(%17) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %19 = mpir_expr.str "mul" : <String>
  %20 = mpir_expr.call binary "!="(%18, %19) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %20 : <Boolean>
  %21 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %22 = mpir_expr.call call "intrinsic"(%21) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %23 = mpir_expr.str "llvm.ctlz" : <String>
  %24 = mpir_expr.call binary "=="(%22, %23) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %24 : <Boolean>
  %25 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %26 = mpir_expr.call call "bitWidth"(%25) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
  %27 = mpir_expr.int 32 : ui64 : <Integer>
  %28 = mpir_expr.call binary "=="(%26, %27) anchor %i_a : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %28 : <Boolean>
  %29 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %30 = mpir_expr.call call "opcode"(%29) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %31 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %32 = mpir_expr.call call "opcode"(%31) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %33 = mpir_expr.call binary "=="(%30, %32) anchor %i_a : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %33 : <Boolean>
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
    %12 = mpir_expr.call binary "||"(%3, %10) anchor %11 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %12 : <Boolean>
    %13 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %14 = mpir_index.node 0 : <Instruction>
    %15 = mpir_expr.call call "opcode"(%13) anchor %14 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %16 = mpir_expr.str "br" : <String>
    %17 = mpir_index.node 0 : <Instruction>
    %18 = mpir_expr.call binary "=="(%15, %16) anchor %17 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %19 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %20 = mpir_index.node 0 : <Instruction>
    %21 = mpir_expr.call call "opcode"(%19) anchor %20 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %22 = mpir_expr.str "nothing" : <String>
    %23 = mpir_index.node 0 : <Instruction>
    %24 = mpir_expr.call binary "=="(%21, %22) anchor %23 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %25 = mpir_index.node 0 : <Instruction>
    %26 = mpir_expr.call binary "||"(%18, %24) anchor %25 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %26 : <Boolean>
    %27 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %28 = mpir_index.node 0 : <Instruction>
    %29 = mpir_expr.call call "opcode"(%27) anchor %28 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %30 = mpir_expr.str "mul" : <String>
    %31 = mpir_index.node 0 : <Instruction>
    %32 = mpir_expr.call binary "!="(%29, %30) anchor %31 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %32 : <Boolean>
    %33 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %34 = mpir_index.node 0 : <Instruction>
    %35 = mpir_expr.call call "intrinsic"(%33) anchor %34 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %36 = mpir_expr.str "llvm.ctlz" : <String>
    %37 = mpir_index.node 0 : <Instruction>
    %38 = mpir_expr.call binary "=="(%35, %36) anchor %37 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %38 : <Boolean>
    %39 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %40 = mpir_index.node 0 : <Instruction>
    %41 = mpir_expr.call call "bitWidth"(%39) anchor %40 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
    %42 = mpir_expr.int 32 : ui64 : <Integer>
    %43 = mpir_index.node 0 : <Instruction>
    %44 = mpir_expr.call binary "=="(%41, %42) anchor %43 : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %44 : <Boolean>
    %45 = mpir_expr.read %4 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %46 = mpir_index.node 0 : <Instruction>
    %47 = mpir_expr.call call "opcode"(%45) anchor %46 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %48 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %49 = mpir_index.node 0 : <Instruction>
    %50 = mpir_expr.call call "opcode"(%48) anchor %49 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %51 = mpir_index.node 0 : <Instruction>
    %52 = mpir_expr.call binary "=="(%47, %50) anchor %51 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %52 : <Boolean>
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
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_2]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "br" : <String>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_2:.*]] = mpir_expr.str "nothing" : <String>
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "=="(%[[CALL_6]], %[[STR_2]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_7]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_8]] : <Boolean>
// CHECK:           %[[READ_4:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_9]], %[[STR_3]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
// CHECK:           %[[READ_5:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call call "intrinsic"(%[[READ_5]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_4:.*]] = mpir_expr.str "llvm.ctlz" : <String>
// CHECK:           %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_4]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_12]] : <Boolean>
// CHECK:           %[[READ_6:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_13:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:           %[[CALL_14:.*]] = mpir_expr.call binary "=="(%[[CALL_13]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_14]] : <Boolean>
// CHECK:           %[[READ_7:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[READ_8:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_16:.*]] = mpir_expr.call call "opcode"(%[[READ_8]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[CALL_16]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_17]] : <Boolean>
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
// CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_2]]) anchor %[[NODE_3]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_3]] : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_4:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "opcode"(%[[READ_2]]) anchor %[[NODE_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_1:.*]] = mpir_expr.str "br" : <String>
// CHECK:             %[[NODE_5:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_5:.*]] = mpir_expr.call binary "=="(%[[CALL_4]], %[[STR_1]]) anchor %[[NODE_5]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_6:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_6:.*]] = mpir_expr.call call "opcode"(%[[READ_3]]) anchor %[[NODE_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_2:.*]] = mpir_expr.str "nothing" : <String>
// CHECK:             %[[NODE_7:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_7:.*]] = mpir_expr.call binary "=="(%[[CALL_6]], %[[STR_2]]) anchor %[[NODE_7]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             %[[NODE_8:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_8:.*]] = mpir_expr.call binary "||"(%[[CALL_5]], %[[CALL_7]]) anchor %[[NODE_8]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_8]] : <Boolean>
// CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_9:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_9:.*]] = mpir_expr.call call "opcode"(%[[READ_4]]) anchor %[[NODE_9]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_3:.*]] = mpir_expr.str "mul" : <String>
// CHECK:             %[[NODE_10:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_10:.*]] = mpir_expr.call binary "!="(%[[CALL_9]], %[[STR_3]]) anchor %[[NODE_10]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_10]] : <Boolean>
// CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_11:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_11:.*]] = mpir_expr.call call "intrinsic"(%[[READ_5]]) anchor %[[NODE_11]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[STR_4:.*]] = mpir_expr.str "llvm.ctlz" : <String>
// CHECK:             %[[NODE_12:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_12:.*]] = mpir_expr.call binary "=="(%[[CALL_11]], %[[STR_4]]) anchor %[[NODE_12]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_12]] : <Boolean>
// CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_13:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_13:.*]] = mpir_expr.call call "bitWidth"(%[[READ_6]]) anchor %[[NODE_13]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[NODE_14:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_14:.*]] = mpir_expr.call binary "=="(%[[CALL_13]], %[[INT_0]]) anchor %[[NODE_14]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_14]] : <Boolean>
// CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[SITES_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_15:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_15:.*]] = mpir_expr.call call "opcode"(%[[READ_7]]) anchor %[[NODE_15]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[SITES_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[NODE_16:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_16:.*]] = mpir_expr.call call "opcode"(%[[READ_8]]) anchor %[[NODE_16]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:             %[[NODE_17:.*]] = mpir_index.node 0 : <Instruction>
// CHECK:             %[[CALL_17:.*]] = mpir_expr.call binary "=="(%[[CALL_15]], %[[CALL_16]]) anchor %[[NODE_17]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir_index.assume %[[CALL_17]] : <Boolean>
// CHECK:           }
// CHECK:         }

// -----

// Each variant of a matcher's branches is split on its own.
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
  %2 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %3 = mpir_expr.call call "opcode"(%2) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %4 = mpir_expr.str "mul" : <String>
  %5 = mpir_expr.call binary "=="(%3, %4) anchor %1 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %7 = mpir_expr.call call "opcode"(%6) anchor %1 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
  %8 = mpir_expr.str "shl" : <String>
  %9 = mpir_expr.call binary "=="(%7, %8) anchor %1 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %10 = mpir_expr.call binary "||"(%5, %9) anchor %1 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %10 : <Boolean>
}
mpir_index.query {
  mpir_index.variant {
    mpir_index.has_instruction <add>
    mpir_index.has_shape <add>, 0, 0, 32
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 1, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "mul" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_index.node 0 : <Instruction>
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %14 : <Boolean>
  }
  mpir_index.variant {
    mpir_index.has_instruction <sub>
    mpir_index.has_shape <sub>, 0, 0, 32
    mpir_index.typing <sub> <present = 0, absent = 0, operand_types = [[1, 32, 0], [1, 32, 0]], value_operand = [true, true]>
    %0 = mpir_index.sites [[0, 3, 2]] {var_name = "y"} : <Operand>
    %1 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %2 = mpir_index.node 0 : <Instruction>
    %3 = mpir_expr.call call "opcode"(%1) anchor %2 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %4 = mpir_expr.str "mul" : <String>
    %5 = mpir_index.node 0 : <Instruction>
    %6 = mpir_expr.call binary "=="(%3, %4) anchor %5 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %7 = mpir_expr.read %0 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %8 = mpir_index.node 0 : <Instruction>
    %9 = mpir_expr.call call "opcode"(%7) anchor %8 : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
    %10 = mpir_expr.str "shl" : <String>
    %11 = mpir_index.node 0 : <Instruction>
    %12 = mpir_expr.call binary "=="(%9, %10) anchor %11 : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    %13 = mpir_index.node 0 : <Instruction>
    %14 = mpir_expr.call binary "||"(%6, %12) anchor %13 : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir_index.assume %14 : <Boolean>
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
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "mul" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "opcode"(%[[READ_1]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "shl" : <String>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) anchor %[[ALT_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) anchor %[[ALT_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir_index.query {
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> {derived}
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
// CHECK:             mpir_index.has_instruction <shl> {derived}
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
// CHECK:           mpir_index.variant {
// CHECK:             mpir_index.has_instruction <mul> {derived}
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
// CHECK:             mpir_index.has_instruction <shl> {derived}
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
// CHECK:         }
