// RUN: %metaphir-opt --split-input-file --mpir-expand-matchers %s | FileCheck %s
// mpir-expand-matchers on a module whose metaflags are not desugared yet:
// those of the branch's instructions and operands are copied as written.

// Metaflags in a branch.
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
mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
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
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"zero", [], {{.*}}>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"zero", [], {{.*}}>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }
