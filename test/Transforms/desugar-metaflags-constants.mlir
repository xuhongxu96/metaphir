// RUN: %metaphir-opt --split-input-file --mpir-desugar-metaflags %s | FileCheck %s
// mpir-desugar-metaflags on subjects the parser does not give a defined
// metaflag: an integer constant is read as a literal, a boolean one where
// the definition reads a boolean; a captured instruction is read through
// its capture.

mpir.metaflag_def @small <param_names = ["v"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Integer>
  %ten = mpir_expr.int 10 : ui64 : !mpir.sort<Integer>
  %lt = mpir_expr.call call "ult"(%r, %ten) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %lt : !mpir.sort<Boolean>
}
mpir.metaflag_def @set <param_names = ["v"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %r : !mpir.sort<Boolean>
}
mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %i1 = mpir.type.int 1 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %five = mpir.int 5 : ui3 : !mpir.sort<Value>
  %minus = mpir.int -5 : si4 : !mpir.sort<Value>
  %true = mpir.int 1 : ui1 : !mpir.sort<Value>
  %a = mpir.inst <add>(%i32, %x, %i32, %five) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[], [#mpir.metaflag<"small", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %b = mpir.inst <add>(%i32, %a, %i32, %minus) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[], [#mpir.metaflag<"small", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %c = mpir.inst <and>(%i1, %x, %i1, %true) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[], [#mpir.metaflag<"set", [], loc(unknown)>, #mpir.metaflag<"small", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @small <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Integer>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[READ_0]], %[[INT_0]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @set <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[READ_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 5 : ui3 : <Value>
// CHECK:           %[[INT_1:.*]] = mpir.int -5 : si4 : <Value>
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[INT_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_2:.*]] = mpir.inst <and> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[INT_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 5 : ui64 : <Integer>
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[INT_3]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[INT_5:.*]] = mpir_expr.int -5 : si64 : <Integer>
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "ult"(%[[INT_5]], %[[INT_6]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           mpir.require %[[BOOL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "ult"(%[[INT_7]], %[[INT_8]]) anchor %[[INST_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// The capture of an instruction is the subject of the instruction's flags.
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %one = mpir_expr.call call "hasOneUse"(%r) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %one : !mpir.sort<Boolean>
}
mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %cap = mpir.var "cap" : !mpir.sort<Instruction>
  %a = mpir.inst <add> capture %cap (%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "cap" : <Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_1]] (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }
