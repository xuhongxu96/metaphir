// RUN: %metaphir-opt --split-input-file --mpir-check-bindings %s | FileCheck %s
// mpir-check-bindings accepts the patterns in which every named meta variable
// is bound whichever way ':o' is matched, and changes nothing.

// A variable the instruction binds is also bound elsewhere.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    mpir.yield %x : <Operand>
  }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%2, %1, %2, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }

// -----

// A variable whose name starts with '_' need not be bound.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %_k = mpir.var "_k" : <Operand>
  %1 = mpir.alt {
    mpir.yield %x : <Operand>
  }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %_k) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "_k" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:         }

// -----

// Everything ':o' could leave out is bound by the operand: types, flag
// captures, blocks, aggregates and nested alternatives.
mpir.pattern {
  %bb = mpir.var "bb" : <BasicBlock>
  %w = mpir.var "w" : <Boolean>
  %n = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    %i_i = mpir.inst <add> block %bb flags(%w) (%0, %x, %0, %y) <result_name = "i", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_i : <Instruction>
  }, {
    %i_i = mpir.inst <add> block %bb flags(%w) (%0, %y, %0, %x) <result_name = "i", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_i : <Instruction>
  } attributes {commuted, result_name = "i"} : <Instruction>
  %self = mpir.var "self" : <Instruction>
  %2 = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean>
  %3 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %4 = mpir.type.seq vector 2 x %3 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %5 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %6 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %7 = mpir.aggregate vector(%5, %1, %6, %y) : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Value>
  %8 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %9 = mpir.type.seq vector 2 x %8 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand>
  %10 = mpir.alt {
    mpir.bind %self, %7 : <Instruction>, <Value>
    mpir.yield %7 : <Value>
  }, {
    %i_a = mpir.inst <select> capture %self block %bb (%2, %c, %4, %7, %9, %v) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {or_self_of = "select", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %11 = mpir.type.int 1 : <Type>
  %12 = mpir.global "use" : <Value>
  %13 = mpir.type.int 1 : <Type>
  %14 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %15 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %16 = mpir.type.seq vector 2 x %15 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %17 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %18 = mpir.type.seq vector 2 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %i_u = mpir.inst <call> block %bb (%11, %12, %13, %c, %14, %1, %16, %v, %18, %10) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %19 = mpir_expr.read %w : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.require %19 : <Boolean>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "bb" : <BasicBlock>
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Boolean>
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_4:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[VAR_3]], %[[TYPE_0]], %[[VAR_4]]) <result_name = "i", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[VAR_4]], %[[TYPE_0]], %[[VAR_3]]) <result_name = "i", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "i"} : <Instruction>
// CHECK:           %[[VAR_5:.*]] = mpir.var "self" : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "c" : <Boolean>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.seq vector 2 x %[[TYPE_2]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_4]], %[[ALT_0]], %[[TYPE_5]], %[[VAR_4]]) : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.seq vector 2 x %[[TYPE_6]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_7:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             mpir.bind %[[VAR_5]], %[[AGGREGATE_0]] : <Instruction>, <Value>
// CHECK:             mpir.yield %[[AGGREGATE_0]] : <Value>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <select> capture %[[VAR_5]] block %[[VAR_0]] (%[[TYPE_1]], %[[VAR_6]], %[[TYPE_3]], %[[AGGREGATE_0]], %[[TYPE_7]], %[[VAR_7]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {or_self_of = "select", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "use" : <Value>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 2 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq vector 2 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[INST_3:.*]] = mpir.inst <call> block %[[VAR_0]] (%[[TYPE_8]], %[[GLOBAL_0]], %[[TYPE_9]], %[[VAR_6]], %[[TYPE_10]], %[[ALT_0]], %[[TYPE_12]], %[[VAR_7]], %[[TYPE_14]], %[[ALT_1]]) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0, 0, 0]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[READ_0]] : <Boolean>
// CHECK:         }

// -----

// ':o' on a use of a matcher.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.alt {
    %i_d = mpir.inst <add> (%0, %x, %0, %x) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_d : <Instruction>
  }, {
    mpir.yield %x : <Operand>
  } attributes {or_self_of = "twice", or_self_region = 1 : i32, result_name = "d"} : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %i_e = mpir.inst <mul> (%2, %1, %2, %x) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           } attributes {or_self_of = "twice", or_self_region = 1 : i32, result_name = "d"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_0]]) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:         }

// -----

// Without ':o', nothing to check.
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %2 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  }, {
    %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
// CHECK:         }
