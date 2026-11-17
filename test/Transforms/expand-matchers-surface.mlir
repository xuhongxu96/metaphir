// RUN: %metaphir-opt --split-input-file --mpir-expand-matchers %s | FileCheck %s
// mpir-expand-matchers on a module whose metaflags are not desugared yet:
// those of the branch's instructions and operands are copied as written.

// Metaflags in a branch.
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("expand-matchers-surface.mlir":10:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("expand-matchers-surface.mlir":12:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("expand-matchers-surface.mlir":14:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("expand-matchers-surface.mlir":16:1)
// CHECK:         }
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("expand-matchers-surface.mlir":22:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("expand-matchers-surface.mlir":24:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("expand-matchers-surface.mlir":26:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("expand-matchers-surface.mlir":28:1)
// CHECK:         }
mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers-surface.mlir":32:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers-surface.mlir":34:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("expand-matchers-surface.mlir":40:1)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("expand-matchers-surface.mlir":40:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret", metaflags = [#mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"zero", [], {{.*}}>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers-surface.mlir":42:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers-surface.mlir":44:1)
// CHECK:           }
} loc("expand-matchers-surface.mlir":46:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers-surface.mlir":50:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers-surface.mlir":52:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers-surface.mlir":54:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers-surface.mlir":56:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r", metaflags = [#mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"zero", [], {{.*}}>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
} loc("expand-matchers-surface.mlir":61:1)
// CHECK:         }
