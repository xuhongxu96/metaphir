// RUN: %metaphir-opt --mpir-lower %s | FileCheck %s
// mpir-lower runs the four lowering passes in order: a surface pattern
// with metaflags, a use of a matcher and choices becomes instructions,
// alternatives and requirements only.

mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %z = mpir_expr.call call "isZero"(%r) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %z : !mpir.sort<Boolean>
}
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : !mpir.sort<Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <add>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <sub>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction>
  }
}
mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %y = mpir.var "y" : !mpir.sort<Operand>
  %u = mpir.use @addOrSub(%i32, %x, %i32, %y) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %m = mpir.inst <mul>(%i32, %u, %i32, %x) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } attributes {commuted, result_name = "u"} : <Instruction>
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {result_name = "u"} : <Instruction>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {or_self_of = "mul", or_self_region = 0 : i32, result_name = "m"} : <Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:         }
