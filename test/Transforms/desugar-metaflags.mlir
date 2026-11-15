// RUN: %metaphir-opt --split-input-file --mpir-desugar-metaflags %s | FileCheck %s
// mpir-desugar-metaflags turns each metaflag into an mpir.require of its
// definition's body, read on the flag's subject: the operand it is written
// on, or the instruction. ':c' and ':o' are choices, and stay.

// A defined metaflag on an operand: its body, with the subject read as a
// value.
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// On an instruction: the subject is the instruction itself.
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
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
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// On an operand that is another instruction of the pattern.
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"s", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
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
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// ':or' is the disjunction of its flags, ':not' the negation.
mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], loc(unknown)>, #mpir.metaflag<"allOnes", [], loc(unknown)>, #mpir.metaflag<"power2", [], loc(unknown)>], loc(unknown)>], [#mpir.metaflag<"not", [#mpir.metaflag<"zero", [], loc(unknown)>], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call unary "!"(%[[CALL_5]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// Nested combinators.
mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"not", [#mpir.metaflag<"zero", [], loc(unknown)>], loc(unknown)>, #mpir.metaflag<"not", [#mpir.metaflag<"or", [#mpir.metaflag<"allOnes", [], loc(unknown)>, #mpir.metaflag<"power2", [], loc(unknown)>], loc(unknown)>], loc(unknown)>], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call unary "!"(%[[CALL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call unary "!"(%[[CALL_4]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_5]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// Integer arguments become literals, signed when negative.
mpir.metaflag_def @between <param_names = ["v", "lo", "hi"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>, %arg1: !mpir.sort<Unknown>, %arg2: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg1 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %2 = mpir_expr.call call "sle"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %4 = mpir_expr.read %arg2 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %5 = mpir_expr.call call "sle"(%3, %4) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %6 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"between", [-5, 10], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @between <param_names = ["v", "lo", "hi"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "sle"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_2]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "sle"(%[[READ_2]], %[[READ_3]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int -5 : si64 : <Integer>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "sle"(%[[INT_0]], %[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "sle"(%[[READ_1]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// The choices ':c' and ':o' are kept; the others around them go.
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc(unknown)>, #mpir.metaflag<"s", [], loc(unknown)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.int 0 : ui1 : <Value>
  %i_b = mpir.inst <sub> (%1, %2, %1, %i_a) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], loc(unknown)>, #mpir.metaflag<"s", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INT_0]], %[[TYPE_1]], %[[INST_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// A value-tracking operator in a definition is anchored at the instruction
// the flag is written on.
mpir.metaflag_def @knownNegative <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isKnownNegative"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"knownNegative", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @knownNegative <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownNegative"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownNegative"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// A definition that calls a 'constraint' definition keeps the call.
mpir.constraint_def @isConstantInt <param_names = ["v"]> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.str "ConstantInt" : <String>
  %2 = mpir_expr.call call "isa"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<String>) -> !mpir.sort<Boolean>
  mpir.yield %2 : <Boolean>
}
mpir.constraint_def @isAPIntAllowPoison <param_names = ["v"]> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isConstantInt(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %2 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %3 = mpir_expr.call call "isConstantSplat"(%2) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.call binary "||"(%1, %3) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %6 = mpir_expr.call call "isAnyIntegralConstant"(%5) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "&&"(%4, %6) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %7 : <Boolean>
}
mpir.constraint_def @isAPInt <param_names = ["v"]> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isAPIntAllowPoison(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %2 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %3 = mpir_expr.call call "isForbidPoison"(%2) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.call binary "&&"(%1, %3) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %4 : <Boolean>
}
mpir.metaflag_def @apInt <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isAPInt(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"apInt", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.constraint_def @isConstantInt <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "ConstantInt" : <String>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isa"(%[[READ_0]], %[[STR_0]]) : (!mpir.sort<Unknown>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.constraint_def @isAPIntAllowPoison <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isConstantInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isConstantSplat"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAnyIntegralConstant"(%[[READ_2]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_3]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.constraint_def @isAPInt <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPIntAllowPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isForbidPoison"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @apInt <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[APPLY_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// A definition for instructions, reading the instruction's opcode.
mpir.metaflag_def @isadd <param_names = ["i"], placement = 1> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "opcode"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
  %2 = mpir_expr.str "add" : <String>
  %3 = mpir_expr.call binary "=="(%1, %2) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
  mpir.yield %3 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"isadd", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @isadd <param_names = ["i"], placement = 1> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// Several flags on one operand, and on both operands: one requirement
// each, in order.
mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>, #mpir.metaflag<"power2", [], loc(unknown)>], [#mpir.metaflag<"allOnes", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isPower2"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// On a use of a matcher, and inside a matcher's branches, whose parameters
// are the subjects.
mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>], operand_metaflags = [[], [#mpir.metaflag<"power2", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>], operand_metaflags = [[#mpir.metaflag<"allOnes", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[VAL_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[USE_0:.*]] = mpir.use @addz (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[USE_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[USE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[USE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// On a flag-captured, typed and array operands' neighbours: only value
// operands have subjects.
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @notUndef <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isGuaranteedNotToBeUndef"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %p = mpir.var "p" : <CmpPredicate>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_c = mpir.inst <icmp> (%p, %0, %x, %0, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], operand_metaflags = [[], [#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.type.ptr : () -> !mpir.sort<Type>
  %q = mpir.var "q" : <Operand>
  %al = mpir.var "al" : <Nat>
  %i_l = mpir.inst <load> (%1, %2, %q, %al) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [2, 0, 6], operand_metaflags = [[], [#mpir.metaflag<"notUndef", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.global "f" : <Value>
  %5 = mpir.type.int 32 : <Type>
  %ts = mpir.var "ts" : <TypeArray>
  %vs = mpir.var "vs" : <ValueArray>
  %i_f = mpir.inst <call> (%3, %4, %5, %i_l, %ts, %vs) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4], operand_metaflags = [[], [], [#mpir.metaflag<"s", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @notUndef <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndef"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "p" : <CmpPredicate>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> (%[[VAR_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "q" : <Operand>
// CHECK:           %[[VAR_4:.*]] = mpir.var "al" : <Nat>
// CHECK:           %[[INST_1:.*]] = mpir.inst <load> (%[[TYPE_1]], %[[TYPE_2]], %[[VAR_3]], %[[VAR_4]]) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "f" : <Value>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_5:.*]] = mpir.var "ts" : <TypeArray>
// CHECK:           %[[VAR_6:.*]] = mpir.var "vs" : <ValueArray>
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_3]], %[[GLOBAL_0]], %[[TYPE_4]], %[[INST_1]], %[[VAR_5]], %[[VAR_6]]) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 4]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndef"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// Constraints written in the pattern come after the flags' requirements
// of the instructions before them.
mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 1 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean>
  %4 = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand>
  %i_b = mpir.inst <mul> (%4, %i_a, %4, %z) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[], [#mpir.metaflag<"power2", [], loc(unknown)>]]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %5 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.int 2 : ui64 : <Integer>
  %7 = mpir_expr.call binary "=="(%5, %6) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean>
}
// CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0:.*]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[VAL_1:.*]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAL_0]] = mpir.var "z" : <Operand>
// CHECK:           %[[VAL_1]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAL_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 2 : ui64 : <Integer>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[INT_1]]) anchor %[[VAL_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
// CHECK:         }
