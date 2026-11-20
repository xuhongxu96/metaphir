// RUN: %metaphir-opt --split-input-file --mpir-desugar-metaflags %s | FileCheck %s
// mpir-desugar-metaflags on subjects the parser does not give a defined
// metaflag: an integer constant is read as a literal, a boolean one where
// the definition reads a boolean; an instruction, captured or not, is read
// as itself.

mpir.metaflag_def @small <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @small <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Integer> loc("desugar-metaflags-constants.mlir":11:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Integer>
  %ten = mpir_expr.int 10 : ui64 : !mpir.sort<Integer> loc("desugar-metaflags-constants.mlir":13:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 10 : ui64 : <Integer>
  %lt = mpir_expr.call call "ult"(%r, %ten) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":15:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[READ_0]], %[[INT_0]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %lt : !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":17:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags-constants.mlir":19:1)
// CHECK:         }
mpir.metaflag_def @set <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @set <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":25:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %r : !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":27:1)
// CHECK:           mpir.yield %[[READ_0]] : <Boolean>
} loc("desugar-metaflags-constants.mlir":29:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("desugar-metaflags-constants.mlir":33:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %i1 = mpir.type.int 1 : !mpir.sort<Type> loc("desugar-metaflags-constants.mlir":35:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("desugar-metaflags-constants.mlir":37:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %five = mpir.int 5 : ui3 : !mpir.sort<Value> loc("desugar-metaflags-constants.mlir":39:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 5 : ui3 : <Value>
  %minus = mpir.int -5 : si4 : !mpir.sort<Value> loc("desugar-metaflags-constants.mlir":41:1)
// CHECK:           %[[INT_1:.*]] = mpir.int -5 : si4 : <Value>
  %true = mpir.int 1 : ui1 : !mpir.sort<Value> loc("desugar-metaflags-constants.mlir":43:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 1 : ui1 : <Value>
  %a = mpir.inst <add>(%i32, %x, %i32, %five) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[], [#mpir.metaflag<"small", [], loc("desugar-metaflags-constants.mlir":45:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %b = mpir.inst <add>(%i32, %a, %i32, %minus) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[], [#mpir.metaflag<"small", [], loc("desugar-metaflags-constants.mlir":47:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %c = mpir.inst <and>(%i1, %x, %i1, %true) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[], [#mpir.metaflag<"set", [], loc("desugar-metaflags-constants.mlir":49:1)>, #mpir.metaflag<"small", [], loc("desugar-metaflags-constants.mlir":49:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_2:.*]] = mpir.inst <and> (%[[TYPE_1]], %[[VAR_0]], %[[TYPE_1]], %[[INT_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "c"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:           %[[INT_3:.*]] = mpir_expr.int 5 : ui64 : <Integer>
// CHECK:           %[[INT_4:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[INT_3]], %[[INT_4]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[INT_5:.*]] = mpir_expr.int -5 : si64 : <Integer>
// CHECK:           %[[INT_6:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "ult"(%[[INT_5]], %[[INT_6]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
// CHECK:           mpir.require %[[BOOL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[INT_7:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[INT_8:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "ult"(%[[INT_7]], %[[INT_8]]) anchor %[[INST_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags-constants.mlir":65:1)
// CHECK:         }

// -----

// The instruction is the subject of its flags, whether it is captured or not.
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags-constants.mlir":75:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %one = mpir_expr.call call "hasOneUse"(%r) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":77:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %one : !mpir.sort<Boolean> loc("desugar-metaflags-constants.mlir":79:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags-constants.mlir":81:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("desugar-metaflags-constants.mlir":85:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("desugar-metaflags-constants.mlir":87:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %cap = mpir.var "cap" : !mpir.sort<Instruction> loc("desugar-metaflags-constants.mlir":89:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "cap" : <Instruction>
  %a = mpir.inst <add> capture %cap (%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("desugar-metaflags-constants.mlir":91:1)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_1]] (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags-constants.mlir":96:1)
// CHECK:         }
