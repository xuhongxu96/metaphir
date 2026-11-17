// RUN: %metaphir-opt --mpir-lower-alternatives %s | FileCheck %s
// mpir-lower-alternatives on a module whose metaflags are not desugared:
// an instruction with other metaflags only is left as it is, and one with
// a choice among them loses them all.

mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("lower-alternatives-surface.mlir":8:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("lower-alternatives-surface.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %a = mpir.inst <add>(%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("lower-alternatives-surface.mlir":12:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a", metaflags = [#mpir.metaflag<"s", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %b = mpir.inst <mul>(%i32, %a, %i32, %x) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("lower-alternatives-surface.mlir":15:1)>, #mpir.metaflag<"c", [], loc("lower-alternatives-surface.mlir":15:1)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("lower-alternatives-surface.mlir":15:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "b"} : <Instruction>
} loc("lower-alternatives-surface.mlir":22:1)
// CHECK:         }
