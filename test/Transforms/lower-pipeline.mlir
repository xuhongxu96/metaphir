// RUN: %metaphir-opt --mpir-lower %s | FileCheck %s
// mpir-lower runs the four lowering passes in order: a surface pattern
// with metaflags, a use of a matcher and choices becomes instructions,
// alternatives and requirements only.

mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("lower-pipeline.mlir":10:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %z = mpir_expr.call call "isZero"(%r) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("lower-pipeline.mlir":12:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %z : !mpir.sort<Boolean> loc("lower-pipeline.mlir":14:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("lower-pipeline.mlir":16:1)
// CHECK:         }
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : !mpir.sort<Type> loc("lower-pipeline.mlir":20:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("lower-pipeline.mlir":22:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <add>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"c", [], loc("lower-pipeline.mlir":28:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret", metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction> loc("lower-pipeline.mlir":30:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("lower-pipeline.mlir":32:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <sub>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("lower-pipeline.mlir":38:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction> loc("lower-pipeline.mlir":40:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("lower-pipeline.mlir":42:1)
// CHECK:           }
} loc("lower-pipeline.mlir":44:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("lower-pipeline.mlir":48:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("lower-pipeline.mlir":50:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : !mpir.sort<Operand> loc("lower-pipeline.mlir":52:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
  %u = mpir.use @addOrSub(%i32, %x, %i32, %y) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("lower-pipeline.mlir":56:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "u"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "u"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } <result_name = "u", commuted> : <Instruction>
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "u"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } <result_name = "u"> : <Instruction>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
  %m = mpir.inst <mul>(%i32, %u, %i32, %x) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [], loc("lower-pipeline.mlir":69:1)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } <result_name = "m", or_self_of = "mul", or_self_region = 0> : <Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("lower-pipeline.mlir":78:1)
// CHECK:         }
